module psum_controller (
    input clk,
    input rstn, // Active low reset
    input ready,
    output reg w_counter_en, r_counter_en,
    output reg clear
);

    // State encoding
    localparam S_IDLE = 2'b00;
    localparam S_WRITE = 2'b01;
    localparam S_READ = 2'b10;

    reg [1:0] current_state, next_state;

    // State transition logic
    always @(posedge clk or negedge rstn) begin
        if (!rstn)
            current_state <= S_IDLE;
        else
            current_state <= next_state;
    end

    // Next state and output logic
    always @(*) begin
        // Default values
        next_state = S_IDLE;
        clear = 0;

        case (current_state)
            S_IDLE: begin
                w_counter_en = 1'b0;
                r_counter_en = 1'b0;
                if (ready) begin
                    next_state = S_WRITE;
                end
                clear = 1'b1;
            end

            S_WRITE: begin
                // w_counter_en = ready;
                // if (ready) begin
                //     next_state = S_READ;
                // end
            end

            S_READ: begin
               // r_counter_en = 1'b1;
            end
        endcase
    end

endmodule
