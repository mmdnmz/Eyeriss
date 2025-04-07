module iact_SPadController #(
    parameter DATA_WIDTH = 16,
    parameter MAX_CONFIG_WIDTH = 5
) (
    input clk,
    input rstn, // Active low reset
    input en,
    input buffer_ready,
    input empty, // Input signal indicating FIFO is empty
    input [MAX_CONFIG_WIDTH - 1 : 0] filter_size,
    output reg counter_en,
/*    output reg readytest,*/
    output reg ready,
    output reg clear
);

    // State encoding
    localparam S_IDLE = 2'b00;
    localparam S_START = 2'b01;
    localparam S_WRITE_SPAD = 2'b10;
    localparam S_WRITE_SPAD2 = 2'b11;

    reg [1:0] current_state, next_state;

    reg [MAX_CONFIG_WIDTH - 1 : 0] filter_cnt;

    // State transition logic
    always @(posedge clk or negedge rstn) begin
        if (buffer_ready)
            filter_cnt <= filter_cnt + 1;

        if (ready)
            filter_cnt <= 0;

        if(en)
            current_state <= next_state;

        if (!rstn) begin
            current_state <= S_IDLE;
            filter_cnt <= 0;
        end
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
                clear = 0;
            end

            S_START: begin
                if (!empty) begin
                    next_state = S_WRITE_SPAD;
                    if (filter_cnt >= filter_size - 1)
                        next_state = S_WRITE_SPAD2;
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
                    if (filter_cnt >= filter_size - 1)
                        next_state = S_WRITE_SPAD2;
                end
                counter_en = !empty;
                ready = 0;
            end
            S_WRITE_SPAD2: begin
                if (!buffer_ready)
                    next_state = S_IDLE;
                else if (empty) begin
                    next_state = S_START;
                end else if (!empty) begin
                    next_state = S_WRITE_SPAD2;
                end
                counter_en = !empty;
                ready <= 1'b1;
            end
        endcase
    end

endmodule
