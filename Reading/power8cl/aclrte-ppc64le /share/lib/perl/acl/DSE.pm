
=pod

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

package acl::DSE;
require Exporter;
@ISA        = qw(Exporter);
@EXPORT     = ();
@EXPORT_OK  = qw(
   dse_prologue
   dse_driver
);

use strict;

my $module = 'acl::DSE';


sub max {
    my $max = shift;
    foreach my $val (@_) {
        $max = $val if $max < $val;
    }
    return $max;
}

sub min {
    my $min = shift;
    foreach my $val (@_) {
        $min = $val if $min > $val;
    }
    return $min;
}


=head1 NAME

acl::DSE - Design Space Exploration Module

=head1 VERSION

$Header: //acds/rel/15.0/acl/sysgen/lib/acl/DSE.pm#1 $

=head1 SYNOPSIS

   use acl::DSE qw(dse_driver);

   dse_prologue();
 
    do {
       compile();
       my $util_after_dse = dse_driver($dse); 
    while ($util_after_dse == -1);

=head1 DESCRIPTION

This module provides DSE utilities
It drives the aoc compiler repeatedly thorugh DSE

=head1 METHODS

=head2 dse_prologue

Clears DSE related files from previous compiler runs

=cut 

my $ACL_DSE_CONFIG_INPUT_FILE_EXTENSION=".dse_config";
my $ACL_AREA_REPORT="area.rpt";
my $ACL_AREA_INFO_OUTPUT_FILE_EXTENSION=".area";
my $ACL_ATTRIB_INFO_OUTPUT_FILE_EXTENSION=".attrib";

# store a table of explored design points (per kernel)
# each such point is a tuple (kernel, unroll, vectorize, copies, sharingII, throughput, area, unroll_limit, vectorize_limit, copies_limit, sharingII_limit, aggressive_unroll)
my @explored_kernel_configs;

#store a table of overall design points, it includes interconnect
# each such point is a tuple (kernel1_config, kernel2_config ....., area)
my @explored_configs;

my $work_dir_stored;

sub dse_prologue {
  my $work_dir = shift;
  $work_dir_stored = $work_dir;
  unlink acl::File::simple_glob("$work_dir/\*$ACL_AREA_INFO_OUTPUT_FILE_EXTENSION");
  unlink acl::File::simple_glob("$work_dir/\*$ACL_ATTRIB_INFO_OUTPUT_FILE_EXTENSION");
  unlink acl::File::simple_glob("$work_dir/\*$ACL_DSE_CONFIG_INPUT_FILE_EXTENSION");
  unlink acl::File::simple_glob("$work_dir/\$ACL_AREA_REPORT");
  if (-e "$work_dir\*$ACL_DSE_CONFIG_INPUT_FILE_EXTENSION") {
    die("DSE: Failed to clean auto-configuration file: $acl::File::error");
  }
}

=head2 dse_driver(utilization, debug)

DSE drives the entire flow because area utilization is not known until after llc
the compilation may be restarted if it is determined that additional DSE is required
the first run has no DSE configuration files, so it assumes no vectorization and no copies on all kernels

DSE info files provide information about current vec_num_lanes and num_copies for each kernel, as well as additional performance metrics from the throughput analyzer


=cut 

my $debug = 0;

sub dse_driver {
    my $dse = shift;
    my $late = shift;
    my $rpt_line;
    my @identity_move;

    my @dse_record; 
    # parse currently compiled configuration and add it to the exploration tables
    my @kernels = acl::File::simple_glob("\*$ACL_AREA_INFO_OUTPUT_FILE_EXTENSION"); # list of kernels
    @kernels = sort @kernels;
    my $updated_limits = 0; # if I parsed updated limits on unrolling or vectorization, do not process this design point as it may not be pareto-optimal
    foreach my $kernel(@kernels) {
       # creating an identity move, it is the base for all subsequent moves
       push (@identity_move, {unroll => 1, vectorize => 1, copies => 1, sharing => 1});

       my $kernel_name = substr($kernel, 2, -length($ACL_AREA_INFO_OUTPUT_FILE_EXTENSION));
        open(KERNEL, "<./$kernel_name$ACL_AREA_INFO_OUTPUT_FILE_EXTENSION");
        while (<KERNEL> !~ m/\-\-/) {
           if (eof(KERNEL)) {
              die ("DSE: Corrupted dse info file on kernel $kernel_name\n");
           }
        }
        $rpt_line = <KERNEL>; chomp; my $kernelLEs = (split(" ", $rpt_line))[1];
        $rpt_line = <KERNEL>; chomp; my $kernelFFs = (split(" ", $rpt_line))[1];
        $rpt_line = <KERNEL>; chomp; my $kernelRAMs = (split(" ", $rpt_line))[1];
        $rpt_line = <KERNEL>; chomp; my $kernelDSPs = (split(" ", $rpt_line))[1];
        $rpt_line = <KERNEL>; chomp; my $kernelLogic = (split(" ", $rpt_line))[1];
        my $kernel_area = {
           util => $kernelLogic, 
           les  => $kernelLEs, 
           ffs  => $kernelFFs, 
           rams => $kernelRAMs, 
           dsps => $kernelDSPs};
        close(KERNEL);
        my $unroll = 1.0; # the unroll file may be missing because there is no loop
        my $unroll_limit = 1.0;
        my $aggressive_unroll = 0;
        open(KERNEL, "<./$kernel_name$ACL_ATTRIB_INFO_OUTPUT_FILE_EXTENSION");
        $rpt_line = <KERNEL>; chomp; my $vectorize = (split(" ", $rpt_line))[1];
        $rpt_line = <KERNEL>; chomp; my $vectorize_limit = (split(" ", $rpt_line))[1];
        $rpt_line = <KERNEL>; chomp; my $copies = (split(" ", $rpt_line))[1];
        $rpt_line = <KERNEL>; chomp; my $copies_limit = (split(" ", $rpt_line))[1];
        $rpt_line = <KERNEL>; chomp; my $kernel_throughput = (split(" ", $rpt_line))[1];
        $rpt_line = <KERNEL>; chomp; my $kernel_copyfactor = (split(" ", $rpt_line))[1];
        $rpt_line = <KERNEL>; chomp; my $sharing = (split(" ", $rpt_line))[1];
        $rpt_line = <KERNEL>; chomp; my $sharing_limit = (split(" ", $rpt_line))[1];
        $rpt_line = <KERNEL>; chomp; $unroll = (split(" ", $rpt_line))[1];
        $rpt_line = <KERNEL>; chomp; $unroll_limit = (split(" ", $rpt_line))[1];
        <KERNEL>;
        $rpt_line = <KERNEL>; chomp; $aggressive_unroll = (split(" ", $rpt_line))[1];
        close(KERNEL);
        # insert this row in the table, if it does not exist
        my $record_index = -1;
        my $index=0;
        # check if this compilation has determined any limit on unrolling
        my $updated_limits_kernel = 0;
        for my $record(@explored_kernel_configs) {
           if (($kernel_name eq $record->{kernel_name}) && ($unroll_limit < $record->{unroll_limit})) {
              $record->{unroll_limit} = $unroll_limit;
              $updated_limits_kernel = 1;
              print "Updated unroll limit to $unroll_limit on $kernel_name\n" if ($debug);
              $updated_limits = 1;
           }
        }
        next if ($updated_limits_kernel);
        # check if this compilation has determined any limit on sharing
        for my $record(@explored_kernel_configs) {
           if (($kernel_name eq $record->{kernel_name}) && ($unroll == $record->{unroll})) {
              if ($sharing_limit < $record->{sharing_limit}) {
                 $record->{sharing_limit} = $sharing_limit;
                 $updated_limits_kernel = 1;
                 print "Updated sharing limit to $sharing_limit on $kernel_name\n" if ($debug);
                 $updated_limits = 1;
              }
           }
        }
        next if ($updated_limits_kernel);
        # this kernel did not change any limits, I can proceed to add it
        # check if this compilation has determined any limit on vectorization - not necessary to restart
        for my $record(@explored_kernel_configs) {
           if (($kernel_name eq $record->{kernel_name}) && ($unroll == $record->{unroll})) {
              if ($vectorize_limit < $record->{vectorize_limit}) {
                 $record->{vectorize_limit} = $vectorize_limit;
                 print "Updated vectorization limit to $vectorize_limit on $kernel_name\n" if ($debug);
              }
              $unroll_limit = $record->{unroll_limit} if ($unroll_limit > $record->{unroll_limit}); # correct unroll limit when requesting a different vectorization
           }
        }
        for my $record(@explored_kernel_configs) {
           if (($kernel_name eq $record->{kernel_name}) && ($unroll == $record->{unroll}) && 
               ($vectorize == $record->{vectorize}) && ($copies == $record->{copies}) && ($sharing == $record->{sharing})) {
              # record exists, verify consistency
              if (($kernel_throughput != $record->{kernel_throughput})
                  || ($kernel_copyfactor != $record->{kernel_copyfactor})
                  || ($kernel_area->{util} != $record->{kernel_area}->{util})
                  || ($kernel_area->{les} != $record->{kernel_area}->{les})
                  || ($kernel_area->{ffs} != $record->{kernel_area}->{ffs})
                  || ($kernel_area->{rams} != $record->{kernel_area}->{rams})
                  || ($kernel_area->{dsps} != $record->{kernel_area}->{dsps})
                  || ($unroll_limit < $record->{unroll_limit})
                  || ($vectorize_limit < $record->{vectorize_limit})
                  || ($copies_limit != $record->{copies_limit})
                  || ($sharing_limit < $record->{sharing_limit})) {
                 print ("Inconsistent DSE information on kernel: ".kernel_config_to_string($record)."\n") if ($debug);
              }
              print "Have seen this kernel's configuration before\n" if ($debug);
              # record is consistent
              $record_index = $index;
              last;
           }
           $index++;
        }
        if ($record_index == -1) {
           my $record={
              kernel_name => $kernel_name,
              unroll => $unroll,
              vectorize => $vectorize,
              copies => $copies,
              sharing => $sharing,
              kernel_throughput => $kernel_throughput,
              kernel_copyfactor => $kernel_copyfactor,
              kernel_area => $kernel_area,
              aggressive_unroll => $aggressive_unroll,
              unroll_limit => $unroll_limit,
              vectorize_limit => $vectorize_limit,
              copies_limit => $copies_limit,
              sharing_limit => $sharing_limit,
           };
           $record_index = @explored_kernel_configs;
           push(@explored_kernel_configs, $record);
        }
        # add this kernel to the overall record
        print "Adding record $record_index to scanned design\n" if ($debug);
        push (@dse_record, $record_index);
    } 
    if ($updated_limits) {
       print "Corrected DSE limits\n";
    } else {
       # return unused if can't find an area file, or if the file is formatted incorrectly
       open(AREA, "<$ACL_AREA_REPORT"); 
       while (<AREA> !~ m/\-\-/) { 
          if (eof(AREA)) {
             print "Warning: No area report is available\n";
             last;
          }
       };
       $rpt_line = <AREA>; chomp; my $baseLEs = (split(" ", $rpt_line))[1];
       $rpt_line = <AREA>; chomp; my $baseFFs = (split(" ", $rpt_line))[1];
       $rpt_line = <AREA>; chomp; my $baseRAMs = (split(" ", $rpt_line))[1];
       $rpt_line = <AREA>; chomp; my $baseDSPs = (split(" ", $rpt_line))[1];
       $rpt_line = <AREA>; chomp; my $baseLogic = (split(" ", $rpt_line))[1];
       close(AREA); 
 
       my $design_area = {
          util => $baseLogic, 
          les => $baseLEs, 
          ffs => $baseFFs, 
          rams => $baseRAMs, 
          dsps => $baseDSPs
       };
       push (@dse_record, $design_area);
       if (!$late) {
          print "Early resource estimate: ".design_point_to_string(\@dse_record) if ($dse);
       }
       push (@explored_configs, \@dse_record);
    } 
    # decides whether to try a new design or accept the current design
    if ($dse > 0) {
        # is there any fitting design? if not, take the closest and share it more
        # RAMs can't be shared, so if the design does not fit because of RAMs, the only hope is vectorization
        my @fitting_designs = grep(design_fits_except_rams(@{$_}[@{$_} - 1], $dse), @explored_configs);
        if (@fitting_designs == 0) {
           print "The design may not fit\n";
           my $best_fitting =  (sort {@{$a}[@{$a} - 1]->{util} <=> @{$b}[@{$b} - 1]->{util} } @explored_configs)[0]; # sort by utilization
           print "Closest to fit: \n".design_point_to_string($best_fitting) if ($debug);
           # try to increase sharing up to a point where the design may fit
           my $sharing_move = get_best_sharing_move($best_fitting, $dse);
           # build a move which varies only in sharing
           if (build_move($best_fitting, $sharing_move) || $updated_limits) { 
              return {
                 util => -1
              };
           }
        } else {
           my @sorted_by_throughput = sort {sort_by_RAM_fitting($a, $b, $dse) ||  # prioritize RAM fitting designs
                                            (cmp_throughput($b, $a, 0))} @fitting_designs;         # sort by throughput, descending
           my @sorted_by_throughput_per_area = sort {sort_by_RAM_fitting($a, $b, $dse) ||  # prioritize RAM fitting designs
                                            (cmp_throughput($b, $a, 1))} @fitting_designs; # sort by throughput / area, descending
           my @candidates_for_improvement;
           # add moves that provide a good throughput per area tradeoff
           my $added_best = 0;
           for (my $i = 0; $i < 2; $i++) {
              if ((@sorted_by_throughput_per_area > $i)) {
                 if ($sorted_by_throughput[0] != $sorted_by_throughput_per_area[$i]) {
                    $added_best = 1;
                 }
                 push(@candidates_for_improvement, $sorted_by_throughput_per_area[$i]);
              }
           }
           # add the best known to the candidates for improvement
           if ($added_best) {
              push(@candidates_for_improvement, $sorted_by_throughput[0]);
           }
           for my $best_so_far(@candidates_for_improvement) {
              # list of moves -> unrolling 2x, vectorization 2x, copies + 1
              my $moves_for_design = get_sorted_feasible_moves($best_so_far, $dse);
              if (@{$moves_for_design} > 0) {
                 # choose best of bests and try it
                 for my $move(@{$moves_for_design}) {
                    if (build_move($best_so_far, $move) || $updated_limits) {
                       return {
                          util => -1
                       };
                    }
                    # try another move if this one does not change anything
                 }
              }
           }
           # no moves were possible, build a design from the best so far and restart if necessary
           my $best_throughput = $sorted_by_throughput[0]; # sort by throughput, descending
           if (build_move($best_throughput, \@identity_move) || $updated_limits) {
              return {
                 util => -1
              };
           }
        }
    }
    my $design_area = (@{$explored_configs[@explored_configs - 1]})[-1];
    return {
       util => int($design_area->{util} + 0.5),
       les => int($design_area->{les} + 0.5),
       ffs => int($design_area->{ffs} + 0.5),
       rams => int($design_area->{rams} + 0.5),
       dsps => int($design_area->{dsps} + 0.5)
    };
}

sub sort_by_RAM_fitting {
  my $a = shift;
  my $b = shift;
  my $dse = shift;
  my $alarge = @{$a}[@$a - 1]->{rams} > $dse;
  my $blarge = @{$b}[@$b - 1]->{rams} > $dse;
  return 0 if ($alarge == $blarge);
  return 1 if ($alarge);
  return -1;
}

# get 0 or 1 feasible moves for a design
# list of moves -> unrolling 2x, vectorization 2x, copies + 1
sub get_sorted_feasible_moves {
   my $identity = {unroll => 1, vectorize => 1, copies => 1, sharing => 1};
   my @design = @{$_[0]};
   my $dse = $_[1];
   my @feasible_moves; # will contain 0 or 1 move
   my @sorted_by_throughput = sort {kernel_throughput($design[$a], $identity) <=> kernel_throughput($design[$b], $identity) } (0..@design-2);
   # try to increase throughput for min_throughput design first; if this fails, try for a higher throughput design
   for my $design_kernel(@sorted_by_throughput) {
      my $min_throughput = kernel_throughput($design[$design_kernel], $identity);
      for (my $var = 0; $var < 4; ++$var) { # 3 corresponds to the maximum number of moves in the @kernel_move_set
         # creating an identity move and then replacing individual kernels
         my @move;
         for my $kernel_index(@sorted_by_throughput) {
            push(@move, $identity);
         }
   kernel_analysis:
         for my $kernel_index(@sorted_by_throughput) {
            if (kernel_throughput($design[$kernel_index], $identity) == $min_throughput) { # determine move only for the lowest throughput kernel(s)
               my $kernel_config = $explored_kernel_configs[$design[$kernel_index]];
               print "Investigating possible moves (variant $var) for kernel $kernel_config->{kernel_name}\n" if ($debug);

               my @kernel_move_set = ({unroll => 2, vectorize => 1, copies => 1, sharing => 1},
                                      {unroll => 1, vectorize => 2, copies => 1, sharing => 1},
                                      {unroll => 1, vectorize => 1, copies => ($kernel_config->{copies} + 1) / ($kernel_config->{copies}), sharing => 1});
   
               # allow only vectorization if the design exceeds the available RAMs
               if ($design[@design - 1]->{rams} > $dse) {
                  @kernel_move_set = ($kernel_move_set[1]);
               } 
#               elsif (4 * $kernel_config->{vectorize} <= $kernel_config->{unroll}) {
#                  # try some vectorization if I unrolled for a while
#                  @kernel_move_set = ($kernel_move_set[1], $kernel_move_set[0], $kernel_move_set[2]);
#               }
               # add an aggressive unrolling move if can figure out the unrolling necessary to fully unroll inner loops
               elsif ($kernel_config->{aggressive_unroll} > 0) {
                  @kernel_move_set = ({unroll => $kernel_config->{aggressive_unroll}, vectorize => 1, copies => 1, sharing => 1},
                                      $kernel_move_set[0], $kernel_move_set[1], $kernel_move_set[2]);
               }

               for (my $shift_amount = 0; $shift_amount < @kernel_move_set; ++$shift_amount) {
                  my $kernel_move = $kernel_move_set[($shift_amount + $var) % @kernel_move_set];
                  if (feasible_move($kernel_config, $kernel_move)) {
                     $move[$kernel_index] = $kernel_move;
                     print "Intend to move ".kernel_config_to_string($kernel_move)."\n" if ($debug);
                     next kernel_analysis;
                  }
                  print "Not feasible\n" if ($debug);
               }
               print "Failed to identify a move\n" if ($debug);
            } 
         }
         if (!seen_design(\@design, \@move)) {;
            print "Returning a move\n" if ($debug);
            push (@feasible_moves, \@move);
            return \@feasible_moves;
         }
         print "Trying alternative moves\n" if ($debug);
      }
   }
   print "Failed to identify a move\n" if ($debug);
   return [];
}

sub seen_design {
   my @design = @{$_[0]};
   my @move = @{$_[1]};
design_search:
   for my $other_design(@explored_configs) {
      for (my $i = 0; $i < @design - 1; ++$i) {
         my $other_kernel = $explored_kernel_configs[@{$other_design}[$i]];
         my $kernel = $explored_kernel_configs[$design[$i]];
         die("DSE: failed design comparison\n") if ($other_kernel->{kernel_name} ne $kernel->{kernel_name});
         if (($kernel->{unroll} * $move[$i]->{unroll} != $other_kernel->{unroll}) or
             ($kernel->{vectorize} * $move[$i]->{vectorize} != $other_kernel->{vectorize}) or
             ($kernel->{copies} * $move[$i]->{copies} != $other_kernel->{copies}) or
             ($kernel->{sharing} * $move[$i]->{sharing} != $other_kernel->{sharing})) {
            next design_search; 
         }
      }
      print "Seen design".design_point_to_string(\@design)."\n" if ($debug);
      return 1;
   }
   return 0;
}

sub feasible_move {
   my $kernel = shift;
   my $move = shift;
   my $identity = {unroll => 1, vectorize => 1, copies => 1, sharing => 1};
   return 0 if ($kernel->{unroll} * $move->{unroll} > $kernel->{unroll_limit});
   return 0 if ($kernel->{vectorize} * $move->{vectorize} > $kernel->{vectorize_limit});
   return 0 if ($kernel->{copies} * $move->{copies} > $kernel->{copies_limit});
   return 0 if ($kernel->{sharing} * $move->{sharing} > $kernel->{sharing_limit});
   return 0 if ($move->{copies} > $kernel->{kernel_copyfactor}); # prevent moves that exceed bandwidth
   return 0 if (estimate_move_throughput($kernel, $move) <= estimate_move_throughput($kernel, $identity));
   return 1;
}


# compares throughput of two designs - look at the first kernel that shows diff throughput
# weigh the comparison
sub cmp_throughput {
   my @b = @{$_[0]};
   my @a = @{$_[1]};
   my $sort_by_area = $_[2];
   my $throughput_b = 0;
   my $throughput_a = 0;
   my $util_b = 1;
   my $util_a = 1;
   for my $kernel(0..@b-2) {
      $throughput_b = $explored_kernel_configs[$b[$kernel]]->{kernel_throughput};
      $throughput_a = $explored_kernel_configs[$a[$kernel]]->{kernel_throughput};
      $util_b = $explored_kernel_configs[$b[$kernel]]->{kernel_area}->{util};
      $util_a = $explored_kernel_configs[$a[$kernel]]->{kernel_area}->{util};
      last if $throughput_b != $throughput_a;
   }
   if ($sort_by_area) {
      $throughput_b /= $util_b;
      $throughput_a /= $util_a;
   }
   return $throughput_b <=> $throughput_a;
}

# return the throughput of a kernel to which a move has been applied
sub kernel_throughput {
   my $kernel_index = shift;
   my $move = shift;
   return $explored_kernel_configs[$kernel_index]->{kernel_throughput} * $move->{unroll} * $move->{vectorize} * $move->{copies} / $move->{sharing};
}

sub get_best_sharing_move {
   my @best_fitting = @{$_[0]};
   my $dse = $_[1];
   my @sharing_move;
   my $best_fitting_area = $best_fitting[@best_fitting - 1];
   for (my $i = 0; $i < @best_fitting - 1; ++$i) {
      push(@sharing_move, {unroll => 1, vectorize => 1, copies => 1, sharing => 1});
   }
sharing_move: 
   while (!design_fits($best_fitting_area, $dse)) {
      my @sorted_by_throughput = sort {kernel_throughput($best_fitting[$b], $sharing_move[$b]) <=> kernel_throughput($best_fitting[$a], $sharing_move[$a]) } (0..@sharing_move-1);
      for my $fastest(@sorted_by_throughput) {
         my $kernel_config=$explored_kernel_configs[$best_fitting[$fastest]];
         print "Fastest kernel is ".($kernel_config->{kernel_name}).", sharing...\n" if ($debug);
         if ($kernel_config->{sharing} * $sharing_move[$fastest]->{sharing} < $kernel_config->{sharing_limit}) {
            $sharing_move[$fastest]->{sharing} = (($sharing_move[$fastest]->{sharing} * $kernel_config->{sharing}) + 1) / ($kernel_config->{sharing});
            print "Can share more, alter sharing factor to $sharing_move[$fastest]->{sharing}\n" if ($debug);
            $best_fitting_area = estimate_move_area(\@best_fitting, \@sharing_move);
            print "Would get down to ".area_to_string($best_fitting_area)."\n" if ($debug);
            next sharing_move;
         }
      }
      last;
   }
   return \@sharing_move;
}

# Scale comparison between configurations
sub scale {
   my $kernel_config1 = shift;
   my $kernel_config2 = shift;
   my $move = shift;
   return ($kernel_config1->{unroll} / ($kernel_config2->{unroll} * $move->{unroll})) *
          ($kernel_config1->{vectorize} / ($kernel_config2->{vectorize} * $move->{vectorize})) *
          ($kernel_config1->{copies} / ($kernel_config2->{copies} * $move->{copies})) *
          (($kernel_config2->{sharing} * $move->{sharing}) / $kernel_config1->{sharing});
}


sub design_point_to_string {
  my $string;
  my @config = @{$_[0]};
  my $area = pop(@config);
  $string .= area_to_string($area)."\n";
  for my $i(@config) {
    $string .= "   ".kernel_config_to_string($explored_kernel_configs[$i])."\n";
  }
  return $string;
}

sub area_to_string {
  my $area = shift;
  return int($area->{util})."\% logic, ".int($area->{les})."\% ALUTs, ".int($area->{ffs})."\% registers, ".int($area->{rams})."\% RAMs, ".int($area->{dsps})."\% DSPs";
}

sub kernel_config_to_string {
   my $config = shift;
   return "Kernel '".$config->{kernel_name}."': throughput: ".sprintf("%2.2e",1e+6 * $config->{kernel_throughput})." / resources: ".area_to_string($config->{kernel_area}).")";
}

sub estimate_move_throughput {
   my $kernel = shift;
   my $move = shift;
   my @similar = grep {($kernel->{kernel_name} eq $_->{kernel_name}) &&
                       (($move->{unroll} != 1) || ($kernel->{unroll} == $_->{unroll})) &&
                       (($move->{vectorize} != 1) || ($kernel->{vectorize} == $_->{vectorize})) &&
                       (($move->{copies} != 1) || ($kernel->{copies} == $_->{copies})) &&
                       (($move->{sharing} != 1) || ($kernel->{sharing} == $_->{sharing}))} @explored_kernel_configs;
  my @closest_similar = sort {scale($b, $kernel, $move) <=> scale($a, $kernel, $move)} @similar;
  # extrapolating if at least one point is found
  if (@closest_similar == 0) {
     die "DSE: Can't find similar kernel for extrapolation\n";
  } else {
     my $scale = scale($closest_similar[0], $kernel, $move);
     my $scale2 = @closest_similar > 1 ? scale($closest_similar[1], $kernel, $move) : 0;
     print "Most similar designs are:\n".kernel_config_to_string($closest_similar[0])."\n".kernel_config_to_string($closest_similar[1])."\n" if ($debug);
     my $throughput = kernel_interpolation($closest_similar[0]->{kernel_throughput}, @closest_similar > 1 ? $closest_similar[1]->{kernel_throughput} : 0, $scale, $scale2);
     print "Estimated throughput = $throughput\n" if ($debug);
     return $throughput;
   }
}


# assume that kernel size varies proportionally to move scaling if only one point is available, or extrapolate existing points if several are available
sub estimate_move_area {
   my @config = @{$_[0]};
   my $area = pop(@config);
   my @move = @{$_[1]};
   # for each kernel, find similar designs in the non scaled parameters - should get at least one design
   for (my $i = 0; $i < @config; ++$i) {
      my $ref_kernel = $explored_kernel_configs[$config[$i]];
      my @similar = grep {($ref_kernel->{kernel_name} eq $_->{kernel_name}) &&
                          (($move[$i]->{unroll} != 1) || ($ref_kernel->{unroll} == $_->{unroll})) &&
                          (($move[$i]->{vectorize} != 1) || ($ref_kernel->{vectorize} == $_->{vectorize})) &&
                          (($move[$i]->{copies} != 1) || ($ref_kernel->{copies} == $_->{copies})) &&
                          (($move[$i]->{sharing} != 1) || ($ref_kernel->{sharing} == $_->{sharing}))} @explored_kernel_configs;
     my @closest_similar = sort {scale($b, $ref_kernel, $move[$i]) <=> scale($a, $ref_kernel, $move[$i])} @similar;
     # extrapolating if at least one point is found
     if (@closest_similar == 0) {
        die "DSE: Can't find similar kernel for extrapolation\n";
     } else {
        my $scale = scale($closest_similar[0], $ref_kernel, $move[$i]);
        my $scale2 = @closest_similar > 1 ? scale($closest_similar[1], $ref_kernel, $move[$i]) : 0;
        print "Most similar designs are:\n".kernel_config_to_string($closest_similar[0])."\n".kernel_config_to_string($closest_similar[1])."\n" if ($debug);
        print "Scale of nearest 2 points is $scale and $scale2\n" if ($debug);
        return {
           util => $area->{util} + kernel_interpolation($closest_similar[0]->{kernel_area}->{util}, @closest_similar > 1 ? $closest_similar[1]->{kernel_area}->{util} : 0, $scale, $scale2) - $ref_kernel->{kernel_area}->{util},
           les => $area->{les} + kernel_interpolation($closest_similar[0]->{kernel_area}->{les}, @closest_similar > 1 ? $closest_similar[1]->{kernel_area}->{les} : 0, $scale, $scale2) - $ref_kernel->{kernel_area}->{les},
           ffs => $area->{ffs} + kernel_interpolation($closest_similar[0]->{kernel_area}->{ffs}, @closest_similar > 1 ? $closest_similar[1]->{kernel_area}->{ffs} : 0, $scale, $scale2) - $ref_kernel->{kernel_area}->{ffs},
           rams => $area->{rams} + kernel_interpolation($closest_similar[0]->{kernel_area}->{rams}, @closest_similar > 1 ? $closest_similar[1]->{kernel_area}->{rams} : 0, $scale, $scale2) - $ref_kernel->{kernel_area}->{rams},
           dsps => $area->{dsps} + kernel_interpolation($closest_similar[0]->{kernel_area}->{dsps}, @closest_similar > 1 ? $closest_similar[1]->{kernel_area}->{dsps} : 0, $scale, $scale2) - $ref_kernel->{kernel_area}->{dsps},
        }
     }
   }
}

sub kernel_interpolation {
  my $a = shift;
  my $b = shift;
  my $sa = shift;
  my $sb = shift;
  my $inv = ($b * $sa - $a * $sb) / ($sa - $sb);
  return ($a - $inv) / $sa + $inv;
}

#evaluates if a design fits - ignore rams
sub design_fits_except_rams {
  my $area = shift;
  my $dse = shift;
  my $fit= (($area->{util} <= $dse) && ($area->{les} <= $dse) && ($area->{ffs} <= $dse) && ($area->{dsps} <= 100));
  print "Fit status: $fit\n" if ($debug);
  return $fit;
}

#evaluates if a design fits
sub design_fits {
  my $area = shift;
  my $dse = shift;
  my $fit= (($area->{util} <= $dse) && ($area->{les} <= $dse) && ($area->{ffs} <= $dse) && ($area->{rams} <= $dse) && ($area->{dsps} <= 100));
  print "Fit status: $fit\n" if ($debug);
  return $fit;
}

sub build_move {
   my @config = @{$_[0]};
   pop (@config);
   my @move = @{$_[1]};
   my $changed = 0;
   for (my $i = 0; $i < @config; ++$i) {
      my $last_compiled = $explored_kernel_configs[$explored_configs[@explored_configs - 1][$i]];
      my $ref_kernel = $explored_kernel_configs[$config[$i]];
      my $kernel_name = $ref_kernel->{kernel_name};
      open(KERNEL, ">./$kernel_name$ACL_DSE_CONFIG_INPUT_FILE_EXTENSION");
      my $new_unroll = $ref_kernel->{unroll} * $move[$i]->{unroll};
      printf(KERNEL "Unroll: %f\n", $new_unroll);
      $changed = 1 if ($new_unroll != $last_compiled->{unroll});
      my $new_vectorize = $ref_kernel->{vectorize} * $move[$i]->{vectorize};
      printf(KERNEL "Vectorization: %d\n", $new_vectorize);
      $changed = 1 if ($new_vectorize != $last_compiled->{vectorize});
      my $new_copies = $ref_kernel->{copies} * $move[$i]->{copies};
      printf(KERNEL "Copies: %d\n", $new_copies);
      $changed = 1 if ($new_copies != $last_compiled->{copies});
      my $new_sharing = $ref_kernel->{sharing} * $move[$i]->{sharing};
      my $max_sharing = $new_sharing * 8;
      printf(KERNEL "Sharing: %d %d\n", $new_sharing, $max_sharing);
      $changed = 1 if ($new_sharing != $last_compiled->{sharing});
      close(KERNEL); 
   }
   if ($changed) {
      print "----------------------------------\n";
      print "Using attributes:\n";
      for (my $i = 0; $i < @config; ++$i) {
         my $ref_kernel = $explored_kernel_configs[$config[$i]];
         print "   Kernel '".$ref_kernel->{kernel_name}."':\n      max_unroll_loops(".($ref_kernel->{unroll} * $move[$i]->{unroll}).")\n      num_simd_work_items(".($ref_kernel->{vectorize} * $move[$i]->{vectorize}).")\n      num_compute_units(".($ref_kernel->{copies} * $move[$i]->{copies}).")\n      num_share_resources(".($ref_kernel->{sharing} * $move[$i]->{sharing}).")\n      max_share_resources(".(8 * ($ref_kernel->{sharing} * $move[$i]->{sharing})).")\n";
      }
      
   }
   return $changed;
}

1;

