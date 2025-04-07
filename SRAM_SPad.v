module SRAM_SPad #(
    parameter integer DATA_WIDTH = 24, //data bitwidth
    parameter integer DEPTH = 96, //total size
    parameter integer ADDR_WIDTH = $clog2(DEPTH) //address bitwidth
) (
    input clk,
    input chip_en, //chip enable
    input write_en, //write enable
    input [ADDR_WIDTH - 1 : 0] write_addr, //write address
    input [ADDR_WIDTH - 1 : 0] read_addr, //write address
    input [DATA_WIDTH - 1 : 0] write_data, //input data to write into the SRAM
    output [DATA_WIDTH - 1 : 0] read_data //output data to read from the SRAM
);

//allocated memory
reg [DATA_WIDTH - 1 : 0] mem [0 : DEPTH - 1];

//read/write at one clock, on chip enable
always @(posedge clk) begin
    if (chip_en) begin
        if (write_en) begin
            mem[write_addr] <= write_data;
        end 
    end
end
assign read_data = mem[read_addr];

endmodule