`default_nettype none

// 1. Khối cộng nửa (HA)
module ha_gate (
    input  wire a, b,
    output wire sum, cout
);
    xor g1 (sum, a, b);   // Sum = a XOR b
    and g2 (cout, a, b);  // Cout = a AND b
endmodule

// 2. Khối cộng toàn phần (FA)
module fa_gate (
    input  wire a, b, cin,
    output wire sum, cout
);
    wire w1, w2, w3;
    xor g1 (w1, a, b);
    xor g2 (sum, w1, cin);
    and g3 (w2, w1, cin);
    and g4 (w3, a, b);
    or  g5 (cout, w2, w3);
endmodule

// 3. Khối nhân 4x4 hoàn chỉnh từ cổng logic và các khối HA/FA
module multiplier_4x4_gates (
    input  wire [3:0] A,
    input  wire [3:0] B,
    output wire [7:0] P
);
    // 16 bit tích một phần (Partial Products)
    wire [3:0] pp0, pp1, pp2, pp3;

    // Các đường dây nối trung gian giữa các tầng cộng
    wire s11, s12, s13;
    wire c10, c11, c12, c13;

    wire s21, s22, s23;
    wire c20, c21, c22, c23;

    wire c30, c31, c32, c33;

    // --- TẠO 16 TÍCH MỘT PHẦN (PP) ---
    // Hàng 0 (A * B[0])
    and g_pp0_0 (pp0[0], A[0], B[0]);
    and g_pp0_1 (pp0[1], A[1], B[0]);
    and g_pp0_2 (pp0[2], A[2], B[0]);
    and g_pp0_3 (pp0[3], A[3], B[0]);

    // Hàng 1 (A * B[1])
    and g_pp1_0 (pp1[0], A[0], B[1]);
    and g_pp1_1 (pp1[1], A[1], B[1]);
    and g_pp1_2 (pp1[2], A[2], B[1]);
    and g_pp1_3 (pp1[3], A[3], B[1]);

    // Hàng 2 (A * B[2])
    and g_pp2_0 (pp2[0], A[0], B[2]);
    and g_pp2_1 (pp2[1], A[1], B[2]);
    and g_pp2_2 (pp2[2], A[2], B[2]);
    and g_pp2_3 (pp2[3], A[3], B[2]);

    // Hàng 3 (A * B[3])
    and g_pp3_0 (pp3[0], A[0], B[3]);
    and g_pp3_1 (pp3[1], A[1], B[3]);
    and g_pp3_2 (pp3[2], A[2], B[3]);
    and g_pp3_3 (pp3[3], A[3], B[3]);

    // --- MẢNG CỘNG TẦNG 1 (Cộng pp0 và pp1) ---
    assign P[0] = pp0[0]; // Bit kết quả P[0]

    ha_gate ha1_0 (.a(pp0[1]), .b(pp1[0]),           .sum(P[1]), .cout(c10));
    fa_gate fa1_1 (.a(pp0[2]), .b(pp1[1]), .cin(c10), .sum(s11),  .cout(c11));
    fa_gate fa1_2 (.a(pp0[3]), .b(pp1[2]), .cin(c11), .sum(s12),  .cout(c12));
    ha_gate ha1_3 (.a(pp1[3]), .b(c12),              .sum(s13),  .cout(c13));

    // --- MẢNG CỘNG TẦNG 2 (Cộng tầng 1 và pp2) ---
    ha_gate ha2_0 (.a(s11),    .b(pp2[0]),           .sum(P[2]), .cout(c20));
    fa_gate fa2_1 (.a(s12),    .b(pp2[1]), .cin(c20), .sum(s21),  .cout(c21));
    fa_gate fa2_2 (.a(s13),    .b(pp2[2]), .cin(c21), .sum(s22),  .cout(c22));
    fa_gate fa2_3 (.a(c13),    .b(pp2[3]), .cin(c22), .sum(s23),  .cout(c23));

    // --- MẢNG CỘNG TẦNG 3 (Cộng tầng 2 và pp3) ---
    ha_gate ha3_0 (.a(s21),    .b(pp3[0]),           .sum(P[3]), .cout(c30));
    fa_gate fa3_1 (.a(s22),    .b(pp3[1]), .cin(c30), .sum(P[4]), .cout(c31));
    fa_gate fa3_2 (.a(s23),    .b(pp3[2]), .cin(c31), .sum(P[5]), .cout(c32));
    fa_gate fa3_3 (.a(c23),    .b(pp3[3]), .cin(c32), .sum(P[6]), .cout(c33));

    assign P[7] = c33; // Bit nhớ cuối cùng chính là P[7]

endmodule

// 4. Wrapper module chuẩn cho Tiny Tapeout
module tt_um_Son_nion_multiplier4x4 (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (1=output, 0=input)
    input  wire       ena,      // always 1 when enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n
);

    // Không dùng chân bidirectional
    assign uio_out = 8'b00000000;
    assign uio_oe  = 8'b00000000;

    // Gom các tín hiệu không dùng để tránh cảnh báo Linter
    wire _unused = &{clk, rst_n, ena, uio_in, 1'b0};

    // Kết nối mạch nhân
    multiplier_4x4_gates multiplier_inst (
        .A(ui_in[3:0]),
        .B(ui_in[7:4]),
        .P(uo_out[7:0])
    );

endmodule
