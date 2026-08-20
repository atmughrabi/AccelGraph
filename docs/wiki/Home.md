# AccelGraph wiki

<p align="center">
  <img src="https://raw.githubusercontent.com/atmughrabi/AccelGraph/master/06_slides/fig/logo.svg" width="220" alt="AccelGraph logo">
</p>

AccelGraph combines graph loading and preprocessing, OpenMP reference
implementations, CAPI kernels, benchmark orchestration, and result reporting.
Shared AFU-control documentation lives in the complementary
[CAPI-Precis wiki](https://github.com/atmughrabi/CAPI-Precis/wiki).

- [Benchmark guide](https://github.com/atmughrabi/AccelGraph/wiki/Benchmark-Guide) maps repository ownership, execution
  stages, algorithms, and evidence.
- [Architecture](https://github.com/atmughrabi/AccelGraph/wiki/Architecture) maps the host, AFU-control, CU-cluster, and
  graph-engine boundaries.
- [Accelerator verification](https://github.com/atmughrabi/AccelGraph/wiki/Accelerator-Verification) defines bounded CAPI
  execution inside graph algorithms.
- [Deployment runbook](https://github.com/atmughrabi/AccelGraph/wiki/Deployment-Runbook) covers benchmark launch and hang
  triage, including the scoped CAPI environment wrapper.
- [Repository structure](https://github.com/atmughrabi/AccelGraph/wiki/Repository-Structure)
  defines complementary ownership, migration order, and compatibility gates.
- [Verification infrastructure](https://github.com/atmughrabi/AccelGraph/wiki/Verification-Infrastructure)
  records graph-module, backpressure, scoreboard, golden-model, and coverage
  evidence.
- [Stabilization plan](https://github.com/atmughrabi/AccelGraph/wiki/Stabilization-Plan)
  records the benchmark acceptance matrix and rollout.
