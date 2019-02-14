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
    


# Altera SDK for OpenCL kernel compiler.
#  Inputs:  A .cl file containing all the kernels
#  Output:  A subdirectory containing: 
#              Design template
#              Verilog source for the kernels
#              System definition header file
#
# 
# Example:
#     Command:       aoc foobar.cl
#     Generates:     
#        Subdirectory foobar including key files:
#           *.v
#           <something>.qsf   - Quartus project settings
#           <something>.sopc  - SOPC Builder project settings
#           kernel_system.tcl - SOPC Builder TCL script for kernel_system.qsys 
#           system.tcl        - SOPC Builder TCL script
#
# vim: set ts=2 sw=2 et

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
require acl::File;
require acl::DSE;
require acl::Pkg;
require acl::Env;
require acl::Board_migrate;

my $prog = 'aoc';
my $emulatorDevice = 'EmulatorDevice'; #Must match definition in acl.h
my $return_status = 0;

#Filenames
my $input_file = undef; # might be relative or absolute
my $output_file = undef; # -o argument
my $output_file_arg = undef; # -o argument
my $srcfile = undef; # might be relative or absolute
my $objfile = undef; # might be relative or absolute
my $x_file = undef; # might be relative or absolute
my $pkg_file = undef;
my $absolute_srcfile = undef; # absolute path
my $absolute_efispec_file = undef; # absolute path of the EFI Spec file
my $absolute_profilerconf_file = undef; # absolute path of the Profiler Config file

#directories
my $orig_dir = undef; # absolute path of original working directory.
# $work_dir is to be used when we expand the path name, and verbatim_work_dir when we don't 
my $work_dir = undef; # absolute path of the project working directory with spaces replaced with ?.
my $verbatim_work_dir = undef; # absolute path of the project working directory as is.

# Executables
my $clang_exe = $ENV{'ALTERAOCLSDKROOT'}."/linux64/bin"."/aocl-clang";
my $opt_exe = $ENV{'ALTERAOCLSDKROOT'}."/linux64/bin"."/aocl-opt";
my $link_exe = $ENV{'ALTERAOCLSDKROOT'}."/linux64/bin"."/aocl-link";
my $llc_exe = $ENV{'ALTERAOCLSDKROOT'}."/linux64/bin"."/aocl-llc";
my $sysinteg_exe = $ENV{'ALTERAOCLSDKROOT'}."/linux64/bin"."/system_integrator";

#Log files
my $fulllog = undef;

my $regtest_mode = 0;

#Flow control
my $parse_only = 0; # Hidden option to stop after clang.
my $opt_only = 0; # Hidden option to only run the optimizer
my $verilog_gen_only = 0; # Hidden option to only run the Verilog generator
my $ip_gen_only = 0; # Hidden option to only run up until ip-generate, used by sim
my $high_effort = 0;
my $skip_qsys = 0; # Hidden option to skip the Qsys generation of "system"
my $compile_step = 0; # stop after generating .aoco
my $vfabric_flow = 0;
my $griffin_flow = 0; # Use DSPBA backend instead of HDLGeneration
my $generate_vfabric = 0;
my $reuse_vfabrics = 0;
my $vfabric_seed = undef;
my $custom_vfab_lib_path = undef;
my $emulator_flow = 0;
my $soft_ip_c_flow = 0;
my $accel_gen_flow = 0;
my $run_quartus = 0;
my $c_acceleration = 0; # Hidden option to skip clang for C Acceleration flow.
my $simulation_mode = 0; #Hidden option to generate full board verilogs targeted for simulation  (aoc -s foo.cl)
my $no_automigrate = 0; #Hidden option to skip BSP Auto Migration

#Flow modifiers
my $dse = 0; # If not 0, doing DSE targetting a resource utilization equal to the value specified
my $optarea = 0;
my $force_initial_dir = '.'; # absolute path of original working directory the user told us to use.
my $use_ip_library = 1; # Should AOC use the soft IP library
my $use_ip_library_override = 1;
my $do_env_check = 1;

#Output control
my $verbose = 0; # Note: there are two verbosity levels now 1 and 2
my $report = 0; # Show Throughput and area analysis
my $estimate_throughput = 0; # Show Throughput guesstimate
my $debug = 0; # Show debug output from various stages
my $time_log = undef; # Time various stages of the flow; if not undef, it is a 
                      # file handle (could be STDOUT) to which the output is printed to.
my $time_passes = 0; # Time LLVM passes. Requires $time_log to be valid.
# Should we be tidy? That is, delete all intermediate output and keep only the output .aclx file?
# Intermediates are removed only in the --hw flow
my $dotfiles = 0;
my $tidy = 0; 
my $save_temps = 0;
my $pkg_save_extra = 0; # Save extra items in the package file: source, IR, verilog

# Yet unclassfied
my $save_last_bc= 0; #don't remove final bc if we are generating profiles
my $disassemble = 0; # Hidden option to disassemble the IR
my $fit_seed = undef; # Hidden option to set fitter seed
my $profile = 0; # Option to enable profiling
my $program_hash = undef; # SHA-1 hash of program source, options, and board.
my $big_endian = 0;
my $triple_arg = '';
my $dash_g = 0;      # Debug info enabled? 

# Regular arguments.  These go to clang, but does not include the .cl file.
my @user_clang_args = ();

# The compile options as provided by the clBuildProgram OpenCL API call.
# In a standard flow, the ACL host library will generate the .cl file name, 
# and the board spec, so they do not appear in this list.
my @user_opencl_args = ();

my $opt_arg_after   = ''; # Extra options for opt, after regular options.
my $llc_arg_after   = '';
my $clang_arg_after = '';
my $sysinteg_arg_after = '';

my $efispec_file = undef;
my $profilerconf_file = undef;
my $dft_opt_passes = '--acle ljg7wk8o12ectgfpthjmnj8xmgf1qb17frkzwewi22etqs0o0cvorlvczrk7mipp8xd3egwiyx713svzw3kmlt8clxdbqoypaxbbyw0oygu1nsyzekh3nt0x0jpsmvypfxguwwdo880qqk8pachqllyc18a7q3wp12j7eqwipxw13swz1bp7tk71wyb3rb17frk77rpop2eonuyz8ch72tfxmxkcl8yp3ggewtfmire1mt8zd3bknywxcxa3nczpyxfuwhdop2qqqddpqcvorlvcqgskq10pggju7ryomx713svz3tjmlq8cl2kbq10pt8vs0rjo32wctgfpt3kmljwxfgpsmvjz82j38uui3xleqtyz23bknyycdrkbmv0ot8vs0r8o1guoldyz2cvorlvcz2a7l3jzd2gm0qyi7x713svz33gslkwxz2dunvpzwxbbyw0on2yqqkwokthknuwby2k7lb17frk1wgwoygueqajp03ghll0318a7m8jzrxg1wg8z7xutqgfpttd3mu0318a7mcyz1xgu7uui3rezlg07ekh3nj8xbrkhmzpzx2vs0rjibgezqjwpdtd72tfxm2sbnowoljg7wkvir2wbmg8patk72tfxmgfcl3doggkbekdoyguemy8zq3jzmejxxrzbtijzyrgmegdop2e3lgwzekh3lkpbcrk1mxyzm2hfwwvm7jlzqu8pfcdfnedcfxfomxw7ljg70qyitxyzqsypr3gknt0318a7q3yzgxg70tjip2wtqdypy1bknyvbzga3loype2s7wywo880qqkpoe3j3mjjxmgs1q38zt8vs0rjiorlclgfpthdhlh8cygd33czpyxgu0rdi880qqkwpsth7mtfxmgjsm8vogxd7wqdmire3ndpoetdenlwx8gpsqcwmt8vs0rjiorlclgfpt3fknjjbzrj7qzw7ljg70qyitxyzqsypr3gknt0318a7mzppqgd1wg0z880qqkwpsth7mtfxmgscmzvpaxbbyw0oprlemyy7atjzntwx1rjumippt8vs0rwolglctgfpt3honqvcwghfq10ot8vs0r0z3recnju7atjqllvbyxffmodzgggbwtfmiresqryp83bknywbp2kbmb0zgggzwtfmirezqspo23kfnuwb1rdbtijz3gffwhpom2e3ldjpacvorlvc8xkbqb17frk1wu0o7x713svz33gslkwxz2dunvpzwxbbyw0obglznrvzs3h1nedx1rzbtijz8xdm7qvz7jlzmgyzuckorlvcw2kfq3vpm2s37u0z880qqkjzdth1nuwx8xfbqb17frk70wyitxyuqgpoq3k72tfxm2f1q8dog2jmetfmirezqsdpn3k1qhy3xxfumidoq2vs0rpioryolgfptcfhntfxmgssq3doggg77q0otx713svzdthcmtpb18a7q1yp32j7etfmire1nsposchfntfxmxftmbppf2jh0gvm7jlzmgjzn3foluu3xxfhmivp32vs0r0zb2lcna8pl3a72tfxmra7m8jorxbbyw0oprlemyy7atjoqlpbcrahqb17frk77qdiyxlkmh8ithkcluu3xxf7nvjz3xbbyw0omgyqmju7atjsntyxmrkuniwomxbbyw0obglznrvzs3h1nedx1rzbtijzk2dkwhdmire3ndpoe3jznedx3rzbtijzqrfbwtfmirebmgvzecvorlvcqgskq10pggju7ryomx713svzkhh3qhvccgammzpplxbbyw0otxyold0oekh3ltyc7rdbtijz3gffwkwiw2tclgvoy1bknyjcvxammb0pqrkbwtfmirezqsdp3cfsntpb3gd33czpygk1wg8zb2wonju7atjmlqjb7gh7nczpy2hswepii2wctgfpthhhljyxlgdclb17frkc0yyze2wctgfpt3j3lqy3xxfhmiyzq2vs0r0zwrlolgy7atjqllwblgssm8ypyrfbyw0o1xw3mju7atjenudx8rabmczpy2jo0q0o1xltqu07ekh3lhpb72a7lxvp12gbyw0o7gwkqk8zdch3quu3xxfhmivolgf70wyilx713svzwtjoluu3xxfhmivolgf70wyitxyctgfpt3jfng8cfxkbtijz12jk0wyz720qqkype3horlvcz2acl8ypfrfu0r0z880qqkpoe3hhlgyc18a7mivpu2vs0rpo3re1quvoetd72tfxmrd7mcw7ljg70g0o1xlbmupoecdfluu3xxfcmv8zt8vs0rvzr2qmnuzoetk72tfxm2kbmovp72jbyw0obglkmr8puchqld8cygsfqi87frk7ekwir2wznju7atj7qjjxbxacncwo12hoetfmirebmgvzecvorlvcvxafq187frk77qdiyxlkmh8iy1bkny0bpgsbtijzyrg1wedotrekmsjzy1bknyvbzga3loype2s7wywo880qqk8patdzmyjxb2fuqi8zt8vs0rjo32wctgfpthkqlfybwgpsmvdzgxd70t0zwructgfptchsntyx18a7m8wos2hcekdorx713svzn3k1medcfrzbtijzfrgm7ejitx713svzucfzqj8xngjcncwo1rg37two1xykqsdpy1bknyjcr2a33czpyxjzwjdz7x713svzwtjoluu3xxf7nz8p3xguwypp3gw7mju7atjfnjwblgj7q3ype2s38uui32qqquwotthsly8xxgdbtijzfrgbyw0olx713svz3tjmlq8clgsqnc87frkh0t8zm2w13svzutkcljyc3gfcncjot8vs0r0z32etqjpo23k7qq0318a7qcjzlxbbyw0on2qhlr0oekh3ly8xyxf1m80o8xbbyw0oprl7lgpo3tfqlhvcprzbtijz8rk1wepor2qslg07ekh3ltvc1rzbtijzrxj70uvm7jlzqhdoacvorlvc8xfbqb17frkuww0zwreeqapzkhholuu3xxf3l8vpwgf10edmire7majpr3jfntfxmgabmow7ljg7wh8zorwoljypekh3nrwxc2f1qo87frkk0udi7jlzqrvoutkoluu3xxfcl8yp72h1wedmireuqjwojcvorlvc32jsqb17frk77qdiyxlkmh8iekh3lr0b0jpsmv0zy2j38uui32qqmgyzvtdcmu0bwgssmxw7ljg70jpibreumju7atjzqj8cxxkomidoa2vs0rvzr2qqmrdzy1bknywxcxa3nczpyrfu0evzp2qmqw07ekh3lqvcqxk1qb17frkk0ujiorlcnju7atjbmtpbz2dulb17frkh0wwiy20qqkvok3h7qq8x2gh33czpyxg70g0z1x713svzrhjbljycegpsmvyzfggfwkpow2wctgfptckhlhy3xxf7qxvzljg7wr8ongu1qy07ekh3lypb72a7qz87frk70wyil2wolu8pshh1tuu3xxfcmv8zt8vs0rpiiru3lkjpfhjqllyc0jpsmvyzfggfwkpow2w13svztcgmlldx1rabtijzq2j37uyi02wqqk8petd72tfxm2jbmv0odgfuwado7jlzqfyz2hholq0318a7q28z12ho0svm7jlzqhdoacvorlvcz2a7l3jzd2gm0qyi7x713svzwtjoluu3xxfoncdoggjuetfmireolgypshfontfxmrdbmb0zljg70gjzogu1qu07ekh3ltvc1rzbtijz72jm7qyokx713svzf3k1mryc18a7q1dolxju0rpow2w3qgfpttdzmlpb1xk33czpyxj70uvm7jlzqddp3cf3nlyxngssmcw7ljg7wgdoyxlkqk8z03korlvcvxkblb17frk1wu0o7x713svzd3g3nq0318a7qovpdxfbyw0o3rlumk8pa3k72tfxmraumv8pt8vs0ryz7gukmh8iy1bknywxcxa3nczpyxdm7qvz3rl1nswoekh3nudxxxacnb0olxbbyw0o3gecnju7atjbmtpbz2dulb17frkuww0zwreeqapzkhholuu3xxfzq2ppt8vs0r0zb2lcna8pl3a3lrjc0jpsmv8plgfz0u8z7xy1nudpy1bknyvbzga3loype2s7wywo880qqkwpstfoljvbtgscnvwpt8vs0rwolglctgfptcf1medbzgfhmczpy2g1wkvi880qqkwzt3k72tfxmgfsqivpm2kc7udmirezqs8zd3k3my8xxxdbtijzurgbewjotx713svz83g3nwy3xxfhmijzrxgbyw0oz2wuqgfpttjhlldczxd33czpygdbwgpin2tctgfptchqnyyx0jpsmvpolgfuwypp880qqkvot3jfnupblgdcm3jzm2hfwwvm7jlzmuyzw3f3nty3xxfmncjod2dm7rdotx713svzwtjoluu3xxfoncdoggjuetfmirebmgpp7tdzmtfxmxkuq08z8xbbyw0oq2qkqkypy1bknyvbzga3loype2s7wywo880qqkwpstfoljvbtgscnvwpt8vs0r0ov2eqmsyzd3bknypc72kmnz8z12vs0rpiiru1muwokthkluu3xxfmmbdo12hbwg0zw2ttqg07ekh3ltvc1rzbtijzsrg1wu0zwrlolgvo03afnt0318a7qovowxguww0z7gu3nju7atj1mtyx7rjbq8yprxguwado880qqkwzt3k72tfxm2kbq3wp0rdz0qjo880qqkjokhh72tfxmxjfq8jpgxdb0edmirekmswo23gknj8xmxkbtijzsrgz7u8z7guctgfpt3honqjxlgh7l3dol2kk0qyimx713svzdthmltvbyxamncjom2sh0uvm7jlzqkjpahfoljwb18a7mzppm2jz0u8z7jlzqayodcfqlkwxzgdmn8w7ljg70qyitxyzqsypr3gknt0318a7qcjzlxbbyw0o1xwsqrvo03bknyvbz2hbm8w7ljg7wjdor2qmqw07ekh3lr0b18a7qzyz1xjbwwdo0x713svzl3f3mty3xxfcl8ypwrgs0wdi7xyoldvzekh3lrybxxfcnzvpfrf38uui3gw1luyzekh3nuwc8xkblv87frko0kyi3xykqsdp3cvorlvc8xablv0pl2vs0rvze2lclgfpthk7mtfxmgjsmz0ot8vs0rpiiru3lkjpfhjqllyc0jpsmv0zy2j38uui3gwclky7atjzntvccga3nijogxdu0wyi880qqk8patdzmyjxb2fuqi8zt8vs0rjo32wctgfpthk7myy3xxf7mipp72jm7gpiogl13svz83f3qe0318a7qxwoy2vs0r0ooglmlgpo33ghlly3xxfmnc8pdgd1wevm7jlzqddp3cf3nlyxngssmcw7ljg7wu0o7x713svzlcd3ntfxmrduliyza2h70uui32etqdjzacvorlvcz2a7l3jzd2gm0qyi7x713svzwtjoluu3xxfzq2ppt8vs0r0zb2lcna8pl3aorlvc2rk33czpyxj70uvm7jlzqa0owcvorlvclgdcm3jzl2vs0rjo7xu1mswzehh3nty3xxfcmzjom2ks0rdo880qqkwpsth7mtfxmxkumowos2ho0svm7jlzqjpo23jqmtfxmrkmnzpot8vs0r8z72lemtyzekh3nhdxtgfsq38zq2vs0r0o1xltqu07ekh3lqjx7rd7l3vp12j7ekppp2wctgfpthdhlqwx18a7q1yp32jh0qyi7x713svzkhh3qhvccgammzpplxbbyw0o0re1mju7atjmlldxcrj1q38zljg70edozxw1my07ekh3lrdctrd33czpyrfhwjvm7jlzmypoe3bknywxcxa3nczpyxfuwhdop2qqqddpqcvorlvclgdkmipol2vs0rjoexutqdvzucfontfxmrdmmxw7ljg70yyzix713svzkhh3qhvccgammzpplxbbyw0o1xwzqg07ekh3njvcz2j33czpyxgf0wvz7jlzmy8p83kfnedxz2azqb17frkuww0zwreeqapzkhholuu3xxfcmv8zt8vs0r8z72lemtyzekh3ltybwraumvyzm2jbyw0o0ge7mju7atj3meyxwrauqxyiygjzwtfmiretqsjoehd3mg8xyxftqb17frkc0wjz7jlzqkdzq3bknywxcxa3nczpyxfuwhdop2qqqddpqcvorlvc7rdqm3jom2vs0r0zbgt1qu07ekh3lgyclgsom7w7ljg7wyjio2e3lddpqcdhnedxyxkcn70plxbbyw0o3gu1qjwoe3bknyvbygfhqo87frkowgdo720qqkvzd3f3qhyclxk33czpygfbwudz32w13svzl3jknlybyrzbtijzugfb0t0i7jlzqayzfckolk0318a7qcjzlxbbyw0or2wzlsyo2tjontfxmxktmbdogggzwtfmire3ndpos3fcle0burjbtijz3gfuwwjz880qqkdoehdqlr8v0jpsmvpz3rj1wjdor2qmqw07akc';
my $soft_ip_opt_passes = '--acle ljg7wk8o12ectgfpthjmnj8xmgf1qb17frk77qdiyxlkmh8ithkcluu3xxf7nvyzs2kmegdoyxlctgfpt3kmljwxfgpsmvjz82j38uui3xleqtyz23bknyycdrkbmv0ot8vs0r8o1guoldyz2cvorlvc3rafqvyzsrg3ekvm7jlzqd0otthknjwbw2kfq1w7ljg7wudo1xwbmujzechqnq0318a7mzpp8xd70wdi22qqqg07ekh3nj8xbrkhmzpzxrko0yvm7jlzmypo7hhontfxmgdtqb17frkuwwjibgl1mju7atjqllwxz2abmczpyxdtwgdotxqemawzekhznk71wyb3r1em3vbbyw0on2yqqkwokthknuwby2k7lb17frk1wgwoygueqajp03ghll0318a7m8jzrxg1wg8z7xutqgfpttd3mu0318a7mcyz1xgu7uui3rezlg07ekh3nj8xbrkhmzpzx2vs0rjibgezqjwpdtd72tfxm2sbnowoljg7wkvir2wbmg8patk72tfxmgfcl3doggkbekdoyguemy8zq3jzmejxxrzbtijzyrgmegdop2e3lgwzekh3lkpbcrk1mxyzm2hfwwvm7jlzqu8pfcdfnedcfxfomxw7ljg70qyitxyzqsypr3gknt0318a7q3yzgxg70tjip2wtqdypy1bknyvbzga3loype2s7wywo880qqkpoe3j3mjjxmgs1q38zt8vs0rjiorlclgfpthdhlh8cygd33czpyxgu0rdi880qqkwpsth7mtfxmgjsm8vogxd7wqdmire3ndpoetdenlwx8gpsqcwmt8vs0rjiorlclgfpt3fknjjbzrj7qzw7ljg70qyitxyzqsypr3gknt0318a7mzppqgd1wg0z880qqkwpsth7mtfxmgscmzvpaxbbyw0oprlemyy7atjzntwx1rjumippt8vs0rwolglctgfpt3honqvcwghfq10ot8vs0r0z3recnju7atjqllvbyxffmodzgggbwtfmiresqryp83bknywbp2kbmb0zgggzwtfmirezqspo23kfnuwb1rdbtijz3gffwhpom2e3ldjpacvorlvc8xkbqb17frk1wu0o7x713svz33gslkwxz2dunvpzwxbbyw0obglznrvzs3h1nedx1rzbtijz8xdm7qvz7jlzmgyzuckorlvcw2kfq3vpm2s37u0z880qqkjzdth1nuwx8xfbqb17frk70wyitxyuqgpoq3k72tfxm2f1q8dog2jmetfmiretqsjp83bknyvbzga3loype2s38uui3xlzquvoucvorlvcvxafq187frkbew8zoxltmju7atjclgdx0jpsmv8pl2g7whppoxu3nju7atj3myvcwrzbtijzggg7ek0oo2loqddpecvorlvcigjkq187frkceq8z72e3qddpqcvorlvcmxaml88zs2kc7ujo7jlzmyposcdmnr8cygsfqiw7ljg7wu0z7x713svzuck3nt0318a7m8ypaxfh0qyokremqh07ekh3nedxqrj7mi8pu2hs0uvm7jlzquwo23g7mtfxmrdbmb0zljg7wh8zoxyemr8i83k3quu3xxfzqovpu2khwu0o7x713svztthknjwbbgdmnx8zt8vs0r8o1guoldyz2cvorlvc7raznbyi82vs0rpiixlkmsyzy1bknyvby2kuq1ppjxbbyw0oirlolapoecf72tfxmrdzq28olxbbyw0o1retqgfptchhnuwc18a7m80odgfb0uui32qqmrpokhh3mevcqgpsmvyzqxj38uui3reemsdoehdzmtfxmgsfq80zljg70qwiqgu13svz0thorlvcz2acl8ypfrfu0r0z880qqkwpstfoljvcc2aolb17frkc0rdo880qqkwpstfoljvcc2a7l3w7ljg70tjiq2ekluy7atj1mtyxc2jbmczpy2gb0edmirekmswo23gknj8xmxk33czpyrf70tji1guolg0odcvorlvcw2kuq2dm12jzwtfmirecnujpfthzmt0blgsolb17frkuww0zwreeqapzkhholuu3xxfcmv8zt8vs0ryobxt1nyy7atj1newbmgf7l3jot8vs0rjiz2wuqgfpttd7qq8xyrjbq8w7ljg7wjdor2qmqw07ekh3lljxlgahm8w7ljg70tjzwgukmkyo03k7qjjxwgfzmb0ogrgswtfmire7mtdpy1bknywcmgd33czpyrfu0evzp2qmqwvzltk72tfxmra7l3donrkc7qyokx713svzkhh3qhvccgammzppl2vs0ryio20qqkdoy1bknyvbmgfhmbdoggsb0uui3xlbmujze3bkny8c3xdmncvzrxdb0gvm7jlzquvzuchmljpb1rkhqb17frko0qvpexu13svzr3gzmy8cqrj7lb17frkh0wwz7guzlt8p0tjeluu3xxf7nvyzs2km7q8p7x713svzwtjoluu3xxf1qcjzlxbbyw0omgyqmju7atjznyyc0jpsmvypfrfc7rwizgekmsyzy1bkny0blxazq8yza2vs0rwoprloqjwpekh3nqycbrzbtijz3gff0y8z12l13svzqchhly8cvgpsmv8pl2gbyw0oerubqhyzy1bknywblgsonzyzs2vs0rdi1xyhmju7atj3meyxwrauqxyiljg7wyvz880qqkwzt3k72tfxmgssqc8zcrfz7tvzy2qqqh07ekh3lhpb72a7lxvp12gbyw0oygukmswolcvorlvcvxafq187frk77qdiyxlkmh8iy1bknywxmxk7nbw7ljg70gdoprlemy07ekh3lypc22kbm187frk1wwyioxybmryzy1bknywccrjbtijzygjz0uui3geomhpoe3d72tfxmxkumowos2ho0s0onrwctgfpt3holjjc12kbq38o1gg38uui3geoljdptcgorlvcmxasq28z1rfu0wyirv713svzwtjoluu3xxfuqijomrkf0e8obgl1mju7atjbmtvcyxamnzdil2vs0r0i7guqqgwpy1bknydb12kuqxyit8vs0rwolglctgfpt3gknjwbmxakqvypf2j38uui3xwzqg07ekh3lgyclgsom7w7ljg7wgdozrlmlgy7atjznt8c8gpsmvjomrgm7u0z880qqkwzt3k72tfxm2jbq8ype2s38uui32l1mujze3bkny0blgdcmzjzrxdbwudmireznrjp23k3quu3xxfcmv8zt8vs0rpiiru3lkjpfhjqllyc0jpsmvyzfggfwkpow2w13svztthmlqycqxfuqivzljg7wrwiegl3qu07ekh3nwycl2abqo87frkc0kvzp2qzqjwoshd72tfxmrd7mcw7ljg7wjdor2qmqw07ekh3nqycbxamn7jzd2kh0u0z32qqqh07ekh3lgyclgsom7w7ljg70yyzix713svzwtjoluu3xxfoncdoggjuetfmirezlk8zd3j1qjyc8gj7q3ypdgg38uui3xlkqkypy1bknywxcxa3nczpyrkf0e8obgl1mju7atjfnevcbrzbtijza2jm7ydor2w3lrpoacvorlvcqgskq10pggju7ryomx713svzdthcmtpbqxjuq3jzhxbbyw0omgyqmju7atjzqj8xrgs1qo87frkk0tjzvx713svzwtjoluu3xxf7nc0orxgu0yyiz2wqmrvoy1bknydb12kuqxyit8vs0r8z7xw1lkyzekh3ljycqxabl8jzlrf38uui3xwzqg07ekh3lgyclgsom7w7ljg70tjox2yznry7atj3mepv1xk33czpyrfu0evzp2qmqwvzltk72tfxmrafm28z1rfz7qjz3xqctgfpttfqll0318a7qvyz1gfu0u8ztxyknayzy1bkny8xxxkcnvvpagkuwwdo880qqkwzt3k72tfxmrakmc8pljg7wrpoirq13svz8th1qhy3xxf1m8jogrjs0edoixyctgfptchhnuwcqrjfq88z8xdueedo880qqkwpmtkfnedxqgdml3w7ljg7wgdoz2e3lgpok3jfnepv1rzbtijzqrkbwtfmiretqs8zwtdzmlpb1xkcn70plxbbyw0owxqolsyoqcg7mhwb18a7mbppfrgc7tjz7x713svzh3k1qlycvgpsmvjolxgb0rjzoguctgfptck3nt0318a7q28z12ho0svm7jlzqkjpahfoljwb18a7mzppm2jz0u8z7jlzqayodcfqlkwxzgdmn8w7ljg70qyitxyzqsypr3gknt0318a7qcjzlxbbyw0o1xwsqrvo03bknyvbz2hbm8w7ljg7wjdor2qmqw07ekh3lrybqgdbtijzmgfu0ywiirluqgwo23g3ntfxm2dblijzm2hfww0z880qqkwzs3f1lqyc18a7q18oaxfbyw0onxu13svz7hhqlh0318a7mzpp8xd70wdi22qqqg07ekh3ltvc1rzbtijzexf70uui3xw1qkjpfcdhnj8xygsfqiw7ljg70qyitxyzqsypr3gknt0318a7qcjzlxbbyw0onxuzqgfpttjhlldb12k7nzvpf2vs0r8z72lemt8zdcvorlvcz2a7l3jzd2gm0qyi7x713svzwtjoluu3xxfoq1jzljg7wuppi2euqdvzekh3nuwxzxdsqb17frkuww0zwreeqapzkhholuu3xxfcmv8zt8vs0r0zb2lcna8pl3aorlvc2rk33czpyxj70uvm7jlzqjwzg3f3qhy3xxf7nzdilrf38uui3gy1mu8pl3a72tfxm2dhmiyzm2hs0yvzo2qqmrvo03afnt0318a7mcwi3rg77udmiretqddoe3bknydb7rabncjot8vs0rjiorlclgfptcdqlkycvgssmzppwxbbyw0o0re1mju7atj1mtvbcgjmnv8zljg70gvi1gukmsjzy1bknywbp2kfm3vzhxfbekdmirecnu8pacf72tfxm2jbq8ype2s38uui3gwclh8zn3k1medcfrzsti';

