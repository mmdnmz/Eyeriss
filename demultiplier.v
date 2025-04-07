module DEMultiplier #(
    parameter INPUT_WIDTH = 16,
    parameter OUTPUT_WIDTH = INPUT_WIDTH * 2
)
(
    input clk,
    input reset,
    input en,
    input den,
    input [INPUT_WIDTH - 1 : 0] data_in_a,
    input [INPUT_WIDTH - 1 : 0] data_in_b,
    output [OUTPUT_WIDTH - 1 : 0] data_out,
    output mul_out_valid
);
    // Internal registers for pipelining
    reg [INPUT_WIDTH - 1 : 0] a_reg1, a_reg2;
    reg [INPUT_WIDTH - 1 : 0] b_reg1, b_reg2;
    reg [OUTPUT_WIDTH - 1 : 0] partial_product1, partial_product2;
    reg [1:0] mul_ready;
    reg mul_valid = 1'b0;

    // Stage 1: Capture inputs and compute lower half partial product
    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            a_reg1 <= 0;
            b_reg1 <= 0;
            partial_product1 <= 0;
        end else if (~den) begin
            a_reg1 <= data_in_a;
            b_reg1 <= data_in_b;
            partial_product1 <= data_in_a * data_in_b[INPUT_WIDTH/2-1:0]; // Lower half multiplication
        end
    end

    // Stage 2: Compute upper half partial product and aggregate results
    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            a_reg2 <= 0;
            b_reg2 <= 0;
            partial_product2 <= 0;
        end else if (~den) begin
            a_reg2 <= a_reg1;
            b_reg2 <= b_reg1;
            partial_product2 <= a_reg1 * b_reg1[INPUT_WIDTH-1:INPUT_WIDTH/2]; // Upper half multiplication
        end
    end
    
    reg [OUTPUT_WIDTH - 1 : 0] result_reg;
    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            result_reg <= 0;
        end else if (~den) begin
            result_reg <= partial_product1 + (partial_product2 << (INPUT_WIDTH/2)); // Combine partial products
        end
    end

    assign data_out = result_reg;

    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            mul_ready = 2'b00;
        end
        else if (~den) begin
            mul_ready = mul_ready + 1'b1 ;
        end
        if (mul_ready == 2'b11) begin
            mul_valid = mul_valid + 1'b1;
        end
    end

assign mul_out_valid = mul_valid;

endmodule

/*
module Multiplier #(
    parameter INPUT_WIDTH = 16,
    parameter OUTPUT_WIDTH = INPUT_WIDTH * 2
)
(
    input clk,
    input ~den,
    input [INPUT_WIDTH - 1 : 0] data_in_a,
    input [INPUT_WIDTH - 1 : 0] data_in_b,
    output [OUTPUT_WIDTH - 1 : 0] data_out
);
    // Internal registers for pipelining
    reg [INPUT_WIDTH-1 : 0] a_reg, b_reg;
    reg [OUTPUT_WIDTH - 1 : 0] pdt_reg1, pdt_reg2;
    
    // Stage 1: Multiply data_in_a and data_in_b
    always @(posedge clk) begin
        if (~den) begin
            a_reg <= data_in_a;
            b_reg <= data_in_b;
            pdt_reg1 <= a_reg * b_reg;
        end
    end
    
    // Stage 2: Pipeline register to hold the result
    always @(posedge clk) begin
        if (~den)
            pdt_reg2 <= pdt_reg1;
    end
    
    // Output the pipelined result
    assign data_out = pdt_reg2;
endmodule
*/
