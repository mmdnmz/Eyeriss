// `include "../../src/hdl/PE.v"
// `include "../../src/hdl/Fifo_buffer.v"
// `include "../../src/hdl/BufferController.v"
// `include "../../src/hdl/SRAM_SPad.v"
// `include "../../src/hdl/SPadController.v"
// `include "../../src/hdl/Reg_SPad.v"
// `include "../../src/hdl/Multiplier.v"
// `include "../../src/hdl/Buffer.v"
// `include "../../src/hdl/counter.v"
// `include "../../src/hdl/mux2x1.v"
// `include "../../src/hdl/dff.v"
// `include "../../src/hdl/PE_Controller.v"

`timescale 1ns / 1ns

module PE_tb;
    // Parameters
    parameter MAX_CONFIG_WIDTH = 8;
    parameter DATA_WIDTH = 16;
    parameter IACT_SPAD_DEPTH = 12;
    parameter IACT_SPAD_WIDTH = 16;
    parameter WEIGHT_SPAD_DEPTH = 224;
    parameter WEIGHT_SPAD_WIDTH = 16;
    parameter PSUM_SPAD_DEPTH = 24;
    parameter PSUM_SPAD_WIDTH = 16;
    parameter IACT_BUFFER_DEPTH = 4;
    parameter IACT_BUFFER_WIDTH = 16;
    parameter WEIGHT_BUFFER_DEPTH = 8;
    parameter WEIGHT_BUFFER_WIDTH = 16;
    parameter WEIGHT_PAR_WRITE = 4;
    parameter PSUM_IN_BUFFER_DEPTH = 8;
    parameter PSUM_OUT_BUFFER_DEPTH = 8;
    parameter PSUM_BUFFER_WIDTH = 16;

    // Inputs
    reg clk;
    reg rstn;
    reg en;
    reg iact_write_en;
    reg weight_write_en;
    reg psum_read_en;
    reg psum_write_en;
    reg [IACT_BUFFER_WIDTH-1:0] data_iact_in;
    reg [WEIGHT_PAR_WRITE * WEIGHT_BUFFER_WIDTH-1:0] data_weight_in;
    reg [PSUM_BUFFER_WIDTH-1:0] data_psum_in;
    reg [MAX_CONFIG_WIDTH-1:0] input_channels_num;
    reg [MAX_CONFIG_WIDTH-1:0] output_channels_num;

    // Outputs
    wire [PSUM_BUFFER_WIDTH-1:0] data_psum_out;
    wire iact_buffer_ready;
    wire weight_buffer_ready;
    wire psum_out_valid;

    // Debug/Test
    reg [2:0] ready_phase;
    // Instantiate the PE module
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
    ) dut (
        .clk(clk),
        .rstn(rstn),
        .en(en),
        .iact_write_en(iact_write_en),
        .weight_write_en(weight_write_en),
        .psum_write_en(psum_write_en),
        .psum_read_en(psum_read_en),
        .data_iact_in(data_iact_in),
        .data_weight_in(data_weight_in),
        .data_psum_in(data_psum_in),
        .filter_size(4),
        .stride(1),
        .input_channels_num(input_channels_num),
        .output_channels_num(output_channels_num),
        .data_psum_out(data_psum_out),
        .iact_buffer_ready(iact_buffer_ready),
        .weight_buffer_ready(weight_buffer_ready),
        .psum_out_valid(psum_out_valid)
    );

    PEGRID GUT (
        .clk(clk),
        .rstn(rstn),
        .en(en),
        .iact_write_en(iact_write_en),
        .weight_write_en(weight_write_en),
        .psum_write_en(psum_write_en),
        .psum_read_en(psum_read_en),
        .data_iact_in({16'd4, 16'd3, 16'd2, 16'd1, 16'd0}),
        .data_weight_in({16'd2, 16'd1, 16'd0}),
        //.data_psum_in(data_psum_in),
        .filter_size(4),
        .stride(1),
        .input_channels_num(input_channels_num),
        .output_channels_num(output_channels_num),
        .data_psum_out(data_psum_out),
        .iact_buffer_ready(iact_buffer_ready),
        .weight_buffer_ready(weight_buffer_ready),
        .psum_out_valid(psum_out_valid)        
    );

    // Array_of_PEs #(
    //     .MAX_CONFIG_WIDTH(MAX_CONFIG_WIDTH),
    //     .DATA_WIDTH(DATA_WIDTH),
    //     .IACT_SPAD_DEPTH(IACT_SPAD_DEPTH),
    //     .IACT_SPAD_WIDTH(IACT_SPAD_WIDTH),
    //     .WEIGHT_SPAD_DEPTH(WEIGHT_SPAD_DEPTH),
    //     .WEIGHT_SPAD_WIDTH(WEIGHT_SPAD_WIDTH),
    //     .PSUM_SPAD_DEPTH(PSUM_SPAD_DEPTH),
    //     .PSUM_SPAD_WIDTH(PSUM_SPAD_WIDTH),
    //     .IACT_BUFFER_DEPTH(IACT_BUFFER_DEPTH),
    //     .IACT_BUFFER_WIDTH(IACT_BUFFER_WIDTH),
    //     .WEIGHT_BUFFER_DEPTH(WEIGHT_BUFFER_DEPTH),
    //     .WEIGHT_BUFFER_WIDTH(WEIGHT_BUFFER_WIDTH),
    //     .WEIGHT_PAR_WRITE(WEIGHT_PAR_WRITE),
    //     .PSUM_IN_BUFFER_DEPTH(PSUM_IN_BUFFER_DEPTH),
    //     .PSUM_OUT_BUFFER_DEPTH(PSUM_OUT_BUFFER_DEPTH),
    //     .PSUM_BUFFER_WIDTH(PSUM_BUFFER_WIDTH)
    // ) AUT (
    //     .clk(clk),
    //     .rstn(rstn),
    //     .en(en),
    //     .iact_write_en(iact_write_en),
    //     .weight_write_en(weight_write_en),
    //     .psum_write_en(psum_write_en),
    //     .psum_read_en(psum_read_en),
    //     .data_iact_in(data_iact_in),
    //     .data_weight_in(data_weight_in),
    //     .data_psum_in(data_psum_in),
    //     .input_channels_num(input_channels_num),
    //     .output_channels_num(output_channels_num),
    //     .data_psum_out(data_psum_out),
    //     .iact_buffer_ready(iact_buffer_ready),
    //     .weight_buffer_ready(weight_buffer_ready),
    //     .psum_out_valid(psum_out_valid)
    // );

//      PE_Array  pe_inst (
//             .clk(clk),
//             .rstn(rstn),
//             .en(en),
//             .iact_write_en(iact_write_en),
//             .weight_write_en(weight_write_en),
//             .psum_write_en(psum_write_en),
//             .psum_read_en(psum_read_en),
//             .data_iact_in_grid(data_iact_in_grid ) ,
//             .data_weight_in_grid(data_weight_in_grid),
//             .data_psum_in_grid(data_psum_in_grid ) ,
//             .filter_size(filter_size),
//             .stride(stride),
//             .input_channels_num(input_channels_num),
//             .output_channels_num(output_channels_num)
//             // .data_psum_out_grid(data_psum_out_grid),
//             // .iact_buffer_ready(iact_buffer_ready),
//             // .weight_buffer_ready(weight_buffer_ready),
//             // .psum_out_valid(psum_out_valid)
// );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rstn = 0;
        en = 0;
        iact_write_en = 0;
        weight_write_en = 0;
        data_iact_in = 0;
        data_weight_in = 0;
        data_psum_in = 0;
        input_channels_num = 3;
        output_channels_num = 3;
        psum_write_en = 0; // always select mult_data_out
        psum_read_en = 0;

        #10;
        rstn = 1;
        en = 1;
    end

    initial begin
        #10;
        do begin
            #10;
        end while(!iact_buffer_ready);

        iact_write_en = 1;
        data_iact_in = 16'd5;
        
         do begin
            #10;
            iact_write_en = iact_buffer_ready;
        end while(!iact_buffer_ready);

        iact_write_en = 1;
        data_iact_in = 16'd7;
        
        do begin
            #10;
            iact_write_en = iact_buffer_ready;
        end while(!iact_buffer_ready);

        iact_write_en = 1;
        data_iact_in = 16'd13;

        do begin
            #10;
            iact_write_en = iact_buffer_ready;
        end while(!iact_buffer_ready);

        iact_write_en = 1;
        data_iact_in = 16'd1;

        #10;
        iact_write_en = 0;

        #10;
        do begin
            #10;
        end while(!iact_buffer_ready);

        iact_write_en = 1;
        data_iact_in = 16'd5;
        
         do begin
            #10;
            iact_write_en = iact_buffer_ready;
        end while(!iact_buffer_ready);

        iact_write_en = 1;
        data_iact_in = 16'd6;
        
        do begin
            #10;
            iact_write_en = iact_buffer_ready;
        end while(!iact_buffer_ready);

        iact_write_en = 1;
        data_iact_in = 16'd18;

        do begin
            #10;
            iact_write_en = iact_buffer_ready;
        end while(!iact_buffer_ready);

        iact_write_en = 1;
        data_iact_in = 16'd3;

        #10;
        iact_write_en = 0;
        #10;
        do begin
            #10;
        end while(!iact_buffer_ready);

        iact_write_en = 1;
        data_iact_in = 16'd4;
        
         do begin
            #10;
            iact_write_en = iact_buffer_ready;
        end while(!iact_buffer_ready);

        iact_write_en = 1;
        data_iact_in = 16'd5;
        
        do begin
            #10;
            iact_write_en = iact_buffer_ready;
        end while(!iact_buffer_ready);

        iact_write_en = 1;
        data_iact_in = 16'd18;

        do begin
            #10;
            iact_write_en = iact_buffer_ready;
        end while(!iact_buffer_ready);

        iact_write_en = 1;
        data_iact_in = 16'd5;

        #10;
        iact_write_en = 0;

        #200;

        $display("data_psum_out: .%h", data_psum_out);
        $display("psum_out_valid: %b", psum_out_valid);

        
        $finish;
    end

    initial begin
        #10;

        do begin
            #10;
            ready_phase = 3'd1;
        end while(!weight_buffer_ready);

        // #10; //for fun
        ready_phase = 3'd2;
        weight_write_en = 1;
        data_weight_in = {16'd1, 16'd0, 16'd4, 16'd9};
        
         do begin
            #10;
            weight_write_en = weight_buffer_ready;
            ready_phase = 3'd3;
        end while(!weight_buffer_ready);

        weight_write_en = 1;
        data_weight_in = {16'd2, 16'd3, 16'd7, 16'd8};
        ready_phase = 3'd4;
        #10;
        weight_write_en = 0;

        #200;

        $display("data_psum_out: %h", data_psum_out);
        $display("psum_out_valid: %b", psum_out_valid);

        #200;
        $finish;
    end

    initial begin
        #150;

        psum_read_en = 1;

        // #20;

        // psum_read_en = 0;
    end

    initial begin
        // Monitor key signals
        $monitor("Time: %0t | data_psum_out: %h | psum_out_valid: %b | iact_buffer_ready: %b | weight_buffer_ready: %b", 
                 $time, data_psum_out, psum_out_valid, iact_buffer_ready, weight_buffer_ready);

    end

endmodule