# device spec differs from board spec since it
# can only contain device information (no board specific parameters,
# like memory interfaces, etc)
my $device_spec = "";
my $soft_ip_c_name = "";
my $accel_name = "";

my $lmem_sweep_flag = '-sweeping-opt=1';
my $lmem_disable_split_flag = '-no-lms=1';
my $lmem_disable_replication_flag = ' -no-local-mem-replication=1';

# On Windows, always use 64-bit binaries.
# On Linux, always use 64-bit binaries, but via the wrapper shell scripts in "bin".
my $qbindir = ( $^O =~ m/MSWin/ ? 'bin64' : 'bin' );

# For messaging about missing executables
my $exesuffix = ( $^O =~ m/MSWin/ ? '.exe' : '' );

my $emulator_arch=acl::Env::get_arch();

sub mydie(@) {
  print STDERR "Error: ".join("\n",@_)."\n";
  chdir $orig_dir if defined $orig_dir;
  unlink $pkg_file;
  exit 1;
}

sub move_to_log { #string, filename ..., logfile
  my $string = shift @_;
  my $logfile= pop @_;
  open(LOG, ">>$logfile") or mydie("Couldn't open $logfile for appending.");
  print LOG $string."\n" if ($string && ($verbose > 1 || $save_temps));
  foreach my $infile (@_) {
    open(TMP, "<$infile") or mydie("Couldn't open $infile for reading.");;
    while(my $l = <TMP>) {
      print LOG $l;
    }
    close TMP;
    unlink $infile;
  }
  close LOG;
}

sub append_to_log { #filename ..., logfile
  my $logfile= pop @_;
  open(LOG, ">>$logfile") or mydie("Couldn't open $logfile for appending.");
  foreach my $infile (@_) {
    open(TMP, "<$infile")  or mydie("Couldn't open $infile for reading.");
    while(my $l = <TMP>) {
      print LOG $l;
    }
    close TMP;
  }
  close LOG;
}

sub move_to_err { #filename ..., logfile
  foreach my $infile (@_) {
    open(ERR, "<$infile");  ## We currently can't guarantee existence of $infile # or mydie("Couldn't open $infile for appending.");
    while(my $l = <ERR>) {
      print STDERR $l;
    }
    close ERR;
    unlink $infile;
  }
}

# This functions filters output from LLVM's --time-passes
# into the time log. The source log file is modified to not
# contain this output as well.
sub filter_llvm_time_passes {
  my ($logfile) = @_;

  if ($time_passes) {
    open (my $L, '<', $logfile) or mydie("Couldn't open $logfile for reading.");
    my @lines = <$L>;
    close ($L);

    # Look for the specific output pattern that corresponds to the
    # LLVM --time-passes report.
    for (my $i = 0; $i <= $#lines;) {
      my $l = $lines[$i];
      if ($l =~ m/^\s+\.\.\. Pass execution timing report \.\.\.\s+$/) {
        # We are in a --time-passes section.
        my $start_line = $i - 1; # -1 because there's a ===----=== line before that's part of the --time-passes output

        # The end of the section is the SECOND blank line.
        for(my $j = 0; $j < 2; ++$j) {
          for(++$i; $i <= $#lines && $lines[$i] !~ m/^$/; ++$i) {
          }
        }
        my $end_line = $i;

        my @time_passes = splice (@lines, $start_line, $end_line - $start_line + 1);
        print $time_log join ("", @time_passes);

        # Continue processing the rest of the lines, taking into account that
        # a chunk of the array just got removed.
        $i = $start_line;
      }
      else {
        ++$i;
      }
    }

    # Now rewrite the log file without the --time-passes output.
    open (my $L, '>', $logfile) or mydie("Couldn't open $logfile for writing.");
    print $L join ("", @lines);
    close ($L);
  }
}

# This is called between system call and check child error so it can 
# NOT do system calls
sub move_to_err_and_log { #String filename ..., logfile
  my $string = shift @_;
  my $logfile = pop @_;
  foreach my $infile (@_) {
    open ERR, "<$infile"  or mydie("Couldn't open $logfile for reading.");
    while(my $l = <ERR>) {
      print STDERR $l;
    }
    close ERR;
    move_to_log($string, $infile, $logfile);
  }
}

# Functions to execute external commands, with various wrapper capabilities:
#   1. Logging
#   2. Time measurement
# Arguments:
#   @_[0] = { 
#       'stdout' => 'filename',   # optional
#       'stderr' => 'filename',   # optional
#       'time' => 0|1,            # optional
#       'time-label' => 'string'  # optional
#     }
#   @_[1..$#@_] = arguments of command to execute
sub mysystem_full($@) {
  my $opts = shift(@_);
  my @cmd = @_;

  my $out = $opts->{'stdout'};
  my $err = $opts->{'stderr'};

  if ($verbose >= 2) {
    print join(' ',@cmd)."\n";
  }

  # Replace STDOUT/STDERR as requested.
  # Save the original handles.
  if($out) {
    open(OLD_STDOUT, ">&STDOUT") or mydie "Couldn't open STDOUT: $!";
    open(STDOUT, ">$out") or mydie "Couldn't redirect STDOUT to $out: $!";
    $| = 1;
  }
  if($err) {
    open(OLD_STDERR, ">&STDERR") or mydie "Couldn't open STDERR: $!";
    open(STDERR, ">$err") or mydie "Couldn't redirect STDERR to $err: $!";
    select(STDERR);
    $| = 1;
    select(STDOUT);
  }

  # Run the command.
  my $start_time = time();
  system(@cmd);
  my $end_time = time();

  # Restore STDOUT/STDERR if they were replaced.
  if($out) {
    close(STDOUT) or mydie "Couldn't close STDOUT: $!";
    open(STDOUT, ">&OLD_STDOUT") or mydie "Couldn't reopen STDOUT: $!";
  }
  if($err) {
    close(STDERR) or mydie "Couldn't close STDERR: $!";
    open(STDERR, ">&OLD_STDERR") or mydie "Couldn't reopen STDERR: $!";
  }

  # Dump out time taken if we're tracking time.
  if ($time_log && $opts->{'time'}) {
    my $time_label = $opts->{'time-label'};
    if (!$time_label) {
      # Just use the command as the label.
      $time_label = join (' ', @cmd);
    }

    log_time ($time_label, $end_time - $start_time);
  }
  return $?
}

sub mysystem_redirect($@) {
  # Run command, but redirect standard output to $outfile.
  my ($outfile,@cmd) = @_;
  return mysystem_full ({'stdout' => $outfile}, @cmd);
}

