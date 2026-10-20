`timescale 1ns / 1ps

module tb;
    reg  [7:0] ui_in;    // Input chuyên dụng [7:4]=b, [3:0]=a
    wire [7:0] uo_out;   // Output chuyên dụng p[7:0]
    reg  [7:0] uio_in;   // Biến không dùng (gán bằng 0)
    wire [7:0] uio_out;  // Tín hiệu quan sát từ IOs
    wire [7:0] uio_oe;   // Output Enable
    reg        ena;      // Enable signal
    reg        clk;      // Clock signal
    reg        rst_n;    // Reset active low
    wire [7:0] p_dut = uo_out;
    reg  [7:0] p_ref;
    integer n_run;        
    integer n_mismatch;   
    integer n_inv;        
    integer n_named;      
    integer ia, ib;       
    integer pp_sum;       
    integer i, j;         
    tt_um_Son_nion_multiplier4x4 (
        .ui_in  (ui_in),
        .uo_out (uo_out),
        .uio_in (uio_in),
        .uio_out(uio_out),
        .uio_oe (uio_oe),
        .ena    (ena),
        .clk    (clk),
        .rst_n  (rst_n)
    );
    always @(*) begin
        p_ref = ui_in[3:0] * ui_in[7:4];
    end
    task automatic check_vector(input string tc, input logic [3:0] va,
                                input logic [3:0] vb, input int unsigned want,
                                input bit verbose);
        begin
            ui_in = {vb, va}; // Thả va vào [3:0] và vb vào [7:4]
            #1;               // Chờ logic tổ hợp ổn định
            n_run = n_run + 1;
            if (p_dut !== p_ref) begin
                n_mismatch = n_mismatch + 1;
                $display("ERROR %s: a=%0d b=%0d | DUT=%0d (0x%02h) REF=%0d (0x%02h)",
                         tc, va, vb, p_dut, p_dut, p_ref, p_ref);
                $fatal(1, "A05 MISMATCH tại %s: a=%0d b=%0d DUT=%0d REF=%0d",
                       tc, va, vb, p_dut, p_ref);
            end
            if (verbose && (p_dut !== want[7:0])) begin
                n_mismatch = n_mismatch + 1;
                $fatal(1, "A05 SAI GIÁ TRỊ MONG ĐỢI tại %s: a=%0d b=%0d DUT=%0d mong đợi=%0d",
                       tc, va, vb, p_dut, want);
            end
            if (^p_dut === 1'bx) begin
                n_inv = n_inv + 1;
                $fatal(1, "A05 ĐẦU RA CÓ X/Z tại %s: a=%0d b=%0d p=%b",
                       tc, va, vb, p_dut);
            end
            if (p_dut > 8'd225) begin
                n_inv = n_inv + 1;
                $fatal(1, "A05 VI PHẠM INV-2 tại %s: a=%0d b=%0d p=%0d > 225",
                       tc, va, vb, p_dut);
            end

            // 5. INV-4: Tính chất phần tử 0 và 1
            if (((va == 4'd0) || (vb == 4'd0)) && (p_dut !== 8'd0)) begin
                n_inv = n_inv + 1;
                $fatal(1, "A05 VI PHẠM INV-4 tại %s: a=%0d b=%0d p=%0d, phải bằng 0",
                       tc, va, vb, p_dut);
            end
            if ((vb == 4'd1) && (p_dut !== {4'b0000, va})) begin
                n_inv = n_inv + 1;
                $fatal(1, "A05 VI PHẠM INV-4 tại %s: b==1 nhưng p=%0d != a=%0d",
                       tc, p_dut, va);
            end
            if (p_dut[0] !== (va[0] & vb[0])) begin
                n_inv = n_inv + 1;
                $fatal(1, "A05 VI PHẠM INV-5 tại %s: a=%0d b=%0d p[0]=%b, a[0]&b[0]=%b",
                       tc, va, vb, p_dut[0], (va[0] & vb[0]));
            end
            pp_sum = 0;
            for (i = 0; i < 4; i = i + 1) begin
                for (j = 0; j < 4; j = j + 1) begin
                    pp_sum = pp_sum + ((va[j] & vb[i]) << (i + j));
                end
            end
            if (pp_sum !== {24'd0, p_dut}) begin
                n_inv = n_inv + 1;
                $fatal(1, "A05 VI PHẠM INV-6 tại %s: a=%0d b=%0d tổng pp=%0d p=%0d",
                       tc, va, vb, pp_sum, p_dut);
            end

            if (verbose) begin
                n_named = n_named + 1;
                $display("  %-8s a=%2d b=%2d -> p=%3d (0x%02h)  REF=%3d  PASS",
                         tc, va, vb, p_dut, p_dut, p_ref);
            end
        end
    endtask
    initial begin
        // Khởi tạo các tín hiệu điều khiển Tiny Tapeout
        clk    = 1'b0;
        rst_n  = 1'b0;
        ena    = 1'b1;
        uio_in = 8'b0;
        ui_in  = 8'b0;

        n_run      = 0;
        n_mismatch = 0;
        n_inv      = 0;
        n_named    = 0;

        // Bật ghi sóng waveform
        $dumpfile("tb.vcd");
        $dumpvars(0, tb);

        #10 rst_n = 1'b1; // Thả Reset

        $display("======================================================");
        $display("TINY TAPEOUT - A05 ARRAY MULTIPLIER 4x4 TESTBENCH");
        $display("======================================================");
        $display("\n[PHA 1] Các ca test tiêu chuẩn");
        check_vector("TC-001",  4'd0,  4'd0,   0, 1);
        check_vector("TC-002", 4'd15, 4'd15, 225, 1);
        check_vector("TC-003",  4'd1, 4'd15,  15, 1);
        check_vector("TC-004",  4'd8,  4'd8,  64, 1);
        check_vector("TC-005",  4'd7,  4'd9,  63, 1);
        $display("\n[PHA 2] Các ca kiểm tra biên");
        check_vector("TC-006", 4'd15,  4'd1,  15, 1);
        check_vector("TC-007", 4'd14, 4'd15, 210, 1);
        check_vector("TC-008",  4'd8,  4'd2,  16, 1);
        check_vector("TC-009",  4'd5, 4'd10,  50, 1);
        check_vector("TC-010",  4'd3,  4'd5,  15, 1);
        check_vector("TC-011", 4'd15, 4'd13, 195, 1);
        check_vector("TC-012", 4'd11, 4'd15, 165, 1);
        $dumpoff; // Tắt Dump dạng sóng để tối ưu bộ nhớ
        $display("\n[PHA 3] Quét vét cạn toàn bộ không gian (16 x 16 = 256)");
        for (ia = 0; ia < 16; ia = ia + 1) begin
            for (ib = 0; ib < 16; ib = ib + 1) begin
                check_vector("EXH", ia[3:0], ib[3:0], 0, 0);
            end
        end
        $display("  Quét vét cạn thành công 256/256 trường hợp.");
        $dumpon;

        $display("\n======================================================");
        $display("TỔNG KẾT: Tổng=%0d | Test có tên=%0d | Sai lệch=%0d | Vi phạm=%0d",
                 n_run, n_named, n_mismatch, n_inv);

        if ((n_mismatch == 0) && (n_inv == 0) && (n_run == 268)) begin
            $display(">> TINY TAPEOUT VALIDATION PASS <<");
        end else begin
            $fatal(1, ">> TESTBENCH FAIL: Đã phát hiện lỗi! <<");
        end
        $display("======================================================");

        $finish;
    end

endmodule
