module example_module;
    parameter DATA_WIDTH = 8;
    parameter ARRAY_LENGTH = 4;
    parameter ARRAY_WIDTH = 4;

    reg [DATA_WIDTH-1:0] psum_carry_wire [0:ARRAY_LENGTH-1][0:ARRAY_WIDTH-1];

    integer i;
    initial begin
        for (i = 0; i < ARRAY_LENGTH; i = i + 1) begin
            psum_carry_wire[i][ARRAY_WIDTH-1] = {DATA_WIDTH{1'b0}};
        end
    end
endmodule