sub mysystem(@) {
  return mysystem_redirect('',@_);
}

sub hard_routing_error_code($@)
{
  my $error_string = shift @_;
  if( $error_string =~ /^Error \(170113\)/ ) {
    return 1;
  }
  return 0;
}

sub hard_routing_error($@)
 { #filename
     my $infile = shift @_;
     open(ERR, "<$infile");  ## if there is no $infile, we just return 0;
     while( <ERR> ) {
       if( hard_routing_error_code( $_ ) ) {
         return 1;
       }
     }
     close ERR;
     return 0;
 }

sub print_quartus_errors($@)
 { #filename
     my $infile = shift @_;
     my $flag_recomendation = shift @_;
     open(ERR, "<$infile");  ## if there is no $infile, we just die on the error
     while( <ERR> ) {
	if( $_ =~ /^Error/ ){
	    if( hard_routing_error_code( $_ ) && $flag_recomendation ) {
                print STDERR "Error: Kernel fit error, recommend using --high-effort.\n";
	    }
	    if( $_ =~ /^Error \(11802\)/ ) {
		mydie("Cannot fit kernel(s) on device");
	    }
	}
     }
     close ERR;
     mydie("Compiler Error, not able to generate hardware\n");
 }

sub log_time($$) {
  my ($label, $time) = @_;
  if ($time_log) {
    printf ($time_log "[time] %s ran in %ds\n", $label, $time);
  }
}

sub save_pkg_section($$$) {
   my ($pkg,$section,$value) = @_;
   # The temporary file should be in the compiler work directory.
   # The work directory has already been created.
   my $file = $verbatim_work_dir.'/value.txt';
   open(VALUE,">$file") or mydie("Can't write to $file: $!");
   binmode(VALUE);
   print VALUE $value;
   close VALUE;
   $pkg->set_file($section,$file)
       or mydie("Can't save value into package file: $acl::Pkg::error\n");
   unlink $file;
}

sub save_vfabric_files_to_pkg($$$$) {
  my ($pkg, $var_id, $vfab_lib_path, $work_dir) = @_;
  if (!-f $vfab_lib_path."/var".$var_id.".fpga.bin" ) {
    mydie("Cannot find Rapid Prototyping programming file.");
  }

  if (!-f $vfab_lib_path."/sys_description.txt" ) {
    mydie("Cannot find Rapid Prototyping system description.");
  }

  if (!-f $work_dir."/vfabric_settings.bin" ) {
    mydie("Cannot find Rapid Prototyping configuration settings.");
  }

  # add the complete vfabric configuration file to the package
  $pkg->set_file('.acl.vfabric', $work_dir."/vfabric_settings.bin")
      or mydie("Can't save Rapid Prototyping configuration file into package file: $acl::Pkg::error\n");

  $pkg->set_file('.acl.fpga.bin', $vfab_lib_path."/var".$var_id.".fpga.bin" )
      or mydie("Can't save FPGA programming file into package file: $acl::Pkg::error\n");

  $pkg->set_file('.acl.autodiscovery', $vfab_lib_path."/sys_description.txt")
      or mydie("Can't save system description into package file: $acl::Pkg::error\n");

  # Include the acl_quartus_report.txt file if it exists 
  my $acl_quartus_report = $vfab_lib_path."/var".$var_id.".acl_quartus_report.txt";
  if ( -f $acl_quartus_report ) {
    $pkg->set_file('.acl.quartus_report',$acl_quartus_report)
       or mydie("Can't save Quartus report file $acl_quartus_report into package file: $acl::Pkg::error\n");
  }      
}

sub save_profiling_xml($$) {
  my ($pkg,$basename) = @_;
  # Save the profile XML file in the aocx
  $pkg->add_file('.acl.profiler.xml',"$basename.bc.profiler.xml")
      or mydie("Can't save profiler XML $basename.bc.profiler.xml into package file: $acl::Pkg::error\n");
}

# Do setup checks:
sub check_env() {
  # 1. Is clang on the path?
  mydie ("$prog: The Altera SDK for OpenCL compiler front end (aocl-clang$exesuffix) can not be found")  unless -x $clang_exe.$exesuffix; 
  # Do we have a license?
  my $clang_output = `$clang_exe --version 2>&1`;
  chomp $clang_output;
  if ($clang_output =~ /Could not acquire OpenCL SDK license/ ) {
    mydie("$prog: Can't find a valid license for the Altera SDK for OpenCL\n");
  }
  if ($clang_output !~ /Altera SDK for OpenCL, Version/ ) {
    mydie("$prog: Can't find a working version of executable (aocl-opt$exesuffix) for the Altera SDK for OpenCL\n");
  }

  # 2. Is /opt/llc/system_integrator on the path?
  mydie ("$prog: The Altera SDK for OpenCL compiler front end (aocl-opt$exesuffix) can not be found")  unless -x $opt_exe.$exesuffix;   
  my $opt_out = `$opt_exe  --version 2>&1`;
  chomp $opt_out; 
  if ($opt_out !~ /Altera SDK for OpenCL, Version/ ) {
    mydie("$prog: Can't find a working version of executable (aocl-opt$exesuffix) for the Altera SDK for OpenCL\n");
  }
  mydie ("$prog: The Altera SDK for OpenCL compiler front end (aocl-llc$exesuffix) can not be found")  unless -x $llc_exe.$exesuffix; 
  my $llc_out = `$llc_exe --version`;
  chomp $llc_out; 
  if ($llc_out !~ /Altera SDK for OpenCL, Version/ ) {
    mydie("$prog: Can't find a working version of executable (aocl-llc$exesuffix) for the Altera SDK for OpenCL\n");
  }
  mydie ("$prog: The Altera SDK for OpenCL compiler front end (system_intgrator$exesuffix) can not be found")  unless -x $sysinteg_exe.$exesuffix; 
  my $system_integ = `$sysinteg_exe --help`;
  chomp $system_integ;
  if ($system_integ !~ /system_integrator - Create complete OpenCL system with kernels and a target board/ ) {
    mydie("$prog: Can't find a working version of executable (system_integrator$exesuffix) for the Altera SDK for OpenCL\n");
  }

  # 3. Is Quartus on the path?
  my $q_out = `$ENV{QUARTUS_ROOTDIR}/$qbindir/quartus_sh --version`;
  chomp $q_out;
  if ($q_out eq "") {
    print STDERR "$prog: Quartus is not on the path!\n";
    print STDERR "$prog: Is it installed on your system and QUARTUS_ROOTDIR environment variable set correctly?\n";
    exit 1;
  }

  # 4. Is it right Quartus version?
  my $q_ok = 0;
  my $q_version = "";
  my $req_qversion_str = exists($ENV{ACL_ACDS_VERSION_OVERRIDE}) ? $ENV{ACL_ACDS_VERSION_OVERRIDE} : "15.0.0";
  my $req_qversion = acl::Env::get_quartus_version($req_qversion_str);

  foreach my $line (split ('\n', $q_out)) {
    if ($line =~ /64-Bit/) {
      $q_ok += 1;
    }
    # With QXP flow should be compatible with future versions

    # Do version check.
    my ($qversion_str) = ($line =~ m/Version (\S+)/);
    my $qversion = acl::Env::get_quartus_version($qversion_str);
    if(acl::Env::are_quartus_versions_compatible($req_qversion, $qversion)) {
      $q_ok++;
    }
  }
  if ($q_ok != 2) {
    print STDERR "$prog: This release of the Altera SDK for OpenCL requires ACDS Version $req_qversion_str (64-bit).";
    print STDERR " However, the following version was found: \n$q_out\n";
    exit 1;
  }

  # If here, everything checks out fine.
  print "$prog: Environment checks are completed successfully.\n" if $verbose;
  return;
}

sub get_acl_board_hw_path {
  my $bv = shift @_;
  my ($result) = acl::Env::board_hw_path($bv);
  return $result;
}


sub remove_named_files {
    foreach my $fname (@_) {
      acl::File::remove_tree( $fname, { verbose => ($verbose == 1 ? 0 : $verbose), dry_run => 0 } )
         or mydie("Could not remove intermediate files under directory $fname: $acl::File::error\n");
    }
}

sub remove_intermediate_files($$) {
   my ($dir,$exceptfile) = @_;
   my $thedir = "$dir/.";
   my $thisdir = "$dir/..";
   my %is_exception = (
      $exceptfile => 1,
      "$dir/." => 1,
      "$dir/.." => 1,
   );
   foreach my $file ( acl::File::simple_glob( "$dir/*", { all => 1 } ) ) {
      if ( $is_exception{$file} ) {
         next;
      }
      if ( $file =~ m/\.aclx$/ ) {
         next if $exceptfile eq acl::File::abs_path($file);
      }
      acl::File::remove_tree( $file, { verbose => $verbose, dry_run => 0 } )
         or mydie("Could not remove intermediate files under directory $dir: $acl::File::error\n");
   }
   # If output file is outside the intermediate dir, then can remove the intermediate dir
   my $files_remain = 0;
   foreach my $file ( acl::File::simple_glob( "$dir/*", { all => 1 } ) ) {
      next if $file eq "$dir/.";
      next if $file eq "$dir/..";
      $files_remain = 1;
      last;
   }
   unless ( $files_remain ) { rmdir $dir; }
}

