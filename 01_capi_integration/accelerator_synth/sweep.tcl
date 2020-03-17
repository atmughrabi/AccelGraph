#!/usr/bin/tclsh
# By Boon Seong https://almost-a-technocrat.blogspot.com/2013/07/run-quartus-ii-fitter-and-timequest_3.html
# This tcl is used to sweep seed by running fitter and STA, the timing report will be stored in seed_rpt directory
load_package flow
load_package report
# Specify project name and revision name
set PROJECT accel-graph


set PART 5SGXMA7H2F35C2
set FAMILY StratixV
set LIBCAPI  ./capi
set VERSION   [binary format A24 [exec ${LIBCAPI}/scripts/version.py]]
set project_revision accel-graph
set INPUT_SOF ${PROJECT}.sof

# Set seeds
# set seedList { 2 3 5 7 11 12 13 14 17 19 23 29 31 37 41 43 }
set seedList { 12 13 14 17 19 23 29 31 37 41 43 }
# set seedList { 2 }

set timetrynum [llength $seedList]
puts "Total compiles: $timetrynum"
project_open -revision ${project_revision} ${PROJECT}

# Specify seed compile report directory
set rptdir seed_rpt
file mkdir $rptdir
set trynum 0
while { $timetrynum > $trynum } {
	set CURRENTSEED [lindex $seedList $trynum]
	set TIMESTAMP [exec "date" "+%Y_%m_%d_%H_%M_%S"]
	set OUTPUT_RBF ${PROJECT}_${CURRENTSEED}.rbf
	set outdir $rptdir/output_seed${CURRENTSEED}
	file mkdir $outdir

	set_global_assignment -name SEED ${CURRENTSEED}
# # Place & Route
if {[catch {execute_module -tool fit -args "--64bit --part=${PART}"} result]} {
	puts "\nResult: $result\n"
	puts "ERROR: Quartus II Fitter failed. See the report file.\n"
	qexit -error
	} else {
		puts "\nInfo: Quartus II Fitter was successful.\n"
	}
# # Timing Analyzer
if {[catch {execute_module -tool sta -args "--64bit --do_report_timing"} result]} {
	puts "\nResult: $result\n"
	puts "ERROR: TimeQuest Analyzer failed. See the report file.\n"
	qexit -error
	} else {
		puts "\nInfo: TimeQuest Analyzer was successful.\n"
	}
# # Assembler
if {[catch {execute_module -tool asm -args "--64bit"} result]} {
	puts "\nResult: $result\n"
	puts "ERROR: Assembler failed. See the report file.\n"
	qexit -error
	} else {
		puts "\nInfo: Assembler was successful.\n"
	}
# rbf generation
if {[catch {execute_module -tool cpf -args "--64bit -c ${INPUT_SOF} ${OUTPUT_RBF}"} result]} {
	puts "\nResult: $result\n"
	puts "ERROR: rbf gen failed. See the report file.\n"
	qexit -error
	} else {

		file copy -force ./${INPUT_SOF} $outdir/${INPUT_SOF}
		file copy -force ./${OUTPUT_RBF} $outdir/${OUTPUT_RBF}
		file delete -force ./${INPUT_SOF}
		file delete -force ./${OUTPUT_RBF}
		puts "\nInfo: rbf gen was successful.\n"
	}
# Store compile results
file copy -force ./${project_revision}.fit.summary $outdir/${PROJECT}.fit.summary
file copy -force ./${project_revision}.sta.rpt $outdir/${PROJECT}.sta.rpt
file copy -force ./${project_revision}.sta.summary $outdir/${PROJECT}.sta.summary

	incr trynum
}



project_close