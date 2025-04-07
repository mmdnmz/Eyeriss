module ClkGate( 
	input wire input_clk, en,
	output wire output_clk
	);

   reg en_latch;

    always @(posedge input_clk) begin
        en_latch <= en;
    end

    assign output_clk = input_clk & en_latch;
endmodule