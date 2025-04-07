`timescale 1ns/1ns

//custom counter
//this module counts 1 and also has an input to add it to its counter
//reset counting when:
//1. reset is set
//2. reaching max

//enable signal need to be set for counting
module Custom_counter #(
    parameter integer WIDTH = 4 //bitwidth of counter
)
(
    input clk,
    input en, //enable
    input rstn, //active low reset
    input clear, //clear counter
    input [WIDTH - 1 : 0] step, //step count, default = 1
    input [WIDTH - 1 : 0] max_count, //upper bound of counter 

    output at_max, //counter finish signal
    output reg [WIDTH - 1 : 0] count //current counter output value
);

always @(posedge clk) begin
    if (!rstn) begin
        count <= 0;
    end else if (clear) begin
        count <= 0;
    end else if (en) begin
        if (!at_max)
            count <= count + 1'b1;
    end
end

assign at_max = (count >= max_count);

endmodule