sub create_system {
  my ($base,$work_dir,$src,$obj,$board_variant) = @_;

  my $pkg_file_final = $obj;
  $pkg_file = $pkg_file_final.".tmp";
  $fulllog = "$base.log"; #definition moved to global space
  my $run_copy_skel = 1;
  my $run_copy_ip = 1;
  my $run_clang = 1;
  my $run_opt = 1;
  my $run_verilog_gen = 1;
  my $run_opt_vfabric = 0;
  my $run_vfabric_cfg_gen = 0;

  my $finalize = sub {
     unlink( $pkg_file_final ) if -f $pkg_file_final;
     rename( $pkg_file, $pkg_file_final )
         or mydie("Can't rename $pkg_file to $pkg_file_final: $!");
     chdir $orig_dir or mydie("Can't change back into directory $orig_dir: $!");
  };

  if ( $parse_only || $opt_only || $verilog_gen_only || ($vfabric_flow && !$generate_vfabric) || $emulator_flow ) {
    $run_copy_ip = 0;
    $run_copy_skel = 0;
  }

  if ( $accel_gen_flow ) {
    $run_copy_skel = 0;
  }

  if ($vfabric_flow) {
    $run_opt = 0;
    $run_opt_vfabric = 1;
    $run_vfabric_cfg_gen = 1;
  }

  my $stage1_start_time = time();
  #Create the new direcory verbatim, then rewrite it to not contain spaces
  $work_dir = $verbatim_work_dir;
  acl::File::make_path($work_dir) or mydie("Can't create temporary directory $work_dir: $!");
  $work_dir =~ s/ /\?/g;
  unlink "$work_dir/$fulllog";
  if ($regtest_mode){
      open(my $TMPOUT, ">$verbatim_work_dir/$fulllog") or mydie ("Couldn't open $work_dir/$fulllog to log version information.");
      version ($TMPOUT);
      close($TMPOUT);
  }
  my $acl_board_hw_path= get_acl_board_hw_path($board_variant);

  # Make sure the board specification file exists. This is needed by multiple stages of the compile.
  my ($board_spec_xml) = acl::File::simple_glob( $acl_board_hw_path."/board_spec.xml" );
  my $xml_error_msg = "Cannot find Board specification!\n*** No board specification (*.xml) file inside ".$acl_board_hw_path.". ***\n" ;
  if ( $device_spec ne "" ) {
    my $full_path =  acl::File::abs_path( $device_spec );
    $board_spec_xml = $full_path;
    $xml_error_msg = "Cannot find Device Specification!\n*** device file ".$board_spec_xml." not found.***\n";
  }
  -f $board_spec_xml or mydie( $xml_error_msg );
  my $llvm_board_option = "-board $board_spec_xml";   # To be passed to LLVM executables.
  my $llvm_efi_option = (defined $absolute_efispec_file ? "-efi $absolute_efispec_file" : ""); # To be passed to LLVM executables
  my $llvm_profilerconf_option = (defined $absolute_profilerconf_file ? "-profile-config $absolute_profilerconf_file" : ""); # To be passed to LLVM executables

  if (!$accel_gen_flow && !$soft_ip_c_flow) {
    print "$prog: Selected target board $board_variant\n" if $verbose||$report;
  }

  if(defined $absolute_efispec_file) {
    print "$prog: Selected EFI spec $absolute_efispec_file\n" if $verbose||$report;
  }

  if(defined $absolute_profilerconf_file) {
    print "$prog: Selected profiler conf $absolute_profilerconf_file\n" if $verbose||$report;
  }

  if ( $run_copy_skel ) {
    # Copy board skeleton, unconditionally.
    # Later steps update .qsf and .sopc in place.
    # You *will* get SOPC generation failures because of double-add of same
    # interface unless you get a fresh .sopc here.
    acl::File::copy_tree( $acl_board_hw_path."/*", $verbatim_work_dir )
      or mydie("Can't copy Board template files: $acl::File::error");
    map { acl::File::make_writable($_) } (
      acl::File::simple_glob( "$work_dir/*.qsf" ),
      acl::File::simple_glob( "$work_dir/*.sopc" ) );
  }

  if ( $run_copy_ip ) {
    # Rather than copy ip files from the SDK root to the kernel directory, 
    # generate an opencl.ipx file to point Qsys to hw.tcl components in 
    # the IP in the SDK root when generating the system.
    my $opencl_ipx = "$verbatim_work_dir/opencl.ipx";
    open(my $fh, '>', $opencl_ipx) or die "Could not open file '$opencl_ipx' $!";
    print $fh '<?xml version="1.0" encoding="UTF-8"?>
<library>
 <path path="${ALTERAOCLSDKROOT}/ip/*" />
</library>
';
    close $fh;

    # Also generate an assignment in the .qsf pointing to this IP.
    # We need to do this because not all the hdl files required by synthesis
    # are necessarily in the hw.tcl (i.e., not the entire file hierarchy).
    #
    # For example, if the Qsys system needs A.v to instantiate module A, then
    # A.v will be listed in the hw.tcl. Every file listed in the hw.tcl also
    # gets copied to system/synthesis/submodules and referenced in system.qip,
    # and system.qip is included in the .qsf, therefore synthesis will be able
    # to find the file A.v. 
    #
    # But if A instantiates module B, B.v does not need to be in the hw.tcl, 
    # since Qsys still is able to find B.v during system generation. So while
    # the Qsys generation will still succeed without B.v listed in the hw.tcl, 
    # B.v will not be copied to submodules/ and will not be included in the .qip,
    # so synthesis will fail while looking for this IP file. This happens in the 
    # virtual fabric flow, where the full hierarchy is not included in the hw.tcl.
    #
    # Since we are using an environment variable in the path, move the 
    # assignment to a tcl file and source the file in each qsf (done below).
    my $ip_include = "$verbatim_work_dir/ip_include.tcl";
    open(my $fh, '>', $ip_include) or die "Could not open file '$ip_include' $!";
    print $fh 'set_global_assignment -name SEARCH_PATH "$::env(ALTERAOCLSDKROOT)/ip"
';
    close $fh;

    # Add SEARCH_PATH for ip/$base to the QSF file
    foreach my $qsf_file (acl::File::simple_glob( "$work_dir/*.qsf" )) {
      open (QSF_FILE, ">>$qsf_file") or die "Couldn't open $qsf_file for append!\n";

      # Source a tcl script which points the project to the IP directory
      print QSF_FILE "\nset_global_assignment -name SOURCE_TCL_SCRIPT_FILE ip_include.tcl\n";

      # Case:149478. Disable auto shift register inference for appropriately named nodes
      print "$prog: Adding wild-carded AUTO_SHIFT_REGISTER_RECOGNITION assignment to $qsf_file\n" if $verbose>1;
      print QSF_FILE "\nset_instance_assignment -name AUTO_SHIFT_REGISTER_RECOGNITION OFF -to *_NO_SHIFT_REG*\n";
      close (QSF_FILE);
    }
  }

  my $optinfile = "$base.1.bc";
  my $pkg = undef;


  # Copy the CL file to subdir so that archived with the project
  # Useful when creating many design variants
  # But make sure it doesn't end with .cl
  acl::File::copy( $absolute_srcfile, $verbatim_work_dir."/".acl::File::mybasename($absolute_srcfile).".orig" )
   or mydie("Can't copy cl file to destination directory: $acl::File::error");

  # OK, no turning back remove the result file, so no one thinks we succedded
  unlink "$objfile";

  # initializes DSE
  acl::DSE::dse_prologue($work_dir);

  if ( $soft_ip_c_flow ) {
      $clang_arg_after = "-x soft-ip-c -soft-ip-c-func-name=$soft_ip_c_name";
      $dse = 0;
  } elsif ($accel_gen_flow ) {
      $clang_arg_after = "-x cl -soft-ip-c-func-name=$accel_name";
  } elsif ($dse > 0) { 
    # do automated sharing only if dse is active
    # change unrolling behavior only if dse is active, this is overriden by dse_config
    $opt_arg_after .= " -dseon=1"; 
  }

  # Late environment check IFF we are using the emulator
  if (($emulator_arch eq 'windows64') && ($emulator_flow == 1) ) {
    my $msvc_out = `LINK 2>&1`;
    chomp $msvc_out; 

    if ($msvc_out !~ /Microsoft \(R\) Incremental Linker Version/ ) {
      mydie("$prog: Can't find VisualStudio linker LINK.EXE.\nEither use Visual Studio x64 Command Prompt or run %ALTERAOCLSDKROOT%\\init_opencl.bat to setup your environment.\n");
    }
  }

  if ( $run_clang ) {
    my $clangout = "$base.pre.bc";
    my @cmd_list = ();

    if ( not $c_acceleration ) {
      print "$prog: Running OpenCL parser....\n" if $verbose; 
      chdir $force_initial_dir or mydie("Can't change into dir $force_initial_dir: $!\n");

      my @debug_options = ( $debug ? qw(-mllvm -debug) : ());
      my @clang_std_opts = ( $emulator_flow ? qw(-cc1 -target-abi opencl -emit-llvm-bc -mllvm -gen-efi-tb -DALTERA_CL -Wuninitialized) : qw( -cc1 -O3 -emit-llvm-bc -DALTERA_CL -Wuninitialized));
      my @board_options = map { ('-mllvm', $_) } split( /\s+/, $llvm_board_option );
      my @board_def = (
          "-DACL_BOARD_$board_variant=1", # Keep this around for backward compatibility
          "-DAOCL_BOARD_$board_variant=1",
          );
      my @efi_options = map { ('-mllvm', $_) } split( /\s+/, $llvm_efi_option );
      my @clang_arg_after_array = split(/\s+/m,$clang_arg_after);
      my @triple_arg = ('-triple',($big_endian ? 'fpga64be' : 'fpga64'));
      my @emulator_arg = ('-triple',(($emulator_arch eq 'windows64') ? 'x86_64-pc-win32' : 'x86_64-unknown-linux-gnu'));
      @cmd_list = (
          $clang_exe, 
          @clang_std_opts,
          ($emulator_flow ? @emulator_arg : @triple_arg),
          @board_options,
          @board_def,
          @efi_options,
          @debug_options, 
          $absolute_srcfile,
          @clang_arg_after_array,
          '-o',
          "$verbatim_work_dir/$clangout",
          @user_clang_args,
          );
      $return_status = mysystem_full(
          {'stdout' => "$verbatim_work_dir/clang.log", 'stderr' => "$verbatim_work_dir/clang.err",
           'time' => 1, 'time-label' => 'clang'},
          @cmd_list);
      move_to_log("!========== [clang] parse ==========", "$verbatim_work_dir/clang.log", "$verbatim_work_dir/$fulllog"); 
      append_to_log("$verbatim_work_dir/clang.err", "$verbatim_work_dir/$fulllog");
      move_to_err("$verbatim_work_dir/clang.err");
      $return_status == 0 or mydie("OpenCL parser FAILED.\nRefer to $base/$fulllog for details.\n");
    }

    if ( $parse_only ) { return; }

    # Create package file in source directory, and save compile options.
    $pkg = create acl::Pkg($pkg_file);
    if ( defined $program_hash ){ 
      save_pkg_section($pkg,'.acl.hash',$program_hash);
    }
    if ($emulator_flow) {
	save_pkg_section($pkg,'.acl.board',$emulatorDevice);
    } else {
	save_pkg_section($pkg,'.acl.board',$board_variant);
    }
    save_pkg_section($pkg,'.acl.compileoptions',join(' ',@user_opencl_args));
    # Set version of the compiler, for informational use.
    # It will be set again when we actually produce executable contents.
    save_pkg_section($pkg,'.acl.version',acl::Env::sdk_version());

    print "$prog: OpenCL parser completed successfully.\n" if $verbose;
    if ( $disassemble ) { mysystem("llvm-dis \"$work_dir/$clangout\" -o \"$verbatim_work_dir/$clangout.ll\"" ) == 0 or mydie("Cannot disassemble: \"$work_dir/$clangout\"\n"); }

    if ( $pkg_save_extra || $profile || $dash_g ) {
      my $files = `file-list \"$work_dir/$clangout\"`;
      my $index = 0;
      foreach my $file ( split(/\n/, $files) ) {
        save_pkg_section($pkg,'.acl.file.'.$index,$file);
        $pkg->add_file('.acl.source.'. $index,$file)
        or mydie("Can't save source into package file: $acl::Pkg::error\n");
        $index = $index + 1;
      }
      save_pkg_section($pkg,'.acl.nfiles',$index);

      $pkg->add_file('.acl.source',$absolute_srcfile)
      or mydie("Can't save source into package file: $acl::Pkg::error\n");
    }

    # do not enter to the work directory before this point, 
    # $pkg->add_file above may be called for files with relative paths
    chdir $verbatim_work_dir or mydie("Can't change dir into $work_dir: $!");

    if ($emulator_flow) {
      print "$prog: Compiling for Emulation ....\n" if $verbose;
      # Link with standard library.
      my $emulator_lib = acl::File::abs_path( acl::Env::sdk_root()."/share/lib/acl/acl_early.bc");
      my $emulator2_lib = acl::File::abs_path( acl::Env::sdk_root()."/share/lib/acl/acl_late.bc");
      @cmd_list = (
	  $link_exe,
	  "$verbatim_work_dir/$clangout",
	  $emulator_lib,
	  $emulator2_lib,
	  '-o',
	  $optinfile );
      $return_status = mysystem_full(
	  {'stdout' => "$verbatim_work_dir/clang-link.log", 'stderr' => "$verbatim_work_dir/clang-link.err",
	   'time' => 1, 'time-label' => 'link (early)'},
	  @cmd_list);
      move_to_log("!========== [link] early link ==========", "$verbatim_work_dir/clang-link.log",
		  "$verbatim_work_dir/$fulllog");
      move_to_err("$verbatim_work_dir/clang-link.err");
      remove_named_files($clangout) unless $save_temps;
      $return_status == 0 or mydie("OpenCL parser FAILED.\nRefer to $base/$fulllog for details.\n");
      my $debug_option = ( $debug ? '-debug' : '');
      my $emulator_efi_option = ( $efispec_file ? '-createemulatorefiwrappers' : '');
      $return_status = mysystem_full(
	  {'time' => 1, 'time-label' => 'opt (opt (emulator tweaks))'},
	  "$opt_exe -translate-library-calls -reverse-library-translation -lowerconv -insert-ip-library-calls -createemulatorwrapper $emulator_efi_option -generateemulatorsysdesc  $llvm_board_option $llvm_efi_option $debug_option $opt_arg_after \"$optinfile\" -o \"$base.bc\" >>$fulllog 2>opt.err" );
      filter_llvm_time_passes("opt.err");
      move_to_err_and_log("========== [aocl-opt] Emulator specific messages ==========", "opt.err", $fulllog);
      $return_status == 0 or mydie("Optimizer FAILED.\nRefer to $base/$fulllog for details.\n");

      $pkg->set_file('.acl.llvmir',"$base.bc")
	  or mydie("Can't save optimized IR into package file: $acl::Pkg::error\n");
      $pkg->set_file('.acl.autodiscovery',"sys_description.txt")
	  or mydie("Can't save system description into package file: $acl::Pkg::error\n");
      my $arch_options = ();
      if ($emulator_arch eq 'windows64') {
          $arch_options = "-cc1 -triple x86_64-pc-win32 -emit-obj -o libkernel.obj";
      } else {
	  $arch_options = "-fPIC -shared -Wl,-soname,libkernel.so -o libkernel.so";
      }
      $return_status = mysystem_full(
	  {'time' => 1, 'time-label' => 'clang (executable emulator image)'},
	  "$clang_exe $arch_options -O0 \"$base.bc\" >>$fulllog 2>opt.err" );
      filter_llvm_time_passes("opt.err");
      move_to_err_and_log("========== [clang compile kernel emulator] Emulator specific messages ==========", "opt.err", $fulllog);
      $return_status == 0 or mydie("Optimizer FAILED.\nRefer $base/$fulllog for details.\n");
      if ($emulator_arch eq 'windows64') {

        $return_status = mysystem_full(
            {'time' => 1, 'time-label' => 'clang (executable emulator image)'},
            "link /DLL /EXPORT:__kernel_desc,DATA /libpath:$ENV{\"ALTERAOCLSDKROOT\"}\\host\\windows64\\lib acl_emulator_kernel_rt.lib msvcrt.lib libkernel.obj>>$fulllog 2>opt.err" );
        filter_llvm_time_passes("opt.err");
        move_to_err_and_log("========== [Create kernel loadbable module] Emulator specific messages ==========", "opt.err", $fulllog);
        $return_status == 0 or mydie("Optimizer FAILED.\nRefer $base/$fulllog for details.\n");
        $pkg->set_file('.acl.emulator_object.windows',"libkernel.dll")
            or mydie("Can't save emulated kernel into package file: $acl::Pkg::error\n");
      } else {     
        $pkg->set_file('.acl.emulator_object.linux',"libkernel.so")
          or mydie("Can't save emulated kernel into package file: $acl::Pkg::error\n");
      }

      # Compute runtime.
      my $stage1_end_time = time();
      log_time ("emulator compilation", $stage1_end_time - $stage1_start_time);

      print "$prog: Emulator Compilation completed successfully.\n" if $verbose;
      &$finalize();
      return;
    } 

    # Link with standard library.
    my $early_bc = acl::File::abs_path( acl::Env::sdk_root()."/share/lib/acl/acl_early.bc");
    @cmd_list = (
      $link_exe,
      "$verbatim_work_dir/$clangout",
      $early_bc,
      '-o',
      $optinfile );
    $return_status = mysystem_full(
        {'stdout' => "$verbatim_work_dir/clang-link.log", 'stderr' => "$verbatim_work_dir/clang-link.err",
         'time' => 1, 'time-label' => 'link (early)'},
        @cmd_list);
    move_to_log("!========== [link] early link ==========", "$verbatim_work_dir/clang-link.log",
        "$verbatim_work_dir/$fulllog");
    move_to_err("$verbatim_work_dir/clang-link.err");
    remove_named_files($clangout) unless $save_temps;
    $return_status == 0 or mydie("OpenCL parser FAILED.\nRefer to $base/$fulllog for details.\n");
  }

  chdir $verbatim_work_dir or mydie("Can't change dir into $work_dir: $!");

  my $disabled_lmem_replication = 0;
  my $restart_acl = 1;  # Enable first iteration
  my $opt_passes = $dft_opt_passes;
  if ( $soft_ip_c_flow ) {
      $opt_passes = $soft_ip_opt_passes;
  }

  if ( $run_opt_vfabric ) {
    print "$prog: Compiling with Rapid Prototyping flow....\n" if $verbose;
    $restart_acl = 0;
    my $debug_option = ( $debug ? '-debug' : '');
    my $profile_option = ( $profile ? '-profile' : '');

    # run opt
    $return_status = mysystem_full(
        {'time' => 1, 'time-label' => 'opt ', 'stdout' => 'opt.log', 'stderr' => 'opt.err'},
        "$opt_exe --acle ljg7wk8o12ectgfpthjmnj8xmgf1qb17frkzwewi22etqs0o0cvorlvczrk7mipp8xd3egwiyx713svzw3kmlt8clxdbqoypaxbbyw0oygu1nsyzekh3nt0x0jpsmvypfxguwwdo880qqk8pachqllyc18a7q3wp12j7eqwipxw13swz1bp7tk71wyb3rb17frk77rpop2eonuyz8ch72tfxmxkcl8yp3ggewtfmiremqspot3korlvcxxabtijz8xfb0rdzp2e3ldjpacvorlvc12j1qo87frkh0wwiy20qqk0okcdolq8xxgssmxw7ljg70gpizxutqddzbtjbnr0318a7m8jzrxg1wg8z7xutmju7atjznyyc0jpsmv8zrgfh0sdmirezquyzy1bknywxcxjbq887frkbwsvz7re3nju7atj1nupblgsbq8w7ljg70qyitxyzqsypr3gknt0318a7m8ypaxfh0qyokremqh07ekh3lrybxxfcnzvpf2kcek8ztx713svzuhdclkpbcgafq3ypdgg38uui3ruzqjwpuhd1mt0bvgpsmvjo82k38uui32wbmuwpb3bknyvcqgd33czpyrfu0evzp2qmqwy7atjfnepcmgfhqojot8vs0r8ie2lclgfptcfeljyc7rduqivzt8vs0rpowxyoldpz7cfolkpbcrk1mxyzm2hfwwvm7jlzqkjp2hdolq8cygdcmczpyxfm7wvz1rwbmr8pshh72tfxmxkumowos2ho0s0onrwctgfpt3gknjwbmxakqvypf2j38uui3xybqdwpt3jflqycvgskqb17frk77qdiyxlkmh8ithkcluu3xxfmncyz8rff0rpi1xy1mju7atjfnljxwgpsmvdodxd1wkdo880qqkwpktjsluu3xxfhmivp32vs0rdziru7ldwotcgorlvcyrsmncjohrghwudmixwc2ju7atjfnljxwgpsmv8ofrfz7qjz3xqctgfpt3gknjwbmxakqvypf2j38uui32qqmgdouhd3quu3xxfhmivp32vs0rpi02qeqa07ekh3lqjxcrkbtijzq2jh0ujzbrlqmju7atjclgdx0jpsmv8pl2g7whppoxu3nju7atj3myvcwrzbtijzggg7ek0oo2loqddpecvorlvcigjkq187frkceq8z72e3qddpqcvorlvcmxaml88zs2kc7ujo7jlzmyposcdmnr8cygsfqiw7ljg7wu0z7x713svzuck3nt0318a7m8ypaxfh0qyokremqh07ekh3nedxqrj7mi8pu2hs0uvm7jlzquwo23g7mtfxmrdbmb0zljg7wh8zoxyemr8i83k3quu3xxfzqovpu2khwu0o7x713svztthknjwbbgdmnx8zt8vs0r8o1guoldyz2cvorlvcmxasq28z1xdbyw0obrlongy7atjqnljblgpsmv0od2vs0rpiixyolddp33g3nj0318a7qovpdxfbyw0ot2qumywpkhkqquu3xxfhmvjo82k38uui3xleqs0oekh3nhdxlxahqow7ljg70gpizxutqddzbtjbnr0318a7m8jzyxf38uui3rwmns07ekh3nqycbxf3n7vp3xd38uui32qqquwotthsly8xxgd33czpyghb7evz7jlzmr0p23kmlt8xxxd33czpyrkfwg8z7xlbmryzw3bkny0blxa3nbvzrxdu0wyi880qqkwz33k72tfxmgfcmv8zt8vs0r0zb2lcna8pl3a3lrjc0jpsmvypfrfc7rwizgekmsyzy1bknyvby2kuq187frkc0upo020qqk0o2thzmlwbfrkbm8w7ljg70yjiogebmawzt3k72tfxmxffqijom2gbwgwo7x713svzr3j1qj8x12k33czpy2kh0jpokru13svzkhhfnedx1rzbtijzfrgm7e8z7xyctgfptckclgyb1rzbtijzrrkh0uui3xleqjwzekh3njwbc2kbmczpy2hswk8zbglzldvz33bkny8c8rd33czpyxgf0jdorreemsdoy1bknywcmgd33czpy2kh0jpokru13svz23ksnldb1gpsmv8pl2gbyw0obgl3nu8patdqnyvb0jpsmvdol2gfwjdo7jlzqsjpr3bkny8cmxfbm8jolrf38uui3xwzqg07ekh3njvc7ra1q8dolxfhwtfmire3qkyzy1bknyybqgdbtijz3gfuwj87r2w7qgfptcfeljycqrsfqo0zt8vs0rvzr2qmnuzoetkorlvcyrsmncjohrghwudmixwz2u77ekh3lkpbz2jmr88zwxbbyw0or2wuqsdoe3bkny8xxgscnzyzs2hq7tjzbrlqqgfpttdzmlpb1xk33czpygfb0ewil2w13svz7hhcmudxygdcmczpyrk1wejitx713svz8hdhnqjxygd3l8yp7xbbyw0o1xwzqg07ekh3lqjxcrkbtijz82hkwhjibgwknju7atj7qe8x18a7mvvprxgb0g0obgl7mju7atj3meyxwrauqxyiygjzwtfmirekmsvo0tjhnqpcz2abqb17frkc0rdo880qqkdzkcaoqky3xxfmmz0oy2k7ek0z880qqkwpftdorlvcbgdmnx8zljg70tjipx713svzd3honqy3xxf7l10pgxdc7u8z880qqkdoehdqlr8v0jpsmvppdgfkwe0z880qqk8z0cf1mepcurjbq1dodxf10ypow2qems07ekh3nrdbxrzbtijzqrkbwtfmirezldyp8chqlr8vm2dzqb17frkh0gjzr2yzmr8pl3a72tfxmgssm80oyrgkwrpii2w13svzathorlvcrrzbtijz8rk1wepor2qslgy7atjfnupb3gdbtijzrrjzwgdom2e3lgvoy1bknyvbmgfhmbdo12j3eevm7jlzmgvzecvorlvc2gstn3woljg7wrpiwrebquwo3cvorlvcvxazncdo8rduwk0ovx713svz3tjmlq8clgsqnc87frkc0wyiw20qqkwos3f3ley3xxfuq717frkk0udi7jlzqs0o33bkltdc7ra7ncw7ljg70g0o1xlbmu8px3korlvc3rafqvyzs2vs0rpo3re1quvoetd72tfxmxk7mb0prgfuwado7jlzmajpt3jfntfxmgf7mv8z8rfb0gvm7jlzquvzuchmlj8xagdbtijzyrgs0gjz7jlzqjvzt3k3mjycqrzbtijzs2hk0qjz7jlzqhdoa3bknywxcgfcmczpyrduwujzv20qqkwos3bknyv1lyzbtijz8rk1wepor2qslg07ekh3ltvc1rzbtijzrxj70uvm7jlzqhdoacvorlvc8xfbqb17frkuww0zwreeqapzkhholuu3xxf3l8vpwgf10edmire7majpr3jfntfxmgabmow7ljg7wh8zorwoljypekh3nrwxc2f1qo87frkk0udi7jlzqrvoutkoluu3xxf7npyp32vs0r0z02qmlgfpttd1mtyx18a7miwomxbbyw0owgukmt8puchorlvcbgfclzw7ljg70qyi02whlujoucd7medx3rzbtijzmgf1ww0znrlolay7atj7qj8xxrjoqb17frkh0wwiy20qqkvok3h7qq8x2gh33czpyxg70g0z1x713svzf3kfnljxwrzbtijz72jm7qyokx713svzdthhlky3xxf7nz8p3xguwypp880qqkwpttd3mu0318a7qvdzegfb0hdmirebmsdpscfmlhyc0jpsmvdz12ks0rvi7jlzqkjpahfoljvbzxasq8e7ljg7wu0o7x713svzkhh3qhvccgammzpplxbbyw0ol2wzmrjp23gumty3xxfemcdof2jhwtfmiremlgpokhkqquu3xxfzq2ppt8vs0rpiiru3lkjpfhjqllyc0jpsmv0zy2j38uui3gy1mu8pl3a72tfxm2kbmovp72jbyw0o02wbmgy7atj3qhjxlgd7lb17frkc0rdo880qqkdoehdqlr8v0jpsmv8plgfz0udmirecnuyzw3g3nuwb1rdbtijz8xdfwgdotx713svzwtjoluu3xxfuqijomrkf0e8obgl1mju7atj3my8cvgfml88zq2d7wkpioglctgfpt3jznyyc0jpsmv0pgrkkwtfmiretqsjp83bknyvccgammzpplxbbyw0op2qzqa07ekh3lgyclgsom7w7ljg7wewioxu13svz0hdqlkvccgjsq387frk1wwyioxybmryzy1bknyvcnrk33czpygdbwgpin2tctgfpt3gknjwbmxakqvypf2j38uui3rwmns07ekh3nj8xbrkhmzpzxrko0yvm7jlzqayz2tkoljycygjmliw7ljg70gpizxutqddzbtjbnr0318a7qovp02jm7gwzbxyzmd07ekh3nrdbxrzbtijzmgfuwjpi1xl13svzf3jzqe0318a7qcjzlxbbyw0ot2w3ljwpktkknqycxrj7lb17frko7u8zbgwknju7atj1mtwcuxfbmczpygfb0gwieguzqgvoy1bknywcmgd33czpygdbwgpin2tctgfpt3jzlwybqrjbtijz82hq7u0z880qqkvok3h7qq8x2gh7qxvzt8vs0rjiory1muvom3gzmy0x0jpsmvdzrgfm7qdorru3lwwpecvorlvc8xfbqb17frkuww0zwreeqapzkhholuu3xxfcmv8zt8vs0rjiz2wuqgfpthjmllvx18a7q1vp1xdbyw0o1ruzldjza3hollwb0jpsmv0pdrk1wedmireuqgypekh3lq8x2gdcnz8plrfbyw0o0rlqmry7atj3nlyxwgjcncw7ljg7wewzmxlkmsvoehdzquu3xxf1qovor2s77uui3gu1mryo2hhorlvcpxjznxypqxbbyw0or2w3ndjomtkqlt0318a7q2pz32k70lpi0ructgfpttfqll0318a7m2vp1rhuwkdoz20qqk8pacf1medxqgs7m887frkh0wwz7gu1mu07ekh3nyjxx2jbq80oljg70wyz7gummajpm3bknyjxxraunczpqxdm7kdo880qqkvzshhbmtpbygpsmvypfxdb0ydor20qqkyp7chzme0bvgsbq8jot8vs0rpiiru3lkjpfhjqllyc0jpsmv0zy2j38uui32e3mfyo3cforlvcqgsqncjot8vs0ryz7gukmh8iy1bknydcuxkbmczpyxdm7qwoogleqayz0hdqnyy3xxfom3ppyxdu0wyitx713svzwthoqywx1gpsmvwon2g37uui3gwclgfpt3fknewb0jpsmvypfrfc7rwizgekmsyzy1bknywcmgd33czpygj37rdmire3qgvzs3h7mlvbzrjumippt8vs0rpiiru3lkjpfhjqllyc0jpsmv0zy2j38uui3gwclky7atj3nldxrgdmn8ypdggbyw0or2wuqsdouch72tfxmgssm80oyrgkwrpii2wctgfptck3nt0318a7mxpofxbbyw0ozxu3mju7atj1mtwcuxfbmczpyxjbwhdoixw1msvze3bknywczxkcnbppy2j38uui32eonu8zb3bkny0blgsolb17frk1wwyioxybmryzekh3nqycbrdbq1w7ljg7whjiorlclgfptcdqlkycvgssmzppw2vs0ryzn2eomu8ptcvorlvcw2kbmczpyxgf0wvz7jlzmy8p83kfnedxz2azqb17frkm7udiogy1qgfptckoqkwxzxf1q38zljg7wu8omx713svzqhfkluu3xxfuqijomrkf0e8obgl1mju7atjmltvc1rzbtijz8rkuwjvm7jlzmajpscdorlvcwgs3nc0pggguwwwo880qqk8patdzmyjxb2fuqi8zt8vs0rjo32wctgfpthdonqjxrgdbtijzq2d3eepi32e3lgy7atjzlyjc0jpsmvjog2g3eepin2tzmhjzy1bknywxcxjbq8jo02hc7rvi880qqkwzscforlvcm2dzmczpyxgf0wvz7jlzmy8p83kfnedxz2azqb17frk1wu8ieru3lgfpttdqldycqrzbtijz72jm7qyokx713svzlchhnuwbz2azq1vpgggc7gjzkxl1mju7atjbmtpbz2dulb17frk70wyil2wonry7atjolfwb18a7q3vpljg70gdop2wzmr07ekh3ltvc1rzbtijzwgdswtfmire3qkyzy1bkny8xxxkcnvvpagkuwwdo880qqkwzt3k72tfxm2kbmoyzm2jm7qpop2qslgy7atjbnlpb18a7q2pzrgk38uui3gu1qa8z03k1me8cvgsqncw7ljg7wu0o7x713svz0hdqlg8x7rabtijzggg7ek0z7jlzmhjp23bknydb2gfmqb17frkcegpil2qbmay7atjqllvby2kbnv0ogrgs0uui3gu1mywpktjmlh8xc2a33czpy2jtehwit2w13svzd3gbmty3xxfonb0pn2j7etfmire3qkyzykck $llvm_board_option $debug_option $opt_arg_after \"$optinfile\" -o \"$base.bc\"" );
    filter_llvm_time_passes('opt.err');
    move_to_log("!========== [opt] ==========", 'opt.log', 'opt.err', $fulllog);
    move_to_err('opt.err'); # Warnings/errors
    if ($return_status != 0) {
      mydie("Optimizer FAILED.\nRefer to $base/$fulllog for details.\n");
    }

    # Finish up opt-like steps.
    if ( $run_opt || $run_opt_vfabric ) {
      if ( $disassemble || $soft_ip_c_flow ) { mysystem("llvm-dis \"$base.bc\" -o \"$base.ll\"" ) == 0 or mydie("Cannot disassemble: \"$base.bc\"\n"); }
      if ( $pkg_save_extra ) {
        $pkg->set_file('.acl.llvmir',"$base.bc")
        or mydie("Can't save optimized IR into package file: $acl::Pkg::error\n");
      }
      if ( $opt_only ) { return; }
    }
    if ( $run_vfabric_cfg_gen ) {
      my $debug_option = ( $debug ? '-debug' : '');
      my $vfab_lib_path = (($custom_vfab_lib_path) ? $custom_vfab_lib_path : 
      				$acl_board_hw_path."_vfabric");

      print "vfab_lib_path = $vfab_lib_path\n" if $verbose>1;

      # Check that this a valid board directory by checking for at least 1 
      # virtual fabric variant in the board directory.
      if (!-f $vfab_lib_path."/var1.txt" && !$generate_vfabric) {
        mydie("Cannot find Rapid Prototyping Library for board '$board_variant' in Rapid Prototyping flow. Run with '--create-template' flag to build new Rapid Protyping templates for this board.");
      }

      # check that this library matches the board_variant we are asked to compile to
      my $vfab_sys_file = "$vfab_lib_path/sys_description.txt";

      if (-f $vfab_sys_file) {
        open SYS_DESCR_FILE, "<$vfab_sys_file" or mydie("Invalid Rapid Prototyping Library Directory");
        my $vfab_sys_str = <SYS_DESCR_FILE>;
        chomp($vfab_sys_str);
        close SYS_DESCR_FILE;
        my @sys_split = split(' ', $vfab_sys_str);
        if ($sys_split[1] ne $board_variant) {
          mydie("Rapid Prototyping Library located in $vfab_lib_path is generated for board '$sys_split[1]' and cannot be used for board '$board_variant'.\n Please specify a different Library path.");
        }
      }
      remove_named_files("vfabv.txt");

      my $vfab_args = "-vfabric-library $vfab_lib_path";
      $vfab_args .= ($generate_vfabric ? " -generate-fabric-from-reqs " : "");
      $vfab_args .= ($reuse_vfabrics ? " -reuse-existing-fabrics " : "");

      if ($vfabric_seed) {
         $vfab_args .= " -vfabric-seed $vfabric_seed ";
      }
      $return_status = mysystem_full(
          {'time' => 1, 'time-label' => 'llc', 'stdout' => 'llc.log', 'stderr' => 'llc.err'},
          "$llc_exe  -march=virtualfabric $llvm_board_option $debug_option $profile_option $vfab_args $llc_arg_after \"$base.bc\" -o \"$base.v\"" );
      filter_llvm_time_passes('llc.err');
      move_to_log("!========== [llc] vfabric ==========", 'llc.log', 'llc.err', $fulllog);
      move_to_err('llc.err');
      if ($return_status != 0) {
        if (!$generate_vfabric) {
          mydie("No suitable Rapid Prototyping templates found.\nPlease run with '--create-template' flag to build new Rapid Prototyping templates.");
        } else {
          mydie("Rapid Prototyping template generation failed.");
        }
      }

      if ( $generate_vfabric ) {
        # add the complete vfabric configuration file to the package
        $pkg->set_file('.acl.vfabric', $work_dir."/vfabric_settings.bin")
           or mydie("Can't save Rapid Prototyping configuration file into package file: $acl::Pkg::error\n");
        if ($reuse_vfabrics && open VFAB_VAR_FILE, "<vfabv.txt") {
           my $var_id = <VFAB_VAR_FILE>;
           chomp($var_id);
           close VFAB_VAR_FILE;
           acl::File::copy( $vfab_lib_path."/var".$var_id.".txt", "vfab_var1.txt" )
              or mydie("Cannot find reused template: $acl::File::error");
        }
      } else {
        # Virtual Fabric flow is done at this point (don't need to generate design)
        # But now we can go copy over the selected sof 
        open VFAB_VAR_FILE, "<vfabv.txt" or mydie("No suitable Rapid Prototyping templates found.\nPlease run with '--create-template' flag to build new Rapid Prototyping templates.");
        my $var_id = <VFAB_VAR_FILE>;
        chomp($var_id);
        close VFAB_VAR_FILE;
        print "Selected Template $var_id\n" if $verbose;

        save_vfabric_files_to_pkg($pkg, $var_id, $vfab_lib_path, $verbatim_work_dir);

        # Save the profile XML file in the aocx
        if ( $profile ) {
          save_profiling_xml($pkg,$base);
        }

        my $board_xml = get_acl_board_hw_path($board_variant)."/board_spec.xml";
        if (-f $board_xml) {
           $pkg->set_file('.acl.board_spec.xml',"$board_xml")
                or mydie("Can't save boardspec.xml into package file: $acl::Pkg::error\n");
        }else { 
           print "Could not find board spec xml\n"
        }

        # Compute runtime.
        my $stage1_end_time = time();
        log_time ("virtual fabric compilation", $stage1_end_time - $stage1_start_time);

        print "$prog: Rapid Prototyping compilation completed successfully.\n" if $verbose;
        &$finalize(); 
        return;
      }
    }
  }

  ############## DSE LOOP #############
  my $design_area = undef;
  my $iterationlog="iteration.tmp";
  my $iterationerr="$iterationlog.err";
  unlink $iterationlog; # Make sure we don't inherit from previous runs

  while ($restart_acl) { # DSE may restart the compiler
    unlink $iterationlog unless $save_temps;
    unlink $iterationerr; # Always remove this guy or we will get duplicates to the the screen;
    $restart_acl = 0; # Don't restart compiling unless DSE or lmem replication decide otherwise

    if ( $run_opt ) {
      print "$prog: Compiling....\n" if $verbose;
      my $debug_option = ( $debug ? '-debug' : '');
      my $profile_option = ( $profile ? '-profile' : '');

      # Opt run
      $return_status = mysystem_full(
          {'time' => 1, 'time-label' => 'opt', 'stdout' => 'opt.log', 'stderr' => 'opt.err'},
          "$opt_exe $opt_passes $llvm_board_option $llvm_efi_option $debug_option $profile_option $opt_arg_after \"$optinfile\" -o \"$base.kwgid.bc\"");
      filter_llvm_time_passes('opt.err');
      append_to_log('opt.err', $iterationerr);
      move_to_log("!========== [opt] optimize ==========", 
          'opt.log', 'opt.err', $iterationlog);
      if ($return_status != 0) {
        move_to_log("", $iterationlog, $fulllog);
        move_to_err($iterationerr);
        mydie("Optimizer FAILED.\nRefer to $base/$fulllog for details.\n");
      }

      if ( $use_ip_library && $use_ip_library_override ) {
        print "$prog: Linking with IP library ...\n" if $verbose;
        # Lower instructions to IP library function calls
        $return_status = mysystem_full(
            {'time' => 1, 'time-label' => 'opt (ip library prep)', 'stdout' => 'opt.log', 'stderr' => 'opt.err'},
            "$opt_exe -insert-ip-library-calls $opt_arg_after \"$base.kwgid.bc\" -o \"$base.lowered.bc\"");
        filter_llvm_time_passes('opt.err');
        append_to_log('opt.err', $iterationerr);
        move_to_log("!========== [opt] ip library prep ==========", 'opt.log', 'opt.err', $iterationlog);
        if ($return_status != 0) {
          move_to_log("", $iterationlog, $fulllog);
          move_to_err($iterationerr);
          mydie("Optimizer FAILED.\nRefer to $base/$fulllog for details.\n");
        }
        remove_named_files("$base.kwgid.bc") unless $save_temps;

        # Link with the soft IP library 
        my $late_bc = acl::File::abs_path( acl::Env::sdk_root()."/share/lib/acl/acl_late.bc");
        $return_status = mysystem_full(
            {'time' => 1, 'time-label' => 'link (ip library)', 'stdout' => 'opt.log', 'stderr' => 'opt.err'},
            "$link_exe \"$base.lowered.bc\" $late_bc -o \"$base.linked.bc\"" );
        filter_llvm_time_passes('opt.err');
        append_to_log('opt.err', $iterationerr);
        move_to_log("!========== [link] ip library link ==========", 'opt.log', 'opt.err', $iterationlog);
        if ($return_status != 0) {
          move_to_log("", $iterationlog, $fulllog);
          move_to_err($iterationerr); 
          mydie("Optimizer FAILED.\nRefer to $base/$fulllog for details.\n");
        }
        remove_named_files("$base.lowered.bc") unless $save_temps;

        # Inline IP calls, simplify and clean up
        $return_status = mysystem_full(
            {'time' => 1, 'time-label' => 'opt (ip library optimize)', 'stdout' => 'opt.log', 'stderr' => 'opt.err'},
            "$opt_exe $llvm_board_option $llvm_efi_option $debug_option -always-inline -add-inline-tag -instcombine -adjust-sizes -dce -stripnk -area-print $opt_arg_after \"$base.linked.bc\" -o \"$base.bc\"");
        filter_llvm_time_passes('opt.err');
        append_to_log('opt.err', $iterationerr);
        move_to_log("!========== [opt] ip library optimize ==========", 'opt.log', 'opt.err', $iterationlog);
        if ($return_status != 0) {
          move_to_log("", $iterationlog, $fulllog);
          move_to_err($iterationerr); 
          mydie("Optimizer FAILED.\nRefer to $base/$fulllog for details.\n");
        }
        remove_named_files("$base.linked.bc") unless $save_temps;
      } else {
        # In normal flow, lower the acl kernel workgroup id last
        $return_status = mysystem_full(
            {'time' => 1, 'time-label' => 'opt (post-process)', 'stdout' => 'opt.log', 'stderr' => 'opt.err'},
            "$opt_exe $llvm_board_option $llvm_efi_option $debug_option -area-print \"$base.kwgid.bc\" -o \"$base.bc\"");
        filter_llvm_time_passes('opt.err');
        append_to_log('opt.err', $iterationerr);
        move_to_log("!========== [opt] post-process ==========", 'opt.log', 'opt.err', $iterationlog);
        if ($return_status != 0) {
          move_to_log("", $iterationlog, $fulllog);
          move_to_err($iterationerr); 
          mydie("Optimizer FAILED.\nRefer to $base/$fulllog for details.\n");
        }
        remove_named_files("$base.kwgid.bc") unless $save_temps;
      }
    }

    # Finish up opt-like steps.
    if ( $run_opt ) {
      if ( $disassemble || $soft_ip_c_flow ) { mysystem("llvm-dis \"$base.bc\" -o \"$base.ll\"" ) == 0 or mydie("Cannot disassemble: \"$base.bc\" \n"); }
      if ( $pkg_save_extra ) {
        $pkg->set_file('.acl.llvmir',"$base.bc")
           or mydie("Can't save optimized IR into package file: $acl::Pkg::error\n");
      }
      if ( $opt_only ) { return; }
    }

    if ( $run_verilog_gen ) {
      my $debug_option = ( $debug ? '-debug' : '');
      my $profile_option = ( $profile ? '-profile' : '');
      my $dseexplore = ( $use_ip_library_override ? '' : '-dseexplore=true');
      my $llc_option_macro = $griffin_flow ? ' -march=griffin ' : ' -march=fpga -mattr=option3wrapper -fpga-const-cache=1';

      # Run LLC
      $return_status = mysystem_full(
          {'time' => 1, 'time-label' => 'llc', 'stdout' => 'llc.log', 'stderr' => 'llc.err'},
          "$llc_exe $llc_option_macro $llvm_board_option $llvm_efi_option $llvm_profilerconf_option $debug_option $profile_option $dseexplore $llc_arg_after \"$base.bc\" -o \"$base.v\"");
      filter_llvm_time_passes('llc.err');
      append_to_log('llc.err', $iterationerr);

      if ( $griffin_flow ) {
        print "MK HACK: Dump llc.log and llc.err to screen for Griffin development.\n";
        print "llc.log:\n"; mysystem("cat llc.log");
        print "\nllc.err:\n"; mysystem("cat llc.err"); print "\n";
      }

      move_to_log("!========== [llc] ==========", 'llc.log', 'llc.err', $iterationlog);
      if ($return_status != 0) {
        move_to_log("", $iterationlog, $fulllog);
        move_to_err($iterationerr); 
        mydie("Verilog generator FAILED.\nRefer to $base/$fulllog for details.\n");
      }

      # If estimate >100% of block ram, rerun opt with lmem replication disabled
      # Don't back off like this if DSE is active.
      my $max_mem_percent_with_replication = 100;
      my $area_rpt_file_path = $verbatim_work_dir."/area.rpt";
      my $xml_file_path = $verbatim_work_dir."/$base.bc.xml";
      my $restart_without_lmem_replication = 0;
      if ( $dse == 0 ) {  # If DSE disabled
        if (-e $area_rpt_file_path) {
          open my $area_rpt_file, '<', $area_rpt_file_path or die $!;
          while ( <$area_rpt_file> ) {
            my $line = $_;
            if ( $line =~ m/RAMs:\s*(\d+).(\d+)\s\%/ ) {  # Triggered at most once
              if ( $1 > $max_mem_percent_with_replication && !$disabled_lmem_replication ) {

                # Check whether memory replication was activate
                my $repl_factor_active = 0;
                if (-e $xml_file_path) {
                  open my $xml_handle, '<', $xml_file_path or die $!;
                  while ( <$xml_handle> ) {
                    my $xml = $_;
                    if ( $xml =~ m/.*LOCAL_MEM.*repl_fac="(\d+)".*/ ) {
                      if ( $1 > 1 ) {
                        $repl_factor_active = 1;
                      }
                    }
                  }
                  close $xml_handle;
                }
                if ( $repl_factor_active ) {
                  print "$prog: Restarting compile without lmem replication because of estimated overutilization!\n" if $verbose;
                  $restart_without_lmem_replication = 1;
                }
              }
            }
          }
          close $area_rpt_file;
        } else {
          print "$prog: Cannot find area.rpt. Disabling lmem optimizations to be safe.\n";
          $restart_without_lmem_replication = 1;
        }
        if ( $restart_without_lmem_replication ) {
          $opt_arg_after .= $lmem_disable_replication_flag;
          $llc_arg_after .= $lmem_disable_replication_flag;
          $disabled_lmem_replication = 1;
          redo;  # Restart the compile loop as if this was a DSE iteration
        }
      }

      #DSE driver
      if (!$griffin_flow) {
        $design_area = acl::DSE::dse_driver($dse, $use_ip_library_override); 
      }

      # negative utilization triggers DSE restart
      if (($design_area->{util}) < 0) {
        $restart_acl = 1;
        mysystem("echo \"!========== [DSE: restarting] ==========\" >>$iterationlog");
      } elsif ($use_ip_library_override == 0) {
        # compile once again, with the ip_library on this time
        $restart_acl = 1;
        $use_ip_library_override = 1;
      }
    }
  } # End of while loop (DSE may restart the compiler)
  if (!$vfabric_flow) {
    move_to_log("",$iterationlog,$fulllog);
    move_to_err($iterationerr);
    remove_named_files($optinfile) unless $save_temps;
  }

  #Put after loop so we only store once
  if ( $pkg_save_extra ) { 
    $pkg->set_file('.acl.verilog',"$base.v")
      or mydie("Can't save Verilog into package file: $acl::Pkg::error\n");
  }  

  # Save the Optimization Report XML file in the aocx 
  if ( -e "opt.rpt.xml" ) {
    $pkg->add_file('.acl.opt.rpt.xml', "opt.rpt.xml")
      or mydie("Can't save opt.rpt.xml into package file: $acl::Pkg::error\n");
  }

  # Save Memory Architecture View JSON file 
  if ( -e "mav.json" ) {
    $pkg->add_file('.acl.mav.json', "mav.json")
      or mydie("Can't save mav.json into package file: $acl::Pkg::error\n");
  }

  # Save Area Report JSON file
  if ( -e "area.json" ) {
    $pkg->add_file('.acl.area.json', "area.json")
      or mydie("Can't save area.json into package file: $acl::Pkg::error\n");
  }

  # Save the profile XML file in the aocx
  if ( $profile ) {
    save_profiling_xml($pkg,$base);
  }

  # Move over the Optimization Report to the log file 
  if ( -e "opt.rpt" ) {
    append_to_log( "opt.rpt", $fulllog );
    unlink "opt.rpt" unless $save_temps;
  }

  unlink "report.out";
  if (( $estimate_throughput ) && ( !$accel_gen_flow ) && ( !$soft_ip_c_flow )) {
      print "Estimating throughput since \$estimate_throughput=$estimate_throughput\n";
    $return_status = mysystem_full(
        {'time' => 1, 'time-label' => 'opt (throughput)', 'stdout' => 'report.out', 'stderr' => 'report.err'},
        "$opt_exe -print-throughput -throughput-print $llvm_board_option $opt_arg_after \"$base.bc\" -o $base.unused" );
    filter_llvm_time_passes("report.err");
    move_to_err_and_log("Throughput analysis","report.err",$fulllog);
  } 
  unlink "$base.unused";

  # Guard probably depricated, if we get here we should have verilog, was only used by vfabric
  if ( $run_verilog_gen && !$vfabric_flow) { 
    open LOG, ">>report.out";
    printf(LOG "\n".
	   "+--------------------------------------------------------------------+\n".
	   "; Estimated Resource Usage Summary                                   ;\n".
	   "+----------------------------------------+---------------------------+\n".
	   "; Resource                               + Usage                     ;\n".
	   "+----------------------------------------+---------------------------+\n".
	   "; Logic utilization                      ; %4d\%                     ;\n".
	   "; Dedicated logic registers              ; %4d\%                     ;\n".
	   "; Memory blocks                          ; %4d\%                     ;\n".
	   "; DSP blocks                             ; %4d\%                     ;\n".
	   "+----------------------------------------+---------------------------;\n", 
	   $design_area->{util}, $design_area->{ffs}, $design_area->{rams}, $design_area->{dsps});
    close LOG;

    append_to_log ("report.out", $fulllog);
  }
  if ($report) {
    open LOG, "<report.out";
    print STDOUT <LOG>;
    close LOG;
  }
  unlink "report.out" unless $save_temps;

  if ($save_last_bc) {
    $pkg->set_file('.acl.profile_base',"$base.bc")
      or mydie("Can't save profiling base listing into package file: $acl::Pkg::error\n");
  }
  remove_named_files("$base.bc") unless $save_temps or $save_last_bc;

  my $xml_file = "$base.bc.xml";
  my $sysinteg_debug .= ($debug ? "-v" : "" );

  if ($vfabric_flow) {
    $xml_file = "virtual_fabric.bc.xml";
    $sysinteg_arg_after .= ' --vfabric ';
  }

  my $version = ::acl::Env::aocl_boardspec( ".", "version");
  my $generic_kernel = ::acl::Env::aocl_boardspec( ".", "generic_kernel");

  if ( $generic_kernel or ($version eq "0.9" and -e "base.qsf")) 
  {
    $return_status = mysystem_full(
        {'time' => 1, 'time-label' => 'system integrator', 'stdout' => 'si.log', 'stderr' => 'si.err'},
        "$sysinteg_exe $sysinteg_debug $sysinteg_arg_after $board_spec_xml \"$xml_file\" system.tcl kernel_system.tcl" );
  } else {
    $return_status = mysystem_full(
        {'time' => 1, 'time-label' => 'system integrator', 'stdout' => 'si.log', 'stderr' => 'si.err'},
        "$sysinteg_exe $sysinteg_debug $sysinteg_arg_after $board_spec_xml \"$xml_file\" system.tcl" );
  }
  move_to_log("!========== [SystemIntegrator] ==========", 'si.log', $fulllog);
  move_to_err_and_log("",'si.err', $fulllog);
  $return_status == 0 or mydie("System integrator FAILED.\nRefer to $base/$fulllog for details.\n");

  $pkg->set_file('.acl.autodiscovery',"sys_description.txt")
    or mydie("Can't save system description into package file: $acl::Pkg::error\n");

  if(-f "autodiscovery.xml") {
    $pkg->set_file('.acl.autodiscovery.xml',"autodiscovery.xml")
      or mydie("Can't save system description xml into package file: $acl::Pkg::error\n");    
  } else {
     print "Could not find autodiscovery xml\n"
  }  

  if(-f "board_spec.xml") {
    $pkg->set_file('.acl.board_spec.xml',"board_spec.xml")
      or mydie("Can't save boardspec.xml into package file: $acl::Pkg::error\n");    
  }else {
     print "Could not find board spec xml\n"
  } 

  print "$prog: First stage compilation completed successfully.\n" if $verbose;
  # Compute aoc runtime WITHOUT Quartus time or integration, since we don't control that
  my $stage1_end_time = time();
  log_time ("first compilation stage", $stage1_end_time - $stage1_start_time);

  if ( $verilog_gen_only || $accel_gen_flow ) { return; }

  &$finalize();
#aoc: Adding SEARCH_PATH assignment to /data/thoffner/trees/opencl/p4/regtest/opencl/aoc/aoc_flow/test/gurka/top.qsf

  my $file_name = "$base.aoco";
  if ( $output_file_arg ) {
      $file_name = $output_file_arg;
  }
  print "$prog: To compile this project, run \"$prog $file_name\"\n" if $verbose && $compile_step;
}

