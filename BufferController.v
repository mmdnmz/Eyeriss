module BufferController(
    input clk,
    input rstn, // Active low reset
    input en, //enable for starting controller fsm
    input write_en, // Enable/valid iact input data
    input full, // Input signal indicating FIFO is full
    input empty, // Input signal indicating FIFO is empty
    output reg valid, // Output signal indicating if buffer has valid data
    output reg ready
);

    // State encoding
    localparam S_IDLE = 2'b00;
    localparam S_WRITE_BUFFER = 2'b01;
    localparam S_FULL = 2'b10;

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

        case (current_state)
            S_IDLE: begin
                if (write_en) begin
                    next_state = S_WRITE_BUFFER;
                end
                ready = 1;
                valid = 0;
            end

            S_WRITE_BUFFER: begin
                if (full) begin
                    next_state = S_FULL;
                end else if (!write_en) begin
                    next_state = S_IDLE;
                end else begin
                    next_state = S_WRITE_BUFFER;
                end
                ready = 1;
                valid = 1;
            end

            S_FULL: begin
                if (!(full | empty) && write_en) begin
                    next_state = S_WRITE_BUFFER;
                end else if (empty) begin
                    next_state = S_IDLE;
                end else begin
                    next_state = S_FULL;
                end
                ready = 0;
                valid = 1;
            end
        endcase
    end

endmodule
