# Accelerator verification

This directory owns AccelGraph accelerator-contract verification. Runtime
watchdog code remains in `02_capi_graph/src/capi_utils`; benchmark and
algorithm tests remain beside the code they validate.

```text
host/          libcxl/watchdog integration tests and fake libcxl boundary
rtl/           graph bind/testbench, manifests, models, scripts
sim/           ModelSim verification wave configuration
```

AccelGraph Phase 0 consumes the pinned CAPI-Precis manifest API and owns only
graph layout, topology, and graph-RTL evidence.

| Artifact | Purpose |
| --- | --- |
| `rtl/manifests/layouts.json` | Exact CAPI pin, 11 layout identities, topology, status, and expected-failure contracts |
| `rtl/manifests/*.f` | Eight active ordered ModelSim/Quartus design source sets |
| `rtl/manifests/*.xfail.f` | Three intended PageRank PUSH source sets with exact missing-file signatures |
| `rtl/manifests/rtl-inventory.json` | All graph RTL paths with declarations, hashes, equivalence groups, membership, and evidence |
| `rtl/manifests/coverage-plan.json` | Graph family strategies and complete reachable-coverage policy |
| `rtl/manifests/module-test-matrix.json` | Generated one-row-per-active-module test ownership |
| `rtl/scripts/verify_manifests.py` | G0 pin/layout/source-set/inventory gate |
| `rtl/scripts/layout_query.py` | Canonical layout ID and hardcoded topology query |
| `rtl/scripts/extract_vsim_sources.tcl` | Evaluates the ModelSim source procedure |
| `rtl/scripts/test_graph_accelerator_sources.tcl` | Quartus loader regression |
| `rtl/scripts/lint_cached_afu_bind.sh` | Eight-layout real-CU elaboration gate |
| `rtl/models/fp_vendor_blackboxes.sv` | Portable lint boundary for two Quartus floating-point IP wrappers |
| `rtl/accelerator_verification_bind.sv` | Graph WED-target monitor bind |
| `rtl/accelerator_verification_tb.sv` | Positive and negative graph lifecycle regression |

Run:

```console
make rtl-manifest-verification
make rtl-real-elaboration
```

After an intentional graph RTL change, review the diff and refresh hashes:

```console
make rtl-manifest-update
```

The active gate covers BFS PULL BottomUp; PageRank PULL FloatPoint,
FixedPoint, and Quantized; SPMV PULL FloatPoint and FixedPoint;
ConnectedComponents ShiloachVishkin; and TriangleCount BinaryIntersection.

PageRank PUSH FloatPoint, FixedPoint, and Quantized remain quarantined. Each
must fail source resolution with the seven paths recorded in `layouts.json`;
a different failure or an unexpected pass fails the gate.

Portable Verilator elaboration uses blackboxes only at the generated Quartus
`fp_single_add_acc` and `fp_single_mul` boundaries. It does not replace
`cached_afu`, AFU control, or graph CU RTL. Licensed ModelSim/Quartus runs with
the generated IP models remain release evidence.

The module matrix maps all 78 active production modules across 54 source hashes
to 16 graph test families. Identical source hashes may share a compiled suite,
but every materially different package/layout context must execute before
coverage closes.
