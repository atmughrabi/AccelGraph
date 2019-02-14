
=pod

=head1 NAME

acl::Env - Mediate read access to the environment used by the Altera SDK for OpenCL.

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
    



=head1 SYNOPSIS

   use acl::Env;

   my $sdk_root = acl::Env::sdk_root();
   print "Did you set environment variable ". acl::Env::sdk_root_name() ." ?\n";

=cut

package acl::Env;
require Exporter;
@acl::Pkg::ISA        = qw(Exporter);
@acl::Pkg::EXPORT     = ();
@acl::Pkg::EXPORT_OK  = qw();
use strict;
use acl::Board_env;
use acl::File;

sub is_windows() { return $^O =~ m/Win/; }
sub pathsep() { return is_windows() ? '\\' : '/'; }

# On what platform are we running?  
# One of windows64, linux64 (Linux on x86-64), ppc64 (Linux on Power), arm32 (SoC)
sub get_arch {
   my ($arg) = shift @_;
   my $arch = $ENV{'AOCL_ARCH_OVERRIDE'};
   chomp $arch;
   if ($arg eq "--arm") {
      return 'arm32';
   } elsif ( ( $arch && $arch =~ m/Win/) || is_windows() ) {
      return 'windows64';
   } else {
      # Autodetect architecture.
      # Can override with an env var, for testability.  Matches shell wrapper.
      $arch = $arch || `uname -m`;
      chomp $arch;
      $ENV{'AOCL_ARCH_OVERRIDE'} = $arch; # Cache the result.
      if ( $arch =~ m/^x86_64/ ) {
         return 'linux64';
      } elsif ( $arch =~ m/^ppc64le/ ) {
         return 'ppc64le';
      } elsif ( $arch =~ m/^ppc64/ ) {
         return 'ppc64';
      } elsif ( $arch =~ m/^armv7l/ ) {
         return 'arm32';
      }
   }
   return undef;
}

sub sdk_root() { return $ENV{'ALTERAOCLSDKROOT'} || $ENV{'ACL_ROOT'}; }
sub sdk_root_name() { return 'ALTERAOCLSDKROOT'; }
sub sdk_root_shellname() {
   return (is_windows() ? '%' : '$' ). 'ALTERAOCLSDKROOT' . (is_windows() ? '%' : '' );
}
sub sdk_dev_bin_dir_shellname() {
   return 
      sdk_root_shellname() 
      . pathsep() 
      . (is_windows() ? 'windows64' : 'linux64' ) 
      . pathsep() 
      . 'bin';
}
sub sdk_dev_bin_dir() { 
   return 
      sdk_root() 
      . pathsep() 
      . (is_windows() ? 'windows64' : 'linux64' ) 
      . pathsep() 
      . 'bin';
}
sub sdk_bin_dir() { 
   return 
      sdk_root() 
      . pathsep() 
      . 'bin';
}
sub sdk_host_bin_dir() { return join(pathsep(), sdk_root(), 'host', get_arch(), 'bin'); }
sub is_sdk() {  return -e sdk_dev_bin_dir(); }
sub sdk_aocl_exe() { return sdk_bin_dir().pathsep().'aocl'; }
sub sdk_aoc_exe() { return sdk_dev_bin_dir().pathsep().'aoc'; }
sub sdk_pkg_editor_exe() { return sdk_host_bin_dir().pathsep().'aocl-binedit'; }
sub sdk_boardspec_exe() { return sdk_host_bin_dir().pathsep().'aocl-boardspec'; }
sub sdk_hash_exe() { return sdk_host_bin_dir().pathsep().'aocl-hash'; }
sub sdk_version() { return '15.0.0.120'; }

sub _get_host_compiler_type {
   # Returns 'msvc' or 'gnu' depending on argument selection.
   # Also return any remaining arguments after consuming an override switch.
   my @args = @_;
   my @return_args = ();
   my $is_msvc = ($^O =~ m/MSWin/i);
   my %msvc_arg = map { ($_,1) } qw( --msvc --windows );
   my %gnu_arg = map { ($_,1) } qw( --gnu --gcc --linux --arm );
   foreach my $arg ( @args ) {
      if ( $msvc_arg{$arg} ) { $is_msvc = 1; }
      elsif ( $gnu_arg{$arg} ) { $is_msvc = 0; }
      else { push @return_args, $arg; }
   }
   return ( $is_msvc ? 'msvc' : 'gnu' ), @return_args;
}

