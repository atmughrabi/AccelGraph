#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(cd "$script_dir/../.." && pwd -P)
wrapper="$repo_root/tools/capi-env"
capi_root="$repo_root/01_capi_precis"
sim_root="$repo_root/03_capi_integration/accelerator_sim"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

test -x "$wrapper"

exports=$("$wrapper" --mode host print)
(
    eval "$exports"
    test "$CAPI_PROJECT_ROOT" = "$repo_root"
    test "$CAPI_ROOT" = "$capi_root"
    test "$CAPI_SIM_ROOT" = "$sim_root"
    test "$CAPI_PROJECT" = "$(basename "$repo_root")"
)

CAPI_DEVICE=/dev/cxl/test-graph-afu \
    "$wrapper" --mode host -- bash -c '
        test "$CAPI_PROJECT_ROOT" = "$1"
        test "$CAPI_ROOT" = "$2"
        test "$CAPI_SIM_ROOT" = "$3"
        test "$CAPI_DEVICE" = /dev/cxl/test-graph-afu
    ' bash "$repo_root" "$capi_root" "$sim_root"

sim_exports=$("$wrapper" --mode sim print)
(
    eval "$sim_exports"
    test "$PSLSE_INSTALL_DIR" = "$capi_root/01_capi_integration/pslse"
    test "$PSLSE_SERVER_DAT" = "$sim_root/server/pslse_server.dat"
    test "${LD_LIBRARY_PATH%%:*}" = \
        "$capi_root/01_capi_integration/pslse/libcxl"
)

"$wrapper" --mode host check >/dev/null

for option in --project-root --capi-root --sim-root; do
    if "$wrapper" "$option" "$tmpdir" print >/dev/null 2>&1; then
        echo "$option override was accepted" >&2
        exit 1
    fi
done

if "$wrapper" \
    --intel-fpga run \
    --capi-root "$tmpdir" \
    print >/dev/null 2>&1; then
    echo "CAPI root override after an option value was accepted" >&2
    exit 1
fi

mkdir -p "$tmpdir/tools"
cp "$wrapper" "$tmpdir/tools/capi-env"
if output=$("$tmpdir/tools/capi-env" --mode host check 2>&1); then
    echo "missing canonical harness was accepted" >&2
    exit 1
fi
grep -F "git submodule update --init --recursive" <<<"$output" >/dev/null

echo "PASS accelgraph_capi_env_wrapper"
