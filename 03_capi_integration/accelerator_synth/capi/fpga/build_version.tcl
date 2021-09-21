
set TIMESTAMP [exec "date" "+%s"]
set VERSION   [binary format A24 [exec $LIBCAPI/scripts/version.py]]

set_global_assignment -name VERILOG_MACRO "BUILD_TIMESTAMP=32'd$TIMESTAMP"
set_global_assignment -name VERILOG_MACRO "BUILD_VERSION=\"$VERSION\""

set_parameter -entity build_version -name BUILD_TIMESTAMP $TIMESTAMP
set_parameter -entity build_version -name BUILD_VERSION $VERSION
