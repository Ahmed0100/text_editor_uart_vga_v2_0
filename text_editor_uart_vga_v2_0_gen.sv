module text_editor_uart_vga_v2_0_gen
(
	input clk,reset_n,
	input rx,
	input [9:0] pixel_x,pixel_y,
	input video_on,
	output logic [2:0] rgb
);
localparam IDLE=0, FIRST=1,START=2;

logic [6:0] rd_data,ascii_char,din;
logic [6:0] scroll_data;
logic [7:0] font_data;
logic font_bit;
logic rx_empty;
logic [11:0] addr_a,addr_b;
logic scroll_reg,scroll_next,scroll;
logic we, we_1;
logic scroll_we;
logic [1:0] current_state, next_state;
logic underline_on,cursor_on;
logic [4:0] y_cursor_reg,y_cursor_next;
logic [6:0] x_cursor_reg,x_cursor_next;
logic [4:0] wr_y_scroll_reg,wr_y_scroll_next;
logic [6:0] wr_x_scroll_reg,wr_x_scroll_next;
logic [4:0] rd_y_scroll_reg,rd_y_scroll_next;
logic [6:0] rd_x_scroll_reg,rd_x_scroll_next;
logic [9:0] pixel_x_reg[1:0],pixel_y_reg[1:0];

always @(posedge clk,negedge reset_n) begin
	if(!reset_n) begin
		y_cursor_reg<='0;
		x_cursor_reg<='0;
		pixel_x_reg[0]<='0;
		pixel_x_reg[1]<='0;
		pixel_y_reg[0]<='0;
		pixel_y_reg[1]<='0;
		scroll_reg<='0;
		current_state<=IDLE;
		wr_x_scroll_reg<='0;
		wr_y_scroll_reg<='0;
		rd_y_scroll_reg<='0;
		rd_x_scroll_reg<='0;
	end
	else begin
		y_cursor_reg <= y_cursor_next;
		x_cursor_reg <= x_cursor_next;
		pixel_x_reg[0] <= pixel_x;
		pixel_x_reg[1] <= pixel_x_reg[0];
		pixel_y_reg[0] <= pixel_y;
		pixel_y_reg[1] <= pixel_y_reg[0];
		scroll_reg <= scroll_next;
		current_state <= next_state;
		wr_x_scroll_reg <= wr_x_scroll_next;
		wr_y_scroll_reg <= wr_y_scroll_next;
		rd_y_scroll_reg <= rd_y_scroll_next;
		rd_x_scroll_reg <= rd_x_scroll_next;
	end
end

always_comb begin : proc_cursors
	x_cursor_next = x_cursor_reg;
	y_cursor_next = y_cursor_reg;
	we = 0;
	scroll = 0;
	if(!rx_empty && rd_data == 8'h0d)
	begin
		x_cursor_next = 0;
		y_cursor_next = (y_cursor_reg == 29)? y_cursor_reg: y_cursor_reg+1;
		scroll = (y_cursor_reg == 29)? 1:0;
	end
	else if(!rx_empty)
	begin
		we = 1;
		x_cursor_next = x_cursor_reg+1;
		if(x_cursor_next == 80)
		begin
			x_cursor_next = 0;
			y_cursor_next = (y_cursor_reg == 29)? y_cursor_reg: y_cursor_reg+1;
			scroll = (y_cursor_reg== 29)? 1 : 0;
		end
	end
end

always_comb begin : proc_logic_for_scrolling
	scroll_next = scroll_reg;
	next_state = current_state;
	wr_x_scroll_next = wr_x_scroll_reg;
	wr_y_scroll_next = wr_y_scroll_reg;
	rd_y_scroll_next = rd_y_scroll_reg;
	rd_x_scroll_next = rd_x_scroll_reg;
	scroll_we = 0;
	scroll_data = ascii_char;
	if(scroll)
		scroll_next = 1;

	if(scroll_reg)
	begin
		case(current_state)
			IDLE: 
			begin
				rd_x_scroll_next = '0;
				rd_y_scroll_next = 'h1;
				wr_x_scroll_next = '0;
				wr_y_scroll_next = '0;
				next_state = FIRST;
			end

			FIRST:
			begin
				scroll_we = 1;
				rd_x_scroll_next = rd_x_scroll_reg+1; //advance reading addr for correct writing order
				next_state = START;
			end

			START:
			begin
				scroll_we = 1;
				if(wr_x_scroll_reg == 79)
				begin
					wr_x_scroll_next = 0;
					wr_y_scroll_next = wr_y_scroll_reg + 1;				
				end
				else
					wr_x_scroll_next = wr_x_scroll_reg + 1;
				
				if(wr_y_scroll_reg == 29)
					scroll_data = 0;
				if(wr_y_scroll_reg == 29 && wr_x_scroll_reg == 79)
				begin
					scroll_next = 0;
					next_state = IDLE;				
				end

				if(rd_x_scroll_reg == 79)
				begin
					rd_x_scroll_next = 0;
					rd_y_scroll_next = rd_y_scroll_reg + 1;
				end
				else
					rd_x_scroll_next = rd_x_scroll_reg + 1;
			end
			default: next_state = IDLE;
		endcase
	end
end

assign font_bit = font_data[~pixel_x_reg[1][2:0]] && !scroll_reg;
assign cursor_on = (pixel_y_reg[1][8:4]==y_cursor_reg) &&
(pixel_x_reg[1][9:3] == x_cursor_reg);
assign underline_on = cursor_on && (pixel_y_reg[1][3:1]==3'b111) && !scroll_reg;
assign we_1 = scroll_reg? scroll_we : we;

assign din=scroll_reg? scroll_data:rd_data;
assign addr_a=scroll_reg? {wr_y_scroll_reg,wr_x_scroll_reg}:{y_cursor_reg,x_cursor_reg}; //write addr
assign addr_b=scroll_reg? {rd_y_scroll_reg,rd_x_scroll_reg}:{pixel_y[8:4],pixel_x[9:3]}; //read addr

always_comb begin : proc_rgb
	rgb='0;
	if(!video_on)
		rgb='0;
	else if(underline_on)
		rgb = 3'b011;
	else
		rgb = (font_bit===1)? 3'b010:3'b000;
end

uart #(.DBIT(8),.SB_TICK(16),.DVSR(326),.FIFO_W(5)) uart_inst //9600 baud rate
(
		.clk(clk),
		.rst_n(reset_n),
		.rd_uart(!rx_empty),
		.wr_uart(),
		.wr_data(),
		.rx(rx),
		.tx(),
		.rd_data(rd_data),
		.rx_empty(rx_empty),
		.tx_full()
);

dual_port_sync_ram #(.ADDR_WIDTH(12),.DATA_WIDTH(8)) dual_port_syn_ram_inst
(
	.clk(clk),
	.we(we_1),
	.din(din), //write data
	.addr_a(addr_a), //write addr
	.addr_b(addr_b), //read addr
	.dout_a(),
	.dout_b(ascii_char) //read data	
);

font_rom font_rom_inst
(
	.clk(clk), 
	.addr({ascii_char,pixel_y[3:0]}),
	.data(font_data)
);


endmodule