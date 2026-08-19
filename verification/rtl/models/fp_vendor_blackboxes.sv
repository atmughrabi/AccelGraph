module fp_single_add_acc (
    input  logic        clk,
    input  logic        areset,
    input  logic [31:0] x,
    input  logic        n,
    output logic [31:0] r,
    output logic        xo,
    output logic        xu,
    output logic        ao,
    input  logic [ 0:0] en
);
endmodule

module fp_single_mul (
    input  logic        clk,
    input  logic        areset,
    input  logic [ 0:0] en,
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic [31:0] q
);
endmodule
