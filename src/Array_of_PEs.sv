module PE_Array #(
    parameter MAX_CONFIG_WIDTH = 32,
    parameter DATA_WIDTH = 16,
    parameter IACT_SPAD_DEPTH = 256,
    parameter IACT_SPAD_WIDTH = 16,
    parameter WEIGHT_SPAD_DEPTH = 256,
    parameter WEIGHT_SPAD_WIDTH = 16,
    parameter PSUM_SPAD_DEPTH = 256,
    parameter PSUM_SPAD_WIDTH = 16,
    parameter IACT_BUFFER_DEPTH = 256,
    parameter IACT_BUFFER_WIDTH = 16,
    parameter WEIGHT_BUFFER_DEPTH = 256,
    parameter WEIGHT_BUFFER_WIDTH = 16,
    parameter WEIGHT_PAR_WRITE = 1,
    parameter PSUM_IN_BUFFER_DEPTH = 256,
    parameter PSUM_OUT_BUFFER_DEPTH = 256,
    parameter PSUM_BUFFER_WIDTH = 16,
    parameter ARRAY_WIDTH = 4,
    parameter ARRAY_HEIGHT = 4,
    parameter STRIDE = 1
)(
    input clk,
    input rstn,
    input en,
    input iact_write_en,
    input weight_write_en,
    input psum_write_en,
    input psum_read_en,
    input [DATA_WIDTH-1:0] data_iact_in_grid ,
    input [DATA_WIDTH-1:0] data_weight_in_grid,
    input [DATA_WIDTH-1:0] data_psum_in_grid ,
    input [3:0] filter_size,
    input [3:0] stride,
    input [7:0] input_channels_num,
    input [7:0] output_channels_num,
    output [DATA_WIDTH-1:0] data_psum_out_grid,
    output iact_buffer_ready,
    output weight_buffer_ready,
    output psum_out_valid
);
/*
reg [DATA_WIDTH] data_iact_in [0:(ARRAY_WIDTH * ARRAY_HEIGHT) ];
reg [DATA_WIDTH] data_weight_in [0:(ARRAY_WIDTH * ARRAY_HEIGHT) ];
reg [DATA_WIDTH] data_psum_in [0:(ARRAY_WIDTH * ARRAY_HEIGHT) ];
reg [DATA_WIDTH] data_psum_out [0:(ARRAY_WIDTH * ARRAY_HEIGHT) ];
*/


// reg [DATA_WIDTH : 0] [0:(ARRAY_WIDTH * ARRAY_HEIGHT) ] data_iact_in ;
// reg [DATA_WIDTH : 0] [0:(ARRAY_WIDTH * ARRAY_HEIGHT) ] data_weight_in ;
// reg [DATA_WIDTH : 0] [0:(ARRAY_WIDTH * ARRAY_HEIGHT) ] data_psum_in ;
// reg [DATA_WIDTH : 0] [0:(ARRAY_WIDTH * ARRAY_HEIGHT) ] data_psum_out ;

reg [DATA_WIDTH : 0] data_iact_in [0:(ARRAY_WIDTH * ARRAY_HEIGHT) ] ;
reg [DATA_WIDTH : 0] data_weight_in [0:(ARRAY_WIDTH * ARRAY_HEIGHT) ] ;
reg [DATA_WIDTH : 0] data_psum_in [0:(ARRAY_WIDTH * ARRAY_HEIGHT) ] ;
reg [DATA_WIDTH : 0] data_psum_out [0:(ARRAY_WIDTH * ARRAY_HEIGHT) ] ;


genvar i, j;
generate
    for (i = 0; i < ARRAY_HEIGHT; i = i + 1) begin : row
        for (j = 0; j < ARRAY_WIDTH; j = j + 1) begin : col
            wire [DATA_WIDTH-1:0] psum_in;
            assign psum_in = (j == ARRAY_WIDTH-1) ? {DATA_WIDTH{1'b0}} : data_psum_in[i][j];

            PE #(
                .MAX_CONFIG_WIDTH(MAX_CONFIG_WIDTH),
                .DATA_WIDTH(DATA_WIDTH),
                .IACT_SPAD_DEPTH(IACT_SPAD_DEPTH),
                .IACT_SPAD_WIDTH(IACT_SPAD_WIDTH),
                .WEIGHT_SPAD_DEPTH(WEIGHT_SPAD_DEPTH),
                .WEIGHT_SPAD_WIDTH(WEIGHT_SPAD_WIDTH),
                .PSUM_SPAD_DEPTH(PSUM_SPAD_DEPTH),
                .PSUM_SPAD_WIDTH(PSUM_SPAD_WIDTH),
                .IACT_BUFFER_DEPTH(IACT_BUFFER_DEPTH),
                .IACT_BUFFER_WIDTH(IACT_BUFFER_WIDTH),
                .WEIGHT_BUFFER_DEPTH(WEIGHT_BUFFER_DEPTH),
                .WEIGHT_BUFFER_WIDTH(WEIGHT_BUFFER_WIDTH),
                .WEIGHT_PAR_WRITE(WEIGHT_PAR_WRITE),
                .PSUM_IN_BUFFER_DEPTH(PSUM_IN_BUFFER_DEPTH),
                .PSUM_OUT_BUFFER_DEPTH(PSUM_OUT_BUFFER_DEPTH),
                .PSUM_BUFFER_WIDTH(PSUM_BUFFER_WIDTH)
            ) pe_inst (
                .clk(clk),
                .rstn(rstn),
                .en(en),
                .iact_write_en(iact_write_en),
                .weight_write_en(weight_write_en),
                .psum_write_en(psum_write_en),
                .psum_read_en(psum_read_en),
                .data_iact_in(data_iact_in[j + (i * STRIDE)]),
                .data_weight_in(data_weight_in[j]),
                .data_psum_in(psum_in),
                .filter_size(filter_size),
                .stride(stride),
                .input_channels_num(input_channels_num),
                .output_channels_num(output_channels_num),
                .data_psum_out(data_psum_out[i][j]),
                .iact_buffer_ready(iact_buffer_ready),
                .weight_buffer_ready(weight_buffer_ready),
                .psum_out_valid(psum_out_valid)
            );
        end
    end
endgenerate

endmodule
