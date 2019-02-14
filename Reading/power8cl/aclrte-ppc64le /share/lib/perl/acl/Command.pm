=pod

=head1 NAME

acl::Command - Utility commands for the Altera SDK for OpenCL

=head1 COPYRIGHT

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
    


=cut

package acl::Command;
require Exporter;
@acl::Command::ISA        = qw(Exporter);
@acl::Command::EXPORT     = ();
@acl::Command::EXPORT_OK  = qw();
use strict;
use acl::Env;
use acl::Board_env;
use acl::Pkg;
our $AUTOLOAD;

my @_valid_cmd_list = qw(
   version
   help
   do
   compile-config
   cflags
   link-config
   linkflags
   ldflags
   ldlibs
   board-path
   board-hw-path
   board-libs
   board-link-flags
   board-default
   board-version
   board-xml-test
   reprogram
   program
   flash
   diagnostic
   diagnose
   install
   uninstall
   example-makefile
   makefile
   binedit
   hash
   report
   vis
);

my @_valid_list = @_valid_cmd_list, qw( pre_args args cmd prog );

my %_valid_cmd = map { ($_ , 1) } @_valid_cmd_list;

my %_valid = map { ($_ , 1) } @_valid_list;

sub new {
   my ($proto,$prog,@args) = @_;
   my $class = ref $proto || $proto;

   my @pre_args = ();
   my @post_args = ();
   my $subcommand = undef;
   my $first_arg = undef;
   while ( $#args >=0 ) {
      my $arg = shift @args;
      $first_arg = $arg unless defined $first_arg;
      if ( $arg =~ m/^[a-z]/ ) {
         $subcommand = $arg;
         last;
      } else {
         push @pre_args, $arg;
      }
   }
   if ( $_valid_cmd{$subcommand} ) {
      $subcommand =~ s/-/_/g;
      return bless {
         prog => $prog, 
         pre_args => [ @pre_args ], 
         cmd => $subcommand, 
         args => [ @args ] 
         }, $class;
   } else {
      if ( defined $first_arg ) {
         $subcommand = $first_arg unless defined $subcommand;
         $subcommand = '' unless defined $subcommand;
         print STDERR "$prog: Unknown subcommand '$subcommand'\n";
      }
      return undef;
   }
}


sub do {
   my $self = shift;
   # Using "exec" would be more natural, but it doesn't work as expected on Windows.
   # http://www.perlmonks.org/?node_id=724701
   if ( $^O =~ m/Win32/ ) {
      system(@{$self->args});
      # Need to post-process $? because it's a mix of status bits, and 
      # it seems Windows only allows "main" to return up to 8b its.
      # The $? bottom 8 bits encodes signals, the upper bits encode return status.
      # So $? for the "false" program (returns 1), is actually 256, and then if we exit 256
      # then it's translated back into 0 by Windows. Thus making "false" look like it succeeded!
      my $raw_status = $?; 
      # Fold in the signal error into our 8 bit error range.
      my $processed_status = ($raw_status>>8) | ($raw_status&255);
      exit $processed_status;
   } else {
      exec(@{$self->args});
   }
}


sub run {
   my $self = shift;
   my $cmd = $self->cmd;
   my @args = @{$self->args};
   my $result = eval "\$self->$cmd(\@args)";
   if ($@) {
      return 0;
   } else {
      return $result;
   }
}


sub version {
   my ($self,@args) = @_;
   if ( $#args < 0 ) {
      my $banner = acl::Env::is_sdk() ? 'Altera SDK for OpenCL, Version 15.0.0 Build 120, Copyright (C) 2015 Altera Corporation' : 'Altera Runtime Environment for OpenCL, Version 15.0.0 Build 120, Copyright (C) 2015 Altera Corporation';
      print $self->prog." 15.0.0.120 ($banner)\n";
   } else {
      if ( $#args == 0 && $args[0] =~ m/.aocx$/i ) {
         my $result = $self->binedit($args[0],'print','.acl.version');
         print "\n";  # "binedit print" does not append the newline
         return $result;
      }
      print STDERR $self->prog." version: Unrecognized options: @args\n";
      return undef;
   }
   return $self;
}

