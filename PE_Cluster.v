`include "hw_config.vh"
`define CLUSTER_SIM
/*
(y, x)
# = y*cols + x
---------------------------> x
| *   *   *   *   *   *   *
| * (0,0) #0  * (0,1)  #1 *
| *   *   *   *   *   *   *
| * (1,0) #2  * (1,1)  #3 *
| *   *   *   *   *   *   *
\/
Y

*/
module PE_Cluster #(
    parameter integer ID = 0,
    parameter integer ROWS = `HWC_PE_CLUSTER_ROWS,
    parameter integer COLS = `HWC_PE_CLUSTER_COLS,
    parameter integer IACT_CONFIG_WIDTH = `HWC_PE_CLUSTER_IACT_CONFIG_WIDTH,
    parameter integer MAX_CONFIG_WIDTH = `HWC_MAX_CONFIG_WIDTH,
    parameter integer IACT_ROUTER_CLUSTER_NUM_WIDTH = $clog2(`HWC_IACT_ROUTER_CLUSTER_NUM)
    )(
    
    input clk,
    input rstn, //active low reset
    input en, //enable for clock gating 
    // configs
    input [IACT_CONFIG_WIDTH - 1: 0]  PE_cluster_iact_config,
    input [COLS - 1: 0] PE_cluster_psum_config,
    input conf_en, conf_rst,
    //configuration inputs
    input [MAX_CONFIG_WIDTH - 1 : 0] filter_size, //filter size parameter config input = S
    input [`HWC_IACT_ADDR_SPAD_WIDTH - 1 : 0] input_channels_num, //C0
    input [MAX_CONFIG_WIDTH - 1 : 0] output_channels_num, //number of output channels = M0
    input [`HWC_IACT_ADDR_SPAD_WIDTH - 1 : 0] window_depth, //C0 * U
    input [`HWC_IACT_ADDR_SPAD_WIDTH - 1 : 0] iact_data_window_max_cnt, //max of iact data window counter 
    input [`HWC_WEIGHT_ADDR_SPAD_WIDTH - 1 : 0] window_segment_cnt, //C0 * U step counter
    
    `ifdef CLUSTER_SIM
        // IACT

        input [`HWC_PE_CLUSTER_IACT_ROUT_CONFIG_SET_SIZE_WIDTH - 1 : 0] iact_data_set_0,
        input iact_enables_0,
        input [`HWC_IACT_BUFFER_WIDTH - 1 : 0] iact_data_in_packed_0,
        output iact_readys_0,

        input [`HWC_PE_CLUSTER_IACT_ROUT_CONFIG_SET_SIZE_WIDTH - 1 : 0] iact_data_set_1,
        input iact_enables_1,
        input [`HWC_IACT_BUFFER_WIDTH - 1 : 0] iact_data_in_packed_1,
        output iact_readys_1,

        input [`HWC_PE_CLUSTER_IACT_ROUT_CONFIG_SET_SIZE_WIDTH - 1 : 0] iact_data_set_2,
        input iact_enables_2,
        input [`HWC_IACT_BUFFER_WIDTH - 1 : 0] iact_data_in_packed_2,
        output iact_readys_2,
        
        input [`HWC_PSUM_BUFFER_WIDTH * `HWC_SIMD - 1 : 0] psum_data_in_router_packed_0,
        input [`HWC_PSUM_BUFFER_WIDTH * `HWC_SIMD - 1 : 0] psum_data_in_router_packed_1,
        input [`HWC_PSUM_BUFFER_WIDTH * `HWC_SIMD - 1 : 0] psum_data_in_router_packed_2,
        input [`HWC_PSUM_BUFFER_WIDTH * `HWC_SIMD - 1 : 0] psum_data_in_router_packed_3,


        input  psum_router_enables_3,
        input  psum_router_enables_2,
        input  psum_router_enables_1,
        input  psum_router_enables_0,


        output  psum_in_router_readys_0,
        output  psum_in_router_readys_1,
        output  psum_in_router_readys_2,
        output  psum_in_router_readys_3,


        input psum_out_cluster_readys_3,
        input psum_out_cluster_readys_2,
        input psum_out_cluster_readys_1,
        input psum_out_cluster_readys_0,



        output [`HWC_PSUM_BUFFER_WIDTH * `HWC_SIMD - 1 : 0] psum_data_out_packed_3,
        output [`HWC_PSUM_BUFFER_WIDTH * `HWC_SIMD - 1 : 0] psum_data_out_packed_2,
        output [`HWC_PSUM_BUFFER_WIDTH * `HWC_SIMD - 1 : 0] psum_data_out_packed_1,
        output [`HWC_PSUM_BUFFER_WIDTH * `HWC_SIMD - 1 : 0] psum_data_out_packed_0,


        output psum_out_cluster_enables_3,
        output psum_out_cluster_enables_2,
        output psum_out_cluster_enables_1,
        output psum_out_cluster_enables_0,

        // weights
        
        input weight_enables_2,
        input weight_enables_1,
        input weight_enables_0,

        input [`HWC_WEIGHT_BUFFER_WIDTH - 1 : 0] weight_data_in_packed_2,
        input [`HWC_WEIGHT_BUFFER_WIDTH - 1 : 0] weight_data_in_packed_1,
        input [`HWC_WEIGHT_BUFFER_WIDTH - 1 : 0] weight_data_in_packed_0,

        output weight_readys_2,
        output weight_readys_1,
        output weight_readys_0

    `else
        // IACT
        input [`HWC_PE_CLUSTER_IACT_ROUT_CONFIG_SET_SIZE_WIDTH * `HWC_IACT_ROUTER_CLUSTER_NUM - 1 : 0] iact_data_set,
        input [`HWC_IACT_ROUTER_CLUSTER_NUM -1 : 0] iact_enables,
        input [`HWC_IACT_ROUTER_CLUSTER_NUM*`HWC_IACT_BUFFER_WIDTH - 1 : 0] iact_data_in_packed,
        output [`HWC_IACT_ROUTER_CLUSTER_NUM - 1 : 0] iact_readys,

        // PSUM

        input [`HWC_PE_CLUSTER_COLS * `HWC_PSUM_BUFFER_WIDTH * `HWC_SIMD - 1 : 0] psum_data_in_cluster_packed,
        input [`HWC_PSUM_ROUTER_CLUSTER_NUM * `HWC_PSUM_BUFFER_WIDTH * `HWC_SIMD - 1 : 0] psum_data_in_router_packed,

        input [`HWC_PE_CLUSTER_COLS - 1 : 0] psum_cluster_enables,
        input [`HWC_PE_CLUSTER_COLS - 1 : 0] psum_router_enables,

        output [`HWC_PE_CLUSTER_COLS - 1 : 0] psum_in_cluster_readys,
        output [`HWC_PE_CLUSTER_COLS - 1 : 0] psum_in_router_readys,

        output [`HWC_PE_CLUSTER_COLS - 1 : 0] psum_out_cluster_readys,
        output [`HWC_PE_CLUSTER_COLS * `HWC_PSUM_BUFFER_WIDTH * `HWC_SIMD - 1 : 0] psum_data_out_packed,
        input [`HWC_PE_CLUSTER_COLS - 1 : 0] psum_out_cluster_enables,


        // WEIGHT
        input [`HWC_WEIGHT_ROUTER_CLUSTER_NUM -1 : 0] weight_enables,
        input [`HWC_WEIGHT_BUFFER_WIDTH * `HWC_WEIGHT_ROUTER_CLUSTER_NUM - 1 : 0] weight_data_in_packed,
        output [`HWC_WEIGHT_ROUTER_CLUSTER_NUM -1 : 0] weight_readys

    `endif


);
`ifdef CLUSTER_SIM
    // IACT
    wire [`HWC_PE_CLUSTER_IACT_ROUT_CONFIG_SET_SIZE_WIDTH * `HWC_IACT_ROUTER_CLUSTER_NUM - 1 : 0] iact_data_set;

    wire [`HWC_IACT_ROUTER_CLUSTER_NUM -1 : 0] iact_enables;
    wire [`HWC_IACT_ROUTER_CLUSTER_NUM*`HWC_IACT_BUFFER_WIDTH - 1 : 0] iact_data_in_packed;
    wire [`HWC_IACT_ROUTER_CLUSTER_NUM - 1 : 0] iact_readys;

    // PSUM

        wire [`HWC_PE_CLUSTER_COLS * `HWC_PSUM_BUFFER_WIDTH * `HWC_SIMD - 1 : 0] psum_data_in_cluster_packed;
        wire [`HWC_PSUM_ROUTER_CLUSTER_NUM * `HWC_PSUM_BUFFER_WIDTH * `HWC_SIMD - 1 : 0] psum_data_in_router_packed;

        wire [`HWC_PE_CLUSTER_COLS - 1 : 0] psum_cluster_enables;
        wire [`HWC_PE_CLUSTER_COLS - 1 : 0] psum_router_enables;

        wire [`HWC_PE_CLUSTER_COLS - 1 : 0] psum_in_cluster_readys;
        wire [`HWC_PE_CLUSTER_COLS - 1 : 0] psum_in_router_readys;

        wire [`HWC_PE_CLUSTER_COLS - 1 : 0] psum_out_cluster_readys;
        wire [`HWC_PE_CLUSTER_COLS * `HWC_PSUM_BUFFER_WIDTH * `HWC_SIMD - 1 : 0] psum_data_out_packed;
        wire [`HWC_PE_CLUSTER_COLS - 1 : 0] psum_out_cluster_enables;

    // weight
        wire [`HWC_WEIGHT_ROUTER_CLUSTER_NUM -1 : 0] weight_enables;
        wire [`HWC_WEIGHT_BUFFER_WIDTH * `HWC_WEIGHT_ROUTER_CLUSTER_NUM - 1 : 0] weight_data_in_packed;
        wire [`HWC_WEIGHT_ROUTER_CLUSTER_NUM -1 : 0] weight_readys;



    // assigns
    assign psum_cluster_enables = 0;
    assign psum_data_in_cluster_packed = 0;
    //iacts
    assign iact_enables = {iact_enables_2, iact_enables_1, iact_enables_2};
    assign iact_data_in_packed = {iact_data_in_packed_2, iact_data_in_packed_1, iact_data_in_packed_0};
    assign {iact_readys_2, iact_readys_1, iact_readys_0} = iact_readys;
    assign iact_data_set = {iact_data_set_2, iact_data_set_1, iact_data_set_0};

    assign psum_data_in_router_packed = {psum_data_in_router_packed_3, psum_data_in_router_packed_2, psum_data_in_router_packed_1, psum_data_in_router_packed_0};
    assign psum_router_enables = {psum_router_enables_3, psum_router_enables_2, psum_router_enables_1, psum_router_enables_0};
    assign {psum_in_router_readys_3, psum_in_router_readys_2, psum_in_router_readys_1, psum_in_router_readys_0} = psum_in_router_readys;

    assign {psum_out_cluster_enables_3, psum_out_cluster_enables_2, psum_out_cluster_enables_1, psum_out_cluster_enables_0} = psum_out_cluster_enables;
    assign psum_out_cluster_readys = {psum_out_cluster_readys_3, psum_out_cluster_readys_2, psum_out_cluster_readys_1, psum_out_cluster_readys_0};
    assign {psum_data_out_packed_3,psum_data_out_packed_2,psum_data_out_packed_1,psum_data_out_packed_0} = psum_data_out_packed;


    // weights

    assign weight_enables = {weight_enables_2,weight_enables_1,weight_enables_0};
    assign {weight_readys_2, weight_readys_1, weight_readys_0} = weight_readys;
    assign weight_data_in_packed = {weight_data_in_packed_2, weight_data_in_packed_1, weight_data_in_packed_0};

`endif

wire [`HWC_PE_CLUSTER_ROWS * `HWC_PE_CLUSTER_COLS - 1 : 0] PE_iact_enables;
wire [`HWC_PE_CLUSTER_ROWS * `HWC_PE_CLUSTER_COLS - 1 : 0] PE_iact_readys;
wire [IACT_ROUTER_CLUSTER_NUM_WIDTH * `HWC_PE_CLUSTER_NUMS - 1 : 0] PE_iact_data_sel;

