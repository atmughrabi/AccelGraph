import AFU_PKG::*;

bind cached_afu accelerator_verification #(
    .CHECK_TARGET(1'b1)
) accelerator_verification_instant (
    .clock              (clock),
    .rstn               (reset_afu_internal),
    .enabled            (enabled),
    .reset_done         (reset_done),
    .cu_done            (cu_done),
    .cu_return_done_ack (cu_return_done_ack),
    .completion_valid   (done_control_instant.current_state == DONE_MMIO_REQ),
    .report_errors      (report_errors),
    .afu_status         (afu_status),
    .cu_status          (cu_status),
    .afu_configure_1    (afu_configure.var1),
    .cu_configure_1     (cu_configure.var1),
    .cu_configure_2     (cu_configure.var2),
    .cu_configure_3     (cu_configure.var3),
    .cu_configure_4     (cu_configure.var4),
    .cu_return_1        (cu_return.var1),
    .cu_return_2        (cu_return.var2),
    .cu_return_done_1   (cu_return_done.var1),
    .cu_return_done_2   (cu_return_done.var2),
    .target_valid       (wed.valid),
    .target_count       (wed.payload.wed.num_vertices),
    .failure_count      (),
    .cover_mask         ()
);
