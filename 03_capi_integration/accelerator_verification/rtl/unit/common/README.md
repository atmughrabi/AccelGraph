# Graph common RTL unit suite

Executable coverage for the `routing-demux`, `sum-reduction` and
`graph-package-contracts` families of
`03_capi_integration/accelerator_verification/rtl/manifests/coverage-plan.json`.

```
03_capi_integration/accelerator_verification/rtl/unit/common/run_common.py
```

The suite needs Verilator 5 or newer. Without it the runner skips, unless
`RTL_VERIFICATION_REQUIRED=1` is set. Everything is built under
`02_capi_graph/obj/rtl_unit_common`, which is the only directory the suite
writes to; `summary.json` there is the machine readable evidence of a run.

## What is executed

| Declaration | Distinct hashes | Context executions |
| --- | --- | --- |
| `array_struct_type_demux_bus` | 3 | 8 |
| `demux_bus` | 1 | 8 |
| `sum_reduce` | 1 | 8 |
| `WED_PKG` | 2 | 8 |
| `GLOBALS_CU_PKG` | 8 | 8 |
| `CU_PKG` | 4 | 8 |

Every layout defines its own `WED_PKG`, `GLOBALS_CU_PKG` and `CU_PKG`, so a
context is one elaboration of one active layout. The 48 declaration contexts are
covered by 24 Verilator builds: three suites per active layout, where the
routing build carries two module declarations and the package build carries
three package declarations.

The denominator is never written down by hand. `run_common.py` derives it from
`rtl-inventory.json`, `module-test-matrix.json`, `layouts.json` and the per
layout `.f` manifests, then refuses to run when `scenarios.json` disagrees with
the manifests, when the inventory and the matrix disagree about the scope, or
when a source no longer matches its recorded hash.

## Oracles

* **Routing** - an independent three stage route and payload journal. The
  selector to destination table of `array_struct_type_demux_bus` comes from
  `scenarios.json`, keyed by source hash, never from the RTL case list.
* **Reduction** - an independent 128 bit accumulation with one explicit wrap
  step to `DATA_WIDTH_OUT`, plus the enable, hold and reset contract.
* **Packages** - a byte level descriptor model. The expected field offsets are
  parsed from the packed C structure `WEDGraphCSR` in
  `02_capi_graph/include/capi_utils/capienv.h`, so the C and SystemVerilog views
  of the work element descriptor cannot drift apart.

## Coverage policy

`coverage.json` pins the observed statement, branch and toggle point count of
every measured declaration in every context. A run fails when a denominator
changes, when a reachable point is left unexercised, or when a point declared
unreachable turns out to be exercised. Unreachable points carry a reason and are
listed per context; `not_applicable` records what the families do not have at
all, such as state machines or toggle points inside packages.

## Sensitivity

Every distinct source hash is mutated in one representative context and the
mutant has to fail with the expected diagnostic. The catalogue lives in
`scenarios.json` and covers route selection, route payload, route qualification,
unassigned selector handling, reduction terms, enable gating, reset value,
descriptor field offsets, transaction ordering decode, endianness conversion,
request size rounding, layout compute unit counts and derived widths.

## Debug helpers

`--only-context`, `--skip-mutations` and `--emit-baseline` exist for iteration.
The first two report `PARTIAL` and exit nonzero so a narrowed run can never be
mistaken for closure, and `--emit-baseline` only writes an observed denominator
file for review; it is never read back as an input.