sub host_ldlibs(@) {
   # Return a string with the libraries to use, 
   # followed by remaining arguments after consuming an override switch.
   my ($host_compiler_type,@args) = _get_host_compiler_type( @_ );
   acl::Board_env::override_platform($host_compiler_type);
   my $board_libs = acl::Board_env::get_xml_platform_tag("linklibs");
   my $result = '';
   my $emulator_additions = '';
   my $c_acceleration = 0;
   my @return_args = ();
   foreach my $arg (@args) {
      if ($arg eq '--altera-c-acceleration' and not is_windows()) {
         $c_acceleration = 1;
      } else {
         push @return_args, $arg;
      }
   }
   if ( $host_compiler_type eq 'msvc' ) {
      $result = "$board_libs alteracl.lib acl_emulator_kernel_rt.lib pkg_editor.lib libelf.lib acl_hostxml.lib";
   } else {
      if ($c_acceleration) {
         $result = "-lc_accel_runtime ";
      }
      if ((get_arch() eq 'linux64') and (!$c_acceleration)) {
         $emulator_additions = "-lacl_emulator_kernel_rt ";
      }
      # -ldl needs to be after -lalteracl
      $result .= "-Wl,--no-as-needed -lalteracl $emulator_additions $board_libs -lelf -lrt -ldl -lstdc++";
   }
   return $result,@return_args;
}


sub host_ldflags(@) {
   # Return a string with the linker flags to use (but not the list of libraries),
   # followed by remaining arguments after consuming an override switch.
   my ($host_compiler_type,@args) = _get_host_compiler_type( @_ );
   acl::Board_env::override_platform($host_compiler_type);
   my $board_flags = acl::Board_env::get_xml_platform_tag("linkflags");
   my $result = '';
   if ( $host_compiler_type eq 'msvc' ) {
      $result = "/libpath:".sdk_root()."/host/windows64/lib";
   } else {
      my $host_arch = get_arch(@_);
      $result = "$result-L".sdk_root()."/host/$host_arch/lib";
   }
   if ( ($board_flags ne '') && ($board_flags ne $result) ) { $result = $board_flags." ".$result; }
   return $result,@args;
}


sub host_link_config(@) {
   # Return a string with the link configuration, followed by remaining arguments.
   my ($host_compiler_type,@args) = _get_host_compiler_type( @_ );
   my $sub_args = "--$host_compiler_type";
   my ($ldflags) = host_ldflags(@_);
   my ($ldlibs, @return_args) = host_ldlibs($sub_args, @args);
   return "$ldflags $ldlibs", @return_args;
}


sub board_path(@) {
   # Return a string with the board path,
   # followed by remaining arguments after consuming an override switch.
   return acl::Board_env::get_board_path(),@_;
}

sub aocl_boardspec(@) { 
  my ($boardspec, $cmd ) = @_;
  $boardspec = acl::File::abs_path("$boardspec" . "/board_spec.xml") if ( -d $boardspec );
  if ( ! -f $boardspec ) {
    return "Error: Can't find board_spec.xml ($boardspec)";
  }
  my ($exe) = (sdk_boardspec_exe());
  my $result = `$exe \"$boardspec\" $cmd`;
  return $result;
}

# Return a hash of name -> path 
sub board_hw_list(@) {
  my (@args) = @_;
  my %boards = ();

  # We want to find $acl_board_path/*/*.xml, however acl::File::simple_glob
  # cannot handle the two-levels of wildcards. Do one at a time.
  my $acl_board_path = acl::Board_env::get_board_path();
  $acl_board_path .= "/";
  $acl_board_path .= acl::Board_env::get_hardware_dir();
  $acl_board_path = acl::File::abs_path($acl_board_path);
  my @board_dirs = acl::File::simple_glob($acl_board_path . "/*");
  foreach my $dir (@board_dirs) {
    my @board_spec = acl::File::simple_glob($dir . "/board_spec.xml");
    if(scalar(@board_spec) != 0) {
      my ($board) = aocl_boardspec($board_spec[0], "name");
      if ( defined $boards{ $board } ) {
        print "Error: Multiple boards named $board found at \n";
        print "Error:   $dir\n";
        print "Error:   $boards{ $board }\n";
        return (undef,@args);
      }
      $boards{ $board } = $dir;
    }
  }
  return (%boards,@args);
}