sub report {
   my ($self,@args) = @_;
   my $aocx = undef;
   my $mon = undef;
   my @input_args;
   foreach my $arg ( @args ) {
      my ($ext) = $arg =~ /(\.[^.]+)$/;
      if ( $ext eq '.aocx' ) { $aocx = $arg;} 
      elsif ( $ext eq '.mon' ) { $mon = $arg; }
      else { push(@input_args, $arg); }
   }
   if ( defined $aocx && defined $mon ) {
      my $ACL_ROOT = acl::Env::sdk_root();
      my $QUARTUS_ROOT = $ENV{'QUARTUS_ROOTDIR'};
      if (!defined($QUARTUS_ROOT)) {
	 print $self->prog." report: QUARTUS_ROOTDIR not set, please set it to your base Quartus installation path.\n";
	 return $self;
      }
      my $java_runtime = 'linux64/jre64/bin/java';
      if (acl::Env::is_windows()) {
          $java_runtime = 'bin64/jre64/bin/java';
      }
      if ( ! -e "$ACL_ROOT/share/lib/java/reportgui.jar" ) {
	 print $self->prog." report: Altera's SDK OpenCL report application not installed, please reinstall your Altera SDK for OpenCL.\n";
	 return $self;
      }
      if ( ! -e $aocx ) {
	 print $self->prog." report: Invalid aocx file supplied: $aocx\n";
	 return $self;
      }
      if (! -e $mon ) {
	 print $self->prog." report: Invalid profile.mon file supplied: $mon\n";
	 return $self;
      }

      # check for java runtime existence
      my $command = acl::File::which( "$QUARTUS_ROOT","$java_runtime" );
      
      if (defined $command) {
         system("$QUARTUS_ROOT/$java_runtime","-jar", "$ACL_ROOT/share/lib/java/reportgui.jar", $aocx, $mon, @input_args );
      } else {
         print $self->prog               ." report: Java runtime not installed with Quartus, please reinstall Quartus   \n";
         print (" " x length($self->prog));
	 print "         and ensure the java runtime is included with your install.          \n";
      }
   } else {
      print $self->prog." report: Report needs aocx and mon\n";
      return undef;
   }
   return $self;
}


sub vis {
   my ($self,@args) = @_;
   
   if ( $#args >= 0 && ($args[0] =~ m/.aoc[xo]$/i ) ) {
      my $ACL_ROOT = acl::Env::sdk_root();
      my $VIS_BIN = "$ACL_ROOT/bin/vis";
      my $VIS_LIB = "$ACL_ROOT/share/lib/acl_vis/";
      my $AOCL_PATH = "$ACL_ROOT/bin/aocl";
      if ((! -e $VIS_BIN) && (! -e "$VIS_BIN.exe")) {
         print $self->prog." vis: Visualizer application not installed, please reinstall your Altera SDK for OpenCL.\n";
         return $self;
      }
      if (! -e $VIS_LIB) {
         print $self->prog." vis: Visualizer application missing resources, please reinstall your Altera SDK for OpenCL.\n";
         return $self;
      }
      if ( ! -e $args[0] ) {
	       print $self->prog." vis: Invalid aocx or aoco file supplied: $args[0]\n";
	       return $self;
      }
      # Temporarily pass a flag to the visualizer binary
      # TODO remove this 
      if ( $#args > 0 ) {
        system($VIS_BIN, $args[0], $VIS_LIB, $AOCL_PATH, $args[1]); 
      }
      else {
        system($VIS_BIN, $args[0], $VIS_LIB, $AOCL_PATH); 
      }
   } 
   else {
      print $self->prog." vis: Visualizer requires aocx or aoco\n";
      return undef;
   }
   return $self;
}


