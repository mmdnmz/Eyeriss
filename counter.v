`timescale 1ns / 1ns

module Counter #(
    parameter MAX = 3'b111, // Upper bound of count
//    parameter dayan = 1;
    parameter WIDTH = 3 // Bitwidth of counter
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
        if (count == 3'd7) begin
            count <= 0;
            prev_count <= 3'b111;
            dayan <= dayan + 1;
        end else if (count == 3) begin
            dayan <= dayan + 1;
            count <= 4;
        end else begin
            prev_count <= count;
            count <= count + 1;
        end
    end
end

assign at_max = (count == 3'b111);

endmodule