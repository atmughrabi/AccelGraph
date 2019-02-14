#!/bin/bash
# ALTERAOCLSDKROOT must already be set
# This script updates PATH and LD_LIBRARY_PATH to add SDK's and board's libraries

# Make sure the script is being source'd, not executed.
# Otherwise, environment variables set here will not stick.
if [ ${BASH_SOURCE[0]} == "$0" ]; then
  echo "Proper usage: source init_opencl.sh"
  exit 1
fi

if [ "$ALTERAOCLSDKROOT" == "" ]; then
  echo "Error: ALTERAOCLSDKROOT is not set!"
  return 1
fi
if [ ! -d $ALTERAOCLSDKROOT ]; then
  echo "Error: ALTERAOCLSDKROOT is set but is not a directory!"
  return 1
fi

# Add to path if not already there
pathadd() {
  echo "Adding $1 to PATH"
  if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
    export PATH="$1:$PATH"
  fi
}
# Add to ld_library _path if not already there
ldpathadd() {
  echo "Adding $1 to LD_LIBRARY_PATH"
  if [ -d "$1" ]; then
    if [[ ":$LD_LIBRARY_PATH:" != *":$1:"* ]]; then
      # For non-empty, only add if not already there
      export LD_LIBRARY_PATH="$1:$LD_LIBRARY_PATH"
    fi
  fi
}

if [ "$AOCL_BOARD_PACKAGE_ROOT" != "" ]; then
  echo "AOCL_BOARD_PACKAGE_ROOT is set to $AOCL_BOARD_PACKAGE_ROOT. Using that."
else
  echo "AOCL_BOARD_PACKAGE_ROOT path is not set in environment."
  echo "Setting to default s5_ref board."
  echo "If you want to target another board, do "
  echo "   export AOCL_BOARD_PACKAGE_ROOT=<board_pkg_dir>"
  echo "and re-run this script"
  export AOCL_BOARD_PACKAGE_ROOT="$ALTERAOCLSDKROOT/board/s5_ref"
fi

pathadd "$ALTERAOCLSDKROOT/bin"
ldpathadd "$ALTERAOCLSDKROOT/host/linux64/lib"
ldpathadd "$AOCL_BOARD_PACKAGE_ROOT/linux64/lib"

