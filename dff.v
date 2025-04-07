`timescale 1ns/1ns
module DFF #(
   parameter DATA_WIDTH = 16 //data bit width
) (
   input clk,  
   input en, //enable
   input rstn, //active low reset 
   input [DATA_WIDTH - 1 : 0] data_in, //input data
   output reg [DATA_WIDTH - 1 : 0] data_out //output data
);  

always @(posedge clk or negedge rstn) begin
      if (!rstn)
         data_out <= {DATA_WIDTH{1'b0}}; // reset output to 0
      else if (en)
         data_out <= data_in; // write data to output if enabled and write enabled
   end


endmodule
