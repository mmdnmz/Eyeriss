`include "hw_config.vh"

module PE_Cluster_Ctrl #(
    parameter integer IACT_ROUTER_CLUSTER_NUM_WIDTH = $clog2(`HWC_IACT_ROUTER_CLUSTER_NUM)
)

(
    input clk,
    input rstn,
    input en,
    input conf_en, conf_rst,
    input [`HWC_IACT_ROUTER_CLUSTER_NUM - 1 : 0] iact_enables,
    input [`HWC_PE_CLUSTER_IACT_ROUT_CONFIG_SET_SIZE_WIDTH * `HWC_IACT_ROUTER_CLUSTER_NUM - 1 : 0] iact_data_set,

    input [`HWC_PE_CLUSTER_ROWS * `HWC_PE_CLUSTER_COLS - 1 : 0] PE_iact_readys,

    input [`HWC_PE_CLUSTER_IACT_CONFIG_WIDTH - 1 : 0] iact_configs,
    
    output reg [`HWC_PE_CLUSTER_ROWS * `HWC_PE_CLUSTER_COLS - 1 : 0] PE_iact_enables,
    output reg [IACT_ROUTER_CLUSTER_NUM_WIDTH * `HWC_PE_CLUSTER_NUMS - 1 : 0] PE_iact_data_sel,
    output reg [`HWC_IACT_ROUTER_CLUSTER_NUM - 1 : 0] iact_readys    
);
localparam integer ROUTERS = `HWC_IACT_ROUTER_CLUSTER_NUM;
localparam integer SETS = `HWC_PE_CLUSTER_IACT_ROUT_CONFIG_SET_SIZE;
localparam integer SET_INDEX = `HWC_PE_CLUSTER_ROWS;
localparam integer PE_ADDR_WIDTH = $clog2(`HWC_PE_CLUSTER_ROWS) + $clog2(`HWC_PE_CLUSTER_COLS);
localparam integer ROUT_CONFIG = `HWC_PE_CLUSTER_IACT_ROUT_CONFIG_WIDTH;
localparam integer TOTAL_ITER = ROUTERS * SETS * SET_INDEX;
localparam integer SETS_WIDTH = $clog2(SETS);
localparam integer ROUTERS_WIDTH = $clog2(ROUTERS);
localparam integer SET_INDEX_WIDTH = $clog2(SET_INDEX);

reg [PE_ADDR_WIDTH : 0] R_confs[ROUTERS-1 :0][SETS-1 :0][SET_INDEX-1 : 0];

reg [SETS_WIDTH : 0]  s2;
reg [ROUTERS_WIDTH : 0]  r2;
reg [SET_INDEX_WIDTH : 0]  iv, i2;
reg [$clog2(`HWC_IACT_ROUTER_CLUSTER_NUM) : 0] RR;

reg [SETS_WIDTH - 1 : 0] set;
reg [ROUTERS_WIDTH - 1 : 0] router;
reg [SET_INDEX_WIDTH - 1 : 0] index;


reg [PE_ADDR_WIDTH - 1 : 0] p;
// reg [$clog2(TOTAL_ITER):0] idx;

wire [ROUTERS-1 : 0] Scnts;
wire [ROUTERS-1 : 0] Sco;
wire [ROUTERS-1 : 0] Sclears;
wire [SETS_WIDTH - 1 : 0] Svals [ROUTERS - 1 : 0];

always @(posedge clk) begin
    {set, router, index} = 0;
    
    if (conf_en & en) begin
        for(p = 0; p < `HWC_PE_CLUSTER_NUMS; p = p + 1) begin
            {router, set, index} = iact_configs [ (p+1) * ROUT_CONFIG -1 -: ROUT_CONFIG];
            R_confs[router][set][index] = {1'b1, p};
            PE_iact_data_sel[(IACT_ROUTER_CLUSTER_NUM_WIDTH*(p+1) - 1)  -: IACT_ROUTER_CLUSTER_NUM_WIDTH] = router;
        end
    end
    if (conf_rst | ~rstn) begin
        for(p = 0; p < `HWC_PE_CLUSTER_NUMS; p = p + 1) begin
            PE_iact_data_sel[(p+1)*IACT_ROUTER_CLUSTER_NUM_WIDTH - 1 -: IACT_ROUTER_CLUSTER_NUM_WIDTH] = 0;
        end
        for (r2 = 0; r2 < ROUTERS; r2 = r2 + 1 ) begin
            for (s2 = 0; s2 < SETS; s2 = s2 + 1) begin
                for (i2 = 0; i2 < SET_INDEX; i2 = i2 + 1) begin
                    R_confs[r2][s2][i2] = 0;
                end
            end
        end
        // for (idx = 0; idx < TOTAL_ITER; idx = idx + 1) begin
        //     r2 = idx / (SETS * SET_INDEX);
        //     s2 = (idx / SET_INDEX) % SETS;
        //     i2 = idx % SET_INDEX;
        //     R_confs[r2][s2][i2] = 0;
        // end
    end
end
reg [`HWC_IACT_ROUTER_CLUSTER_NUM - 1 : 0] temp;
reg [`HWC_PE_CLUSTER_IACT_ROUT_CONFIG_SET_SIZE_WIDTH - 1 : 0] temp_set;

always @(*) begin
    PE_iact_enables = {(`HWC_PE_CLUSTER_ROWS * `HWC_PE_CLUSTER_COLS ){1'b0}};
    iact_readys = {`HWC_IACT_ROUTER_CLUSTER_NUM{1'b0}};
    for (RR = 0; RR < `HWC_IACT_ROUTER_CLUSTER_NUM; RR = RR + 1) begin
        temp[RR] = 1'b1;
        temp_set = iact_data_set[(RR+1)*`HWC_PE_CLUSTER_IACT_ROUT_CONFIG_SET_SIZE_WIDTH - 1 -: `HWC_PE_CLUSTER_IACT_ROUT_CONFIG_SET_SIZE_WIDTH];
        for (iv = 0; iv < SET_INDEX; iv = iv + 1) begin
            if (R_confs[RR][temp_set][iv][PE_ADDR_WIDTH] == 1'b1) begin
                $display("iact enable for %d router is %d", RR, R_confs[RR][temp_set][iv][PE_ADDR_WIDTH-1:0]);
                temp[RR] = temp[RR] & PE_iact_readys[R_confs[RR][temp_set][iv][PE_ADDR_WIDTH - 1 : 0]];
                PE_iact_enables[R_confs[RR][temp_set][iv][PE_ADDR_WIDTH-1:0]] = iact_enables[RR];
            end
        end
        iact_readys[RR] = temp[RR];
    end
end

endmodule

module pe_cluster_counter #(
    parameter integer MAX_DATA=4,
    parameter integer MAX_DATA_WIDTH = $clog2(MAX_DATA)
    ) (
    input clk, rstn, en, clear, cnt,
    output reg [MAX_DATA_WIDTH - 1:0] val,
    output co);
    always @(posedge clk) begin
        if (~rstn | clear | co)
            val <= 0;
        
        else if (en & cnt)
            val <= val + 1;
    end

    assign co = (val == (MAX_DATA - 1)) & cnt;

endmodule
