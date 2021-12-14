//reference"https://zhuanlan.zhihu.com/p/143802580"

//Top module of booth
module booth_top(
	input [15:0] A,
	input [15:0] B,
	output [31:0] P
);
wire [7:0] neg;
wire [7:0] zero;
wire [7:0] one;
wire [7:0] two;

genvar i;
generate 
	for(i=0; i<8;i=i+1) begin
		if(i==0)
			booth_enc u_booth_enc(
				.code ({B[1:0],1'b0}),
				.neg  (neg[i]    ),
				.zero (zero[i]   ),
				.one  (one[i]	 ),
				.two  (two[i]	 )
			);
		else
			booth_enc u_booth_enc(
				.code (B[i*2+1:i*2-1]),
				.neg  (neg[i]    ),
				.zero (zero[i]   ),
				.one  (one[i]	 ),
				.two  (two[i]	 )
			);
	end
endgenerate

wire [31:0] prod[0:7];
generate 
	for(i=0; i<8; i=i+1)begin
		gen_prod u_gen_prod (
			.A    ( A       ),
			.neg  ( neg[i]  ),
			.zero ( zero[i] ),
			.one  ( one[i]  ),
			.two  ( two[i]  ),
			.prod ( prod[i] )
		);
	end
endgenerate

wallace_tree u_watree(
    .prod(prod),
    .P(P)
);
endmodule


//booth encode
module booth_enc(
	input [2:0] code,
	output neg,
	output zero,
	output one,
	output two
);

assign neg  = code[2];
assign zero = (code==3'b000) || (code==3'b111);
assign two  = (code==3'b100) || (code==3'b011);
assign one  = !zero & !two;

endmodule


//generator new array from A, depend on booth code.
module gen_prod (
	input [15:0] A,
	input neg,
	input zero,
	input one,
	input two,
	output [31:0] prod
);

reg [31:0] prod_pre;

always @ (*) begin
	prod_pre = 32'd0;
	if (zero)
		prod_pre = 32'd0;
	else if (one)
		prod_pre = { { 16{A[15]} }, A};
	else if (two)
		prod_pre = { { 15{A[15]} }, A, 1'b0};
end

assign prod = neg ? ( ~prod_pre+1'b1 ) : prod_pre;
		
endmodule

//define the structure of process of add, using csa & fa
module wallace_tree (
	input [31:0] prod_0,
	input [31:0] prod_1,
	input [31:0] prod_2,
	input [31:0] prod_3,
	input [31:0] prod_4,
	input [31:0] prod_5,
	input [31:0] prod_6,
	input [31:0] prod_7,
    output [31:0] P
);
reg [31:0] prod[0:7];
endgenerate

wire [31:0] s_lev01;
wire [31:0] c_lev01;
wire [31:0] s_lev02;
wire [31:0] c_lev02;
wire [31:0] s_lev11;
wire [31:0] c_lev11;
wire [31:0] s_lev12;
wire [31:0] c_lev12;
wire [31:0] s_lev21;
wire [31:0] c_lev21;
wire [31:0] s_lev31;
wire [31:0] c_lev31;

//level 0
csa #(32) csa_lev01(
	.op1( prod_0      ),
	.op2( prod_1 << 2 ),
	.op3( prod_2 << 4 ),
	.S	( s_lev01      ),
	.C	( c_lev01      )
);

csa #(32) csa_lev02(
	.op1( prod_3 << 6 ),
	.op2( prod_4 << 8 ),
	.op3( prod_5 << 10 ),
	.S	( s_lev02      ),
	.C	( c_lev02      )
);

//level 1
csa #(32) csa_lev11(
	.op1( s_lev01      ),
	.op2( c_lev01 << 1 ),
	.op3( s_lev02      ),
	.S	( s_lev11      ),
	.C	( c_lev11      )
);

csa #(32) csa_lev12(
	.op1( c_lev02 << 1 ),
	.op2( prod_6 << 12),
	.op3( prod_7 << 14),
	.S	( s_lev12      ),
	.C	( c_lev12      )
);

//level 2
csa #(32) csa_lev21(
	.op1( s_lev11      ),
	.op2( c_lev11 << 1 ),
	.op3( s_lev12      ),
	.S	( s_lev21      ),
	.C	( c_lev21      )
);

//level 3
csa #(32) csa_lev31(
	.op1( s_lev21 ),
	.op2( c_lev21 << 1 ),
	.op3( c_lev12 << 1 ),
	.S	( s_lev31),
	.C	( c_lev31)
);

//adder
rca #(32) u_rca (
    .op1 ( s_lev31  ), 
    .op2 ( c_lev31 << 1  ),
    .cin ( 1'b0   ),
    .sum ( P      ),
    .cout(        )
);

endmodule

//Basic arithment units
//carry save adder
module csa #(width=16) (
	input [width-1:0] op1,
	input [width-1:0] op2,
	input [width-1:0] op3,
	output [width-1:0] S,
	output [width-1:0] C
);

genvar i;
generate
	for(i=0; i<width; i=i+1) begin
		full_adder u_full_adder(
			.a      (   op1[i]    ),
			.b      (   op2[i]    ),
			.cin    (   op3[i]    ),
			.cout   (   C[i]	  ),
			.s      (   S[i]      )
		);
	end
endgenerate

endmodule

//rca adder
module rca #(width=16) (
    input  [width-1:0] op1,
    input  [width-1:0] op2,
    input  cin,
    output [width-1:0] sum,
    output cout
);

wire [width:0] temp;
assign temp[0] = cin;
assign cout = temp[width];

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

endmodule

//full adder
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