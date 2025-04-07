

module PEGRID #(

    parameter MAX_CONFIG_WIDTH = 8, //configuration inputs bitwidth, e.g filter size
    parameter DATA_WIDTH = 16, //iact and weight data width
    //Scratch pads
    parameter IACT_SPAD_DEPTH = 12, //size of ifmap data spad
    parameter IACT_SPAD_WIDTH = 16, //block width of ifmap data spad
    parameter WEIGHT_SPAD_DEPTH = 224, //size of weight data spad
    parameter WEIGHT_SPAD_WIDTH = 16, //block width of weight data spad 
    parameter PSUM_SPAD_DEPTH = 24, //size of psum data spad
    parameter PSUM_SPAD_WIDTH = 16, //block width of psum data spad
    //I/O buffers
    parameter IACT_BUFFER_DEPTH = 4, //size of iact buffer
    parameter IACT_BUFFER_WIDTH = 16, //block width of iact buffer
    parameter WEIGHT_BUFFER_DEPTH = 4, //size of weight buffer
    parameter WEIGHT_BUFFER_WIDTH = 16, //block width of weight buffer
    parameter WEIGHT_PAR_WRITE = 4, //weight parallel input bus
    parameter PSUM_IN_BUFFER_DEPTH = 6, //size of psum in buffer
    parameter PSUM_OUT_BUFFER_DEPTH = 6, //size of psum out buffer
    parameter PSUM_BUFFER_WIDTH = 16, //block width of psum buffer
    parameter PSUM_PAR_WRITE = 4, //psum parallel input bus
    parameter PSUM_PAR_READ = 4,
    parameter ARRAY_WIDTH = 3,
    parameter ARRAY_LENGTH = 3, 
    parameter ifmap_count = 5,
    parameter filter_count = 3
) (
    //inputs
    input clk,
    input rstn, //active low reset
    input en, //enable for clock gating
    input iact_write_en, //enable/valid iact input data
    input weight_write_en, //enable/valid weight input data
    input psum_write_en, //enable/valid psum input data
    input psum_read_en, //enable read psum output
    // input [((IACT_BUFFER_WIDTH * (w + ((l - 1) * s))) - 1) : 0] data_iact_in, //input iact data 
    input [((DATA_WIDTH * ifmap_count) - 1) : 0] data_iact_in, //input iact data 
    //input [WEIGHT_BUFFER_WIDTH - 1 : 0] data_weight_in, //input weight data
    input [((DATA_WIDTH * ARRAY_WIDTH) - 1) : 0] data_weight_in,
    input [PSUM_BUFFER_WIDTH - 1 : 0] data_psum_in, //input psum data
    //configuration inputs
    input [MAX_CONFIG_WIDTH - 1 : 0] filter_size, //filter size parameter config input
    input [MAX_CONFIG_WIDTH - 1 : 0] stride, //stride parameter config input
    input [MAX_CONFIG_WIDTH - 1 : 0] input_channels_num, //number of input channels parameter config input
    input [MAX_CONFIG_WIDTH - 1 : 0] output_channels_num, //number of output channels
    //outputs
    output [PSUM_BUFFER_WIDTH - 1 : 0] data_psum_out, //output psum data
    output wire iact_buffer_ready,
    output wire weight_buffer_ready,
    output wire psum_buffer_ready,
    output wire psum_out_valid //valid output psum data
);

// parameter ARRAY_WIDTH = 3;
// parameter ARRAY_LENGTH = 3;

reg [DATA_WIDTH-1:0] psum_carry_wire_in  [0:(ARRAY_LENGTH - 1)] [0:ARRAY_WIDTH];
wire [DATA_WIDTH-1:0] psum_carry_wire_out  [0:(ARRAY_LENGTH - 1)] [0:ARRAY_WIDTH-1];

//reg [DATA_WIDTH-1:0] psum_carry_wire_in  [0:ARRAY_WIDTH][0:(ARRAY_LENGTH - 1)] ;

reg [DATA_WIDTH-1:0] filter_carry_wire [0:(ARRAY_WIDTH - 1)];

reg [((DATA_WIDTH * ifmap_count)-1):0] ifmap_carry_wire;

// reg [DATA_WIDTH-1:0] ifmap_carry_wire [0: 4];

    integer l, k;
    initial begin
        for (l = 0; l < ARRAY_LENGTH + 1; l = l + 1) begin
            psum_carry_wire_in[l][ARRAY_WIDTH] = {DATA_WIDTH{1'b0}};
        end

        for (l = 0; l < 5; l = l + 1) begin
            ifmap_carry_wire[l] = l;
        end

        for (l = 0; l < ARRAY_WIDTH; l = l + 1) begin
            filter_carry_wire[l] = l;
        end

    end

always @(*)
begin
        for(l = 0; l<ARRAY_LENGTH; l = l + 1)
    begin
        for (k = 0; k< ARRAY_WIDTH; k = k + 1)
        begin
        psum_carry_wire_in [l][k] = psum_carry_wire_out [l][k];
        end
    end
end




genvar i, j;
    
generate




    //     for(i = 0; i<ARRAY_LENGTH; i++)
    // begin
    //     for (j = 0; j< ARRAY_WIDTH; j++)
    //     begin
        
    //     end
    // end


    // for (i = 0; i < (ARRAY_LENGTH + 1); i = i + 1) begin
    //     psum_carry_wire_in [i][ARRAY_WIDTH] = {DATA_WIDTH{1'b0}};
    // end




    for(i = 0; i<ARRAY_LENGTH; i = i + 1)
    begin
        for (j = 0; j< ARRAY_WIDTH; j = j + 1)
        begin

            
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
        ) AUT (
            .clk(clk),
            .rstn(rstn),
            .en(en),
            .iact_write_en(iact_write_en),
            .weight_write_en(weight_write_en),
            .psum_write_en(psum_write_en),
            .psum_read_en(psum_read_en),
            .data_iact_in(data_iact_in[(( (1 + j + (i)) * 16 ) - 1) : ( (j + (i)) * 16)]),
            .data_weight_in(data_weight_in[(((1 + j) * 16) - 1):(j * 16)]),
            .data_psum_in(psum_carry_wire_in[i][j + 1]),
            .filter_size(4),
            .stride(1),
            .input_channels_num(input_channels_num),
            .output_channels_num(output_channels_num),
            .data_psum_out(psum_carry_wire_out[i][j]),
            .iact_buffer_ready(iact_buffer_ready),
            .weight_buffer_ready(weight_buffer_ready),
            .psum_out_valid(psum_out_valid)
        );

        end
    end


endgenerate





endmodule