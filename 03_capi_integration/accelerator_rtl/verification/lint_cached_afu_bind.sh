#!/usr/bin/env bash
set -euo pipefail

VERILATOR=${VERILATOR:-verilator}
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../../.." && pwd)
AFU_RTL="$REPO_ROOT/01_capi_precis/01_capi_integration/accelerator_rtl"
CU_RTL="$REPO_ROOT/03_capi_integration/accelerator_rtl"

WARNINGS=(
  -Wall
  -Wno-fatal
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
)

PREFIX_SOURCES=(
  "$AFU_RTL/afu_pkgs/globals_afu_pkg.sv"
  "$AFU_RTL/afu_pkgs/capi_pkg.sv"
)

SUFFIX_SOURCES=(
  "$AFU_RTL/afu_pkgs/credit_pkg.sv"
  "$AFU_RTL/afu_pkgs/afu_pkg.sv"
  "$AFU_RTL/afu_control/parity.sv"
  "$AFU_RTL/afu_control/reset_filter.sv"
  "$AFU_RTL/afu_control/reset_control.sv"
  "$AFU_RTL/afu_control/error_control.sv"
  "$AFU_RTL/afu_control/done_control.sv"
  "$AFU_RTL/afu_control/ram.sv"
  "$AFU_RTL/afu_control/fifo.sv"
  "$AFU_RTL/afu_control/priority_arbiters.sv"
  "$AFU_RTL/afu_control/round_robin_priority_arbiter.sv"
  "$AFU_RTL/afu_control/fixed_priority_arbiter.sv"
  "$AFU_RTL/afu_control/credit_control.sv"
  "$AFU_RTL/afu_control/response_statistics_control.sv"
  "$AFU_RTL/afu_control/response_control.sv"
  "$AFU_RTL/afu_control/restart_control.sv"
  "$AFU_RTL/afu_control/command_control.sv"
  "$AFU_RTL/afu_control/tag_control.sv"
  "$AFU_RTL/afu_control/read_data_control.sv"
  "$AFU_RTL/afu_control/write_data_control.sv"
  "$AFU_RTL/afu_control/afu_control.sv"
  "$AFU_RTL/afu_control/job.sv"
  "$AFU_RTL/afu_control/mmio.sv"
  "$AFU_RTL/afu_control/wed_control.sv"
  "$SCRIPT_DIR/cached_afu_bind_cu_stub.sv"
  "$AFU_RTL/afu_control/cached_afu.sv"
  "$AFU_RTL/verification/accelerator_verification.sv"
  "$SCRIPT_DIR/accelerator_verification_bind.sv"
)

lint_variant() {
  local name=$1
  local globals_cu=$2
  local wed_pkg=$3
  local cu_pkg=$4

  "$VERILATOR" --lint-only --timing "${WARNINGS[@]}" \
    --top-module cached_afu \
    "${PREFIX_SOURCES[@]}" \
    "$CU_RTL/$globals_cu" \
    "$CU_RTL/$wed_pkg" \
    "$CU_RTL/$cu_pkg" \
    "${SUFFIX_SOURCES[@]}"

  printf 'PASS cached_afu bind %s\n' "$name"
}

lint_variant \
  BFS \
  cu_control/cu_BFS/CSR/PULL/BottomUp/pkg/globals_cu_pkg.sv \
  cu_control/cu_BFS/CSR/PULL/global_pkg/wed_pkg.sv \
  cu_control/cu_BFS/CSR/PULL/global_pkg/cu_pkg.sv

lint_variant \
  PageRank \
  cu_control/cu_PageRank/CSR/PULL/FloatPoint/pkg/globals_cu_pkg.sv \
  cu_control/cu_PageRank/CSR/PULL/global_pkg/wed_pkg.sv \
  cu_control/cu_PageRank/CSR/PULL/global_pkg/cu_pkg.sv

lint_variant \
  SPMV \
  cu_control/cu_SPMV/CSR/PULL/FloatPoint/pkg/globals_cu_pkg.sv \
  cu_control/cu_SPMV/CSR/PULL/global_pkg/wed_pkg.sv \
  cu_control/cu_SPMV/CSR/PULL/global_pkg/cu_pkg.sv

lint_variant \
  ConnectedComponents \
  cu_control/cu_ConnectedComponents/CSR/ShiloachVishkin/ShiloachVishkin/pkg/globals_cu_pkg.sv \
  cu_control/cu_ConnectedComponents/CSR/ShiloachVishkin/global_pkg/wed_pkg.sv \
  cu_control/cu_ConnectedComponents/CSR/ShiloachVishkin/global_pkg/cu_pkg.sv

lint_variant \
  TriangleCount \
  cu_control/cu_TriangleCount/CSR/BinaryIntersection/Binary/pkg/globals_cu_pkg.sv \
  cu_control/cu_TriangleCount/CSR/BinaryIntersection/global_pkg/wed_pkg.sv \
  cu_control/cu_TriangleCount/CSR/BinaryIntersection/global_pkg/cu_pkg.sv
