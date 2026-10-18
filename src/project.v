/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

// 1. Khối cộng nửa (HA) dựng hoàn toàn từ cổng XOR và AND
module ha_gate (
    input wire a, b,
    output wire sum, cout
);
    xor g1 (sum, a, b);   // Tổng Sum = a XOR b
    and g2 (cout, a, b);  // Bit nhớ Cout = a AND b
endmodule

// 2. Khối cộng toàn phần (FA) dựng từ các cổng cơ bản
module fa_gate (
    input wire a, b, cin,
    output wire sum, cout
);
    wire w1, w2, w3;
    xor g1 (w1, a, b);
    xor g2 (sum, w1, cin);
    and g3 (w2, w1, cin);
    and g4 (w3, a, b);
    or  g5 (cout, w2, w3);
endmodule

// 3. Khối nhân 4x4 chính
module multiplier_4x4_gates (
    input  wire [3:0] A,
    input  wire [3:0] B,
    output wire [7:0] P
);
    wire [3:0] pp0, pp1, pp2, pp3;

    // Tạo 16 tích một phần bằng 16 cổng AND (không dùng dấu *)
    and (pp0[0], A[0], B[0]); and (pp0[1], A[1], B[0]); ...
    and (pp1[0], A[0], B[1]); and (pp1[1], A[1], B[1]); ...
    // ... Đưa các đường dây pp vào mảng HA và FA để cộng ra P[7:0]
endmodule

module tt_um_Son_nion_multiplier4x4 (
    input  wire [7:0] ui_in,    // Chân vào cố định (Dedicated inputs)
    output wire [7:0] uo_out,   // Chân ra cố định (Dedicated outputs)
    input  wire [7:0] uio_in,   // IOs hai chiều - đường vào
    output wire [7:0] uio_out,  // IOs hai chiều - đường ra
    output wire [7:0] uio_oe,   // IOs hai chiều - cho phép xuất (1 = Output, 0 = Input)
    input  wire       ena,      // Tín hiệu enable từ chip Tiny Tapeout (luôn = 1 khi chọn)
    input  wire       clk,      // Xung clock (không dùng tới)
    input  wire       rst_n     // Reset tích cực mức thấp (không dùng tới)
);

    // 1. Cấu hình các chân I/O hai chiều không sử dụng
    assign uio_out = 8'b00000000;
    assign uio_oe  = 8'b00000000; // Đặt tất cả làm Input để tránh xung đột bus

    // 2. Tránh cảnh báo Linter/OpenLane về các tín hiệu dư thừa không kết nối
    wire _unused = &{clk, rst_n, ena, uio_in, 1'b0};

    // 3. Gọi (Instantiate) khối nhân 4x4 chính
    multiplier_4x4_gates multiplier_inst (
        .A(ui_in[3:0]),   // 4 bit thấp của ui_in làm số nhân A
        .B(ui_in[7:4]),   // 4 bit cao của ui_in làm số nhân B
        .P(uo_out[7:0])   // Kết quả tích 8-bit xuất ra uo_out
    );

endmodule
