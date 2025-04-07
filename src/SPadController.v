module SPadController #(
    parameter DATA_WIDTH = 16
) (
    input clk,
    input rstn, // Active low reset
    input en,
    input buffer_ready,
    input empty, // Input signal indicating FIFO is empty
    output reg counter_en,
    output reg ready,
    output reg clear
);

    // State encoding
    localparam S_IDLE = 2'b00;
    localparam S_START = 2'b01;
    localparam S_WRITE_SPAD = 2'b10;

    reg [1:0] current_state, next_state;

    // State transition logic
    always @(posedge clk or negedge rstn) begin
        if (!rstn)
            current_state <= S_IDLE;
        else if (en)
            current_state <= next_state;
    end

    // Next state and output logic
    always @(*) begin
        // Default values
        next_state = S_IDLE;
        ready = 0;
        clear = 0;

        case (current_state)
            S_IDLE: begin
                if (buffer_ready) begin
                    next_state = S_START;
                end
                counter_en = buffer_ready;
                ready = 0;
                clear = !buffer_ready;
            end

            S_START: begin
                next_state = S_START;
                if (!empty) begin
                    next_state = S_WRITE_SPAD;
                end
                counter_en = 1;
                ready = 0;
            end

            S_WRITE_SPAD: begin
                if (!buffer_ready)
                    next_state = S_IDLE;
                else if (empty) begin
                    next_state = S_START;
                end else if (!empty) begin
                    next_state = S_WRITE_SPAD;
                end
                counter_en = !empty;
                ready = 1;
            end
        endcase
    end

endmodule
