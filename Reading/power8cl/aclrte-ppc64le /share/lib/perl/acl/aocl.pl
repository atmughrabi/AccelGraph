# (C) 1992-2015 Altera Corporation. All rights reserved.                         
# Your use of Altera Corporation's design tools, logic functions and other       
# software and tools, and its AMPP partner logic functions, and any output       
# files any of the foregoing (including device programming or simulation         
# files), and any associated documentation or information are expressly subject  
# to the terms and conditions of the Altera Program License Subscription         
# Agreement, Altera MegaCore Function License Agreement, or other applicable     
# license agreement, including, without limitation, that your use is for the     
# sole purpose of programming logic devices manufactured by Altera and sold by   
# Altera or its authorized distributors.  Please refer to the applicable         
# agreement for further details.                                                 
    


# Utility command for the Altera SDK for OpenCL

      BEGIN { 
         unshift @INC,
            (grep { -d $_ }
               (map { $ENV{"ALTERAOCLSDKROOT"}.$_ }
                  qw(
                     /host/windows64/bin/perl/lib/MSWin32-x64-multi-thread
                     /host/windows64/bin/perl/lib
                     /share/lib/perl
                     /share/lib/perl/5.8.8 ) ) );
      };


use strict;
require acl::Command;
my $prog = 'aocl';


my $cmd = new acl::Command( $prog, @ARGV );
if ( $cmd ) {
   exit (! $cmd->run());
} else {
   printf("$prog: Need a valid subcommand argument.\n");
   (new acl::Command($prog,"help"))->run();
   exit 1;
}
# vim: set ts=2 sw=2 expandtab
