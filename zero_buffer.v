module Zero_buffer #(
    parameter DATA_WIDTH = 16 //data bitwidth
)(
    input  [DATA_WIDTH - 1 : 0] in_data_ifmap, //input data
    input  [DATA_WIDTH - 1 : 0] in_data_filter,
    output  zero_buffer //zero check signal
);

assign zero_buffer =  ((|in_data_ifmap) && (|in_data_filter)); //check if zero

// Multiplexer for data_out
//assign out_data = in_data;

endmodule
