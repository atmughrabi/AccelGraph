// -----------------------------------------------------------------------------
// Compilation-unit scope imports of the exact IEEE-754 binary32 helpers used by
// the FloatPoint algorithm suites.  The implementation lives in
// models/fp32_reference.cpp.
// -----------------------------------------------------------------------------

import "DPI-C" function int unsigned fp32_add(input int unsigned a, input int unsigned b);
import "DPI-C" function int unsigned fp32_mul(input int unsigned a, input int unsigned b);
import "DPI-C" function int unsigned fp32_from_ratio(input int numerator, input int denominator);
