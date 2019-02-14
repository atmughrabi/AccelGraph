=pod

=head1 NAME

acl::Board_migrate - Utility to migrate platforms

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

package acl::Board_migrate;
require Exporter;
use strict;
use acl::Env;
use acl::File;

my $rpt = "automigration.rpt";

# Any successfully applied patch shoud display this:
my $success_string = "Successfully Implemented";

# Everything here assumes present working directory is in the Quartus project of the design

sub get_platform($@) {
  my ($type) = @_;

  if ( $type eq "s5_net" ) {
    return ( name     => "s5_net", 
             host     => "PCIe", 
             pgm      => "CvP", 
             flow     => "persona",
             family   => "STRATIX V",
           );
  } elsif ( $type eq "cvpqxp_13.x" ) {
      return ( name     => "cvpqxp_13.x", 
        host     => "PCIe", 
        pgm      => "CvP", 
        flow     => "qxp",
        family   => "STRATIX V",
      );
  } elsif ( $type eq "c5soc" ) {
      return ( name     => "c5soc", 
        host     => "ARM32", 
        pgm      => "ARM", 
        flow     => "unpreserved",
        family   => "CYCLONE V",
      );
  } elsif ( $type eq "a5soc" ) {
      return ( name     => "a5soc", 
        host     => "ARM32", 
        pgm      => "ARM", 
        flow     => "unpreserved",
        family   => "ARRIA V",
      );
  } elsif ( $type eq "a10_ref" ) {
      return ( name     => "a10_ref", 
        host     => "unknown", 
        pgm      => "unknown", 
        flow     => "unpreserved",
        family   => "ARRIA 10",
      );
  } elsif ( $type eq "sil_jtag" ) {
      return ( name     => "sil_jtag", 
        host     => "JTAG", 
        pgm      => "JTAG", 
        flow     => "unpreserved",
        family   => "any",
      );
  } elsif ( $type eq "sil_pcie" ) {
      return ( name     => "sil_pcie", 
        host     => "PCIe", 
        pgm      => "JTAG", 
        flow     => "unpreserved",
        family   => "any",
      );
  }
  print "Warning: Unknown platform type: $type\n";
  return undef;
}

sub detect_platform {

  ####  Get FPGA Family ###
  my @lines = get_qsf_setting("top.qsf", "FAMILY");
  if ( 1 != scalar @lines ) {
    print "Warning: Expected 1 FAMILY assignment in top.qsf\n";
    return undef;
  }
  my $family = uc $lines[0];

  ####  Get Quartus Version last compiled in ###
  @lines = get_qsf_setting("top.qsf", "LAST_QUARTUS_VERSION");
  if ( 1 != scalar @lines ) {
    print "Warning found none or too many LAST_QUARTUS_VERSION settings in top.qsf\n";
    return undef;
  }
  my $last_quartus_version = $lines[0];

  if ( 13.0 > $last_quartus_version )
  {
    print "Warning unexpected value ($last_quartus_version) for setting LAST_QUARTUS_VERSION in top.qsf\n";
    return undef;
  }

  ####  Detect if an SoC design ####
  my $is_soc = 0;
  my @qsysfiles = (acl::File::simple_glob("*.qsys"),
                   acl::File::simple_glob("iface/*.qsys"));
  foreach my $q (@qsysfiles) {
    $is_soc = 1 if acl::File::grep_file($q, "altera_hps", 0);
  }    

  my %platform;

  if ( -e "base.qsf" and -e "persona/base.root_partition.personax" and $family eq "STRATIX V") {
    return get_platform( "s5_net" );
  } elsif ( -e "acl_iface_partition.qxp" and $family eq "STRATIX V" ) {
    return get_platform( "cvpqxp_13.x" );
  } elsif ( $is_soc and $family eq "CYCLONE V" ) {
      return get_platform( "c5soc" );
  } elsif ( $is_soc and $family eq "ARRIA V" ) {
      return get_platform( "a5soc" );
  } else {
    return undef;
  }
  $platform{last_quartus_version} = $last_quartus_version;
  $platform{qsf_family} = $family;
  return %platform;
}