sub _print_or_unrecognized(@) {
   my ($self,$name,$printval,@args) = @_;
   if ( $#args >= 0 ) {
      print STDERR $self->prog." $name: Unrecognized option: $args[0]\n";
      return undef;
   }
   print $printval,"\n";
   return $self
}


sub link_config { shift->_print_or_unrecognized('link-config',acl::Env::host_link_config(@_)); }
sub linkflags { shift->_print_or_unrecognized('linkflags',acl::Env::host_link_config(@_)); }
sub ldflags { shift->_print_or_unrecognized('ldflags',acl::Env::host_ldflags(@_)); }
sub ldlibs { shift->_print_or_unrecognized('ldlibs',acl::Env::host_ldlibs(@_)); }
sub board_path { shift->_print_or_unrecognized('board-path',acl::Env::board_path(@_)); }
sub board_hw_path { 
   my ($self,$variant,@args) = @_;
   unless ( $variant ) {
      print STDERR $self->prog." board-hw-path: Missing a board variant argument\n";
      return undef;
   }
   $self->_print_or_unrecognized('board-hw-path',acl::Env::board_hw_path($variant,@args));
}
sub board_libs { shift->_print_or_unrecognized('board-libs',acl::Env::board_libs(@_)); }
sub board_link_flags { shift->_print_or_unrecognized('board-libs',acl::Env::board_link_flags(@_)); }
sub board_default { shift->_print_or_unrecognized('board-default',acl::Env::board_hardware_default(@_)); }
sub board_version { shift->_print_or_unrecognized('board-version',acl::Env::board_version(@_)); }


sub board_xml_test {
   my $self = shift;
   my $aocl = acl::Env::sdk_aocl_exe();
   print " board-path       = ".`$aocl board-path`."\n";
   my $bd_default = `$aocl board-default`;
   print " board-default    = ".$bd_default."\n";
   print " board-hw-path    = ".`$aocl board-hw-path $bd_default`."\n";
   print " board-link-flags = ".`$aocl board-link-flags`."\n";
   print " board-libs       = ".`$aocl board-libs`."\n";
   print " board-util-bin   = ".acl::Board_env::get_util_bin()."\n";
   return $self;
}

sub program {
  my ($self,@args) = @_;
  reprogram(@_);
  if ( $? ) { return undef; }
  return $self;
}

# Return full path to fpga_temp.bin
sub get_fpga_temp_bin {
   my $arg = shift @_;
   my $pkg = get acl::Pkg($arg);
   if ( !defined($pkg) ) {
     print "Failed to open file: $arg\n";
     return -1;
   }
   my $hasbin = $pkg->exists_section('.acl.fpga.bin');
   if (not $hasbin )
   {  return ""; }
   my $tmpfpgabin = acl::File::mktemp();
   my $fpgabin = $tmpfpgabin;
   if ( length $tmpfpgabin == 0 ) {
     # In case we fail to get a temp file, use local dir.  Using PID
     # as a uniqifier is safe here since this function is called only
     # once by flash, or once by program, and not both in the same process.
     $fpgabin = "fpga_temp_$$.bin";
   } else {
     $fpgabin .= '_fpga_temp.bin';
   }
   my $gotbin = $pkg->get_file('.acl.fpga.bin', $fpgabin);
   if ( !defined( $gotbin )) {
     print "Failed to extract binary section from file: $arg\n";
     print "  Tried: $fpgabin and $tmpfpgabin\n";
     return "";
   }
   return $fpgabin;
}

