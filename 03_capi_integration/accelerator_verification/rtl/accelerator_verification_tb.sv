`timescale 1ns/1ps

module accelerator_verification_tb;

    logic        clock;
    logic        rstn;
    logic        enabled;
    logic        reset_done;
    logic        cu_done;
    logic        cu_return_done_ack;
    logic        completion_valid;
    logic [0:63] report_errors;
    logic [0:63] afu_status;
    logic [0:63] cu_status;
    logic [0:63] afu_configure_1;
    logic [0:63] cu_configure_1;
    logic [0:63] cu_configure_2;
    logic [0:63] cu_configure_3;
    logic [0:63] cu_configure_4;
    logic [0:63] cu_return_1;
    logic [0:63] cu_return_2;
    logic [0:63] cu_return_done_1;
    logic [0:63] cu_return_done_2;
    logic        target_valid;
    logic [31:0] target_count;
    logic [31:0] failure_count;
    logic [31:0] cover_mask;

    accelerator_verification #(
        .CONFIG_BOUND_CYCLES(8),
        .STALL_BOUND_CYCLES (4),
        .DONE_BOUND_CYCLES  (8),
        .ACK_BOUND_CYCLES   (8),
        .RESET_BOUND_CYCLES (8),
        .CHECK_TARGET       (1'b1),
        .REPORT_FAILURES    (1'b0)
    ) verification (
        .clock,
        .rstn,
        .enabled,
        .reset_done,
        .cu_done,
        .cu_return_done_ack,
        .completion_valid,
        .report_errors,
        .afu_status,
        .cu_status,
        .afu_configure_1,
        .cu_configure_1,
        .cu_configure_2,
        .cu_configure_3,
        .cu_configure_4,
        .cu_return_1,
        .cu_return_2,
        .cu_return_done_1,
        .cu_return_done_2,
        .target_valid,
        .target_count,
        .failure_count,
        .cover_mask
    );

    always #5 clock = ~clock;

    task automatic tick(input int unsigned count);
        repeat(count) @(posedge clock);
    endtask

    task automatic clear_inputs;
        begin
            enabled            = 0;
            reset_done         = 1;
            cu_done            = 0;
            cu_return_done_ack = 0;
            completion_valid   = 0;
            report_errors      = 0;
            afu_status         = 0;
            cu_status          = 0;
            afu_configure_1    = 0;
            cu_configure_1     = 0;
            cu_configure_2     = 0;
            cu_configure_3     = 0;
            cu_configure_4     = 0;
            cu_return_1        = 0;
            cu_return_2        = 0;
            cu_return_done_1   = 0;
            cu_return_done_2   = 0;
            target_valid       = 0;
            target_count       = 0;
        end
    endtask

    task automatic configure_cu;
        begin
            cu_configure_1 = 64'h1;
            tick(1);
            cu_configure_1 = 0;
            cu_configure_3 = 64'h1;
            tick(1);
            cu_configure_3 = 0;
            cu_configure_4 = 64'h1;
            tick(1);
            cu_configure_4 = 0;
            cu_status      = 64'h1;
            tick(2);
        end
    endtask

    initial begin
        clock = 0;
        rstn  = 0;
        clear_inputs();
        tick(3);
        rstn        = 1;
        enabled     = 1;
        target_valid = 1;
        target_count = 4;

        afu_configure_1 = 64'h11;
        tick(1);
        afu_configure_1 = 0;
        tick(1);
        afu_status = 64'h11;
        tick(2);

        configure_cu();

        cu_return_1 = 1;
        tick(1);
        cu_return_1 = 2;
        cu_return_2 = 1;
        tick(1);
        cu_return_1 = 4;
        cu_return_2 = 2;
        cu_done     = 1;
        tick(1);
        cu_done = 0;
        tick(1);

        reset_done = 0;
        tick(1);
        reset_done       = 1;
        completion_valid = 1;
        cu_return_done_1 = 4;
        cu_return_done_2 = 2;
        tick(2);

        cu_return_done_ack = 1;
        tick(1);
        cu_return_done_ack = 0;
        completion_valid   = 0;
        cu_return_done_1   = 0;
        cu_return_done_2   = 0;
        cu_status          = 0;
        tick(2);

        if(failure_count != 0)
            $fatal(1, "unexpected RTL verification failure count: %0d", failure_count);

        if((cover_mask & 32'h7f) != 32'h7f)
            $fatal(1, "missing RTL verification coverage: %h", cover_mask);

        rstn = 0;
        tick(2);
        clear_inputs();
        rstn         = 1;
        enabled      = 1;
        target_valid = 1;
        target_count = 0;
        configure_cu();
        cu_done = 1;
        tick(1);
        cu_done = 0;
        tick(1);
        reset_done = 0;
        tick(1);
        reset_done = 1;
        completion_valid = 1;
        tick(2);
        cu_return_done_ack = 1;
        tick(1);
        cu_return_done_ack = 0;
        completion_valid   = 0;
        cu_status          = 0;
        tick(2);

        if(failure_count != 0)
            $fatal(1, "zero-valued completion was rejected");

        rstn = 0;
        tick(2);
        clear_inputs();
        rstn               = 1;
        cu_return_done_ack = 1;
        tick(1);

        if(failure_count == 0)
            $fatal(1, "wrong-state acknowledgement was not detected");

        rstn = 0;
        tick(2);
        clear_inputs();
        rstn           = 1;
        enabled        = 1;
        cu_configure_1 = 1;
        tick(1);
        cu_configure_1 = 0;
        cu_status      = 1;
        tick(2);
        cu_return_1    = 1;
        tick(1);
        cu_return_1    = 2;
        tick(1);

        if(failure_count == 0)
            $fatal(1, "missing CU configuration words were not detected");

        rstn = 0;
        tick(2);
        clear_inputs();
        rstn    = 1;
        enabled = 1;
        configure_cu();
        cu_status = 0;
        tick(2);

        if(failure_count == 0)
            $fatal(1, "premature CU status loss was not detected");

        rstn = 0;
        tick(2);
        clear_inputs();
        rstn         = 1;
        enabled      = 1;
        target_valid = 1;
        target_count = 4;
        configure_cu();
        cu_return_1  = 3;
        cu_done      = 1;
        tick(1);
        cu_done = 0;
        tick(1);

        if(failure_count == 0)
            $fatal(1, "graph completion target mismatch was not detected");

        rstn = 0;
        tick(2);
        clear_inputs();
        rstn    = 1;
        enabled = 1;
        configure_cu();
        tick(8);

        if(failure_count == 0)
            $fatal(1, "stalled progress was not detected");

        rstn = 0;
        tick(2);
        clear_inputs();
        rstn         = 1;
        enabled      = 1;
        target_valid = 1;
        target_count = 4;
        configure_cu();
        cu_return_1 = 5;
        tick(2);

        if(failure_count == 0)
            $fatal(1, "graph progress beyond the target was not detected");

        rstn = 0;
        tick(2);
        clear_inputs();
        rstn    = 1;
        enabled = 1;
        configure_cu();
        cu_return_1 = 1;
        tick(1);
        cu_return_1 = 2;
        tick(1);
        cu_return_1 = 1;
        tick(1);

        if(failure_count == 0)
            $fatal(1, "decreasing progress was not detected");

        rstn = 0;
        tick(2);
        clear_inputs();
        rstn         = 1;
        enabled      = 1;
        target_valid = 1;
        target_count = 4;
        configure_cu();
        cu_return_1 = 4;
        cu_return_2 = 2;
        cu_done     = 1;
        tick(1);
        cu_done = 0;
        tick(1);
        reset_done = 0;
        tick(1);
        reset_done       = 1;
        completion_valid = 1;
        cu_return_done_1 = 4;
        cu_return_done_2 = 2;
        tick(2);
        cu_return_done_1 = 5;
        tick(1);

        if(failure_count == 0)
            $fatal(1, "completion mutation before acknowledgement was not detected");

        rstn = 0;
        tick(2);
        clear_inputs();
        rstn           = 1;
        enabled        = 1;
        cu_configure_1 = 1;
        tick(1);
        cu_configure_1 = 0;
        tick(12);

        if(failure_count == 0)
            $fatal(1, "configuration timeout was not detected");

        rstn = 0;
        tick(2);
        clear_inputs();
        rstn          = 1;
        enabled       = 1;
        report_errors = 1;
        tick(1);

        if(failure_count == 0)
            $fatal(1, "RTL error register was not detected");

        $display("PASS rtl_accelerator_verification");
        $finish;
    end

endmodule