# Really shouldn't recreate qsf parsing, but instead should use tcl API
# But this will take a while to load tcl, load project, etc.  
sub get_qsf_setting($@) {
  my ($qsf, $setting ) = @_;
  my @lines = acl::File::grep_file( $qsf, $setting , 1);

  my @result;
  foreach my $l (@lines) {
    my $val = $l;
    $val =~ s/set_global_assignment //;
    $val =~ s/-name //;
    $val =~ s/$setting//;
    $val =~ s/\"//g;
    $val =~ s/^\s+//g;
    $val =~ s/\s+$//g;
    chomp($val);
    push (@result, $val);
  }
  return @result;
}

sub runtclmigration($@) {
  my ($name, $rpt , $title) = @_;
  my $tcl = acl::File::abs_path("$ENV{ALTERAOCLSDKROOT}/ip/board/migrate/$name/$name.tcl");
  die "Migration Tcl script $tcl not found\n" unless -e $tcl;
  open( OUT,">>$rpt");
  print OUT "-------- $title (name: $name) ----------\n";
  close OUT;

  system("quartus_sh -t $tcl >>$rpt 2>&1");
  my $success = ($? != 0) ? 0 : 1;

  open( OUT,">>$rpt");
  print OUT "$success_string\n" if $success;
  print OUT "------------------------------\n\n";
  close OUT;
  return 1;
}

####################################################
# Perform the migration
####################################################

sub migrate_platform_preqsys {

  return if ( ! -e "board_spec.xml" );
 
  my $version = ::acl::Env::aocl_boardspec( ".", "version");
  my $automigrate_type = ::acl::Env::aocl_boardspec( ".", "automigrate_type");
  my $board = ::acl::Env::aocl_boardspec( ".", "name");

  my %platform;
  if ( $automigrate_type eq "auto" ) {
    %platform = detect_platform();
  } elsif ( $automigrate_type eq "none" ) {
    return;
  } else {
    %platform = get_platform($automigrate_type);
  }

  unless ( defined $platform{name} ) {
    print "Warning: Unknown platform type, no auto migration performed\n";
    return;
  }

  $platform{version} = $version;

  unless ( open( OUT,">$rpt") ) {
    $acl::File::error = "Can't open $rpt for writing: $!";
    return;
  }

  print OUT "OpenCL Auto Migration Report\n\n";
  print OUT "To disable auto migration compile with flag: --no-auto-migrate\n\n";
  print OUT "Alternatively, you can enable/disable individual fixes\n";
  print OUT "by adding them to the include/exclude field in board_spec.xml.\n\n";

  print OUT "----------- Platform ---------\n";
  print OUT "| Board $board with auto migration type $automigrate_type and \n";
  print OUT "| board_spec version $version has the following properties:\n";
  print OUT "|   $_ = $platform{$_}\n" for (sort keys %platform);
  print OUT "------------------------------\n\n";

  my @fixes;

  my $automigrate_include = ::acl::Env::aocl_boardspec( ".", "automigrate_include");
  @fixes = split(',', $automigrate_include);

  if ( $platform{pgm} eq 'CvP' and $platform{flow} eq 'persona' and $version < 14.1 ) {
    push (@fixes, "cvphrcfix");
    push (@fixes, "cvpdanglinginputs");
  }
  if ( $platform{host} eq 'PCIe' and $version < 14.0 ) {
    push (@fixes, "pciemaximum");
  }
  if ( $platform{pgm} eq 'CvP' and $version < 14.1 ) {
    push (@fixes, "cvpenable");
  }

  if ( $platform{flow} eq 'persona' and $version < 14.1 ) {
    push (@fixes, "peripheryhash");
  }
  
  my $automigrate_exclude = ::acl::Env::aocl_boardspec( ".", "automigrate_include");
  my @list_excludes = split(',', $automigrate_exclude);

  if ( length $automigrate_include > 0 and length $automigrate_include > 0 ) {
    print OUT "----------- Inclusions/Exclusions ---------\n";
    print OUT "| Inclusions from board_spec.xml: $automigrate_include\n";
    print OUT "| Exclusions from board_spec.xml: $automigrate_exclude\n";
    print OUT "-------------------------------------------\n\n";
  }

  my @filtered_fixes;
  foreach my $f (@fixes) {
    my $found = scalar grep( $f, @list_excludes);
    push(@filtered_fixes, $f) if ( ! $found );
  }

  print OUT "----------- Fixes To Apply ---------\n";
  if ( scalar @filtered_fixes > 0 ) {
    foreach my $fix (@filtered_fixes) {
      print OUT "| $fix\n"
    }
  } else {
    print OUT "| none\n"
  }
  print OUT "------------------------------------\n\n";
  close OUT;

  process_fixes( @filtered_fixes );
}

