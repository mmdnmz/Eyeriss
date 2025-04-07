module Mux2x1 #( parameter DATA_WIDTH = 16)
(
input [DATA_WIDTH-1:0] data_in_a,
input [DATA_WIDTH-1:0] data_in_b,
input sel,
output [DATA_WIDTH-1:0] data_out
);
	
assign data_out = sel ? data_in_b : data_in_a;
	
endmodule