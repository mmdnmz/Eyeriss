module PE #(
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
    parameter PSUM_PAR_READ = 4
) (
    //inputs
    input clk,
    input rstn, //active low reset
    input en, //enable for clock gating
    input iact_write_en, //enable/valid iact input data
    input weight_write_en, //enable/valid weight input data
    input psum_write_en, //enable/valid psum input data
    input psum_read_en, //enable read psum output
    input [IACT_BUFFER_WIDTH - 1 : 0] data_iact_in, //input iact data 
    input [WEIGHT_PAR_WRITE * WEIGHT_BUFFER_WIDTH - 1 : 0] data_weight_in, //input weight data
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
    //=============================================================
    // Local Parameters
    //=============================================================
    localparam IACT_SPAD_ADDR_WIDTH = $clog2(IACT_SPAD_DEPTH);
    localparam WEIGHT_SPAD_ADDR_WIDTH = $clog2(WEIGHT_SPAD_DEPTH);
    //=============================================================
    // Wires and Signals
    //=============================================================
    wire [IACT_BUFFER_WIDTH-1:0] iact_buffer_read_data;
    wire [WEIGHT_BUFFER_WIDTH-1:0] weight_buffer_read_data;
    wire [PSUM_BUFFER_WIDTH-1:0] psum_buffer_read_data;
    wire [16-1:0] psum_tomux, mux_toadder;
    wire iact_buffer_full, iact_buffer_empty;
    wire weight_buffer_full, weight_buffer_empty;
    wire psum_buffer_full, psum_buffer_empty;
    wire psum_out_buffer_full, psum_out_buffer_empty;
    wire iact_buffer_valid;
    wire weight_buffer_valid;
    wire psum_buffer_valid;
    wire iact_counter_en, iact_spad_controller_ready, iact_spad_controller_clear;
    wire w_counter_en, r_counter_en;

    wire rst_acc;


    wire mul_out_valid;


    wire weight_counter_en, weight_spad_controller_ready, weight_spad_controller_clear;
    wire pipe_en, pipe_en_reg;
    wire counter_clear;

    wire acc_input_sum_sel;

    wire [PSUM_SPAD_WIDTH - 1 : 0] reg_out_psum_dff;
    wire [PSUM_SPAD_WIDTH-1:0] psum_mux_out;
    wire [PSUM_SPAD_WIDTH - 1 : 0] reg_out_psum_mux;


    wire psum_write_cnt_en, psum_read_cnt_en;
    reg psum_write_cnt_en_reg;
    wire [PSUM_SPAD_WIDTH - 1 : 0] psum_write_cnt, psum_read_cnt;


    //============================================================
    // Test Signals
    //============================================================
    wire fourcount_cout, loc_en_disp_dut, read_addr_toggle;
    wire [1:0] fourcount_num;
    wire [4:0] psum_write_addr_fr, psum_read_addr_fr;

    //=============================================================
    // FIFO Buffer Instantiation
    //=============================================================
    Ifmap_fifo #(
        .DATA_WIDTH(IACT_BUFFER_WIDTH),
        .PAR_WRITE(1),
        .PAR_READ(1),
        .DEPTH(IACT_BUFFER_DEPTH)
    ) iact_fifo (
        .clk(clk),
        .rstn(rstn),
        .clear(!rstn),
        .read_en(iact_buffer_valid),
        .write_en(iact_write_en),
        .write_data(data_iact_in),
        .read_data(iact_buffer_read_data),
        .full(iact_buffer_full),
        .empty(iact_buffer_empty)
    );

    Fifo_buffer #(
        .DATA_WIDTH(WEIGHT_BUFFER_WIDTH),
        .PAR_WRITE(WEIGHT_PAR_WRITE),
        .PAR_READ(1),
        .DEPTH(WEIGHT_BUFFER_DEPTH)
    ) weight_fifo (
        .clk(clk),
        .rstn(rstn),
        .clear(!rstn),
        .read_en(weight_buffer_valid), // Always trying to read
        .write_en(weight_write_en),
        .write_data(data_weight_in),
        .read_data(weight_buffer_read_data),
        .full(weight_buffer_full),
        .empty(weight_buffer_empty)
    );

    Fifo_buffer #(
        .DATA_WIDTH(PSUM_BUFFER_WIDTH),
        .PAR_WRITE(PSUM_PAR_WRITE),
        .PAR_READ(1),
        .DEPTH(PSUM_IN_BUFFER_DEPTH)
    ) psum_fifo (
        .clk(clk),
        .rstn(rstn),
        .clear(!rstn),
        .read_en(psum_buffer_valid), // Always trying to read
        .write_en(psum_write_en),
        .write_data(data_psum_in),
        .read_data(psum_buffer_read_data),
        .full(psum_buffer_full),
        .empty(psum_buffer_empty)
    );

    //=============================================================
    // Buffer Controllers
    //=============================================================
    BufferController iact_buffer_ctrl (
        .clk(clk),
        .rstn(rstn),
        .en(en),
        .write_en(iact_write_en),
        .full(iact_buffer_full),
        .empty(iact_buffer_empty),
        .valid(iact_buffer_valid),
        .ready(iact_buffer_ready)
    );

    BufferController weight_buffer_ctrl (
        .clk(clk),
        .rstn(rstn),
        .en(en),
        .write_en(weight_write_en), // Note: Connecting weight_write_en to controller
        .full(weight_buffer_full),
        .empty(weight_buffer_empty),
        .valid(weight_buffer_valid),
        .ready(weight_buffer_ready)
    );

    
    BufferController psum_buffer_ctrl (
        .clk(clk),
        .rstn(rstn),
        .en(en),
        .write_en(psum_write_en), // Note: Connecting psum_write_en to controller
        .full(psum_buffer_full),
        .empty(psum_buffer_empty),
        .valid(psum_buffer_valid),
        .ready(psum_buffer_ready)
    );


    //=============================================================
    // Scratch Pads
    //=============================================================
    wire [IACT_SPAD_WIDTH - 1 : 0] ifmap_spad_read_data;
    wire [IACT_SPAD_ADDR_WIDTH - 1 : 0] ifmap_write_cout;
    wire [IACT_SPAD_ADDR_WIDTH - 1 : 0] ifmap_read_cout;

    ifmap_counter_nbit #(
        .MAX(IACT_SPAD_DEPTH),
        .WIDTH(IACT_SPAD_ADDR_WIDTH)
    ) ifmap_write_counter(
        .clk(clk),
        .rstn(rstn),
        .en(iact_counter_en),
        .clear(iact_spad_controller_clear),
        .count(ifmap_write_cout)
    );

    Counter #(
        .MAX(IACT_SPAD_DEPTH - 1),
        .WIDTH(IACT_SPAD_ADDR_WIDTH)
    ) ifmap_read_counter(
        .clk(clk),
        .rstn(rstn),
        .en(pipe_en),
        .clear(counter_clear),
        .count(ifmap_read_cout)
    );

    Reg_SPad_ifmap #(
        .DATA_WIDTH(IACT_SPAD_WIDTH),
        .NUM_REGS(IACT_SPAD_DEPTH)
    ) ifmap_spad (
        .clk(clk),
        .rstn(rstn),
        .en(1), //ignored
        .write_en(iact_counter_en),
        .read_addr(ifmap_read_cout),
        .write_addr(ifmap_write_cout),
        .write_data(iact_buffer_read_data),
        .read_data(ifmap_spad_read_data)
    );

    wire [WEIGHT_SPAD_WIDTH - 1 : 0] filter_spad_read_data;
    wire [WEIGHT_SPAD_ADDR_WIDTH - 1 : 0] filter_write_cout;
    wire [WEIGHT_SPAD_ADDR_WIDTH - 1 : 0] filter_read_cout;
    wire [WEIGHT_SPAD_ADDR_WIDTH - 1 : 0] psum_write_addr_count;

    Counter #(
        .MAX(WEIGHT_SPAD_DEPTH),
        .WIDTH(WEIGHT_SPAD_ADDR_WIDTH)
    ) filter_write_counter(
        .clk(clk),
        .rstn(rstn),
        .en(weight_counter_en),
        .clear(weight_spad_controller_clear),
        .count(filter_write_cout)
    );

    Custom_counter #(
        .WIDTH(WEIGHT_SPAD_ADDR_WIDTH)
    ) filter_read_counter(
        .clk(clk),
        .rstn(rstn),
        .en(pipe_en),
        .clear(counter_clear),
        .count(filter_read_cout),
        .max_count(filter_size),
        .step(1)
    );

    SRAM_SPad #(
        .DATA_WIDTH(WEIGHT_SPAD_WIDTH),
        .DEPTH(WEIGHT_SPAD_DEPTH)
    ) filter_spad (
        .clk(clk),
        .chip_en(en),
        .write_en(weight_counter_en),
        .write_addr(filter_write_cout),
        .read_addr(filter_read_cout),
        .write_data(weight_buffer_read_data),
        .read_data(filter_spad_read_data)
    );

    //=============================================================
    // SPad Controllers
    //=============================================================
    iact_SPadController #(
        .DATA_WIDTH(DATA_WIDTH),
        .MAX_CONFIG_WIDTH(MAX_CONFIG_WIDTH)
    ) iact_spad_controller (
        .clk(clk),
        .rstn(rstn),
        .en(en),
        .buffer_ready(iact_buffer_valid),
        .empty(iact_buffer_empty),
        .filter_size(filter_size),
        .counter_en(iact_counter_en),
        .ready(iact_spad_controller_ready),
        .clear(iact_spad_controller_clear)
    );

    SPadController #(
        .DATA_WIDTH(DATA_WIDTH)
    ) weight_spad_controller (
        .clk(clk),
        .rstn(rstn),
        .en(en),
        .buffer_ready(weight_buffer_valid),
        .empty(weight_buffer_empty),
        .counter_en(weight_counter_en),
        .ready(weight_spad_controller_ready),
        .clear(weight_spad_controller_clear)
    );
    
    //=============================================================
    // Zero Buffer
    //=============================================================
    wire zero_flag;
    //  wire [DATA_WIDTH - 1] ifmap_spad_read_data, filter_spad_read_data;

    Zero_buffer #(
        .DATA_WIDTH(DATA_WIDTH)
    ) zero_flag_buffer(
        .in_data_ifmap(ifmap_spad_read_data),
        .in_data_filter(filter_spad_read_data),
        .zero_buffer(zero_flag)
    );

    wire psum_zero_flag;

    Disabling_mech zero_energy_saver (
        .clk(clk),
        .rstn(rstn),
        .flag_in(zero_flag),
        .psum_dis(psum_zero_flag)
    );
    //=============================================================
    // Registers in pipeline 
    //=============================================================
    wire [IACT_SPAD_WIDTH-1:0] reg_iact_data;
    wire [WEIGHT_SPAD_WIDTH-1:0] reg_filter_data;
   
    DFF #(
        .DATA_WIDTH(IACT_SPAD_WIDTH)
    ) iact_data_reg (
        .clk(clk),
        .en(pipe_en && zero_flag),
        .rstn(rstn),
        .data_in(ifmap_spad_read_data),
        .data_out(reg_iact_data)
    );

    DFF #(
        .DATA_WIDTH(WEIGHT_SPAD_WIDTH)
    ) filter_data_reg (
        .clk(clk),
        .en((pipe_en && zero_flag)),
        .rstn(rstn),
        .data_in(filter_spad_read_data),
        .data_out(reg_filter_data)
    );

    //=============================================================
    // Multiplier Instantiation
    //=============================================================
    wire [DATA_WIDTH - 1 : 0] mult_data_out;
    Multiplier #(
        .INPUT_WIDTH(DATA_WIDTH),
        .OUTPUT_WIDTH(DATA_WIDTH)
    ) multiplier (
        .clk(clk),
        .en(pipe_en),
        .reset(rstn),
        .data_in_a(reg_iact_data),
        .data_in_b(reg_filter_data),
        .data_out(mult_data_out),
        .mul_out_valid(mul_out_valid)
    );

    //=============================================================
    // Mux2x1 Instantiation
    //=============================================================
    wire [PSUM_BUFFER_WIDTH-1:0] mux_data_out;
    Mux2x1 #(
        .DATA_WIDTH(PSUM_BUFFER_WIDTH)
    ) mux (
        .data_in_a(psum_buffer_read_data),
        .data_in_b(mult_data_out),
        .sel(~acc_input_sum_sel),
        .data_out(mux_data_out)
    );

    assign acc_input_sum_sel = psum_write_en;

    //=============================================================
    // Adder
    //=============================================================
    wire [DATA_WIDTH -1:0] sum_adder_out;

    FA #(.WIDTH(DATA_WIDTH)) adder_after_mux(
        .clk(clk),
        .en(pipe_en),
        .data_in_a(mux_data_out),
        .data_in_b(mux_toadder),
        .sum(sum_adder_out)
    );
     //=============================================================
    // PSUM Scratch Pad
    //==============================================================

    Counter #(
        .MAX(PSUM_SPAD_DEPTH),
        .WIDTH(PSUM_SPAD_WIDTH)
    ) psum_write_counter(
        .clk(clk),
        .rstn(rstn),
        .en(psum_write_cnt_en),
        .clear(counter_clear),
        .count(psum_write_cnt)
    );

    // filter_counter #(
    //     .MAX(3),
    //     .WIDTH(WEIGHT_SPAD_ADDR_WIDTH)
    // ) psum_write_addr_counter(
    //     .clk(clk),
    //     .rstn(rstn),
    //     .en(pipe_en),
    //     .clear(counter_clear),
    //     .count(psum_write_addr_count),
    //     .max_count(filter_size)
    // );


    Counter #(
        .MAX(PSUM_SPAD_DEPTH),
        .WIDTH(PSUM_SPAD_WIDTH)
    ) psum_read_counter(
        .clk(clk),
        .rstn(rstn),
        .en(psum_read_cnt_en),
        .clear(counter_clear),
        .count(psum_read_cnt)
    );



    psum_addr_counter #(.MAX_CONFIG_WIDTH(MAX_CONFIG_WIDTH))filter_ifmap_coordinator(
        .clk(clk),
        .rstn(rstn),
        .en(mul_out_valid),
        .clear(counter_clear),
        .filter_size(filter_size),
        .at_max(fourcount_cout),
        .count(fourcount_num),
        .loc_en_disp(loc_en_disp_dut),
        .read_addr_change(read_addr_toggle)
    );

    Custom_counter #(.WIDTH($clog2(PSUM_SPAD_DEPTH)))
     psum_writeaddr_coordinator(
        .clk(clk),
        .rstn(rstn),
        .en(read_addr_toggle),
        .clear(counter_clear),
        .count(psum_write_addr_fr),
        .max_count(filter_size - 1)
    );






    wire [PSUM_SPAD_WIDTH - 1 : 0] psum_spad_read_data;

    Reg_SPad #(
        .DATA_WIDTH(PSUM_SPAD_WIDTH),
        .NUM_REGS(PSUM_SPAD_DEPTH)
    ) psum_spad (
        .clk(clk),
        .rstn(rstn),
        .en(1), //ignored
//        .write_en(psum_write_cnt_en),
//        .write_en(mul_out_valid),
        .write_en(psum_zero_flag),
//        .read_addr(psum_read_cnt),
//        .write_addr(psum_write_cnt),
        .read_addr(psum_write_addr_fr),
        .write_addr(psum_write_addr_fr),
        .write_data(sum_adder_out),
        .read_data(psum_tomux)
    );
    
    //=============================================================
    // Psum mux and registers
    //=============================================================
    DFF #(
        .DATA_WIDTH(PSUM_SPAD_WIDTH)
    ) psum_reg_input (
        .clk(clk),
        .en(pipe_en),
        .rstn(rstn),
        .data_in(psum_spad_read_data),
        .data_out(reg_out_psum_dff)
    );
   
    Mux2x1 #(
        .DATA_WIDTH(PSUM_SPAD_WIDTH)
    ) mux_psum (
        .data_in_a(0),
        .data_in_b(psum_tomux),
        .sel(1'b1),
//        .sel(rst_acc),
        .data_out(mux_toadder)
    );

  
    DFF #(
        .DATA_WIDTH(PSUM_SPAD_WIDTH)
    ) psum_reg_output (
        .clk(clk),
        .en(pipe_en),
        .rstn(rstn),
        .data_in(psum_mux_out),
        .data_out(reg_out_psum_mux)
    );

    //=============================================================
    // Output Psum
    //=============================================================
    Fifo_buffer #(
        .DATA_WIDTH(PSUM_BUFFER_WIDTH),
        .PAR_WRITE(1),
        .PAR_READ(PSUM_PAR_READ),
        .DEPTH(PSUM_OUT_BUFFER_DEPTH)
    ) output_psum_fifo (
        .clk(clk),
        .rstn(rstn),
        .clear(!rstn),
        .read_en(psum_read_en), // Always trying to read
        .write_en(psum_write_cnt_en_reg),
        .write_data(reg_out_psum_mux),
        .read_data(data_psum_out),
        .full(psum_out_buffer_full),
        .empty(psum_out_buffer_empty)
    );

    PE_Controller  #(
        .MAX_CONFIG_WIDTH(MAX_CONFIG_WIDTH)
    ) pe_ctrl (
        .clk(clk),
        .rstn(rstn),
        .en(en),
        .iact_spad_ready(iact_spad_controller_ready),
        .weight_spad_ready(weight_spad_controller_ready),
        .filter_size(filter_size),

        .pipe_en(pipe_en),
        .pipe_en_reg(pipe_en_reg),
        .psum_write_cnt_en(psum_write_cnt_en),
        .counter_clear(counter_clear),
        .rst_acc(rst_acc)
    );

    always @(posedge clk) begin
        if (pipe_en)
            psum_write_cnt_en_reg <= psum_write_cnt_en;

        if (!rstn)
            psum_write_cnt_en_reg <= 0;
    end

    assign psum_read_cnt_en = psum_buffer_ready & (psum_read_cnt < psum_write_cnt);
    assign psum_out_valid = psum_buffer_valid;
    //=============================================================
    // Debug
    //=============================================================
    // always @(posedge clk) begin
    //     $display("===================================================");
    //     $display("---------------------------------------------------");

    //     $display("General Signals:");
    //     $display("  pipe_en: %b", pipe_en);
    //     $display("---------------------------------------------------");

    //     $display("Input Data:");
    //     $display("  data_iact_in: %0d", data_iact_in);
    //     $display("  data_weight_in: %0d", data_weight_in);
    //     $display("  data_psum_in: %0d", data_psum_in);
    //     $display("  iact_write_en: %b", iact_write_en);
    //     $display("  weight_write_en: %b", weight_write_en);
    //     $display("---------------------------------------------------");

    //     $display("Buffer States:");
    //     $display("  IACT Buffer:");
    //     $display("    Read Data: %0d", iact_buffer_read_data);
    //     $display("    Empty: %b", iact_buffer_empty);
    //     $display("    Full: %b", iact_buffer_full);
    //     $display("  Weight Buffer:");
    //     $display("    Read Data: %0d", weight_buffer_read_data);
    //     $display("    Empty: %b", weight_buffer_empty);
    //     $display("    Full: %b", weight_buffer_full);
    //     $display("---------------------------------------------------");

    //     $display("SPAD Controllers:");
    //     $display("  IACT SPAD:");
    //     $display("    Controller Ready: %b", iact_spad_controller_ready);
    //     $display("    Counter Enable: %b", iact_counter_en);
    //     $display("    Write Count: %0d", ifmap_write_cout);
    //     $display("    Read Count: %0d", ifmap_read_cout);
    //     $display("    Read Data: %0d", ifmap_spad_read_data);
    //     $display("  Weight SPAD:");
    //     $display("    Controller Ready: %b", weight_spad_controller_ready);
    //     $display("    Counter Enable: %b", weight_counter_en);
    //     $display("    Write Count: %0d", filter_write_cout);
    //     $display("    Read Count: %0d", filter_read_cout);
    //     $display("    Read Data: %0d", filter_spad_read_data);
    //     $display("---------------------------------------------------");

    //     $display("Registers:");
    //     $display("  IACT Register Data: %0d", reg_iact_data);
    //     $display("  Weight Register Data: %0d", reg_filter_data);
    //     $display("---------------------------------------------------");

    //     $display("Multiplier and PSum Outputs:");
    //     $display("  Multiplier Data Out: %0d", mult_data_out);
    //     $display("  PSUM Data Out: %0d", data_psum_out);
    //     $display("===================================================");
    // end

endmodule