sub process_fixes($@) {
  my @fixes = @_;

  foreach my $fix (@fixes) {

    #### FIX: CVP update HRC fix - assume fix was localized
    if ( $fix eq "cvphrcfix" ) {
      my $targetdir = "scripts/cvpupdatefix";
      open( OUT,">>$rpt");
      print OUT "-------- CvP HRC Fix (name: cvphrcfix) ----------\n";
      if ( -d $targetdir ) {
        acl::File::copy_tree( $ENV{"ALTERAOCLSDKROOT"}."/ip/board/migrate/cvpupdatefix/*", $targetdir);

        print OUT "Replaced files in $targetdir\n";
        print OUT "$success_string\n";
      } else {
        print OUT "Error: Auto migration expected to find directory $targetdir \n";
      }
      print OUT "-------------------------------------------------\n\n";
      close OUT;
    }

    #### FIX: PCIe removed Maximum setting for credit allocation
    if ( $fix eq "pciemaximum" ) {
      runtclmigration("pciemaximum",$rpt,"PCIe Maximum RX Credit Allocation");
    }

    #### FIX: Enable CvP support despite it being deprecated
    if ( $fix eq "cvpenable" ) {
      runtclmigration("cvpenable",$rpt,"CvP Enable");
    }

    #### FIX: Dangling inputs handling in 14.1 breaks 14.0 personas (232736)
    if ( $fix eq "cvpdanglinginputs" ) {
      open( OUT,">>$rpt");
      print OUT "-------- Periphy Hash Fix (name: peripheryhash) ----------\n";
      if ( open( INI,">>quartus.ini") ) {
        print INI "fitcc_disable_dangling_cvp_input_wireluts=on\n";
        close INI;
        print OUT "$success_string\n"; 
      } else {
        print OUT "Failed to open quartus.ini for write append\n"; 
      }
      print OUT "----------------------------------------------------------\n\n";
      close OUT;
    }
    
    #### FIX: Disable periphery hash gating CvP
    if ( $fix eq "peripheryhash" ) {
      open( OUT,">>$rpt");
      print OUT "-------- Periphy Hash Fix (name: peripheryhash) ----------\n";
      unlink "scripts/create_hash_hex.tcl";
      if ( acl::File::copy( $ENV{"ALTERAOCLSDKROOT"}."/ip/board/migrate/peripheryhash/create_hash_hex.tcl", "./scripts/create_hash_hex.tcl")) {
        print OUT "Replaced scripts/create_hash_hex.tcl\n";
        print OUT "$success_string\n"; 
      }else {
        print OUT "Error: Failed to replace scripts/create_hash_hex.tcl\n";
      }
      print OUT "----------------------------------------------------------\n\n";
      close OUT;
    }
  }
}
