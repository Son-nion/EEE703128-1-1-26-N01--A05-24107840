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
