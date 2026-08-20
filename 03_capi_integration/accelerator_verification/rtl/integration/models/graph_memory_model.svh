// -----------------------------------------------------------------------------
//
//      "ACCEL-GRAPH Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Graph memory adapter for the AccelGraph integration suites.
//
// The file is included inside a testbench module so the byte memory stays local
// to the testbench and no hierarchical access is required.  It maps the graph
// arrays of a fixture onto a byte addressable image, serves cache line reads
// with the CommandTagLine echoed back exactly as the CAPI read path does, and
// applies writes to the same image so the write scoreboard can compare against
// an independently computed expected image.
//
// The including module must declare:
//   clock, rstn, read_command_out, read_response_in, read_data_0_in,
//   read_data_1_in, read_buffer_status, write_command_out, write_data_0_out,
//   write_data_1_out, write_response_in, write_buffer_status,
//   mem_read_stall, mem_write_stall, mem_write_alfull
// and the functions mem_read_stalled(int unsigned address), which classifies
// the graph domain of a pending read by its address range, and
// mem_read_property(int unsigned address, CommandTagLine cmd), which reports
// whether the served read belongs to the per-vertex property array.
// -----------------------------------------------------------------------------

	localparam int MEM_BYTES     = 1 << 16;
	localparam int MEM_LATENCY   = 4      ;
	localparam int MEM_QUEUE     = 16     ;

	// byte addressable graph image
	logic [7:0] mem[0:MEM_BYTES-1];

	// outstanding read pipeline
	CommandTagLine mem_read_cmd  [0:MEM_QUEUE-1];
	logic [0:63]   mem_read_addr [0:MEM_QUEUE-1];
	int            mem_read_delay[0:MEM_QUEUE-1];
	bit            mem_read_busy [0:MEM_QUEUE-1];

	CommandTagLine mem_write_cmd  [0:MEM_QUEUE-1];
	int            mem_write_delay[0:MEM_QUEUE-1];
	bit            mem_write_busy [0:MEM_QUEUE-1];

	// set with the read response when the served command targeted the property
	// array, so a testbench can route only property lines into the element
	// extraction engine without depending on layout specific enum names
	logic        mem_read_is_property;
	int unsigned mem_reads_served ;
	int unsigned mem_writes_served;
	int unsigned mem_read_drops   ;
	int unsigned mem_write_drops  ;

	function automatic void mem_store_bytes(
			input int unsigned address,
			input int unsigned size,
			input longint unsigned value
		);
		// The graph arrays are written by the host in little endian byte order;
		// the CU restores them with the swap_endianness helpers in CU_PKG.
		// The address wraps exactly as the cache-line accessor does, so a
		// deliberately wide census identifier addresses the image instead of
		// stepping outside it.
		for (int b = 0; b < size; b++)
			mem[(address + b) % MEM_BYTES] = (value >> (8 * b)) & 8'hFF;
	endfunction

	function automatic longint unsigned mem_load_bytes(
			input int unsigned address,
			input int unsigned size
		);
		longint unsigned value;
		value = 0;
		for (int b = 0; b < size; b++)
			value = value | (longint'(mem[(address + b) % MEM_BYTES]) << (8 * b));
		return value;
	endfunction

	function automatic void mem_clear();
		for (int i = 0; i < MEM_BYTES; i++)
			mem[i] = 8'h00;
	endfunction

	function automatic logic [0:(CACHELINE_SIZE_BITS_HF-1)] mem_cacheline_half(
			input int unsigned address
		);
		logic [0:(CACHELINE_SIZE_BITS_HF-1)] line;
		line = '0;
		for (int b = 0; b < (CACHELINE_SIZE_BITS_HF / 8); b++)
			line[b*8 +: 8] = mem[(address + b) % MEM_BYTES];
		return line;
	endfunction

	always @(posedge clock) begin
		if (!rstn) begin
			read_response_in     <= '0;
			read_data_0_in       <= '0;
			read_data_1_in       <= '0;
			mem_read_is_property <= 1'b0;
			write_response_in <= '0;
			mem_reads_served  <= 0;
			mem_writes_served <= 0;
			mem_read_drops    <= 0;
			mem_write_drops   <= 0;
			for (int i = 0; i < MEM_QUEUE; i++) begin
				mem_read_busy [i] = 1'b0;
				mem_write_busy[i] = 1'b0;
			end
			read_buffer_status        <= '0;
			read_buffer_status.empty  <= 1'b1;
			write_buffer_status       <= '0;
			write_buffer_status.empty <= 1'b1;
		end else begin
			automatic bit read_slot_found  = 1'b0;
			automatic bit write_slot_found = 1'b0;
			automatic int read_outstanding = 0;
			automatic int write_outstanding = 0;
			automatic bit read_issued  = 1'b0;
			automatic bit write_issued = 1'b0;

			read_response_in.valid  <= 1'b0;
			read_data_0_in.valid    <= 1'b0;
			read_data_1_in.valid    <= 1'b0;
			write_response_in.valid <= 1'b0;

			// accept a new read command
			if (read_command_out.valid) begin
				for (int i = 0; i < MEM_QUEUE; i++) begin
					if (!read_slot_found && !mem_read_busy[i]) begin
						mem_read_busy [i] = 1'b1;
						mem_read_cmd  [i] = read_command_out.payload.cmd;
						mem_read_addr [i] = read_command_out.payload.address;
						mem_read_delay[i] = MEM_LATENCY;
						read_slot_found    = 1'b1;
					end
				end
				if (!read_slot_found)
					mem_read_drops <= mem_read_drops + 1;
			end

			// accept a new write command and apply its data
			if (write_command_out.valid) begin
				for (int i = 0; i < MEM_QUEUE; i++) begin
					if (!write_slot_found && !mem_write_busy[i]) begin
						mem_write_busy [i] = 1'b1;
						mem_write_cmd  [i] = write_command_out.payload.cmd;
						mem_write_delay[i] = MEM_LATENCY;
						write_slot_found    = 1'b1;
					end
				end
				if (!write_slot_found)
					mem_write_drops <= mem_write_drops + 1;
			end

			// retire reads in order of expiry
			for (int i = 0; i < MEM_QUEUE; i++) begin
				if (mem_read_busy[i]) begin
					if (mem_read_delay[i] > 0)
						mem_read_delay[i] = mem_read_delay[i] - 1;
					else if (!mem_read_stall && !mem_read_stalled(mem_read_addr[i][32:63]) &&
					         !read_issued) begin
						mem_read_busy[i]         = 1'b0;
						read_issued              = 1'b1;
						read_response_in.valid   <= 1'b1;
						read_response_in.payload.cmd              <= mem_read_cmd[i];
						read_response_in.payload.response         <= DONE;
						read_response_in.payload.response_credits <= 9'd1;
						read_data_0_in.valid          <= 1'b1;
						read_data_0_in.payload.cmd    <= mem_read_cmd[i];
						read_data_0_in.payload.data   <= mem_cacheline_half(mem_read_addr[i][32:63]);
						read_data_1_in.valid          <= 1'b1;
						read_data_1_in.payload.cmd    <= mem_read_cmd[i];
						read_data_1_in.payload.data   <=
							mem_cacheline_half(mem_read_addr[i][32:63] + (CACHELINE_SIZE_BITS_HF / 8));
						mem_read_is_property <= mem_read_property(mem_read_addr[i][32:63], mem_read_cmd[i]);
						mem_reads_served <= mem_reads_served + 1;
					end
					if (mem_read_busy[i])
						read_outstanding = read_outstanding + 1;
				end
			end

			// retire writes
			for (int i = 0; i < MEM_QUEUE; i++) begin
				if (mem_write_busy[i]) begin
					if (mem_write_delay[i] > 0)
						mem_write_delay[i] = mem_write_delay[i] - 1;
					else if (!mem_write_stall && !write_issued) begin
						mem_write_busy[i]        = 1'b0;
						write_issued             = 1'b1;
						write_response_in.valid  <= 1'b1;
						write_response_in.payload.cmd              <= mem_write_cmd[i];
						write_response_in.payload.response         <= DONE;
						write_response_in.payload.response_credits <= 9'd1;
						mem_writes_served <= mem_writes_served + 1;
					end
					if (mem_write_busy[i])
						write_outstanding = write_outstanding + 1;
				end
			end

			read_buffer_status.empty   <= (read_outstanding == 0);
			read_buffer_status.alfull  <= mem_read_stall || (read_outstanding >= (MEM_QUEUE - 4));
			read_buffer_status.full    <= (read_outstanding >= MEM_QUEUE);
			read_buffer_status.valid   <= (read_outstanding != 0);
			write_buffer_status.empty  <= (write_outstanding == 0);
			write_buffer_status.alfull <= mem_write_alfull || (write_outstanding >= (MEM_QUEUE - 4));
			write_buffer_status.full   <= (write_outstanding >= MEM_QUEUE);
			write_buffer_status.valid  <= (write_outstanding != 0);
		end
	end

	// CAPI partial write: `size` bytes are taken from the half cache line that
	// contains the addressed offset, at that offset inside the half.  Both
	// halves carry the same payload, so either may be used.
	int unsigned mem_write_bytes;

	always @(posedge clock) begin
		if (rstn && write_command_out.valid) begin
			automatic int unsigned address    = write_command_out.payload.address[32:63];
			automatic int unsigned size       = write_command_out.payload.size;
			automatic int unsigned line_off   = address % CACHELINE_SIZE;
			automatic int unsigned half_off   = line_off % CACHELINE_SIZE_HF;
			automatic logic [0:(CACHELINE_SIZE_BITS_HF-1)] half =
				(line_off < CACHELINE_SIZE_HF) ?
					write_data_0_out.payload.data : write_data_1_out.payload.data;
			if (size > 0 && size <= CACHELINE_SIZE_HF) begin
				for (int b = 0; b < size; b++)
					mem[(address + b) % MEM_BYTES] = half[(half_off + b) * 8 +: 8];
				mem_write_bytes <= mem_write_bytes + size;
			end
		end
	end
