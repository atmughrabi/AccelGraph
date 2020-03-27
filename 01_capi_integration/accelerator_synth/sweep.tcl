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

if { $argc != 5 } {
	puts "SET Project to DEFAULT"
	set graph_algorithm "cu_PageRank"
	set data_structure 	"CSR"
	set direction 		"PULL"
	set cu_precision 	"FloatPoint"
	set cu_count  	 	"20"
} else {
	puts "SET Project to ARGV"
	set graph_algorithm "[lindex $argv 0]"
	set data_structure 	"[lindex $argv 1]"
	set direction 		"[lindex $argv 2]"
	set cu_precision 	"[lindex $argv 3]"
	set cu_count 		"[lindex $argv 4]"
}

puts "Algorithm $graph_algorithm"
puts "Datastructure $data_structure"
puts "Direction $direction"
puts "Precision $cu_precision"
puts "CU Count  $cu_count"

# Set seeds
set seedList { 16 1 2 5 7 3 11 12 13 14 15 17 41 30 18 19 20 21 23 25 29 31 32 33 34 37 39 43 45 47 49 51 53 55 6 9 }
# set seedList { 12 13 14 15 16 30 1 7 17 18 19 20 21 23 25 29 6 9 }
# set seedList { 31 32 33 34 37 39 41 43 45 47 49 51 53 55 2 3 5 11 }
# set seedList { 30 }

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
	set OUTPUT_RBF ${graph_algorithm}_${data_structure}_${direction}_${cu_precision}_CU${cu_count}_SEED${CURRENTSEED}.rbf
	set outdir $rptdir/${graph_algorithm}_${data_structure}_${direction}_${cu_precision}_CU${cu_count}_SEED${CURRENTSEED}
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
# # Power Analyzer
if {[catch {execute_module -tool pow -args "--64bit"} result]} {
	puts "\nResult: $result\n"
	puts "ERROR: Power Analyzer failed. See the report file.\n"
	qexit -error
	} else {
		puts "\nInfo: Power Analyzer was successful.\n"
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
file copy -force ./${project_revision}.fit.rpt $outdir/${PROJECT}.fit.rpt
file copy -force ./${project_revision}.fit.summary $outdir/${PROJECT}.fit.summary
file copy -force ./${project_revision}.sta.rpt $outdir/${PROJECT}.sta.rpt
file copy -force ./${project_revision}.sta.summary $outdir/${PROJECT}.sta.summary
file copy -force ./${project_revision}.pow.summary $outdir/${PROJECT}.pow.summary

	incr trynum
}



project_close