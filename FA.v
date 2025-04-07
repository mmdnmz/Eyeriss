module FA #(
    parameter WIDTH = 16
)(
    input clk,
    input en,
    input wire [WIDTH-1:0] data_in_a,
    input wire [WIDTH-1:0] data_in_b,
    output [WIDTH:0] sum
);
/*
//add at one clock
always @(posedge clk) begin
    if (en)
        sum <= data_in_a + data_in_b;
end
endmodule
*/
//add at one clock
assign sum = data_in_a + data_in_b;

endmodule
