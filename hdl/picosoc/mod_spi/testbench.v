module testbench;
	reg clk = 1;
	reg resetn = 0;

	always #5 clk = ~clk;
	initial begin
		$dumpfile("testbench.vcd");
		$dumpvars(0, testbench);
		repeat (100) @(posedge clk);
		resetn <= 1;
	end

	reg         ctrl_wr = 0;
	reg         ctrl_rd = 0;
	reg  [ 7:0] ctrl_addr;
	reg  [31:0] ctrl_wdat;
	wire [31:0] ctrl_rdat;
	wire        ctrl_done;

	wire [31:0] CS;
	wire mosi, miso, sclk;
	assign miso = ~mosi;

	task ctrl_write(input [7:0] addr, input [31:0] data); begin
		ctrl_wr <= 1;
		ctrl_rd <= 0;
		ctrl_addr <= addr;
		ctrl_wdat <= data;
		@(posedge clk);
		while (!ctrl_done) @(posedge clk);
		ctrl_wr <= 0;
	end endtask

	task ctrl_read(input [7:0] addr); begin
		ctrl_wr <= 0;
		ctrl_rd <= 1;
		ctrl_addr <= addr;
		@(posedge clk);
		while (!ctrl_done) @(posedge clk);
		ctrl_rd <= 0;
	end endtask

	task xfer_test; begin
		ctrl_write('h0008, 151);
		ctrl_read('h0008);

		$display("%b %x %x %s", CS[3:0], ctrl_wdat[7:0], ctrl_rdat[7:0], ctrl_wdat[7:0] === ~ctrl_rdat[7:0] ? "OK" : "NOK");

		repeat (10) @(posedge clk);

		ctrl_write('h0008, 42);
		ctrl_read('h0008);
		$display("%b %x %x %s", CS[3:0], ctrl_wdat[7:0], ctrl_rdat[7:0], ctrl_wdat[7:0] === ~ctrl_rdat[7:0] ? "OK" : "NOK");
	end endtask

	icosoc_mod_spi uut (
		.clk      (clk      ),
		.resetn   (resetn   ),
		.ctrl_wr  (ctrl_wr  ),
		.ctrl_rd  (ctrl_rd  ),
		.ctrl_addr(ctrl_addr),
		.ctrl_wdat(ctrl_wdat),
		.ctrl_rdat(ctrl_rdat),
		.ctrl_done(ctrl_done),
		.CS       (CS       ),
		.mosi     (mosi     ),
		.miso     (miso     ),
		.sclk     (sclk     )
	);

	initial begin
		@(posedge resetn);
		repeat (10) @(posedge clk);

		ctrl_write('h0000, 10);
		ctrl_write('h0004, ~0);

		$display("----");

		ctrl_write('h000c, 0);
		ctrl_write('h0004, ~1);

		xfer_test;

		ctrl_write('h0004, ~0);

		$display("----");

		ctrl_write('h000c, 1);
		ctrl_write('h0004, ~2);

		xfer_test;

		ctrl_write('h0004, ~0);

		$display("----");

		ctrl_write('h000c, 2);
		ctrl_write('h0004, ~4);

		xfer_test;

		ctrl_write('h0004, ~0);

		$display("----");

		ctrl_write('h000c, 3);
		ctrl_write('h0004, ~8);

		xfer_test;

		ctrl_write('h0004, ~0);

		$display("----");

		repeat (10) @(posedge clk);
		$finish;
	end
endmodule
