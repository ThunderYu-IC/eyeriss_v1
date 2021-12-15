//一个PE单元




//一个PE单元例化5个3*3的乘法器，并行计算
parameter FIL_S = 3;
parameter DI_W = 7;
parameter DI_L = 7;
parameter DO_W = 5;
parameter DO_H = 5;

module PE
#(
    parameter INWIDTH = 16
)(
    input clk,rst,en;

    input signed  [INWIDTH-1:0] PSUM_IN     [0:DO_W-1];
    input signed  [INWIDTH-1:0] FILTER_IN   [0:FIL_S -1];
    input signed  [INWIDTH-1:0] DATA_IN     [0:DI_W - 1];

    output signed [INWIDTH-1:0] FILTER_IN   [0:FIL_S-1];
    output signed [INWIDTH-1:0] DATA_OUT    [0:DI_W-1];
    output signed [INWIDTH-1:0] PSUM_OUT    [0:DO_W-1];
)
parameter  = ;
genvar ii,jj;
//实现序列乘法
reg signed [INWIDTH-1:0]data_in     [0:DI_W];
reg signed [INWIDTH-1:0]filter   [0:FIL_S]; 
reg signed [INWIDTH-1:0]sum     [0:DO_W];
reg signed [INWIDTH-1:0]psum     [0:DO_W];

reg en;
reg [1:0] state,state_next;
parameter [1:0] IDLE = 2'd0; //初始态
                INPT = 2'd1; //输入
                COMP = 2'd2; //计算
                OUPT = 2'd3; //输出
reg [2:0]counter;
always @(*) begin
    case (state)
        IDLE: if(en) state_next = INPT ;
        INPT: state_next = COMP;    
        COMP: if(counter == 5) state_next = OUPT;
        OUPT: state_next = IDLE;
        default: 
    endcase
    
end

//INPT
always @(posedge clk) begin
    if(rst) begin
        data_in <= 0;
        filter <= 0;
        psum <= 0;
    else if(state_next == INPT) begin
        data_in <= DATA_IN;
        filter <= FILTER_IN;
        psum <= PSUM_IN;
    end
    end
end

//COMP
always @(posedge clk) begin:counter
    if(rst&en) begin
        counter <= 0;
    else
        counter <= counter + 1;
    end
end

always @(*) begin
    case (counter)
        0: data = {{data_in[0]},{data_in[1]},{data_in[2]}} ;
        1: data = {{data_in[1]},{data_in[2]},{data_in[3]}} ;
        2: data = {{data_in[2]},{data_in[3]},{data_in[4]}} ;
        3: data = {{data_in[3]},{data_in[4]},{data_in[5]}} ;
        4: data = {{data_in[4]},{data_in[5]},{data_in[6]}} ;
        default: 
    endcase

end
generate
    for(ii; ii < DO_W; ii = ii + 1)  begin:psum
            mult_3 m1(.a(filter),.b(data),.res(sum[ii]));
        end    
endgenerate


//OUPT  en, psum
always @(posedge clk) begin:en
    if(count == 5)
        en <= 1;
    else    
        en <= 0;
end

always @(posedge clk) begin:psum
    if(state_next == OUPT) begin
        DATA_OUT <= data_in;
        PSUM_OUT <= psum;
        FILTER_OUT <= filter;
    end 
    else begin
        PSUM_out <= 0;
        DATA_OUT <= 0;
        FILTER_OUT <= 0;
    end
end

endmodule;

// //INPT
// generate
//     for(ii = 0; ii < DI_W; ii = ii + 1)  begin :data_in
//         always @(posedge clk) begin
//             if(rst) begin
//                 data_in[ii] <= 0;
//             else if (en) begin
//                 data_in[ii] <= DATA_IN[ii];
//             end
//             end
//         end
// endgenerate

// generate
//     for(ii = 0; ii < FIL_S; ii = ii + 1)  begin :filter
//         always @(posedge clk) begin
//             if(rst) begin
//                 filter[ii] <= 0;
//             else if (en) begin
//                 filter[ii] <= FILTER_IN[ii];
//             end
//             end
//         end
// endgenerate

// generate
//     for(ii = 0; ii < DO_W; ii = ii + 1)  begin :psum

// endgenerate