sub reprogram {
   my ($self, @args) = @_;
   my $utilbin = acl::Board_env::get_util_bin(); 
   my $util = ( acl::Board_env::get_board_version() < 14.1 ) ? "reprogram" : "program";
   my $command = acl::File::which( "$utilbin","$util" );
   if ( defined $command ) {
     print $self->prog." program: Running $util from $utilbin\n";
     # Parse the arguments
     my $device = undef;
     my $aocx = undef;
     my $num_args = @args;
     foreach my $arg ( @args ) {
        my ($ext) = $arg =~ /(\.[^.]+)$/;
        if ( $ext eq '.aocx' ) { $aocx = $arg;} 
        else { $device = $arg; }
     }
     # If arguments not valid, print help/usage message.
     if ( $num_args != 2 or !defined($aocx) or !defined($device)) {
        my $help = new acl::Command($self->prog, qw(help program));
        $help->run();
        return undef;
     }
     # Get .bin from the AOCX file and call reprogram with that
     my $fpgabin = get_fpga_temp_bin($aocx);
     if ( length $fpgabin == 0 ) { printf "%s program: Program failed. Error reading aocx file.\n", $self->prog; return undef; }

     system("$utilbin/$util","$device",$fpgabin);
     #remove the file we ouput
     unlink $fpgabin;

     if ( $? ) { printf "%s program: Program failed.\n", $self->prog; return undef; }
     return $self;
     print $self->prog." program: Running program from $utilbin\n";
     system("$utilbin/$util",$device,@args);
     if ( $? ) { printf "%s program: Program failed.\n", $self->prog; return undef; }
   } else { 
     print "--------------------------------------------------------------------\n";
     print "No programming routine supplied.                                    \n";
     print "Please consult your board manufacturer's documentation or support   \n";
     print "team for information on how to load a new image on to the FPGA.     \n";
     print "--------------------------------------------------------------------\n";
   }
   return $self;
}

sub flash {
   my ($self, @args) = @_;
   my $utilbin = acl::Board_env::get_util_bin(); 
   my $util = "flash";
   my $command = acl::File::which( "$utilbin","$util" );
   if ( defined $command ) {
     print $self->prog." flash: Running $util from $utilbin\n";
     # Parse the arguments
     my $device = undef;
     my $aocx = undef;
     my $num_args = @args;
     foreach my $arg ( @args ) {
        my ($ext) = $arg =~ /(\.[^.]+)$/;
        if ( $ext eq '.aocx' ) { $aocx = $arg;} 
        else { $device = $arg; }
     }
     # If arguments not valid, print help/usage message.
     if ( $num_args != 2 or !defined($aocx) or !defined($device)) {
        my $help = new acl::Command($self->prog, qw(help flash));
        $help->run();
        return undef;
     }
     # Get .bin from the AOCX file and call flash with that
     my $fpgabin = get_fpga_temp_bin($aocx);
     if ( length $fpgabin == 0 ) { printf "%s flash: Flashing failed. Error reading aocx file.\n", $self->prog; return undef; }

     system("$utilbin/$util","$device",$fpgabin);
     #remove the file we ouput
     unlink $fpgabin;

     if ( $? ) { printf "%s flash: Program failed.\n", $self->prog; return undef; }
     return $self;
     print $self->prog." flash: Running flash from $utilbin\n";
     system("$utilbin/$util",$device,@args);
     if ( $? ) { printf "%s flash: Program failed.\n", $self->prog; return undef; }
   } else { 
     print "--------------------------------------------------------------------\n";
     print "No flash routine supplied.                                    \n";
     print "Please consult your board manufacturer's documentation or support   \n";
     print "team for information on how to load a new image on to the FPGA.     \n";
     print "--------------------------------------------------------------------\n";
   }
   return $self;
}

sub diagnose {
  my ($self,@args) = @_;
  diagnostic(@_);
  if ( $? ) { return undef; }
  return $self;
}

sub diagnostic {
   my ($self,@args) = @_;
   my $utilbin = acl::Board_env::get_util_bin();
   my $util = ( acl::Board_env::get_board_version() < 14.1 ) ? "diagnostic" : "diagnose";
   my $command = acl::File::which( "$utilbin","$util" );
   if ( defined $command ) {
     print $self->prog." diagnose: Running $util from $utilbin\n";
     system("$utilbin/$util",@args);
     if ( $? ) { printf "%s diagnose: failed.\n", $self->prog; return undef; }
   } else { 
     print "--------------------------------------------------------------------\n";
     print "No board diagnose routine supplied.                               \n";
     print "Please consult your board manufacturer's documentation or support   \n";
     print "team for information on how to debug board installation problems.   \n";
     print "--------------------------------------------------------------------\n";
   }
   return $self;
}

