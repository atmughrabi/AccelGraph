# AccelGraph RTL accelerator verification

The generic simulation-only monitor is owned by CAPI-Precis at
`01_capi_precis/01_capi_integration/accelerator_rtl/verification/accelerator_verification.sv`.
AccelGraph consumes that source directly and supplies only the graph-specific
bind and regressions.

`accelerator_verification_bind.sv` enables `CHECK_TARGET`, connects
`WED.num_vertices`, and binds the shared monitor without changing synthesizable
RTL. A violation terminates simulation with `$fatal`;
`+VERIF_FATAL=0` retains evidence without stopping at the first violation.

`accelerator_verification_tb.sv` provides positive and negative protocol
regression cases. `lint_cached_afu_bind.sh` elaborates the real `cached_afu`,
AFU-control RTL, and all eight active graph `cu_control` layouts from the
ordered Phase 0 manifests. The CU compatibility stub is excluded; implicit
nets and pin mismatches fail the gate. Portable lint blackboxes only the two
generated Quartus floating-point IP boundaries.

Run from the repository root:

```console
make rtl-verification
make rtl-real-elaboration
```
