# Graph RTL verification manifests

AccelGraph Phase 0 consumes the pinned CAPI-Precis manifest API and owns only
graph layout, topology, and graph-RTL evidence.

| Artifact | Purpose |
| --- | --- |
| `manifests/layouts.json` | Exact CAPI pin, 11 layout identities, topology, status, and expected-failure contracts |
| `manifests/*.f` | Eight active ordered ModelSim/Quartus design source sets |
| `manifests/*.xfail.f` | Three intended PageRank PUSH source sets with exact missing-file signatures |
| `manifests/rtl-inventory.json` | All 118 graph RTL paths with declarations, hashes, equivalence groups, membership, and evidence |
| `scripts/verify_manifests.py` | G0 pin/layout/source-set/inventory gate |
| `scripts/layout_query.py` | Canonical layout ID and hardcoded topology query |
| `models/fp_vendor_blackboxes.sv` | Portable lint boundary for two Quartus floating-point IP wrappers |

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