sub compile_design {
  my ($base,$verbatim_work_dir,$obj,$x_file,$board_variant) = @_;
  $fulllog = "$base.log"; #definition moved to global space
  my $pkgo_file = $obj; # Should have been created by first phase.
  my $pkg_file_final = $output_file || acl::File::abs_path("$base.aocx");
  $pkg_file = $pkg_file_final.".tmp";

  # OK, no turning back remove the result file, so no one thinks we succedded
  unlink $pkg_file_final;
  #Create the new direcory verbatim, then rewrite it to not contain spaces
  $work_dir = $verbatim_work_dir;
  $work_dir =~ s/ /\?/g;

  chdir $verbatim_work_dir or mydie("Can't change dir into $base: $!");

  # First, look in the pkg file to see if there were virtual fabric binaries
  # If there are, that means the previous compile was a vfabric run, and 
  # there is no hardware to build
  acl::File::copy( $pkgo_file, $pkg_file )
   or mydie("Can't copy binary package file $pkgo_file to $pkg_file: $acl::File::error");
  my $pkg = get acl::Pkg($pkg_file)
     or mydie("Can't find package file: $acl::Pkg::error\n");

  #Remember the reason we are here, can't query pkg_file after rename
  my $emulator = $pkg->exists_section('.acl.emulator_object.linux') ||
      $pkg->exists_section('.acl.emulator_object.windows');

  if ( ! $no_automigrate && ! $emulator) {
    acl::Board_migrate::migrate_platform_preqsys();
  }
  
  # Set version again, for informational purposes.
  # Do it again, because the second half flow is more authoritative
  # about the executable contents of the package file.
  save_pkg_section($pkg,'.acl.version',acl::Env::sdk_version());

  if (($pkg->exists_section('.acl.vfabric') && 
      $pkg->exists_section('.acl.fpga.bin')) ||
      $pkg->exists_section('.acl.emulator_object.linux') ||
     $pkg->exists_section('.acl.emulator_object.windows'))
  {
     unlink( $pkg_file_final ) if -f $pkg_file_final;
     rename( $pkg_file, $pkg_file_final )
       or mydie("Can't rename $pkg_file to $pkg_file_final: $!");

     if (!$emulator) {
         print "Rapid Prototyping flow is successful.\n" if $verbose;
     } else {
	 print "Emulator flow is successful.\n" if $verbose;
	 print "To execute emulated kernel, invoke host with \n\tenv CL_CONTEXT_EMULATOR_DEVICE_ALTERA=1 <host_program>\n For multi device emulations replace the 1 with the number of devices you which to emulate\n" if $verbose;

     }
     return;
  }

  # If we have the vfabric section, but not the bin section, then
  # we are doing a vfabric compile
  if ($pkg->exists_section('.acl.vfabric') && 
      !$pkg->exists_section('.acl.fpga.bin')) {
    $generate_vfabric = 1;
  }

  if ( ! $skip_qsys) { 

    #Ignore SOPC Builder's return value
    my $sopc_builder_cmd = $ENV{QUARTUS_ROOTDIR}."/sopc_builder/bin/qsys-script";
    my $ip_gen_cmd = $ENV{QUARTUS_ROOTDIR}."/sopc_builder/bin/ip-generate";

    # Run Java Runtime Engine with max heap size 512MB, and serial garbage collection.
    my $jre_tweaks = "-Xmx512M -XX:+UseSerialGC";

    open LOG, "<sopc.tmp";
    while (<LOG>) { print if / Error:/; }
    close LOG;

    my $version = ::acl::Env::aocl_boardspec( ".", "version");
    my $generic_kernel = ::acl::Env::aocl_boardspec( ".", "generic_kernel");
    my $qsys_file = ::acl::Env::aocl_boardspec( ".", "qsys_file");

    if ( $generic_kernel or ($version eq "0.9" and -e "base.qsf")) 
    {
      $return_status = mysystem_full(
        {'time' => 1, 'time-label' => 'sopc builder', 'stdout' => 'sopc.tmp', 'stderr' => '&STDOUT'},
        "$sopc_builder_cmd --script=kernel_system.tcl $jre_tweaks" );
      move_to_log("!=========Qsys kernel_system script===========", "sopc.tmp", $fulllog);
      $return_status == 0 or  mydie("Qsys-script FAILED.\nRefer to $base/$fulllog for details.\n");

      $return_status =mysystem_full(
        {'time' => 1, 'time-label' => 'sopc builder', 'stdout' => 'sopc.tmp', 'stderr' => '&STDOUT'},
        "$sopc_builder_cmd --script=system.tcl $jre_tweaks --system-file=$qsys_file" );
      move_to_log("!=========Qsys system script===========", "sopc.tmp", $fulllog);
      $return_status == 0 or  mydie("Qsys-script FAILED.\nRefer to $base/$fulllog for details.\n");
    } else {
      $return_status = mysystem_full(
        {'time' => 1, 'time-label' => 'sopc builder', 'stdout' => 'sopc.tmp', 'stderr' => '&STDOUT'},
        "$sopc_builder_cmd --script=system.tcl $jre_tweaks --system-file=$qsys_file" );
      move_to_log("!=========Qsys script===========", "sopc.tmp", $fulllog);
      $return_status == 0 or  mydie("Qsys-script FAILED.\nRefer to $base/$fulllog for details.\n");
    }

    if ($simulation_mode) {
      print "Qsys ip-generate (simulation mode) started!\n" ;      
      $return_status = mysystem_full( 
        {'time' => 1, 'time-label' => 'ip generate (simulation), ', 'stdout' => 'ipgen.tmp', 'stderr' => '&STDOUT'},
      "$ip_gen_cmd --component-file=$qsys_file --file-set=SIM_VERILOG --component-param=CALIBRATION_MODE=Skip  --output-directory=system/simulation --report-file=sip:system/simulation/system.sip --jvm-max-heap-size=3G" );                           
      print "Qsys ip-generate done!\n" ;            
    } else {      
      my $generate_cmd = ::acl::Env::aocl_boardspec( ".", "generate_cmd");
      $generate_cmd = process_board_cmd($generate_cmd);

      $return_status = mysystem_full( 
        {'time' => 1, 'time-label' => 'ip generate', 'stdout' => 'ipgen.tmp', 'stderr' => '&STDOUT'},
        "$generate_cmd" );  
    }

    open LOG, "<ipgen.tmp";
    while (<LOG>) { print if / Error:/; }
    close LOG;
    move_to_log("!=========ip-generate===========","ipgen.tmp",$fulllog);
    $return_status == 0 or mydie("ip-generate FAILED.\nRefer to $base/$fulllog for details.\n");

    # Some boards may post-process qsys output
    my $postqsys_script = acl::Env::board_post_qsys_script();
    if (defined $postqsys_script and $postqsys_script ne "") {
      mysystem( "$postqsys_script" ) == 0 or mydie("Couldn't run postqsys-script for the board!\n");
    }

  }

  # Override the fitter seed, if specified.
  if ( $fit_seed ) {
    my @designs = acl::File::simple_glob( "*.qsf" );
    $#designs > -1 or mydie ("Internal Compiler Error.\n");
    foreach (@designs) {
      my $qsf = $_;
      $return_status = mysystem( "echo set_global_assignment -name SEED $fit_seed >> $qsf" );
    }
  }

  if ( $ip_gen_only ) { return; }

  # "Old --hw" starting point
  my $project = ::acl::Env::aocl_boardspec( ".", "project");
  my $revision = ::acl::Env::aocl_boardspec( ".", "revision");
  my @designs = acl::File::simple_glob( "$project.qpf" );
  $#designs >= 0 or mydie ("Internal Compiler Error.\n");
  $#designs == 0 or mydie ("Internal Compiler Error.\n");
  my $design = shift @designs;

  my $synthesize_cmd = ::acl::Env::aocl_boardspec( ".", "synthesize_cmd");
  $synthesize_cmd = process_board_cmd($synthesize_cmd);

  my $retry = 0;
  my $MAX_RETRIES = 3;
  if ($high_effort) {
    print "High-effort hardware generation selected, compile time may increase signficantly.\n";
  }

  do {

    if (defined $ENV{ACL_QSH_COMPILE_CMD})
    {
      # Environment variable ACL_QSH_COMPILE_CMD can be used to replace default
      # quartus compile command (internal use only).  
      my $top = acl::File::mybasename($design); 
      $top =~ s/\.qpf//;
      my $custom_cmd = $ENV{ACL_QSH_COMPILE_CMD};
      $custom_cmd =~ s/PROJECT/$top/;
      $custom_cmd =~ s/REVISION/$top/;
      $return_status = mysystem_full(
        {'time' => 1, 'time-label' => 'Quartus compilation', 'stdout' => 'quartus_sh_compile.log'},
        $custom_cmd);
    } else {
      $return_status = mysystem_full(
        {'time' => 1, 'time-label' => 'Quartus compilation', 'stdout' => 'quartus_sh_compile.log', 'stderr' => 'quartuserr.tmp'},
        $synthesize_cmd);
    }

    if ( $return_status != 0 ) {
      if ($high_effort && hard_routing_error('quartus_sh_compile.log') && $retry < $MAX_RETRIES) {
        print " kernel fitting error encountered - retrying aocx compile.\n";
	$retry = $retry + 1;

        # Override the fitter seed, if specified.
        my @designs = acl::File::simple_glob( "*.qsf" );
        $#designs > -1 or print_quartus_errors('quartus_sh_compile.log', 0);
        my $seed = $retry * 10;
        foreach (@designs) {
          my $qsf = $_;
	  if ($retry > 1) {
	    # Remove the old seed setting
	    open( my $read_fh, "<", $qsf ) or mydie("Unexpected Compiler Error, not able to generate hardware in high effort mode.");
            my @file_lines = <$read_fh>; 
	    close( $read_fh ); 

	    open( my $write_fh, ">", $qsf ) or mydie("Unexpected Compiler Error, not able to generate hardware in high effort mode.");
	    foreach my $line ( @file_lines ) { 
	      print {$write_fh} $line unless ( $line =~ /set_global_assignment -name SEED/ ); 
	    } 
            print {$write_fh} "echo set_global_assignment -name SEED $seed\n";
	    close( $write_fh ); 
	  } else {
            $return_status = mysystem( "echo set_global_assignment -name SEED $seed >> $qsf" );
	  }
        }
      } else {
        $retry = 0;
        print_quartus_errors('quartus_sh_compile.log', $high_effort == 0);
      }
    } else {
      $retry = 0;
    }
  } while ($retry && $retry < $MAX_RETRIES);


  # check sta log for timing not met warnings
  print "$prog: Hardware generation completed successfully.\n" if $verbose;

  my $fpga_bin = 'fpga.bin';
  if ( -f $fpga_bin ) {
    $pkg->set_file('.acl.fpga.bin',$fpga_bin)
       or mydie("Can't save FPGA configuration file $fpga_bin into package file: $acl::Pkg::error\n");

    if ($generate_vfabric) { # need to save this to the board path
        my $acl_board_hw_path= get_acl_board_hw_path($board_variant);
        my $vfab_lib_path = (($custom_vfab_lib_path) ? $custom_vfab_lib_path : 
      				$acl_board_hw_path."_vfabric");
        my $num_templates_file = "$vfab_lib_path/num_templates.txt";
        my $dir_writeable = 1;
        my $var_id = 0;

        # create the directory if necessary
        if (!-f $num_templates_file) { 
           $dir_writeable = acl::File::make_path($vfab_lib_path);
           if ($dir_writeable) {
              $dir_writeable = open (VFAB_NUM_TMP_FILE, '>', $num_templates_file);
              if ($dir_writeable) {
                 print VFAB_NUM_TMP_FILE "$var_id\n";
                 close VFAB_NUM_TMP_FILE;
              }
           }
        } else { #templates file already exist: read variant number
          open VFAB_NUM_TMP_FILE, "<$num_templates_file" or mydie("Invalid template directory");
          $var_id = <VFAB_NUM_TMP_FILE>;
          chomp($var_id);
          close VFAB_NUM_TMP_FILE;
        }
        $var_id++;

        if (!$reuse_vfabrics && open (VFAB_NUM_TMP_FILE, '>', $num_templates_file)) {
          acl::File::copy( "vfab_var1.txt", $vfab_lib_path."/var".$var_id.".txt" )
            or mydie("Can't copy created template vfab_var1.txt to $vfab_lib_path/var$var_id.txt: $acl::File::error");
          acl::File::copy( $fpga_bin, $vfab_lib_path."/var".$var_id.".fpga.bin" )
            or mydie("Can't copy created template fpga.bin to $vfab_lib_path/var$var_id.fpga.bin: $acl::File::error");
          acl::File::copy( "acl_quartus_report.txt", $vfab_lib_path."/var".$var_id.".acl_quartus_report.txt" )
            or mydie("Can't copy created template acl_quartus_report.txt to $vfab_lib_path/var$var_id.acl_quartus_report.txt: $acl::File::error");
          if (! -f "$vfab_lib_path./sys_description.txt") {
             acl::File::copy( "sys_description.txt", $vfab_lib_path."/sys_description.txt" )
               or mydie("Can't copy sys_description.txt to $vfab_lib_path/sys_description.txt: $acl::File::error");
          }

          print "Successfully created Rapid Prototyping Template $var_id\n";

          save_vfabric_files_to_pkg($pkg, $var_id, $vfab_lib_path, ".");

	  # update the number of templates there are in the directory
          print VFAB_NUM_TMP_FILE $var_id;
          close VFAB_NUM_TMP_FILE;
        } else {
          print "Cannot save generated Rapid Prototyping Template to directory $vfab_lib_path. May not have write permissions.\n\n";
          print "To reuse this Template in a future kernel compile, please manually save the following files:\n";
          print " - vfab_var1.txt as $vfab_lib_path"."/var".$var_id.".txt\n";
          print " - fpga.bin as $vfab_lib_path"."/var".$var_id.".fpga.bin\n";
          print " - acl_quartus_report.txt as $vfab_lib_path"."/var".$var_id.".acl_quartus_report.txt\n";
          print " - sys_description.txt as $vfab_lib_path"."/sys_description.txt if missing\n";
          print "\nPlease increment ".$vfab_lib_path."/num_templates.txt to include this Template\n";
        }
    }

  } else { #If fpga.bin not found, package up sof and core.rbf

    # Save the SOF in the package file.
    my @sofs = (acl::File::simple_glob( "*.sof" ));
    if ( $#sofs < 0 ) {
      print "$prog: Warning: Could not find a FPGA programming (.sof) file\n";
    } else {
      if ( $#sofs > 0 ) {
        print "$prog: Warning: Found ".(1+$#sofs)." FPGA programming files. Using the first: $sofs[0]\n";
      }
      $pkg->set_file('.acl.sof',$sofs[0])
        or mydie("Can't save FPGA programming file into package file: $acl::Pkg::error\n");
    }
    # Save the RBF in the package file, if it exists.
    # Sort by name instead of leaving it random.
    # Besides, sorting will pick foo.core.rbf over foo.periph.rbf
    foreach my $rbf_type ( qw( core periph ) ) {
      my @rbfs = sort { $a cmp $b } (acl::File::simple_glob( "*.$rbf_type.rbf" ));
      if ( $#rbfs < 0 ) {
        #     print "$prog: Warning: Could not find a FPGA core programming (.rbf) file\n";
      } else {
        if ( $#rbfs > 0 ) {
          print "$prog: Warning: Found ".(1+$#rbfs)." FPGA $rbf_type.rbf programming files. Using the first: $rbfs[0]\n";
        }
        $pkg->set_file(".acl.$rbf_type.rbf",$rbfs[0])
          or mydie("Can't save FPGA $rbf_type.rbf programming file into package file: $acl::Pkg::error\n");
      }
    }
  }

  my $pll_config = 'pll_config.bin';
  if ( -f $pll_config ) {
    $pkg->set_file('.acl.pll_config',$pll_config)
       or mydie("Can't save FPGA clocking configuration file $pll_config into package file: $acl::Pkg::error\n");
  }

  my $acl_quartus_report = 'acl_quartus_report.txt';
  if ( -f $acl_quartus_report ) {
    $pkg->set_file('.acl.quartus_report',$acl_quartus_report)
       or mydie("Can't save Quartus report file $acl_quartus_report into package file: $acl::Pkg::error\n");
  }

  unlink( $pkg_file_final ) if -f $pkg_file_final;
  rename( $pkg_file, $pkg_file_final )
    or mydie("Can't rename $pkg_file to $pkg_file_final: $!");

  chdir $orig_dir or mydie("Can't change back into directory $orig_dir: $!");
  remove_intermediate_files($work_dir,$pkg_file_final) if $tidy;
}

# Some aoc args translate to args to many underlying exes.
sub process_meta_args {
  my ($cur_arg, $argv) = @_;
  my $processed = 0;
  if ($cur_arg eq '--1x-clock-for-local-mem') {
    # TEMPORARY: don't actually enforce this flag
    #$opt_arg_after .= ' -force-1x-clock-local-mem';
    #$llc_arg_after .= ' -force-1x-clock-local-mem';
    #$sysinteg_arg_after .= ' --cic-1x-local-mem';
    $processed = 1;
  }
  elsif ( ($cur_arg eq '--sw_dimm_partition') or ($cur_arg eq '--sw-dimm-partition')) {
    # TODO need to do this some other way
    # this flow is incompatible with the dynamic board selection (--board)
    # because it overrides the board setting
    $sysinteg_arg_after .= ' --cic-global_no_interleave ';
    $processed = 1;
  }

  return $processed;
}

sub process_board_cmd($@) {
  my ($fullcmd) = @_;
  chomp ($fullcmd);
  $fullcmd =~ s/^\s+//g;
  my @tokens = split(/\s+/m,$fullcmd);
  if ( scalar(@tokens) < 1 ) {
    return $fullcmd;
  }

  my $cmd = $tokens[0];

  # Use absolute paths to Quartus bin dir commands
  my $qcmd = acl::File::which("$ENV{QUARTUS_ROOTDIR}/$qbindir", $cmd );
  if ( defined($qcmd) ) {
    $tokens[0] = $qcmd;
  }

  # Use absolute paths to sopc commands - This is actually the IMPORTANT one
  # See FB:252506. The entry wrappers prepend the Quartus bin dir to PATH
  # before invoking aoc, however, the sopc_builder/bin path is not added.
  # Hence if this is a Qsys command, it's imperative we find it here!
  my $qsyscmd = acl::File::which("$ENV{QUARTUS_ROOTDIR}/sopc_builder/bin", $cmd );
  if ( defined($qsyscmd) ) {
    $tokens[0] = $qsyscmd;
  }

  return join( " ", @tokens);
}

# List installed boards.
sub list_boards {
  print "Board list:\n";

  my %boards = acl::Env::board_hw_list();
  if( keys( %boards ) == -1 ) {
    print "  none found\n";
  }
  else {
    for my $b ( sort keys %boards ) {
      my $boarddir = $boards{$b};
      print "  $b\n";
      if ( ::acl::Env::aocl_boardspec( $boarddir, "numglobalmems") > 1 ) {
        my $gmemnames = ::acl::Env::aocl_boardspec( $boarddir, "globalmemnames");
        print "     Memories: $gmemnames\n";
      }
      my $channames = ::acl::Env::aocl_boardspec( $boarddir, "channelnames");
      if ( length $channames > 0 ) {
        print "     Channels: $channames\n";
      }
      print "\n";
    }
  }
}


sub usage() {
  print <<USAGE;

aoc -- Altera SDK for OpenCL Kernel Compiler

Usage: aoc <options> <kernel>.[cl|aoco] 

Example:
       # First generate an <File>.aoco file
       aoc -c mykernels.cl
       # Now compile the project into a hardware programming file <File>.aocx.
       aoc mykernels.aoco
       # Or generate all at once
       aoc mykernels.cl

Outputs:
       <File>.aocx and/or <File>.aoco

Help Options:
--version
          Print out version infomation and exit

-v        
          Verbose mode. Report progress of compilation

--report  
          Print area estimates to screen after intial 
          compilation. The report is always written to the log file.

-h
--help    
          Show this message

Overall Options:
-c        
          Stop after generating a <File>.aoco

-o <file> 
          Use <file> as the name for the output

-march=emulator
          Create kernels that can be executed on x86

-g        
          Add debug data to kernels. Also, makes it possible to symbolically
          debug kernels created for the emulator on an x86 machine (Linux only).

--profile
          Enable profile support when generating aocx file. Note that
	  this does have a small performance penalty since profile
	  counters will be instantiated and take some some FPGA
	  resources.

-I <directory> 
          Add directory to header search path.

-D <name> 
          Define macro, as name=value or just name.

-W        
          Suppress warning.

-Werror   
          Make all warnings into errors.

--big-endian  Generate FPGA hardware for a system in which the host
          and global memories are big-endian.  If not specified,
          little endian ordering is assumed.  Specify this option when
          compiling a device program for use in an IBM Power environment.

Modifiers:
--board <board name>
          Compile for the specified board. Default is pcie385n_a7.

--list-boards
          Print a list of available boards and exit.

Optimization Control:

--no-interleaving <global memory name>
          Configure a global memory as separate address spaces for each
          DIMM/bank.  User should then use the Altera specific cl_mem_flags
          (E.g.  CL_MEM_BANK_2_ALTERA) to allocate each buffer in one DIMM or
          the other. The argument 'default' can be used to configure the default
          global memory. Consult your board's documentation for the memory types
          available. See the Best Practices Guide for more details.

--const-cache-bytes <N>
          Configure the constant cache size (rounded up to closest 2^n).
	  If none of the kernels use the __constant address space, this 
	  argument has no effect. 

--fp-relaxed
          Allow the compiler to relax the order of arithmetic operations,
          possibly affecting the precision

--fpc 
          Removes intermediary roundings and conversions when possible, 
          and changes the rounding mode to round towards zero for 
          multiplies and adds

--high-effort
          Increases aocx compile effort to improve ability to fit
	  kernel on the device.

-cl-single-precision-constant
-cl-denorms-are-zero
-cl-opt-disable
-cl-strict-aliasing
-cl-mad-enable
-cl-no-signed-zeros
-cl-unsafe-math-optimizations
-cl-finite-math-only
-cl-fast-relaxed-math
           OpenCL required options. See OpenCL specification for details


USAGE
#--initial-dir <dir>
#          Run the parser from the given directory.  
#          The default is to run the parser in the current directory.

#          Use this option to properly resolve relative include 
#          directories when running the compiler in a directory other
#          than where the source file may be found.
#--save-extra
#          Save kernel program source, optimized intermediate representation,
#          and Verilog into the program package file.
#          By default, these items are not saved.
#
#--no-env-check
#          Skip environment checks at startup.
#          Use this option to save a few seconds of runtime if you 
#          already know the environment is set up to run the Altera SDK
#          for OpenCL compiler.
#--dot
#          Dump out DOT graph of the kernel pipeline.

}

sub version($) {
  my $outfile = $_[0];
  print $outfile "Altera SDK for OpenCL, 64-Bit Offline Compiler\n";
  print $outfile "Version 15.0.0 Build 120\n";
  print $outfile "Copyright (C) 2015 Altera Corporation\n";
}

sub main {
  my @args = (); # regular args.
  @user_opencl_args = ();
  my $atleastoneflag=0;
  my $dirbase=undef;
  my $board_variant=undef;
  while ( $#ARGV >= 0 ) {
    my $arg = shift @ARGV;
    if ( ($arg eq '-h') or ($arg eq '--help') ) { usage(); exit 0; }
    elsif ( ($arg eq '--version') or ($arg eq '-V') ) { version(\*STDOUT); exit 0; }
    elsif ( ($arg eq '-v') ) { $verbose += 1; if ($verbose > 1) {$prog = "#$prog";} }
    elsif ( ($arg eq '--hw') ) { $run_quartus = 1;}
    elsif ( ($arg eq '--quartus') ) { $skip_qsys = 1; $run_quartus = 1;}
    elsif ( ($arg eq '-d') ) { $debug = 1;}
    elsif ( ($arg eq '-s') ) {$simulation_mode = 1; $ip_gen_only = 1; $atleastoneflag = 1;}       
    elsif ( ($arg eq '--high-effort') ) { $high_effort = 1; }       
    elsif ( ($arg eq '--report') ) { $report = 1; }
    elsif ( ($arg eq '-g') ) {  
      $dash_g = 1;
    }
    elsif ( ($arg eq '--profile') ) {
      $profile = 1;
      $save_last_bc=1
    }
    elsif ( ($arg eq '--save-extra') ) { $pkg_save_extra = 1; }
    elsif ( ($arg eq '--no-env-check') ) { $do_env_check = 0; }
    elsif ( ($arg eq '--no-auto-migrate') ) { $no_automigrate = 1;}
    elsif ( ($arg eq '--initial-dir') ) {
      $#ARGV >= 0 or mydie("Option --initial-dir requires an argument");
      $force_initial_dir = shift @ARGV;
    }
    elsif ( ($arg eq '-o') ) {
      # Absorb -o argument, and don't pass it down to Clang
      $#ARGV >= 0 or mydie("Option $arg requires a file argument.");
      $output_file = shift @ARGV;
      $output_file_arg = $output_file;
    }
    elsif ( ($arg eq '--hash') ) {
      $#ARGV >= 0 or mydie("Option --hash requires an argument");
      $program_hash = shift @ARGV;
    }
    elsif ( ($arg eq '--clang-arg') ) {
      $#ARGV >= 0 or mydie("Option --clang-arg requires an argument");
      # Just push onto @args!
      push @args, shift @ARGV;
    }
    elsif ( ($arg eq '--opt-arg') ) {
      $#ARGV >= 0 or mydie("Option --opt-arg requires an argument");
      $opt_arg_after .= " ".(shift @ARGV);
    }
    elsif( ($arg eq '--one-pass') ) {
      $#ARGV >= 0 or mydie("Option --one-pass requires an argument");
      $dft_opt_passes = " ".(shift @ARGV);
      $opt_only = 1;
    }
    elsif ( ($arg eq '--llc-arg') ) {
      $#ARGV >= 0 or mydie("Option --llc-arg requires an argument");
      $llc_arg_after .= " ".(shift @ARGV);
    }
    elsif ( ($arg eq '--optllc-arg') ) {
      $#ARGV >= 0 or mydie("Option --optllc-arg requires an argument");
      my $optllc_arg = (shift @ARGV);
      $opt_arg_after .= " ".$optllc_arg;
      $llc_arg_after .= " ".$optllc_arg;
    }
    elsif ( ($arg eq '--sysinteg-arg') ) {
      $#ARGV >= 0 or mydie("Option --sysinteg-arg requires an argument");
      $sysinteg_arg_after .= " ".(shift @ARGV);
    }
    elsif ( ($arg eq '--c-acceleration') ) { $c_acceleration = 1; }
    elsif ( ($arg eq '--parse-only') ) { $parse_only = 1; $atleastoneflag = 1; }
    elsif ( ($arg eq '--opt-only') ) { $opt_only = 1; $atleastoneflag = 1; }
    elsif ( ($arg eq '--v-only') ) { $verilog_gen_only = 1; $atleastoneflag = 1; }
    elsif ( ($arg eq '--ip-only') ) { $ip_gen_only = 1; $atleastoneflag = 1; }
    elsif ( ($arg eq '--dump-csr') ) {
      $llc_arg_after .= ' -csr';
    }
    elsif ( ($arg eq '--skip-qsys') ) { $skip_qsys = 1; $atleastoneflag = 1; }
    elsif ( ($arg eq '-c') ) { $compile_step = 1; $atleastoneflag = 1; } # dummy to support -c flow 
    elsif ( ($arg eq '--dis') ) { $disassemble = 1; }
    elsif ( ($arg eq '--tidy') ) { $tidy = 1; }
    elsif ( ($arg eq '--save-temps') ) { $save_temps = 1; }
    elsif ( ($arg eq '--use-ip-library') ) { $use_ip_library = 1; }
    elsif ( ($arg eq '--no-link-ip-library') ) { $use_ip_library = 0; }
    elsif ( ($arg eq '--regtest_mode') ) { $regtest_mode = 1; }
    elsif ( ($arg eq '--fmax') ) {
      $opt_arg_after .= ' -scheduler-fmax=';
      $llc_arg_after .= ' -scheduler-fmax=';
      my $fmax_constraint = (shift @ARGV);
      $opt_arg_after .= $fmax_constraint;
      $llc_arg_after .= $fmax_constraint;
    }
    elsif ( ($arg eq '--seed') ) {
      $#ARGV >= 0 or mydie("Option --seed requires an argument");
      $fit_seed = (shift @ARGV);
    }
    elsif ( ($arg eq '-O3') ) {
      # -O3 enables design space exploration targetting 85% device utilization
      # allow the user to override the dse percentage through the --util option
      if ($dse == 0) {
         $dse = 85;
         $use_ip_library_override = 0; # Soft IP library is off until DSE identifies a suitable configuration
      }
    }
    elsif ( ($arg eq '--util') ) {
      $dse = shift @ARGV; 
      if ((int($dse * 1) ne $dse) || $dse <= 0) {
         mydie("Option --util requires an integer value larger than 0");
      }
      $use_ip_library_override = 0; # Soft IP library is off until DSE identifies a suitable configuration
    }
    elsif ( ($arg eq '--no-lms') ) {
      $opt_arg_after .= " ".$lmem_disable_split_flag;
    }
    # temporary fix to match broke documentation
    elsif ( ($arg eq '--fp-relaxed') ) {
      $opt_arg_after .= " -fp-relaxed=true";
    }
    # enable sharing flow
    elsif ( ($arg eq '-Os') ) {
       $opt_arg_after .= ' -opt-area=true';
       $llc_arg_after .= ' -opt-area=true';
    }
    # temporary fix to match broke documentation
    elsif ( ($arg eq '--fpc') ) {
      $opt_arg_after .= " -fpc=true";
    }
    elsif ($arg eq '--const-cache-bytes') {
      $sysinteg_arg_after .= ' --cic-const-cache-bytes ';
      $opt_arg_after .= ' --cic-const-cache-bytes=';
      $#ARGV >= 0 or mydie("Option --const-cache-bytes requires an argument");
      my $const_cache_size = (shift @ARGV);
      my $actual_const_cache_size = 16384;
      while ($actual_const_cache_size < $const_cache_size ) {
        $actual_const_cache_size = $actual_const_cache_size * 2;
      }
      $sysinteg_arg_after .= " ".$actual_const_cache_size;
      $opt_arg_after .= $actual_const_cache_size;
    }
    elsif ($arg eq '--board') {
      ($board_variant) = (shift @ARGV);
    }
    elsif ($arg eq '--efi-spec') {
      $#ARGV >= 0 or mydie("Option --efi-spec requires a path/filename");
      !defined $efispec_file or mydie("Too many EFI Spec files provided\n");
      $efispec_file = (shift @ARGV);
    }
    elsif ($arg eq '--profile-config') {
      $#ARGV >= 0 or mydie("Option --profile-config requires a path/filename");
      !defined $profilerconf_file or mydie("Too many profiler config files provided\n");
      $profilerconf_file = (shift @ARGV);
    }
    elsif ($arg eq '--list-boards') {
      list_boards();
      exit 0;
    }
    elsif ($arg eq '--vfabric' || $arg eq '-march=prototype') {
      $vfabric_flow = 1;
    }
    elsif ($arg eq '--grif') {
      $griffin_flow = 1;
    }
    elsif ($arg eq '--create-template') {
      $generate_vfabric = 1;
    }
    elsif ($arg eq '--reuse-existing-templates') {
      $reuse_vfabrics = 1;
    }
    elsif ($arg eq '--template-seed') {
      $#ARGV >= 0 or mydie("Option --template-seed requires an argument");
      $vfabric_seed = (shift @ARGV);
    }
    elsif ($arg eq '--template-library-path') {
      $#ARGV >= 0 or mydie("Option --template-library-path requires an argument");
      $custom_vfab_lib_path = (shift @ARGV);
    }
    elsif ($arg eq '--ggdb' || $arg eq '-march=emulator' ) {
      $emulator_flow = 1;
      if ($arg eq '--ggdb') {
	  $dash_g = 1;
      }
    }
    elsif ($arg eq '--soft-ip-c') {
      $#ARGV >= 0 or mydie("Option --soft-ip-c requires a function name");
      $soft_ip_c_name = (shift @ARGV);
      $soft_ip_c_flow = 1;
      $verilog_gen_only = 1;
      $dotfiles = 1;
    }
    elsif ($arg eq '--accel') {
      $#ARGV >= 0 or mydie("Option --accel requires a function name");
      $accel_name = (shift @ARGV);
      $accel_gen_flow = 1;
      $llc_arg_after .= ' -csr';
      $compile_step = 1;
      $atleastoneflag = 1;
      $sysinteg_arg_after .= ' --no-opencl-system';
    }
    elsif ($arg eq '--device-spec') {
      $#ARGV >= 0 or mydie("Option --device-spec requires a path/filename");
      $device_spec = (shift @ARGV);
    }
    elsif ($arg eq '--dot') {
      $dotfiles = 1;
    }
    elsif ($arg eq '--time') {
      if($#ARGV >= 0 && $ARGV[0] !~ m/^-./) {
        $time_log = shift(@ARGV);
      }
      else {
        $time_log = "-"; # Default to stdout.
      }
    }
    elsif ($arg eq '--time-passes') {
      $time_passes = 1;
      $opt_arg_after .= ' --time-passes';
      $llc_arg_after .= ' --time-passes';
      if(!$time_log) {
        $time_log = "-"; # Default to stdout.
      }
    }
    # Temporary test flag to enable Unified Netlist flow.
    elsif ($arg eq '--un') {
      $opt_arg_after .= ' --un-flow';
      $llc_arg_after .= ' --un-flow';
    }
    elsif ($arg eq '--no-interleaving')  {
      $#ARGV >= 0 or mydie("Option --no-interleaving requires a memory name or 'default'");
      if($ARGV[0] ne 'default' ) {
        $sysinteg_arg_after .= ' --no-interleaving '.(shift @ARGV);
      }
      else {
        #non-heterogeneous sw-dimm-partition behaviour
        #this will target the default memory
        shift(@ARGV);
        $sysinteg_arg_after .= ' --cic-global_no_interleave ';
      }
    }   
    elsif ($arg eq '--global-tree')  {
       $sysinteg_arg_after .= ' --global-tree';
    } 
    elsif ($arg eq '--duplicate-ring')  {
       $sysinteg_arg_after .= ' --duplicate-ring';
    } 
    elsif ($arg eq '--num-reorder')  {
       $sysinteg_arg_after .= ' --num-reorder '.(shift @ARGV);
    } 
    elsif ( process_meta_args ($arg, \@ARGV) ) { }
    elsif ( $arg =~ m/\.cl$|\.c$|\.aoco/ ) {
      !defined $input_file or mydie("Too many input files provided: $input_file and $arg\n");
      $input_file=$arg;
    }
    elsif ( $arg eq '--big-endian'){ 
      $big_endian = 1;
      $sysinteg_arg_after .= ' --big-endian';
    } else { push @args, $arg }
  }

  # Propagate -g to clang, opt, and llc
  if ($dash_g || $profile) {
      if($emulator_flow && ($emulator_arch eq 'windows64')){
	print "$prog: Debug symbols are not supported in emulation mode on Windows, ignoring -g.\n";
      } else {
	push @args, '-g';
      } 
    $opt_arg_after .= ' -dbg-info-enabled';
    $llc_arg_after.= ' -dbg-info-enabled';
  }

  # if no board variant was given by the --board option fall back to the default board
  if (!defined $board_variant) {
    ($board_variant) = acl::Env::board_hardware_default();
  }
  # treat EmulatorDevice as undefined so we get a valid board 
  if ($board_variant eq $emulatorDevice ) {
    ($board_variant) = acl::Env::board_hardware_default();
  }

  @user_clang_args = @args;
  push @user_opencl_args, @user_clang_args;

  if ($regtest_mode){
      $dotfiles = 1;
      $save_temps = 1;
      $report = 1;
      $sysinteg_arg_after .= ' --regtest_mode ';
  }

  if ($dotfiles) {
    $opt_arg_after .= ' --dump-dot ';
    $llc_arg_after .= ' --dump-dot '; 
    $sysinteg_arg_after .= ' --dump-dot ';
  }

  $orig_dir = acl::File::abs_path('.');
  $force_initial_dir = acl::File::abs_path( $force_initial_dir || '.' );

  my $base = acl::File::mybasename($input_file);
  my $suffix = $base;
  $suffix =~ s/.*\.//;
  $base=~ s/\.$suffix//;
  $base =~ s/[^a-z0-9_]/_/ig;

  if ( $suffix =~ m/^c$/ and !($soft_ip_c_flow || $c_acceleration)) {
      # Pretend we never saw it i.e. issue the same message as we would for 
      # other not recognized extensions. Not the clearest message, 
      # but at least consistent
      mydie("Error: No recognized input file format on the command line");
  }
  if ( $suffix =~ m/^cl$|^c$/ ) {
    $srcfile = $input_file;
    $objfile = $base.".aoco";
    $x_file = $base.".aocx";
    $dirbase = $base;
  } elsif ( $suffix =~ m/^aoco$/ ) {
    $run_quartus = 1;
    $srcfile = undef;
    $objfile = $base.".aoco";
    $x_file = $base.".aocx";
    $dirbase = $base;
  } else {
    mydie("No recognized input file format on the command line");
  }    

  # Process $time_log. If defined, then treat it as a file name 
  # (including "-", which is stdout).
  if ($time_log) {
    my $fh;
    if ($time_log ne "-") {
      # If this is an initial run, clobber time_log, otherwise append to it.
      if (not $run_quartus) {
        open ($fh, '>', $time_log) or mydie ("Couldn't open $time_log for time output.");
      } else {
        open ($fh, '>>', $time_log) or mydie ("Couldn't open $time_log for time output.");
      }
    }
    else {
      # Use STDOUT.
      open ($fh, '>&', \*STDOUT) or mydie ("Couldn't open stdout for time output.");
    }

    # From this forward forward, $time_log is now a file handle!
    $time_log = $fh;
  }

  if ( $output_file ) {
    my $outsuffix = $output_file;
    $outsuffix =~ s/.*\.//;
    my $outbase = $output_file;
    $outbase =~ s/\.$outsuffix//;
    $outbase =~ s/[^a-z0-9_]/_/ig;
    if ($outsuffix eq "aoco") {
      ($run_quartus == 0 && $compile_step != 0) or mydie("Option -o argument must be a filename ending in .aocx when used to name final output"); 
      $objfile = $outbase.".".$outsuffix;
      $dirbase = $outbase;
      $x_file = undef;
    } elsif ($outsuffix eq "aocx") {
      $compile_step == 0 or mydie("Option -o argument must be a filename ending in .aoco when used with -c");  
      # There are two scenarios where aocx can be used:
      # 1. Input is a AOCO
      # 2. Input is a source file
      #
      # If the input is a AOCO, then $objfile and $dirbase is already set correctly.
      # If the input is a source file, set $objfile and $dirbase based on the AOCX name.
      if ($suffix ne "aoco") {
        $objfile = "$outbase.aoco";
        $dirbase = $outbase;
      }
      $x_file = $output_file;
    } elsif ($compile_step == 0) {
      mydie("Option -o argument must be a filename ending in .aocx when used to name final output");
    } else {
      mydie("Option -o argument must be a filename ending in .aoco when used with -c");
    }
    $output_file = acl::File::abs_path( $output_file );
  }
  $objfile = acl::File::abs_path( $objfile );
  $x_file = acl::File::abs_path( $x_file );

  if ($srcfile){ # not necesaarily set for "aoc file.aoco" 
    chdir $force_initial_dir or mydie("Can't change into dir $force_initial_dir: $!\n");
    -f $srcfile or mydie("Invalid kernel file $srcfile: $!");
    $absolute_srcfile = acl::File::abs_path($srcfile);
    -f $absolute_srcfile or mydie("Internal error. Can't determine absolute path for $srcfile");
    chdir $orig_dir or mydie("Can't change into dir $orig_dir: $!\n");
  }

  # get the absolute path for the EFI Spec file
  if(defined $efispec_file) {
      chdir $force_initial_dir or mydie("Can't change into dir $force_initial_dir: $!\n");
      -f $efispec_file or mydie("Invalid EFI Spec file $efispec_file: $!");
      $absolute_efispec_file = acl::File::abs_path($efispec_file);
      -f $absolute_efispec_file or mydie("Internal error. Can't determine absolute path for $efispec_file");
      chdir $orig_dir or mydie("Can't change into dir $orig_dir: $!\n");
  }

  # get the absolute path for the Profiler Config file
  if(defined $profilerconf_file) {
      chdir $force_initial_dir or mydie("Can't change into dir $force_initial_dir: $!\n");
      -f $profilerconf_file or mydie("Invalid profiler config file $profilerconf_file: $!");
      $absolute_profilerconf_file = acl::File::abs_path($profilerconf_file);
      -f $absolute_profilerconf_file or mydie("Internal error. Can't determine absolute path for $profilerconf_file");
      chdir $orig_dir or mydie("Can't change into dir $orig_dir: $!\n");
  }

  # Can't do multiple flows at the same time
  if ($soft_ip_c_flow + $compile_step + $run_quartus >1) {
      mydie("Cannot have more than one of -c, --soft-ip-c --hw on the command line,\n cannot combine -c with *.aoco either\n");
  }
  #check for compatibility for --big-endian argument
  if($big_endian == 1 && $vfabric_flow == 1){
    mydie("The virtual fabric flow does not support big endian targets.");
  }
  if($soft_ip_c_flow == 1 && $big_endian == 1){
    mydie("big_endian does not support soft ip c flow.");
  }
  if($accel_gen_flow == 1 && $big_endian == 1){
    mydie("big_endian does not support C acceleration.");
  }
  if($emulator_flow == 1 && $big_endian == 1){
    mydie("big_endian does not support debugging/emulation.");
  }

  # Griffin exclusion until we add further support
  # Some of these (like emulator) should probably be relaxed, even today
  if($griffin_flow == 1 && $big_endian == 1){
    mydie("Griffin flow not compatible with big-endian target");
  }
  if($griffin_flow == 1 && $vfabric_flow == 1){
    mydie("Griffin flow not compatible with virtual fabric target");
  }
  if($griffin_flow == 1 && $soft_ip_c_flow == 1){
    mydie("Griffin flow not compatible with soft-ip flow");
  }
  if($griffin_flow == 1 && $accel_gen_flow == 1){
    mydie("Griffin flow not compatible with C acceleration");
  }
  if($griffin_flow == 1 && $emulator_flow == 1){
    mydie("Griffin flow not compatible with emulator flow");
  }

  # Check that this a valid board directory by checking for a board_spec.xml 
  # file in the board directory.
  if (not $run_quartus) {
    my $board_xml = get_acl_board_hw_path($board_variant)."/board_spec.xml";
    if (!-f $board_xml) {
      print "Board '$board_variant' not found.\n";
      my $board_path = acl::Board_env::get_board_path();
      print "Searched in the board package at: \n  $board_path\n";
      list_boards();
      print "If you are using a 3rd party board, please ensure:\n";
      print "  1) The board package is installed (contact your 3rd party vendor)\n";
      print "  2) You have set the environment variable 'AOCL_BOARD_PACKAGE_ROOT'\n";
      print "     to the path to your board package installation\n";
      mydie("No board_spec.xml found for board '$board_variant' (Searched for: $board_xml).");
    }
  }

  $verbatim_work_dir = acl::File::abs_path("./$dirbase");

  check_env() if $do_env_check;

  if (not $run_quartus) {
    if(!$atleastoneflag && $verbose) {
      print "You are now compiling the full flow!!\n";
    }
    create_system ($base, $verbatim_work_dir, $srcfile, $objfile, $board_variant);
  }
  if (not ($compile_step|| $parse_only || $opt_only || $verilog_gen_only)) {
    compile_design ($base, $verbatim_work_dir, $objfile, $x_file, $board_variant);
  }

  if ($time_log) {
    close ($time_log);
  }
}

main();
exit 0;
# vim: set ts=2 sw=2 expandtab
