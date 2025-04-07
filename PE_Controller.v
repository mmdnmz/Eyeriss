module PE_Controller #(
    parameter integer MAX_CONFIG_WIDTH = 5
) (
    input wire clk,
    input wire rstn,
    input en,
    input wire iact_spad_ready,
    input wire weight_spad_ready,
    input [MAX_CONFIG_WIDTH - 1 : 0] filter_size,

    output reg pipe_en,
    output reg pipe_en_reg,
    output reg psum_write_cnt_en,
    output reg counter_clear,
    output reg rst_acc
);
    localparam S_IDLE = 0, S_READY = 1, S_IACT_READY = 2, S_WEIGHT_READY = 3, S_PSUM_NEXT = 4;

    reg [2:0] ps, ns;

    reg [MAX_CONFIG_WIDTH - 1 : 0] result_cnt;

    reg pipe_en_p2, pipe_en_p3;

    wire psum_result_ready;

    assign psum_result_ready = result_cnt == filter_size;

    always @(*) begin
        ns = S_IDLE;
        pipe_en = 0;
        counter_clear = 1'b0;
        psum_write_cnt_en = 0;
        rst_acc = 0;
        case (ps)
            S_IDLE: begin
                counter_clear = 1'b1;
                if (iact_spad_ready)
                    ns = weight_spad_ready ? S_READY : S_IACT_READY;
                if (weight_spad_ready)
                    ns = iact_spad_ready ? S_READY : S_WEIGHT_READY;
                end
            S_IACT_READY: begin
                ns = weight_spad_ready ? S_READY : S_IACT_READY;
            end
            S_WEIGHT_READY: begin
                ns = iact_spad_ready ? S_READY : S_WEIGHT_READY;
            end
            S_READY: begin
                rst_acc = 1;
                pipe_en = 1;
                
                ns = S_READY;

                if (psum_result_ready)
                    ns = S_PSUM_NEXT;
            end
            S_PSUM_NEXT: begin
                psum_write_cnt_en = 1;
                pipe_en = 1;
                ns = S_READY;
            end
        endcase
    end

    always @(posedge clk) begin
        if (pipe_en_p3)
            result_cnt <= result_cnt + 1;

        if (psum_result_ready) begin
            result_cnt <= 0;
        end

        if (!rstn) begin
            ps <= S_IDLE;
            result_cnt <= 0;
        end else if (en)
            ps <= ns;
    end

    always @(posedge clk) begin
        if (en) begin
            pipe_en_reg <= pipe_en;
            pipe_en_p2 <= pipe_en_reg;
            pipe_en_p3 <= pipe_en_p2;
        end

        if (!rstn) begin
            pipe_en_reg <= 0;
            pipe_en_p2 <= 0;
            pipe_en_p3 <= 0;
        end
    end

endmodule
