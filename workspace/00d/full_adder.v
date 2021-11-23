//Date		: 2020/03/11
//Author	: zhishangtanxin 
//Function	: full adder
//read more, please refer to wechat public account "zhishangtanxin"
module full_adder(
    input a,
    input b,
    input cin,
    output cout,
    output s
);

assign s = a ^ b ^ cin;
assign cout = a & b | (cin & (a ^ b));

endmodule
