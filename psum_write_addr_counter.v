module psum_writeaddr_counter
(
    input clk,
    input en,       // Enable
    input rstn,     // Active low reset
    input clear, //clear counter
    input read_en,
    output at_max,  // Counter finish signal
    output reg [4 : 0] count,     // Current counter output value
    output reg [4 : 0] read_count
    //output reg [WIDTH - 1 : 0] prev_count // Previous value of counter
);

always @(posedge clk) begin
    if (!rstn) begin // Reset
        count <= 0;
    end else if (clear) begin //clear
        count <= 0;
    end else if (en) begin
            count = count + 1;
    end
end

always @(posedge clk) begin
    if (!rstn) begin // Reset
        read_count <= 0;
    end else if (clear) begin //clear
        read_count <= 0;
    end else if (read_en) begin
            read_count = read_count + 1;
    end
end


assign at_max = (count == 2'b11);

endmodule