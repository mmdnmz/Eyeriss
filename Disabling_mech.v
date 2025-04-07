`timescale 1ns / 1ns

module Disabling_mech 
(
    input clk,
    //input en,       // Enable
    input rstn,     // Active low reset
    //input clear, //clear counter
    //output at_max,  // Counter finish signal
    input flag_in,     // Current counter output value
    output reg psum_dis, mult_dis, reg_iact_dis, reg_filter_dis // Previous value of counter
    
);
    reg stage_a, stage_b, stage_c ; 
always @(posedge clk) begin
    if (!rstn) begin // Reset
        psum_dis <= 1'b0;
    end
    else if (rstn) begin
        stage_a <= flag_in;
        stage_b <= stage_a;
        psum_dis <= stage_b;
        stage_c <= stage_b;
    end
end

endmodule