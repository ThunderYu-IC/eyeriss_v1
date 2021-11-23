//Date		: 2020/03/28
//Author	: zhishangtanxin 
//Function	: 
//read more, please refer to wechat public account "zhishangtanxin"
module rca #(width=16) (
    input  [width-1:0] op1,
    input  [width-1:0] op2,
    output [width-1:0] sum,
    output cout
);

wire [width:0] temp;
assign temp[0] = 0;

genvar i;
for( i=0; i<width; i=i+1) begin
    full_adder u_full_adder(
        .a      (   op1[i]     ),
        .b      (   op2[i]     ),
        .cin    (   temp[i]    ),
        .cout   (   temp[i+1]  ),
        .s      (   sum[i]     )
    );
end

assign cout = temp[width];

endmodule
