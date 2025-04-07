//register array scratch pad single port module. read/write at 1 clock
module Reg_SPad_ifmap #(
    parameter DATA_WIDTH = 16, //data bit width
    parameter NUM_REGS = 16, //number of registers
    parameter ADDR_WIDTH = $clog2(NUM_REGS)
) (
    input clk,
    input rstn, //active low reset
    input en, //enable
    input write_en, //write enable
    input [ADDR_WIDTH - 1 : 0] read_addr,     // address to read from
    input [ADDR_WIDTH - 1 : 0] write_addr,     // address to write into
    input [DATA_WIDTH - 1 : 0] write_data,     //write data port
    output [DATA_WIDTH - 1 : 0] read_data //read data port
);
 
//register array
reg [DATA_WIDTH - 1 : 0] regs [0 : NUM_REGS - 1];
//array counter
reg [$clog2(NUM_REGS) : 0] counter = 0;

always @(posedge clk) begin
    if (!rstn) begin
        for (counter = 0; counter < NUM_REGS; counter = counter + 1)
            regs[counter] <= 0;
    end
    else if (write_en) begin
        regs[write_addr] <= write_data;
        

    end 
end
assign read_data = regs[read_addr];
endmodule