sub install {
   my ($self,@args) = @_;
   my $utilbin = acl::Board_env::get_util_bin();
   my $util = "install";
   my $command = acl::File::which( "$utilbin","$util" );
   if ( defined $command ) {
     print $self->prog." $util: Running $util from $utilbin\n";
     system("$utilbin/$util",@args);
     if ( $? ) { printf "%s $util: failed.\n", $self->prog; return undef; }
   } else { 
     print "--------------------------------------------------------------------\n";
     print "No board installation routine supplied.                             \n";
     print "Please consult your board manufacturer's documentation or support   \n";
     print "team for information on how to properly install your board.         \n";
     print "--------------------------------------------------------------------\n";
   }
   return $self;
}

sub uninstall {
   my ($self,@args) = @_;
   my $utilbin = acl::Board_env::get_util_bin();
   my $util = "uninstall";
   my $command = acl::File::which( "$utilbin","$util" );
   if ( defined $command ) {
     print $self->prog." $util: Running $util from $utilbin\n";
     system("$utilbin/$util",@args);
     if ( $? ) { printf "%s $util: failed.\n", $self->prog; return undef; }
   } else { 
     print "--------------------------------------------------------------------\n";
     print "No board uninstallation routine supplied.                             \n";
     print "Please consult your board manufacturer's documentation or support   \n";
     print "team for information on how to properly uninstall your board.         \n";
     print "--------------------------------------------------------------------\n";
   }
   return $self;
}

sub binedit {
   my ($self,@args) = @_;
   system(acl::Env::sdk_pkg_editor_exe(),@args);
   return undef if $?;
   return $self;
}

sub hash {
   my ($self,@args) = @_;
   system(acl::Env::sdk_hash_exe(),@args);
   return undef if $?;
   return $self;
}


sub _cflags_include_only {
   my $ACL_ROOT = acl::Env::sdk_root();
   return "-I$ACL_ROOT/host/include";
}

sub _get_cross_compiler_include_directories {
   my ($cross_compiler) = @_;

   my $includes = undef;
   my $ACL_ROOT = acl::Env::sdk_root();
   my $output = `$cross_compiler -v -c $ACL_ROOT/share/lib/c/includes.c -o /dev/null 2>&1`;
   $? == 0 or print STDERR "Error determing cross compiler default include directories\n";
   my $add_includes = 0;
   my @lines = split('\n', $output); 
   foreach my $line (@lines) {
      if ($line =~ /^#include <\.\.\.> search starts here:/) {
         $add_includes = 1;
      } elsif ($line =~ /^End of search list./) {
         $add_includes = 0;
      } elsif ($add_includes) {
         $includes .= " -I".$line;
      }
   }
   return $includes." ";
}

sub compile_config {
   my ($self,@args) = @_;
   my $extra_flags = undef;
   while ( $#args >= 0 ) {
      my $arg = shift @args;
      if ( $arg eq '--arm-cross-compiler' ) {
         if (acl::Env::is_windows()) {
            print STDERR $self->prog." compile-config: --arm-cross-compiler is not supported on Windows.\n";
            return undef;
         }
         if ($#args >= 0) {
            my $cross_compiler = shift @args;
            $extra_flags = _get_cross_compiler_include_directories($cross_compiler);
         } else {
            print STDERR $self->prog." compile-config: --arm-cross-compiler requires an argument.\n";
            return undef;
         }
      } elsif ( $arg eq '--arm' ) {
         # Just swallow the arg.
      } else {
         print STDERR $self->prog." compile-config: unknown option $arg.\n"; 
         return undef;
      }
   }
   my $board_flags = acl::Board_env::get_xml_platform_tag_if_exists("compileflags");
   print $extra_flags . _cflags_include_only(). " $board_flags" . "\n";
   return $self;
}
sub cflags {
   my ($self,@args) = @_;
   compile_config(@_);
   return $self;
}


