`default_nettype none

module tt_um_example (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered or selected
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    // 1. Phân chia I/O
    // Gán 4-bit thấp của ui_in cho a, 4-bit cao cho b
    wire [3:0] a = ui_in[3:0];
    wire [3:0] b = ui_in[7:4];
    wire [7:0] p;

    // Gán kết quả nhân ra 8-bit output chuyên dụng
    assign uo_out = p;

    // Không sử dụng các chân uio linh hoạt -> gán bằng 0
    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;

    // Tránh cảnh báo unused cho clk, rst_n, ena trong mạch kết hợp (combinational logic)
    wire _unused = &{clk, rst_n, ena, uio_in, 1'b0};

    // 2. Instantiate bộ nhân Array Multiplier 4x4
    A05_array_mult4x4 mult_inst (
        .a(a),
        .b(b),
        .p(p)
    );

endmodule

// -----------------------------------------------------------------------------
// Core Module của bạn (đã giữ nguyên logic)
// -----------------------------------------------------------------------------
module A05_array_mult4x4 (
    input  [3:0] a,    
    input  [3:0] b,    
    output [7:0] p    
);

    wire [3:0] pp0, pp1, pp2, pp3;

    for (genvar j = 0; j < 4; j = j + 1) begin : GEN_PP
        assign pp0[j] = a[j] & b[0];  
        assign pp1[j] = a[j] & b[1];   
        assign pp2[j] = a[j] & b[2];   
        assign pp3[j] = a[j] & b[3];   
    end

    wire [3:0] x1, y1, s1;
    wire [4:0] k1;
    wire [3:0] x2, y2, s2;
    wire [4:0] k2;
    wire [3:0] x3, y3, s3;
    wire [4:0] k3;

    assign x1    = {1'b0, pp0[3:1]};
    assign y1    = pp1;
    assign k1[0] = 1'b0;            

    for (genvar k = 0; k < 4; k = k + 1) begin : GEN_ROW1
        assign s1[k]   = x1[k] ^ y1[k] ^ k1[k];
        assign k1[k+1] = (x1[k] & y1[k])
                       | (x1[k] & k1[k])
                       | (y1[k] & k1[k]);
    end

    assign x2    = {k1[4], s1[3:1]};
    assign y2    = pp2;
    assign k2[0] = 1'b0;

    for (genvar k = 0; k < 4; k = k + 1) begin : GEN_ROW2
        assign s2[k]   = x2[k] ^ y2[k] ^ k2[k];
        assign k2[k+1] = (x2[k] & y2[k])
                       | (x2[k] & k2[k])
                       | (y2[k] & k2[k]);
    end

    assign x3    = {k2[4], s2[3:1]};
    assign y3    = pp3;
    assign k3[0] = 1'b0;

    for (genvar k = 0; k < 4; k = k + 1) begin : GEN_ROW3
        assign s3[k]   = x3[k] ^ y3[k] ^ k3[k];
        assign k3[k+1] = (x3[k] & y3[k])
                       | (x3[k] & k3[k])
                       | (y3[k] & k3[k]);
    end

    assign p[0]   = pp0[0];
    assign p[1]   = s1[0];
    assign p[2]   = s2[0];
    assign p[3]   = s3[0];
    assign p[7:4] = {k3[4], s3[3:1]};

endmodule
