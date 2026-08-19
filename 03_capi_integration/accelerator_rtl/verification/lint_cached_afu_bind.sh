#!/usr/bin/env bash
set -euo pipefail

VERILATOR=${VERILATOR:-verilator}
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../../.." && pwd)
MANIFEST_ROOT="$REPO_ROOT/verification/rtl/manifests"
CAPI_ROOT="$REPO_ROOT/01_capi_precis"
LAYOUT_QUERY="$REPO_ROOT/verification/rtl/scripts/layout_query.py"

WARNINGS=(
  -Wall
  -Wno-ASCRANGE
  -Wno-BLKANDNBLK
  -Wno-BLKSEQ
  -Wno-CASEINCOMPLETE
  -Wno-CMPCONST
  -Wno-DECLFILENAME
  -Wno-EOFNEWLINE
  -Wno-GENUNNAMED
  -Wno-IMPORTSTAR
  -Wno-MULTIDRIVEN
  -Wno-PINCONNECTEMPTY
  -Wno-SYNCASYNCNET
  -Wno-TIMESCALEMOD
  -Wno-UNDRIVEN
  -Wno-UNOPTFLAT
  -Wno-UNUSEDSIGNAL
  -Wno-UNUSEDPARAM
  -Wno-WIDTHEXPAND
  -Wno-WIDTHTRUNC
  -Werror-IMPLICIT
  -Werror-MODDUP
  -Werror-PINMISSING
  -Werror-PINNOTFOUND
  -Werror-PKGNODECL
)

lint_layout() {
  local layout=$1
  local source
  local -a sources=()

  while IFS= read -r source || [[ -n "$source" ]]; do
    [[ -z "$source" || "$source" == \#* ]] && continue
    sources+=("$REPO_ROOT/$source")
  done <"$MANIFEST_ROOT/$layout.f"

  while IFS= read -r source || [[ -n "$source" ]]; do
    [[ -z "$source" || "$source" == \#* ]] && continue
    sources+=("$CAPI_ROOT/$source")
  done <"$CAPI_ROOT/verification/rtl/manifests/monitor.f"
  sources+=("$REPO_ROOT/verification/rtl/models/fp_vendor_blackboxes.sv")
  sources+=("$SCRIPT_DIR/accelerator_verification_bind.sv")

  "$VERILATOR" --lint-only --timing "${WARNINGS[@]}" \
    --top-module cached_afu \
    "${sources[@]}"

  printf 'PASS cached_afu real graph bind %s\n' "$layout"
}

layouts_output=$("$LAYOUT_QUERY" --active-ids)
mapfile -t layouts <<<"$layouts_output"
if ((${#layouts[@]} != 8)); then
  echo "Expected 8 active layouts, found ${#layouts[@]}" >&2
  exit 1
fi
for layout in "${layouts[@]}"; do
  lint_layout "$layout"
done
printf 'PASS cached_afu real graph bind layouts=%d\n' "${#layouts[@]}"
