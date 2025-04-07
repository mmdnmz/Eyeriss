module Fifo_buffer #(
    parameter DATA_WIDTH = 16, //data bitwidth
    parameter PAR_WRITE = 1,
    parameter PAR_READ = 1,
    parameter DEPTH = 4 //total size
) (
    input clk,
    input rstn, //active low reset
    input clear, //clear buffer counters
    input read_en, //read enable 
    input write_en, //write enable
    input [PAR_WRITE * DATA_WIDTH - 1 : 0] write_data, //input data to write into the buffer
    output [PAR_READ * DATA_WIDTH - 1 : 0] read_data, //output data to read from the buffer
    output full, //output to signal if buffer is full
    output empty //output to signal if buffer is empty
);

//for cicular buffer, consider one more register as one is always unused
localparam BUFFER_DEPTH = DEPTH + 1;
localparam BUFFER_ADDR_WIDTH = $clog2(BUFFER_DEPTH);
localparam PAR_DATA_WRITE = PAR_WRITE == 1 ? PAR_WRITE : PAR_WRITE - 1;
localparam PAR_DATA_READ = PAR_READ == 1 ? PAR_READ : PAR_READ - 1;

reg [BUFFER_ADDR_WIDTH - 1 : 0] read_addr_cnt, write_addr_cnt;
wire buffer_write_en, buffer_read_en;
wire at_max_write, at_max_read;


assign buffer_write_en = write_en & !full;
assign buffer_read_en = read_en & !empty;

assign at_max_write = write_addr_cnt >= DEPTH;
assign at_max_read = read_addr_cnt >= DEPTH;

wire [PAR_DATA_WRITE - 1 : 0] full_conditions;
wire [PAR_DATA_READ - 1 : 0] empty_conditions;

genvar k;
generate
    for (k = 0; k < PAR_DATA_WRITE; k = k + 1) begin : FULL_COND_GEN
        wire [BUFFER_ADDR_WIDTH-1:0] write_addr_cnt_next = write_addr_cnt + (k+1);
        assign full_conditions[k] = at_max_write ? (k+1) == read_addr_cnt : write_addr_cnt_next == read_addr_cnt;
    end
endgenerate

genvar r;
generate
    for (r = 0; r < PAR_DATA_READ; r = r + 1) begin : EMPTY_COND_GEN
        wire [BUFFER_ADDR_WIDTH - 1 : 0] read_addr_cnt_next = read_addr_cnt + r;
        assign empty_conditions[r] = at_max_read ? r == write_addr_cnt : read_addr_cnt_next == write_addr_cnt;
    end
endgenerate

assign full = |full_conditions;
assign empty = |empty_conditions;

Buffer #(
    .DATA_WIDTH(DATA_WIDTH),
    .PAR_WRITE(PAR_WRITE),
    .PAR_READ(PAR_READ),
    .DEPTH(BUFFER_DEPTH),
    .ADDR_WIDTH(BUFFER_ADDR_WIDTH)
) buffer (
    .clk(clk),
    .write_en(buffer_write_en),
    .write_addr(write_addr_cnt),
    .read_addr(read_addr_cnt),
    .write_data(write_data),
    .read_data(read_data)
);

always @(posedge clk) begin
    if (!rstn) begin
        read_addr_cnt <= 0;
        write_addr_cnt <= 0;
    end
    else if (clear) begin
        read_addr_cnt <= 0;
        write_addr_cnt <= 0;
    end
    else begin
        if (at_max_write)
            write_addr_cnt <= 0;
        else if (buffer_write_en)
            write_addr_cnt <= write_addr_cnt + PAR_WRITE;

        if (at_max_read)
            read_addr_cnt <= 0;
        else if (buffer_read_en)
            read_addr_cnt <= read_addr_cnt + PAR_READ;
    end
end

endmodule
