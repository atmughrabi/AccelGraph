// -----------------------------------------------------------------------------
//
//      "ACCEL-GRAPH Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Exact IEEE-754 binary32 helpers for the FloatPoint algorithm suites.
//
// Verilator promotes `shortreal` to double precision, so single precision
// rounding cannot be expressed in SystemVerilog on the portable backend.  These
// helpers perform the arithmetic in native C `float`, which gives exact
// binary32 round-to-nearest-even results for the independent golden model and
// for the behavioural stand-in of the licensed accumulator.
// -----------------------------------------------------------------------------

#include <cstdint>
#include <cstring>

namespace {

float bits_to_float(uint32_t bits)
{
    float value;
    std::memcpy(&value, &bits, sizeof(value));
    return value;
}

uint32_t float_to_bits(float value)
{
    uint32_t bits;
    std::memcpy(&bits, &value, sizeof(bits));
    return bits;
}

} // namespace

extern "C" uint32_t fp32_add(uint32_t a, uint32_t b)
{
    return float_to_bits(bits_to_float(a) + bits_to_float(b));
}

extern "C" uint32_t fp32_mul(uint32_t a, uint32_t b)
{
    return float_to_bits(bits_to_float(a) * bits_to_float(b));
}

extern "C" uint32_t fp32_from_ratio(int numerator, int denominator)
{
    return float_to_bits(static_cast<float>(numerator) / static_cast<float>(denominator));
}
