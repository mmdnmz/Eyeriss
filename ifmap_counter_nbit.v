`timescale 1ns / 1ns

module ifmap_counter_nbit #(
    parameter MAX = 10, // Upper bound of count
//    parameter dayan = 1;
    parameter WIDTH = $clog2(MAX+1) // Bitwidth of counter
)
(
    input clk,
    input en,       // Enable
    input rstn,     // Active low reset
    input clear, //clear counter
    output at_max,  // Counter finish signal
    output reg [WIDTH - 1 : 0] count,     // Current counter output value
    output reg [WIDTH - 1 : 0] prev_count // Previous value of counter
);
    
reg dayan = 1'b0;
always @(posedge clk) begin
    if (!rstn) begin // Reset
        count <= 0;
        prev_count <= 0;
    end else if (clear) begin //clear
        count <= 0;
        prev_count <= 0;
    end else if (en) begin
        if (count == MAX) begin
            count <= 0;
            prev_count <= MAX;
        end else begin
            prev_count <= count;
            count <= count + 1;
        end
    end
end

assign at_max = (count == MAX);

endmodule