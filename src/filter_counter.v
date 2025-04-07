`timescale 1ns / 1ns

module filter_counter #(
    parameter WIDTH = 3 // Bitwidth of counter
)
(
    input clk,
    input en,       // Enable
    input rstn,     // Active low reset
    input clear, //clear counter
    input [WIDTH - 1 : 0] max_count, //upper bound of counter 
    output reg [WIDTH - 1 : 0] count     // Current counter output value
);
    
reg en_in = 1'b0;

always @(posedge clk) begin
    if (en) begin // Reset
        en_in <= 1'b1;
    end
    if (!rstn) begin // Reset
        count <= 0;
        // prev_count <= 0;
    end else if (clear) begin //clear
        count <= 0;
        // prev_count <= 0;
    end else if (en) begin
            if (count == (max_count - 1)) 
            begin
            count <= 0;
            // prev_count <= 2'b11;
            end
            else if (count != max_count)
            begin
            // prev_count <= count;
            count <= count + 1;
            end
    end
end


endmodule