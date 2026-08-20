// -----------------------------------------------------------------------------
//
//      "ACCEL-GRAPH Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Verification-only behavioural stand-ins for the licensed Quartus floating
// point IP used by the FloatPoint algorithm kernels.
//
// These models are NOT a bit-exact replica of the vendor IP.  The vendor
// accumulator normalises through a wide fixed point accumulator, and its
// simulation model ships as VHDL that the portable Verilator gate cannot
// compile.  The stand-ins implement the documented streaming contract:
//
//   fp_single_add_acc : every enabled cycle accumulates `x`; `n` restarts the
//                       accumulation with `x`; the result appears on `r` after
//                       ACC_LATENCY cycles.  Arithmetic is IEEE-754 binary32
//                       with the simulator's round-to-nearest-even.
//   fp_single_mul     : `q` is the IEEE-754 binary32 product of `a` and `b`
//                       after MUL_LATENCY cycles.  MUL_LATENCY defaults to 4
//                       because cu_SPMV's FloatPoint kernel samples the product
//                       into its sixth pipeline stage four cycles after the
//                       operands are presented on the first stage.  Any other
//                       multiplier latency mis-aligns the product with the
//                       edge-data valid, which the suite reports as the
//                       float-multiplier-latency-contract finding.
//
// Bit exact agreement with the licensed IP remains release evidence produced by
// a licensed ModelSim/Questa run; it is never claimed by this suite.
// -----------------------------------------------------------------------------

`ifndef FP_ACC_LATENCY
`define FP_ACC_LATENCY 8
`endif
`ifndef FP_MUL_LATENCY
`define FP_MUL_LATENCY 4
`endif

module fp_single_add_acc #(
	parameter int ACC_LATENCY = `FP_ACC_LATENCY
) (
	input  logic        clk   ,
	input  logic        areset,
	input  logic [31:0] x     ,
	input  logic        n     ,
	output logic [31:0] r     ,
	output logic        xo    ,
	output logic        xu    ,
	output logic        ao    ,
	input  logic [ 0:0] en
);

	logic [31:0] accumulator             ;
	logic [31:0] pipe [0:ACC_LATENCY-1]  ;
	logic [31:0] next                    ;

	// Documented status contract of the vendor accumulator, reproduced here so
	// the exception outputs the kernel wires up are observable:
	//   xo : a finite accumulation rounded to an infinity   (overflow)
	//   xu : a finite non zero accumulation rounded to zero
	//        or to a subnormal                              (tininess)
	//   ao : the accumulator itself has saturated; sticky until the
	//        accumulation is restarted or the model is reset
	function automatic bit fp32_is_inf(input logic [31:0] value);
		return (value[30:23] == 8'hFF) && (value[22:0] == 23'd0);
	endfunction

	function automatic bit fp32_is_nan(input logic [31:0] value);
		return (value[30:23] == 8'hFF) && (value[22:0] != 23'd0);
	endfunction

	function automatic bit fp32_is_normal(input logic [31:0] value);
		return (value[30:23] != 8'h00) && (value[30:23] != 8'hFF);
	endfunction

	always_ff @(posedge clk) begin
		if (areset) begin
			accumulator <= 32'h0000_0000;
			xo          <= 1'b0;
			xu          <= 1'b0;
			ao          <= 1'b0;
			for (int i = 0; i < ACC_LATENCY; i++)
				pipe[i] <= 32'h0000_0000;
		end else if (en) begin
			next        = n ? x : fp32_add(accumulator, x);
			accumulator <= next;
			pipe[0]     <= next;
			for (int i = 1; i < ACC_LATENCY; i++)
				pipe[i] <= pipe[i-1];
			xo <= ~n && fp32_is_inf(next) &&
			      ~fp32_is_inf(accumulator) && ~fp32_is_nan(accumulator) &&
			      ~fp32_is_inf(x)           && ~fp32_is_nan(x);
			xu <= ~n && ~fp32_is_normal(next) &&
			      fp32_is_normal(accumulator) && fp32_is_normal(x);
			if (n)
				ao <= 1'b0;
			else if (fp32_is_inf(next) && ~fp32_is_inf(accumulator) && ~fp32_is_nan(accumulator))
				ao <= 1'b1;
		end
	end

	assign r  = pipe[ACC_LATENCY-1];

endmodule

module fp_single_mul #(
	parameter int MUL_LATENCY = `FP_MUL_LATENCY
) (
	input  logic        clk   ,
	input  logic        areset,
	input  logic [ 0:0] en    ,
	input  logic [31:0] a     ,
	input  logic [31:0] b     ,
	output logic [31:0] q
);

	logic [31:0] pipe [0:MUL_LATENCY-1];

	always_ff @(posedge clk) begin
		if (areset) begin
			for (int i = 0; i < MUL_LATENCY; i++)
				pipe[i] <= 32'h0000_0000;
		end else if (en) begin
			pipe[0] <= fp32_mul(a, b);
			for (int i = 1; i < MUL_LATENCY; i++)
				pipe[i] <= pipe[i-1];
		end
	end

	assign q = pipe[MUL_LATENCY-1];

endmodule