sub board_hw_path(@) {
   # Return a string with the path to a specified board variant,
   # followed by remaining arguments after consuming an override switch.
   my $variant = shift;
   my (%boards,@args) = board_hw_list(@_);
   if ( defined $boards{ $variant } ) {
     return ($boards{ $variant },@args);
   } else {
     # Maintain old behaviour - even if board doesn't exist, here is where
     # it would be
     my ($board_path,@args) = board_path(@args);
     my ($hwdir) = acl::Board_env::get_hardware_dir();
     return "$board_path/$hwdir/$variant",@args;
   }
}


sub board_libs(@) {
   # Return a string with the libraries to compile a host program for the current board,
   # followed by remaining arguments after consuming an override switch.
   my ($host_compiler_type,@args) = _get_host_compiler_type( @_ );
   acl::Board_env::override_platform($host_compiler_type);
   my $board_libs = acl::Board_env::get_xml_platform_tag("linklibs");
   return $board_libs,@args;
}


sub board_link_flags(@) {
   # Return a string with the link flags to compile a host program for the current board,
   # followed by remaining arguments after consuming an override switch.
   my ($host_compiler_type,@args) = _get_host_compiler_type( @_ );
   acl::Board_env::override_platform($host_compiler_type);
   my $link_flags = acl::Board_env::get_xml_platform_tag("linkflags");
   return $link_flags,@args;
}


sub board_version(@) {
   # Return a string with the board version,
   # followed by remaining arguments after consuming an override switch.
   my @args = @_;
   my $board = acl::Board_env::get_board_version();
   return $board,@args;
}

sub board_hardware_default(@) {
   # Return a string with the default board,
   # followed by remaining arguments after consuming an override switch.
   my @args = @_;
   my $board = acl::Board_env::get_hardware_default();
   return $board,@args;
}


sub board_post_qsys_script(@) {
  # Return a string with script to run after qsys. Sometimes needed to 
  # fixup qsys output.
  return acl::Board_env::get_post_qsys_script();
}

# Extract Quartus version string from output of "quartus_sh --version"
# Returns {major => #, minor => #, update => #, variant => 'string'}.
# 
# major, minor and update are self-explanatory
# variant is a special string for specially marked releases
#   e.g. "14.1.0" -> (major => 14, minor => 1, update => 0, variant => '')
#   e.g. "14.1a10s.0" -> (major => 14, minor => 1, update => 0, variant => 'a10s')
# 
# Returns undef if there is no version.
sub get_quartus_version($) {
   my $str = shift;
   if ( $str =~ /^(\d+)\.(\d+)([^\.]*)\.(\d+)$/ ) {
      return {
        major => $1,
        minor => $2,
        update => $4,
        variant => $3
      };
   }
   return undef;
}

# Compare two Quartus versions (based on output from get_quartus_version).
#   are_quartus_versions_compatible($req_ver, $ver)
# Checks if $ver is compatible with $req_ver. Returns 1 if compatible,
# 0 otherwise.
#
# Conditions for compatibility:
#   1. variant of each must be the same
#   2. major and minor numbers must be the same
#   3. update number must be >= required update number
sub are_quartus_versions_compatible($$) {
  my ($req_ver, $ver) = @_;

  if(defined($req_ver) && defined($ver)) {
    if($ver->{variant} eq $req_ver->{variant}) {
      return 0 if($ver->{major} != $req_ver->{major});
      return 0 if($ver->{minor} != $req_ver->{minor});
      return 1 if($ver->{update} >= $req_ver->{update});
    }
  }

  return 0;
}

1;
