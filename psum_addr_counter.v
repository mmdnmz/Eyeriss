module psum_addr_counter #(
    parameter integer MAX_CONFIG_WIDTH = 5
)
(
    input clk,
    input en,       // Enable
    input rstn,     // Active low reset
    input clear, //clear counter
    input [MAX_CONFIG_WIDTH - 1 : 0] filter_size, //filter size parameter config input
    output at_max,  // Counter finish signal
    
    output reg [1 : 0] count,     // Current counter output value
    //output reg [WIDTH - 1 : 0] prev_count // Previous value of counter
    output reg loc_en_disp,
    output reg read_addr_change

);

reg loc_en;
always @(posedge clk) begin
    if (!rstn) begin // Reset
        count <= 0;
    end else if (clear) begin //clear
        count <= 0;
    end else if (loc_en) begin
            count <= count + 1;
            if (count == (filter_size - 3)) begin
                read_addr_change <= 1'b1;
            end
            else begin
                read_addr_change <= 1'b0;
            end
    end
end

always @(posedge clk) begin
    if (en) begin // Reset
        loc_en <= 1;
        loc_en_disp <= 1;
    end
end

assign at_max = (count == 2'b11);

endmodule