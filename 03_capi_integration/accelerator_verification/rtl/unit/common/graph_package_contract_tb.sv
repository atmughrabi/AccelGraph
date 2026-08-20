// -----------------------------------------------------------------------------
//      AccelGraph RTL unit test - graph package contracts
// -----------------------------------------------------------------------------
// Declarations under test : WED_PKG, GLOBALS_CU_PKG, CU_PKG
// Oracle                  : graph-wed-csr-byte-layout-v1
//
// The oracle is byte based. The work element descriptor is built as 128 host
// bytes, every mapped field is recomputed with an independent byte reversal,
// and the expected field offsets come from the packed C structure WEDGraphCSR
// in 02_capi_graph/include/capi_utils/capienv.h, so the SystemVerilog and C
// views of the descriptor cannot drift apart silently.
// -----------------------------------------------------------------------------

import GLOBALS_AFU_PKG::*;
import CAPI_PKG::*;
import WED_PKG::*;
import GLOBALS_CU_PKG::*;
import CU_PKG::*;

module graph_package_contract_tb;
	`include "graph_common_harness.svh"
	`include "graph_common_context.svh"

	localparam int CACHELINE_BYTES = CACHELINE_SIZE_BITS / 8;

	logic [0:CACHELINE_SIZE_BITS-1] cacheline            ;
	logic [                    0:7] cacheline_bytes[0:127];
	string                          pattern_name         ;
	int unsigned                    cycles               ;

	// -------------------------------------------------------------------------
	// Independent byte model
	// -------------------------------------------------------------------------
	function automatic void build_cacheline(input int kind);
		for (int index = 0; index < CACHELINE_BYTES; index++) begin
			case (kind)
				0      : cacheline_bytes[index] = 8'h00;
				1      : cacheline_bytes[index] = 8'hFF;
				2      : cacheline_bytes[index] = index[7:0];
				default: cacheline_bytes[index] = 8'((index * 8'h97) ^ 8'hA5);
			endcase
		end
		for (int index = 0; index < CACHELINE_BYTES; index++) begin
			cacheline[index*8 +: 8] = cacheline_bytes[index];
		end
	endfunction

	// Value of a big endian host field after the package byte swap. The swap
	// reverses the field bytes, so the byte at descriptor offset O ends up as
	// the least significant byte of the mapped value.
	function automatic logic [0:HARNESS_WIDE_BITS-1] expected_field(
			input int byte_offset,
			input int byte_length
		);
		expected_field = '0;
		for (int index = 0; index < byte_length; index++) begin
			expected_field[HARNESS_WIDE_BITS-8*(index+1) +: 8] =
				cacheline_bytes[byte_offset + index];
		end
	endfunction

	function automatic logic [0:HARNESS_WIDE_BITS-1] reverse_bytes(
			input logic [0:HARNESS_WIDE_BITS-1] value      ,
			input int                           byte_length
		);
		reverse_bytes = '0;
		for (int index = 0; index < byte_length; index++) begin
			reverse_bytes[HARNESS_WIDE_BITS-8*(index+1) +: 8] =
				value[HARNESS_WIDE_BITS-8*(byte_length-index) +: 8];
		end
	endfunction

	function automatic logic [0:HARNESS_WIDE_BITS-1] byte_pattern(
			input int kind       ,
			input int byte_length
		);
		byte_pattern = '0;
		for (int index = 0; index < byte_length; index++) begin
			case (kind)
				0      : byte_pattern[HARNESS_WIDE_BITS-8*(index+1) +: 8] = 8'h00;
				1      : byte_pattern[HARNESS_WIDE_BITS-8*(index+1) +: 8] = 8'hFF;
				2      : byte_pattern[HARNESS_WIDE_BITS-8*(index+1) +: 8] = 8'(index + 1);
				default: byte_pattern[HARNESS_WIDE_BITS-8*(index+1) +: 8] = 8'((index * 8'h3B) ^ 8'h5C);
			endcase
		end
	endfunction

	// Smallest legal CAPI request size that covers the requested byte count.
	function automatic int unsigned command_size_model(input logic [0:31] vertex_counter);
		logic [0:VERTEX_SIZE_BITS-1] requested_bytes;
		int unsigned                 size           ;

		requested_bytes = vertex_counter << $clog2(VERTEX_SIZE);
		if (requested_bytes == 0) begin
			return 0;
		end
		size = 1;
		while (size < requested_bytes && size < 128) begin
			size = size << 1;
		end
		return size;
	endfunction

	function automatic trans_order_behavior_t cabt_model(input logic [0:2] encoded);
		case (encoded)
			3'b010 : cabt_model = PAGE  ;
			3'b100 : cabt_model = ABORT ;
			3'b110 : cabt_model = PREF  ;
			3'b111 : cabt_model = SPEC  ;
			default: cabt_model = STRICT;
		endcase
	endfunction

	function automatic bit is_power_of_two(input int value);
		is_power_of_two = (value > 0) && ((value & (value - 1)) == 0);
	endfunction

	`include "graph_package_oracle.svh"

	// -------------------------------------------------------------------------
	// Contract checks
	// -------------------------------------------------------------------------
	task automatic check_wed_structure();
		WED_request         request  ;
		WEDInterfacePayload payload  ;
		WEDInterface        interface_;
		wed_state           state    ;
		string              expected_states[0:5];

		harness_check_int("$bits(WED_request)", EXPECT_WED_BITS, $bits(WED_request),
			"descriptor width changed");
		harness_check_int("$bits(WEDInterfacePayload)", 64 + EXPECT_WED_BITS,
			$bits(WEDInterfacePayload), "descriptor payload wrapper changed");
		harness_check_int("$bits(WEDInterface)", 65 + EXPECT_WED_BITS, $bits(WEDInterface),
			"descriptor interface wrapper changed");
		harness_cover("wed_width_contract");

		payload            = '0;
		payload.address    = '1;
		harness_check_span("WEDInterfacePayload.address", payload, $bits(WEDInterfacePayload), 0, 64);
		interface_         = '0;
		interface_.valid   = 1'b1;
		harness_check_span("WEDInterface.valid", interface_, $bits(WEDInterface), 0, 1);
		harness_cover("wed_interface_wrappers");

		oracle_check_wed_field_spans();
		harness_cover("wed_field_spans");

		expected_states = '{"WED_RESET", "WED_IDLE", "WED_REQ", "WED_WAITING_FOR_REQUEST",
			"WED_READ_DATA", "WED_DONE_REQ"};
		harness_check_int("wed_state literal count", 6, state.num(), "descriptor state set changed");
		state = state.first();
		for (int index = 0; index < 6; index++) begin
			harness_check_string($sformatf("wed_state[%0d]", index), expected_states[index],
				state.name(), "descriptor state order changed");
			harness_check_int($sformatf("wed_state[%0d] encoding", index), index, int'(state),
				"descriptor state encoding changed");
			state = state.next();
		end
		harness_cover("wed_state_enum");
		request = map_DataArrays_to_WED('0);
		if (request !== '0) begin
			$error("empty descriptor did not map to zero: %h", request);
			$fatal(1, "unit contract check failed");
		end
		harness_checks = harness_checks + 1;
	endtask

	task automatic check_wed_mapping(input int kind, input string name);
		WED_request request;

		pattern_name = name;
		build_cacheline(kind);
		request = map_DataArrays_to_WED(cacheline);
		oracle_check_wed_map(request);
		harness_cover($sformatf("wed_map_pattern_%s", name));
	endtask

	task automatic check_cabt();
		trans_order_behavior_t decoded;
		trans_order_behavior_t expected;

		for (int encoded = 0; encoded < 8; encoded++) begin
			decoded  = map_CABT(3'(encoded));
			expected = cabt_model(3'(encoded));
			harness_check_int($sformatf("map_CABT(3'b%03b)", encoded), int'(expected), int'(decoded),
				"transaction ordering decode changed");
			case (encoded)
				2      : harness_cover("cabt_page"    );
				4      : harness_cover("cabt_abort"   );
				6      : harness_cover("cabt_pref"    );
				7      : harness_cover("cabt_spec"    );
				0      : harness_cover("cabt_strict"  );
				default: harness_cover("cabt_reserved");
			endcase
		end
	endtask

	task automatic check_globals();
		harness_check_int("NUM_GRAPH_CU_GLOBAL", CTX_GRAPH_CUS, NUM_GRAPH_CU_GLOBAL,
			"layout manifest disagrees with the package");
		harness_check_int("NUM_VERTEX_CU_GLOBAL", CTX_VERTEX_CUS, NUM_VERTEX_CU_GLOBAL,
			"layout manifest disagrees with the package");
		harness_check_int("total vertex compute units", CTX_TOTAL_VERTEX_CUS,
			NUM_GRAPH_CU_GLOBAL * NUM_VERTEX_CU_GLOBAL, "layout manifest disagrees with the package");
		harness_cover("globals_layout_match");

		oracle_check_precision_constants();

		harness_check_int("VERTEX_SIZE_BITS", VERTEX_SIZE * 8, VERTEX_SIZE_BITS,
			"derived width identity broken");
		harness_check_int("EDGE_SIZE_BITS", EDGE_SIZE * 8, EDGE_SIZE_BITS,
			"derived width identity broken");
		harness_check_int("DATA_SIZE_READ_BITS", DATA_SIZE_READ * 8, DATA_SIZE_READ_BITS,
			"derived width identity broken");
		harness_check_int("DATA_SIZE_WRITE_BITS", DATA_SIZE_WRITE * 8, DATA_SIZE_WRITE_BITS,
			"derived width identity broken");
		harness_check_int("CACHELINE_VERTEX_NUM", CACHELINE_SIZE / VERTEX_SIZE, CACHELINE_VERTEX_NUM,
			"cacheline population identity broken");
		harness_check_int("CACHELINE_VERTEX_NUM_HF", (CACHELINE_SIZE / VERTEX_SIZE) / 2,
			CACHELINE_VERTEX_NUM_HF, "cacheline population identity broken");
		harness_check_int("CACHELINE_EDGE_NUM", CACHELINE_SIZE / EDGE_SIZE, CACHELINE_EDGE_NUM,
			"cacheline population identity broken");
		harness_check_int("CACHELINE_EDGE_NUM_HF", (CACHELINE_SIZE / EDGE_SIZE) / 2,
			CACHELINE_EDGE_NUM_HF, "cacheline population identity broken");
		harness_check_int("CACHELINE_DATA_READ_NUM", CACHELINE_SIZE / DATA_SIZE_READ,
			CACHELINE_DATA_READ_NUM, "cacheline population identity broken");
		harness_check_int("CACHELINE_DATA_WRITE_NUM", CACHELINE_SIZE / DATA_SIZE_WRITE,
			CACHELINE_DATA_WRITE_NUM, "cacheline population identity broken");
		harness_check_int("CACHELINE_DATA_READ_NUM_BITS", $clog2(CACHELINE_SIZE / DATA_SIZE_READ),
			CACHELINE_DATA_READ_NUM_BITS, "cacheline counter width identity broken");
		harness_check_int("CACHELINE_INT_COUNTER_BITS", $clog2(CACHELINE_SIZE),
			CACHELINE_INT_COUNTER_BITS, "cacheline counter width identity broken");
		if (!is_power_of_two(VERTEX_SIZE) || !is_power_of_two(EDGE_SIZE) ||
				!is_power_of_two(DATA_SIZE_READ) || !is_power_of_two(DATA_SIZE_WRITE)) begin
			$error("structure sizes must be powers of two: vertex=%0d edge=%0d read=%0d write=%0d",
				VERTEX_SIZE, EDGE_SIZE, DATA_SIZE_READ, DATA_SIZE_WRITE);
			$fatal(1, "unit contract check failed");
		end
		harness_checks = harness_checks + 1;
		harness_cover("globals_derived_identities");

		harness_check_bits("array alignment mask complement", 64'hFFFF_FFFF_FFFF_FFFF,
			ADDRESS_ARRAY_ALIGN_MASK | ADDRESS_ARRAY_MOD_MASK, "alignment masks are not complements");
		harness_check_bits("array alignment mask overlap", 64'd0,
			ADDRESS_ARRAY_ALIGN_MASK & ADDRESS_ARRAY_MOD_MASK, "alignment masks overlap");
		harness_check_int("array modulo mask", CACHELINE_SIZE - 1, ADDRESS_ARRAY_MOD_MASK,
			"array alignment is not cacheline sized");
		harness_check_int("edge modulo mask", CACHELINE_SIZE - 1, ADDRESS_EDGE_MOD_MASK,
			"edge alignment is not cacheline sized");
		harness_check_int("data read modulo mask", CACHELINE_SIZE - 1, ADDRESS_DATA_READ_MOD_MASK,
			"read data alignment is not cacheline sized");
		harness_check_int("data write modulo mask", CACHELINE_SIZE - 1, ADDRESS_DATA_WRITE_MOD_MASK,
			"write data alignment is not cacheline sized");
		harness_cover("globals_alignment_masks");

		harness_check_int("VERTEX_CONTROL_ID", RESTART_ID - 1, VERTEX_CONTROL_ID,
			"compute unit identifier allocation changed");
		harness_check_int("EDGE_DATA_READ_CONTROL_ID", RESTART_ID - 2, EDGE_DATA_READ_CONTROL_ID,
			"compute unit identifier allocation changed");
		harness_check_int("EDGE_DATA_WRITE_CONTROL_ID", RESTART_ID - 3, EDGE_DATA_WRITE_CONTROL_ID,
			"compute unit identifier allocation changed");
		harness_check_int("PREFETCH_CONTROL_ID", RESTART_ID - 4, PREFETCH_CONTROL_ID,
			"compute unit identifier allocation changed");
		if (VERTEX_CONTROL_ID == INVALID_ID || VERTEX_CONTROL_ID == WED_ID ||
				PREFETCH_CONTROL_ID == INVALID_ID) begin
			$error("compute unit identifiers collide with the reserved encodings");
			$fatal(1, "unit contract check failed");
		end
		harness_checks = harness_checks + 1;
		harness_cover("globals_cu_ids");

		if (!is_power_of_two(CU_VERTEX_JOB_BUFFER_SIZE) ||
				!is_power_of_two(CU_EDGE_JOB_BUFFER_SIZE)) begin
			$error("job buffer sizes must be powers of two: vertex=%0d edge=%0d",
				CU_VERTEX_JOB_BUFFER_SIZE, CU_EDGE_JOB_BUFFER_SIZE);
			$fatal(1, "unit contract check failed");
		end
		harness_checks = harness_checks + 1;
		harness_cover("globals_buffer_sizes");
	endtask

	task automatic check_command_size();
		int unsigned expected;
		int unsigned actual  ;
		logic [0:31] counter ;

		for (int index = 0; index < 320; index++) begin
			counter  = 32'(index);
			expected = command_size_model(counter);
			actual   = cmd_size_calculate(counter);
			harness_check_int($sformatf("cmd_size_calculate(%0d)", index), expected, actual,
				"request size rounding changed");
			harness_cover($sformatf("cmd_size_result_%0d", expected));
		end
		// The byte counter is VERTEX_SIZE_BITS wide, so a large vertex count
		// wraps to zero bytes; that boundary must keep returning no request.
		counter  = 32'hFFFF_FFFF / VERTEX_SIZE + 1;
		expected = command_size_model(counter);
		actual   = cmd_size_calculate(counter);
		harness_check_int("cmd_size_calculate(byte counter wrap)", expected, actual,
			"request size wrap behaviour changed");
		harness_cover($sformatf("cmd_size_result_%0d", expected));
	endtask

	task automatic check_endianness();
		for (int kind = 0; kind < 4; kind++) begin
			oracle_check_endianness(kind);
		end
		harness_cover("swap_involution");
	endtask

	task automatic declare_bins();
		harness_declare_bin("wed_width_contract"        );
		harness_declare_bin("wed_interface_wrappers"    );
		harness_declare_bin("wed_field_spans"           );
		harness_declare_bin("wed_state_enum"            );
		harness_declare_bin("wed_map_pattern_zero"      );
		harness_declare_bin("wed_map_pattern_ones"      );
		harness_declare_bin("wed_map_pattern_ramp"      );
		harness_declare_bin("wed_map_pattern_mixed"     );
		harness_declare_bin("cabt_strict"               );
		harness_declare_bin("cabt_page"                 );
		harness_declare_bin("cabt_abort"                );
		harness_declare_bin("cabt_pref"                 );
		harness_declare_bin("cabt_spec"                 );
		harness_declare_bin("cabt_reserved"             );
		harness_declare_bin("globals_layout_match"      );
		harness_declare_bin("globals_precision_constants");
		harness_declare_bin("globals_derived_identities" );
		harness_declare_bin("globals_alignment_masks"    );
		harness_declare_bin("globals_cu_ids"             );
		harness_declare_bin("globals_buffer_sizes"       );
		harness_declare_bin("cu_enum_contract"           );
		harness_declare_bin("cu_type_layout"             );
		harness_declare_bin("swap_involution"            );
		harness_declare_bin("cmd_size_result_0"          );
		for (int size = VERTEX_SIZE; size <= 128; size = size << 1) begin
			harness_declare_bin($sformatf("cmd_size_result_%0d", size));
		end
		oracle_declare_bins();
	endtask

	initial begin
		harness_scope  = $sformatf("graph_package_contracts[%s]", CTX_LAYOUT);
		harness_checks = 0;
		cycles         = 0;
		pattern_name   = "none";
		declare_bins();

		check_wed_structure();
		check_wed_mapping(0, "zero" );
		check_wed_mapping(1, "ones" );
		check_wed_mapping(2, "ramp" );
		check_wed_mapping(3, "mixed");
		check_cabt();
		check_globals();
		oracle_check_enum_contract();
		oracle_check_type_layout();
		check_command_size();
		check_endianness();

		harness_report_bins();
		if (harness_bin_count != CTX_PACKAGE_BINS) begin
			$fatal(1, "package bin denominator %0d differs from the scenario manifest %0d",
				harness_bin_count, CTX_PACKAGE_BINS);
		end

		$display("PASS graph_package_contracts context=%s cycles=%0d checks=%0d bins=%0d/%0d",
			CTX_LAYOUT, cycles, harness_checks, harness_bins_hit(), harness_bin_count);
		$finish;
	end
endmodule