wire [`HWC_PSUM_BUFFER_WIDTH * `HWC_SIMD - 1 : 0] psum_ins[ROWS : 0][COLS-1 : 0];
wire psum_out_valids[ROWS : 0][COLS-1 : 0];
wire psum_in_readys[ROWS : 0][COLS-1 : 0];                
wire [COLS-1:0] PE_weight_readys [ROWS-1:0];
genvar row, col;
generate 
    for (col = 0; col < COLS; col = col + 1) begin
        // psum in 
        Mux #(.DATA_WIDTH( `HWC_PSUM_BUFFER_WIDTH * `HWC_SIMD), .DATA_NUM(2)) Mpsum (.data_in_packed({psum_data_in_router_packed[((col+1) * (`HWC_PSUM_BUFFER_WIDTH * `HWC_SIMD) - 1) -: (`HWC_PSUM_BUFFER_WIDTH * `HWC_SIMD)], psum_data_in_cluster_packed[((col+1) * (`HWC_PSUM_BUFFER_WIDTH * `HWC_SIMD) - 1) -: (`HWC_PSUM_BUFFER_WIDTH * `HWC_SIMD)]}), .sel(PE_cluster_psum_config[col]), .data_out(psum_ins[ROWS][col]));
        assign psum_out_valids[ROWS][col] = PE_cluster_psum_config[col] ? psum_router_enables[col] : psum_cluster_enables[col];
        assign psum_in_cluster_readys[col] = PE_cluster_psum_config[col] ? 1'b0 : psum_in_readys[ROWS][col];
        assign psum_in_router_readys[col] = PE_cluster_psum_config[col] ? psum_in_readys[ROWS][col] : 1'b0;

        assign psum_out_cluster_enables[col] = psum_out_valids[0][col]; // psum out readys
        assign psum_in_readys[0][col] = psum_out_cluster_readys[col]; // psum out enables
        assign psum_data_out_packed[((col+1)*`HWC_PSUM_BUFFER_WIDTH * `HWC_SIMD - 1) -: `HWC_PSUM_BUFFER_WIDTH * `HWC_SIMD] = psum_ins[0][col];

    end

    for(row = 0; row < ROWS; row = row + 1) begin

        assign weight_readys[row] = &PE_weight_readys[row];

        for (col = 0; col < COLS; col = col + 1) begin
            PE xx (
                    //inputs
                    .clk(clk),
                    .rstn(rstn), //active low reset
                    .en(en), //enable for clock gating
                    .iact_write_en(PE_iact_enables[row*COLS + col]), //enable/valid iact input data
                    .weight_write_en(weight_enables[row]), //enable/valid weight input data
                    .psum_write_en(psum_out_valids[row+1][col]), //enable/valid psum input data
                    .psum_out_read_en(psum_in_readys[row][col]), //enable psum out buffer read
                    
                    .data_iact_in(iact_data_in_packed[((PE_iact_data_sel[(((row*COLS + col + 1)*IACT_ROUTER_CLUSTER_NUM_WIDTH) - 1) -: IACT_ROUTER_CLUSTER_NUM_WIDTH] + 1) * `HWC_IACT_BUFFER_WIDTH - 1) -: `HWC_IACT_BUFFER_WIDTH ]) , //input iact data 

                    .data_weight_in(weight_data_in_packed[((`HWC_WEIGHT_BUFFER_WIDTH * (row+1)) - 1) -: `HWC_WEIGHT_BUFFER_WIDTH]), //input weight data

                    .data_psum_in_a( psum_ins[row + 1][col][`HWC_PSUM_BUFFER_WIDTH - 1 : 0]), //first input psum data
                    .data_psum_in_b(psum_ins[row + 1][col][2*`HWC_PSUM_BUFFER_WIDTH - 1 : `HWC_PSUM_BUFFER_WIDTH]), //second input psum data
                    //configuration inputs
                    .filter_size(filter_size), //filter size parameter config input = S
                    .input_channels_num(input_channels_num), //C0
                    .output_channels_num(output_channels_num), //number of output channels = M0
                    .window_depth(window_depth), //C0 * U
                    .window_segment_cnt(window_segment_cnt), //C0 * U step counter
                    //outputs
                    .iact_ready(PE_iact_readys[row*COLS + col]), //iact buffer is ready
                    .weight_ready(PE_weight_readys[row][col]), //weight buffer is ready
                    //output psum_result_done, //M0 calculated psums are stored in psum spad
                    .data_psum_out_a(psum_ins[row][col][`HWC_PSUM_BUFFER_WIDTH - 1 : 0]), //output psum data
                    .data_psum_out_b(psum_ins[row][col][2*`HWC_PSUM_BUFFER_WIDTH - 1 : `HWC_PSUM_BUFFER_WIDTH]), //output psum data
                    .psum_out_valid(psum_out_valids[row][col]), //valid output psum data
                    .psum_in_ready(psum_in_readys[row+1][col])
                );

        end
    end
endgenerate

PE_Cluster_Ctrl PE_CL_CTL(
    .clk(clk),
    .rstn(rstn),
    .conf_en(conf_en),
    .conf_rst(conf_rst),
    .en(en),
    .iact_enables(iact_enables),
    .iact_data_set(iact_data_set),
    .PE_iact_readys(PE_iact_readys),
    .iact_configs(PE_cluster_iact_config),
    .PE_iact_data_sel(PE_iact_data_sel),
    .PE_iact_enables(PE_iact_enables),
    .iact_readys(iact_readys)
);    


endmodule