sub example_makefile {
   my ($self,@args) = @_;
   my $help = new acl::Command($self->prog, qw(help example-makefile));
   $help->run();
   return $self;
}


sub makefile {
   my ($self,@args) = @_;
   my $help = new acl::Command($self->prog, qw(help example-makefile));
   $help->run();
   return $self;
}

sub AUTOLOAD {
   my $self = shift;
   my $class = ref($self) or die "$self is not an object";
   my $name = $AUTOLOAD;
   $name =~ s/^.*:://;
   my $result = $${self}{$name};
   return $result;
}


sub help {
   my ($self,$topic) = @_;
   my $prog = $self->prog;

   my $sdk_root_name = acl::Env::sdk_root_name();
   my $is_sdk = acl::Env::is_sdk();
   my $sdk = $is_sdk ? "SDK" : "RTE";
   my $sdk_first_mention = $is_sdk ? "SDK" : "Runtime Environment (RTE)";

   my $use_aoc_note= <<USE_AOC_NOTE;
Note: Use the separate "aoc" command to compile your OpenCL kernel programs.
USE_AOC_NOTE
   my $use_aoc_in_rte_note= <<USE_AOC_IN_RTE_NOTE;
Note: Use the "aoc" command from the Altera SDK for OpenCL to compile
your OpenCL kernel programs.
USE_AOC_IN_RTE_NOTE
   my $aoc_note = $is_sdk ? $use_aoc_note : $use_aoc_in_rte_note;

   my $loader_advice =<<LOADER_ADVICE;
   Additionally, at runtime your host program must run in an enviornment
   where it can find the shared libraries provided by the Altera $sdk for
   OpenCL.  

   For example, on Windows the PATH environment variable should include
   the directory %$sdk_root_name%/host/windows64/bin.

   For example, on Linux the LD_LIBRARY_PATH environment variable should
   include the directory \$$sdk_root_name/host/linux64/lib.

See also: $prog example-makefile
LOADER_ADVICE

   my $host_compiler_options = <<HOST_COMPILER_OPTIONS;
   --msvc, --windows       Show link line for Microsoft Visual C/C++.
   --gnu, -gcc, --linux    Show link line for GCC toolchain on Linux.
   --arm                   Show link line for cross-compiling to arm.
HOST_COMPILER_OPTIONS

   my %_help_topics = (

      'example-makefile', <<MAKEFILE_EXAMPLE_HELP,

The following are example Makefile fragments for compiling and linking
a host program against the host runtime libraries included with the 
Altera $sdk for OpenCL.


Example GNU makefile on Linux, with GCC toolchain:

   AOCL_COMPILE_CONFIG=\$(shell $prog compile-config)
   AOCL_LINK_CONFIG=\$(shell $prog link-config)

   host_prog : host_prog.o
   	g++ -o host_prog host_prog.o \$(AOCL_LINK_CONFIG)

   host_prog.o : host_prog.cpp
   	g++ -c host_prog.cpp \$(AOCL_COMPILE_CONFIG)


Example GNU makefile on Windows, with Microsoft Visual C++ command line compiler:

   AOCL_COMPILE_CONFIG=\$(shell $prog compile-config)
   AOCL_LINK_CONFIG=\$(shell $prog link-config)

   host_prog.exe : host_prog.obj
   	link -nologo /OUT:host_prog.exe host_prog.obj \$(AOCL_LINK_CONFIG)

   host_prog.obj : host_prog.cpp
   	cl /MD /Fohost_prog.obj -c host_prog.cpp \$(AOCL_COMPILE_CONFIG)

    
Example GNU makefile cross-compiling to ARM SoC from Linux or Windows, with 
Linaro GCC cross-compiler toolchain:

   CROSS-COMPILER=arm-linux-gnueabihf-
   AOCL_COMPILE_CONFIG=\$(shell $prog compile-config --arm)
   AOCL_LINK_CONFIG=\$(shell $prog link-config --arm)

   host_prog : host_prog.o
   	\$(CROSS-COMPILER)g++ -o host_prog host_prog.o \$(AOCL_LINK_CONFIG)

   host_prog.o : host_prog.cpp
   	\$(CROSS-COMPILER)g++ -c host_prog.cpp \$(AOCL_COMPILE_CONFIG)


MAKEFILE_EXAMPLE_HELP

     'compile-config', <<COMPILE_CONFIG_HELP,

$prog compile-config - Show compilation flags for host programs


Usage: $prog compile-config


Example use in a GNU makefile on Linux:

   AOCL_COMPILE_CONFIG=\$(shell $prog compile-config)
   host_prog.o :
   	g++ -c host_prog.cpp \$(AOCL_COMPILE_CONFIG)

See also: $prog example-makefile

COMPILE_CONFIG_HELP


      'link-config', <<LINK_CONFIG_HELP,

$prog link-config - Show linker flags and libraries for host programs.


Usage: $prog link-config [options]

   By default the link line for the current platform are shown.


Description:

   This subcommand shows the linker flags and the list of libraries
   required to link a host program with the runtime libraries provided
   by the Altera $sdk for OpenCL.

   This subcommand combines the functions of the "ldflags" and "ldlibs"
   subcommands.

$loader_advice

Options:
$host_compiler_options

LINK_CONFIG_HELP


      'ldflags', <<LDFLAGS_HELP,

$prog ldflags - Show linker flags for building a host program.


Usage: $prog ldflags [options]

   By default the linker flags for the current platform are shown.


Description:

   This subcommand shows the general linker flags required to link 
   your host program with the runtime libraries provied by the 
   Altera $sdk for OpenCL.

   Your link line also must include the runtime libraries from the Altera
   $sdk for OpenCL as listed by the "ldlibs" subcommand.

$loader_advice

Options:
$host_compiler_options

LDFLAGS_HELP


      'ldlibs', <<LDLIBS_HELP,

$prog ldlibs - Show list of runtime libraries for building a host program.


Usage: $prog ldlibs [options]

   By default the libraries for the current platform are shown.


Description:

   This subcommand shows the list of libraries provided by the 
   Altera $sdk for OpenCL that are required link a host program.

   Your link line also must include the linker flags as listed by 
   the "ldlfags" subcommand.

$loader_advice

Options:
$host_compiler_options

LDLIBS_HELP

      'program', <<BOARD_PROGRAM_HELP,

$prog program - Configures a new FPGA design onto your board


Usage: $prog program <device_name> <file.aocx>

   Supply the .aocx file for the design you wish to configure onto 
   the FPGA.  You need to provide <device_name> to specify the FPGA 
   device to configure with. 

Description:

   This command downloads a new design onto your FPGA.
   This utility should not normally be used, users should instead use 
   clCreateProgramWithBinary to configure the FPGA with the .aocx file.

BOARD_PROGRAM_HELP

      'flash', <<BOARD_FLASH_HELP,

$prog flash - Initialize the FPGA with a specific startup configuration.


Usage: $prog flash <device_name> <file.aocx>

   Supply the .aocx file for the design you wish to set as the default
   configuration which is loaded on power up.

Description:

   This command initializes the board with a default configuration
   that is loaded onto the FPGA on power up.  Not all boards will 
   support this, check with your board vendor documentation.

BOARD_FLASH_HELP

      'diagnose', <<BOARD_DIAGNOSTIC_HELP,

$prog diagnose - Run your board vendor's test program for the board.


Usage: $prog diagnose [<device_name>]

Description:

   This command executes a board vendor test utility to verify the 
   functionality of the device specified by <device_name>.  

   If <device_name> is not specified, it will show a list of currently 
   installed devices that are supported by the board package.

   The utility should output the text DIAGNOSTIC_PASSED as the final 
   line of output.  If this is not the case (either that text is absent, 
   the test displays DIAGNOSTIC_FAILED, or the test doesn't terminate),
   then there may be a problem with the board.


BOARD_DIAGNOSTIC_HELP

      'install', <<BOARD_INSTALL_HELP,

$prog install -  Installs a board onto your host system.


Usage: $prog install

Description:

   This command installs a board's drivers and other necessary
   software for the host operating system to communicate with the
   board.  For example this might install PCIe drivers.

BOARD_INSTALL_HELP

      'uninstall', <<BOARD_UNINSTALL_HELP,

$prog uninstall -  Installs a board onto your host system.


Usage: $prog uninstall

Description:

   This command uninstalls a board's drivers and other necessary
   software for the host operating system to communicate with the
   board.  For example this might uninstall PCIe drivers.

BOARD_UNINSTALL_HELP

      'report', <<PROFILE_REPORT_HELP,

$prog report - Parse the profiled aocx and mon file and display the
               profiler GUI.


Usage: $prog report <file.aocx> <profile.mon>

Description:

   Supply the .aocx file for the design that was profiled and
   the generated .mon file from the host execution. It is
   assumed that --profile was enabled when generating the
   .aocx file (see aoc options for information on --profile).

PROFILE_REPORT_HELP

      'vis', <<VISUALIZER_APPLICATION_HELP,

$prog vis - Runs the Visualizer application.


Usage: $prog vis <file.aoco/aocx>

Description:
   
   This command takes the aoco or aocx file provided and starts up 
   the Visualizer tool for that design. 

VISUALIZER_APPLICATION_HELP

      help => <<GENERAL_HELP,

$prog - Altera $sdk_first_mention for OpenCL utility command.


$aoc_note

Subcommands for building your host program:

   $prog example-makefile  Show Makefile fragments for compiling and linking
                          a host program.
   $prog makefile          Same as the "example-makefile" subcommand.

   $prog compile-config    Show the flags for compiling your host program.
   $prog link-config       Show the flags for linking your host program with the
                          runtime libraries provided by the Altera $sdk for OpenCL.
                          This combines the function of the "ldflags" and "ldlibs"
                          subcomands.
   $prog linkflags         Same as the "link-config" subcommand.

   $prog ldflags           Show the linker flags used to link your host program
                          to the host runtime libraries provided by the Altera $sdk
                          for OpenCL.  This does not list the libraries themselves.

   $prog ldlibs            Show the list of host runtime libraries provided by the 
                          Altera $sdk for OpenCL.

Subcommands for managing an FPGA board:

   $prog program           Configure a new FPGA image onto the board.  

   $prog flash             [If supported] Initialize the FPGA with a specified
                          startup configuration.

   $prog install           Install your board into the current host system.

   $prog uninstall         Uninstall your board from the current host system.

   $prog diagnose          Run your board vendor's test program for the board.

General:

   $prog report            Parse the profile data and display GUI.
   $prog vis               Run the Visualizer application for the design supplied.
   $prog version           Show version information.
   $prog help              Show this help.
   $prog help <subcommand> Show help for a particular subcommand.
 
GENERAL_HELP
   );

   $_help_topics{'linkflags'} = $_help_topics{'link-config'};
   $_help_topics{'linkflags'} =~ s/link-config/linkflags/g;

   $_help_topics{'cflags'} = $_help_topics{'compile-config'};
   $_help_topics{'cflags'} =~ s/compile-config/cflags/g;

   $_help_topics{'makefile'} = $_help_topics{'example-makefile'};

   if ( defined $topic ) {
      my $output = $_help_topics{$topic};
      if ( defined $output ) { print $output; }
      else { print $_help_topics{'help'}; return undef; }
   } else {
      print $_help_topics{'help'};
   }
   return $self;
}


1;
