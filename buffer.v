`define SIMULATION // Comment this out for synthesis

module Buffer #(
    parameter DATA_WIDTH = 16,
    parameter DEPTH = 4,
    parameter PAR_WRITE = 1,
    parameter PAR_READ = 1,
    parameter ADDR_WIDTH = $clog2(DEPTH)
) (
    input clk,
    input write_en,
    input [ADDR_WIDTH - 1 : 0] write_addr,
    input [ADDR_WIDTH - 1 : 0] read_addr,
    input [PAR_WRITE * DATA_WIDTH - 1 : 0] write_data,
    output [PAR_READ * DATA_WIDTH - 1 : 0] read_data
);
    reg [DATA_WIDTH - 1 : 0] memory [0 : DEPTH - 1];
    
    reg [$clog2(PAR_WRITE) : 0] par_cnt;
    always @(posedge clk) begin
        if (write_en) begin
            for(par_cnt = 0; par_cnt < PAR_WRITE; par_cnt = par_cnt + 1)
                memory[write_addr + par_cnt] <= write_data[par_cnt * DATA_WIDTH +: DATA_WIDTH];
        end
    end

    genvar i;
    generate
        for (i = 0; i < PAR_READ; i = i + 1) begin
            wire [ADDR_WIDTH - 1 : 0] ind = read_addr + i;
            assign read_data[i * DATA_WIDTH +: DATA_WIDTH] = memory[ind];
        end
    endgenerate

    `ifdef SIMULATION
    integer c;
    initial begin
        for (c = 0; c < DEPTH; c = c + 1)
            memory[c] = 0;
    end
`endif
        
endmodule