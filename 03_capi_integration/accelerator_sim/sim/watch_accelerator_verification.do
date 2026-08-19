echo Watching accelerator verification state

add wave -position insertpoint -group "Accelerator Verification" sim:/top/a0/svAFU/accelerator_verification_instant/failure_count
add wave -position insertpoint -group "Accelerator Verification" -radix hexadecimal sim:/top/a0/svAFU/accelerator_verification_instant/cover_mask
add wave -position insertpoint -group "Accelerator Verification" sim:/top/a0/svAFU/accelerator_verification_instant/verification_state
add wave -position insertpoint -group "Accelerator Verification" sim:/top/a0/svAFU/accelerator_verification_instant/completion_valid
add wave -position insertpoint -group "Accelerator Verification" sim:/top/a0/svAFU/accelerator_verification_instant/afu_config_pending
add wave -position insertpoint -group "Accelerator Verification" sim:/top/a0/svAFU/accelerator_verification_instant/cu_config_pending
add wave -position insertpoint -group "Accelerator Verification" sim:/top/a0/svAFU/accelerator_verification_instant/stall_age
add wave -position insertpoint -group "Accelerator Verification" sim:/top/a0/svAFU/accelerator_verification_instant/done_age
add wave -position insertpoint -group "Accelerator Verification" sim:/top/a0/svAFU/accelerator_verification_instant/ack_age
add wave -position insertpoint -group "Accelerator Verification" sim:/top/a0/svAFU/accelerator_verification_instant/reset_age
