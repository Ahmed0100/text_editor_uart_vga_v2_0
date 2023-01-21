module text_editor_uart_vga_v2_0_top (
	input clk,    // Clock
	input reset_n,  // Asynchronous reset active low
	input rx,
	output logic vga_hsync,vga_vsync,
	output logic [2:0] vga_rgb
);

logic [9:0] pixel_x,pixel_y;
logic video_on;

vga_sync vga_sync_inst
(
	.clk(clk), .rst_n(reset_n), .hsync(vga_hsync),.vsync(vga_vsync),
	.pixel_x(pixel_x),.pixel_y(pixel_y),.video_on(video_on)
);

text_editor_uart_vga_v2_0_gen text_editor_uart_vga_v2_0_gen_inst
(
	.clk(clk),
	.reset_n(reset_n),
	.rx(rx),
	.pixel_x(pixel_x),
	.pixel_y(pixel_y),
	.video_on(video_on),
	.rgb(vga_rgb)
);

endmodule : text_editor_uart_vga_v2_0_top