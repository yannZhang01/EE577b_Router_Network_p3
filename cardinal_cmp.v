`timescale 1ns/1ps

module cardinal_cmp (
    input wire clk,
    input wire reset
);

    // ========== Polarity (synced with torus internal polarity) ==========
    reg polarity;
    always @(posedge clk) begin
        if (reset) polarity <= 1'b0;
        else       polarity <= ~polarity;
    end

    // ========== Torus PE-side buses ==========
    wire [15:0]   pe_si;
    wire [15:0]   pe_ri;
    wire [1023:0] pe_di;
    wire [15:0]   pe_so;
    wire [15:0]   pe_ro;
    wire [1023:0] pe_do;

    // ========== Torus Network ==========
    torus_4x4_network #(.PACKET_WIDTH(64)) u_network (
        .clk(clk),
        .reset(reset),
        .pe_si(pe_si),
        .pe_ri(pe_ri),
        .pe_di(pe_di),
        .pe_so(pe_so),
        .pe_ro(pe_ro),
        .pe_do(pe_do)
    );

    // ========== 16 Nodes (CPU + NIC + IMEM + DMEM) ==========
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : NODE

            // ----- CPU interface wires -----
            wire [0:31] pc_out;
            wire [0:31] inst_in;
            wire [0:31] addr_out;
            wire        memEn;
            wire        memWrEn;
            wire [0:63] cpu_d_out;
            wire [0:63] cpu_d_in;

            // ----- Address decode -----
            // imm16[8] = addr_out bit 23 in [0:31] big-endian
            wire nic_sel  = memEn & addr_out[23];
            wire dmem_en  = memEn & ~addr_out[23];
            wire dmem_wr  = memWrEn & ~addr_out[23];

            // Registered NIC select for read-data mux (1-cycle memory latency)
            reg nic_sel_r;
            always @(posedge clk) begin
                if (reset) nic_sel_r <= 1'b0;
                else       nic_sel_r <= nic_sel;
            end

            // ----- DMEM -----
            wire [0:63] dmem_out;

            dmem u_dmem (
                .clk(clk),
                .memEn(dmem_en),
                .memWrEn(dmem_wr),
                .memAddr(addr_out[24:31]),   // imm16[7:0]
                .dataIn(cpu_d_out),
                .dataOut(dmem_out)
            );

            // ----- NIC -----
            wire [63:0] nic_d_out;

            cardinal_nic u_nic (
                .clk(clk),
                .reset(reset),
                .addr({addr_out[30], addr_out[31]}),  // imm16[1:0]
                .d_in(cpu_d_out),
                .d_out(nic_d_out),
                .nicEn(nic_sel),
                .nicWrEn(memWrEn),
                // Router side (PE port of torus)
                .net_so(pe_si[i]),
                .net_ro(pe_ri[i]),
                .net_do(pe_di[i*64 +: 64]),
                .net_si(pe_so[i]),
                .net_ri(pe_ro[i]),
                .net_di(pe_do[i*64 +: 64]),
                .net_polarity(polarity)
            );

            // ----- Read-data mux -----
            assign cpu_d_in = nic_sel_r ? nic_d_out : dmem_out;

            // ----- IMEM -----
            imem u_imem (
                .memAddr(pc_out[22:29]),      // PC/4 lower 8 bits
                .dataOut(inst_in)
            );

            // ----- CPU -----
            cardinal_cpu u_cpu (
                .clk(clk),
                .reset(reset),
                .inst_in(inst_in),
                .d_in(cpu_d_in),
                .pc_out(pc_out),
                .addr_out(addr_out),
                .memEn(memEn),
                .memWrEn(memWrEn),
                .d_out(cpu_d_out)
            );

        end
    endgenerate

endmodule
