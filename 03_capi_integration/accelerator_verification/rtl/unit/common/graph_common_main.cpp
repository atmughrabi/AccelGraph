// -----------------------------------------------------------------------------
//      AccelGraph RTL unit harness entry point - graph common families
// -----------------------------------------------------------------------------
// The top module differs per suite, so the generated class is selected through
// VTOP_HEADER and VTOP_TYPE which run_common.py passes on the compiler command
// line.
// -----------------------------------------------------------------------------
#include VTOP_HEADER
#include "verilated.h"
#include "verilated_cov.h"

int main(int argc, char **argv)
{
    VerilatedContext context;
    VTOP_TYPE top{&context};

    context.commandArgs(argc, argv);
    while(!context.gotFinish())
    {
        top.eval();
        context.timeInc(1);
    }
    top.final();
#if VM_COVERAGE
    context.coveragep()->write("coverage.dat");
#endif

    return 0;
}
