`timescale 1ns/1ps

module cardinal_cmp (
    input wire clk,
    input wire reset
);

    // Polarity (synced with torus internal polarity)
    reg polarity;
    always @(posedge clk) begin
        if (reset) polarity <= 1'b0;
        else       polarity <= ~polarity;
    end

    // Torus PE-side buses
    wire [15:0]   pe_si;
    wire [15:0]   pe_ri;
    wire [1023:0] pe_di;
    wire [15:0]   pe_so;
    wire [15:0]   pe_ro;
    wire [1023:0] pe_do;

    // Torus Network
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

    // ============================================================
    // Node 0 (node00) — Row 0, Col 0
    // ============================================================
    wire [0:31] node00_pc_out;
    wire [0:31] node00_inst_in;
    wire [0:31] node00_addr_out;
    wire        node00_memEn;
    wire        node00_memWrEn;
    wire [0:63] node00_cpu_d_out;
    wire [0:63] node00_cpu_d_in;
    wire [0:63] node00_dmem_out;
    wire [63:0] node00_nic_d_out;

    // Address decode
    wire node00_nic_sel = node00_memEn & node00_addr_out[23];
    wire node00_dmem_en = node00_memEn & ~node00_addr_out[23];
    wire node00_dmem_wr = node00_memWrEn & ~node00_addr_out[23];

    reg node00_nic_sel_r;
    always @(posedge clk) begin
        if (reset) node00_nic_sel_r <= 1'b0;
        else       node00_nic_sel_r <= node00_nic_sel;
    end

    // Read-data mux
    assign node00_cpu_d_in = node00_nic_sel_r ? node00_nic_d_out : node00_dmem_out;

    // IMEM
    imem u_node00_imem (
        .memAddr(node00_pc_out[22:29]),
        .dataOut(node00_inst_in)
    );

    // DMEM
    dmem u_node00_dmem (
        .clk(clk),
        .memEn(node00_dmem_en),
        .memWrEn(node00_dmem_wr),
        .memAddr(node00_addr_out[24:31]),
        .dataIn(node00_cpu_d_out),
        .dataOut(node00_dmem_out)
    );

    // CPU
    cardinal_cpu u_node00_cpu (
        .clk(clk),
        .reset(reset),
        .inst_in(node00_inst_in),
        .d_in(node00_cpu_d_in),
        .pc_out(node00_pc_out),
        .addr_out(node00_addr_out),
        .memEn(node00_memEn),
        .memWrEn(node00_memWrEn),
        .d_out(node00_cpu_d_out)
    );

    // NIC
    cardinal_nic u_node00_nic (
        .clk(clk),
        .reset(reset),
        .addr({node00_addr_out[30], node00_addr_out[31]}),
        .d_in(node00_cpu_d_out),
        .d_out(node00_nic_d_out),
        .nicEn(node00_nic_sel),
        .nicWrEn(node00_memWrEn),
        .net_so(pe_si[0]),
        .net_ro(pe_ri[0]),
        .net_do(pe_di[0 +: 64]),
        .net_si(pe_so[0]),
        .net_ri(pe_ro[0]),
        .net_di(pe_do[0 +: 64]),
        .net_polarity(polarity)
    );

    // ============================================================
    // Node 1 (node01) — Row 0, Col 1
    // ============================================================
    wire [0:31] node01_pc_out;
    wire [0:31] node01_inst_in;
    wire [0:31] node01_addr_out;
    wire        node01_memEn;
    wire        node01_memWrEn;
    wire [0:63] node01_cpu_d_out;
    wire [0:63] node01_cpu_d_in;
    wire [0:63] node01_dmem_out;
    wire [63:0] node01_nic_d_out;

    // Address decode
    wire node01_nic_sel = node01_memEn & node01_addr_out[23];
    wire node01_dmem_en = node01_memEn & ~node01_addr_out[23];
    wire node01_dmem_wr = node01_memWrEn & ~node01_addr_out[23];

    reg node01_nic_sel_r;
    always @(posedge clk) begin
        if (reset) node01_nic_sel_r <= 1'b0;
        else       node01_nic_sel_r <= node01_nic_sel;
    end

    // Read-data mux
    assign node01_cpu_d_in = node01_nic_sel_r ? node01_nic_d_out : node01_dmem_out;

    // IMEM
    imem u_node01_imem (
        .memAddr(node01_pc_out[22:29]),
        .dataOut(node01_inst_in)
    );

    // DMEM
    dmem u_node01_dmem (
        .clk(clk),
        .memEn(node01_dmem_en),
        .memWrEn(node01_dmem_wr),
        .memAddr(node01_addr_out[24:31]),
        .dataIn(node01_cpu_d_out),
        .dataOut(node01_dmem_out)
    );

    // CPU
    cardinal_cpu u_node01_cpu (
        .clk(clk),
        .reset(reset),
        .inst_in(node01_inst_in),
        .d_in(node01_cpu_d_in),
        .pc_out(node01_pc_out),
        .addr_out(node01_addr_out),
        .memEn(node01_memEn),
        .memWrEn(node01_memWrEn),
        .d_out(node01_cpu_d_out)
    );

    // NIC
    cardinal_nic u_node01_nic (
        .clk(clk),
        .reset(reset),
        .addr({node01_addr_out[30], node01_addr_out[31]}),
        .d_in(node01_cpu_d_out),
        .d_out(node01_nic_d_out),
        .nicEn(node01_nic_sel),
        .nicWrEn(node01_memWrEn),
        .net_so(pe_si[1]),
        .net_ro(pe_ri[1]),
        .net_do(pe_di[64 +: 64]),
        .net_si(pe_so[1]),
        .net_ri(pe_ro[1]),
        .net_di(pe_do[64 +: 64]),
        .net_polarity(polarity)
    );

    // ============================================================
    // Node 2 (node02) — Row 0, Col 2
    // ============================================================
    wire [0:31] node02_pc_out;
    wire [0:31] node02_inst_in;
    wire [0:31] node02_addr_out;
    wire        node02_memEn;
    wire        node02_memWrEn;
    wire [0:63] node02_cpu_d_out;
    wire [0:63] node02_cpu_d_in;
    wire [0:63] node02_dmem_out;
    wire [63:0] node02_nic_d_out;

    // Address decode
    wire node02_nic_sel = node02_memEn & node02_addr_out[23];
    wire node02_dmem_en = node02_memEn & ~node02_addr_out[23];
    wire node02_dmem_wr = node02_memWrEn & ~node02_addr_out[23];

    reg node02_nic_sel_r;
    always @(posedge clk) begin
        if (reset) node02_nic_sel_r <= 1'b0;
        else       node02_nic_sel_r <= node02_nic_sel;
    end

    // Read-data mux
    assign node02_cpu_d_in = node02_nic_sel_r ? node02_nic_d_out : node02_dmem_out;

    // IMEM
    imem u_node02_imem (
        .memAddr(node02_pc_out[22:29]),
        .dataOut(node02_inst_in)
    );

    // DMEM
    dmem u_node02_dmem (
        .clk(clk),
        .memEn(node02_dmem_en),
        .memWrEn(node02_dmem_wr),
        .memAddr(node02_addr_out[24:31]),
        .dataIn(node02_cpu_d_out),
        .dataOut(node02_dmem_out)
    );

    // CPU
    cardinal_cpu u_node02_cpu (
        .clk(clk),
        .reset(reset),
        .inst_in(node02_inst_in),
        .d_in(node02_cpu_d_in),
        .pc_out(node02_pc_out),
        .addr_out(node02_addr_out),
        .memEn(node02_memEn),
        .memWrEn(node02_memWrEn),
        .d_out(node02_cpu_d_out)
    );

    // NIC
    cardinal_nic u_node02_nic (
        .clk(clk),
        .reset(reset),
        .addr({node02_addr_out[30], node02_addr_out[31]}),
        .d_in(node02_cpu_d_out),
        .d_out(node02_nic_d_out),
        .nicEn(node02_nic_sel),
        .nicWrEn(node02_memWrEn),
        .net_so(pe_si[2]),
        .net_ro(pe_ri[2]),
        .net_do(pe_di[128 +: 64]),
        .net_si(pe_so[2]),
        .net_ri(pe_ro[2]),
        .net_di(pe_do[128 +: 64]),
        .net_polarity(polarity)
    );

    // ============================================================
    // Node 3 (node03) — Row 0, Col 3
    // ============================================================
    wire [0:31] node03_pc_out;
    wire [0:31] node03_inst_in;
    wire [0:31] node03_addr_out;
    wire        node03_memEn;
    wire        node03_memWrEn;
    wire [0:63] node03_cpu_d_out;
    wire [0:63] node03_cpu_d_in;
    wire [0:63] node03_dmem_out;
    wire [63:0] node03_nic_d_out;

    // Address decode
    wire node03_nic_sel = node03_memEn & node03_addr_out[23];
    wire node03_dmem_en = node03_memEn & ~node03_addr_out[23];
    wire node03_dmem_wr = node03_memWrEn & ~node03_addr_out[23];

    reg node03_nic_sel_r;
    always @(posedge clk) begin
        if (reset) node03_nic_sel_r <= 1'b0;
        else       node03_nic_sel_r <= node03_nic_sel;
    end

    // Read-data mux
    assign node03_cpu_d_in = node03_nic_sel_r ? node03_nic_d_out : node03_dmem_out;

    // IMEM
    imem u_node03_imem (
        .memAddr(node03_pc_out[22:29]),
        .dataOut(node03_inst_in)
    );

    // DMEM
    dmem u_node03_dmem (
        .clk(clk),
        .memEn(node03_dmem_en),
        .memWrEn(node03_dmem_wr),
        .memAddr(node03_addr_out[24:31]),
        .dataIn(node03_cpu_d_out),
        .dataOut(node03_dmem_out)
    );

    // CPU
    cardinal_cpu u_node03_cpu (
        .clk(clk),
        .reset(reset),
        .inst_in(node03_inst_in),
        .d_in(node03_cpu_d_in),
        .pc_out(node03_pc_out),
        .addr_out(node03_addr_out),
        .memEn(node03_memEn),
        .memWrEn(node03_memWrEn),
        .d_out(node03_cpu_d_out)
    );

    // NIC
    cardinal_nic u_node03_nic (
        .clk(clk),
        .reset(reset),
        .addr({node03_addr_out[30], node03_addr_out[31]}),
        .d_in(node03_cpu_d_out),
        .d_out(node03_nic_d_out),
        .nicEn(node03_nic_sel),
        .nicWrEn(node03_memWrEn),
        .net_so(pe_si[3]),
        .net_ro(pe_ri[3]),
        .net_do(pe_di[192 +: 64]),
        .net_si(pe_so[3]),
        .net_ri(pe_ro[3]),
        .net_di(pe_do[192 +: 64]),
        .net_polarity(polarity)
    );

    // ============================================================
    // Node 4 (node10) — Row 1, Col 0
    // ============================================================
    wire [0:31] node10_pc_out;
    wire [0:31] node10_inst_in;
    wire [0:31] node10_addr_out;
    wire        node10_memEn;
    wire        node10_memWrEn;
    wire [0:63] node10_cpu_d_out;
    wire [0:63] node10_cpu_d_in;
    wire [0:63] node10_dmem_out;
    wire [63:0] node10_nic_d_out;

    // Address decode
    wire node10_nic_sel = node10_memEn & node10_addr_out[23];
    wire node10_dmem_en = node10_memEn & ~node10_addr_out[23];
    wire node10_dmem_wr = node10_memWrEn & ~node10_addr_out[23];

    reg node10_nic_sel_r;
    always @(posedge clk) begin
        if (reset) node10_nic_sel_r <= 1'b0;
        else       node10_nic_sel_r <= node10_nic_sel;
    end

    // Read-data mux
    assign node10_cpu_d_in = node10_nic_sel_r ? node10_nic_d_out : node10_dmem_out;

    // IMEM
    imem u_node10_imem (
        .memAddr(node10_pc_out[22:29]),
        .dataOut(node10_inst_in)
    );

    // DMEM
    dmem u_node10_dmem (
        .clk(clk),
        .memEn(node10_dmem_en),
        .memWrEn(node10_dmem_wr),
        .memAddr(node10_addr_out[24:31]),
        .dataIn(node10_cpu_d_out),
        .dataOut(node10_dmem_out)
    );

    // CPU
    cardinal_cpu u_node10_cpu (
        .clk(clk),
        .reset(reset),
        .inst_in(node10_inst_in),
        .d_in(node10_cpu_d_in),
        .pc_out(node10_pc_out),
        .addr_out(node10_addr_out),
        .memEn(node10_memEn),
        .memWrEn(node10_memWrEn),
        .d_out(node10_cpu_d_out)
    );

    // NIC
    cardinal_nic u_node10_nic (
        .clk(clk),
        .reset(reset),
        .addr({node10_addr_out[30], node10_addr_out[31]}),
        .d_in(node10_cpu_d_out),
        .d_out(node10_nic_d_out),
        .nicEn(node10_nic_sel),
        .nicWrEn(node10_memWrEn),
        .net_so(pe_si[4]),
        .net_ro(pe_ri[4]),
        .net_do(pe_di[256 +: 64]),
        .net_si(pe_so[4]),
        .net_ri(pe_ro[4]),
        .net_di(pe_do[256 +: 64]),
        .net_polarity(polarity)
    );

    // ============================================================
    // Node 5 (node11) — Row 1, Col 1
    // ============================================================
    wire [0:31] node11_pc_out;
    wire [0:31] node11_inst_in;
    wire [0:31] node11_addr_out;
    wire        node11_memEn;
    wire        node11_memWrEn;
    wire [0:63] node11_cpu_d_out;
    wire [0:63] node11_cpu_d_in;
    wire [0:63] node11_dmem_out;
    wire [63:0] node11_nic_d_out;

    // Address decode
    wire node11_nic_sel = node11_memEn & node11_addr_out[23];
    wire node11_dmem_en = node11_memEn & ~node11_addr_out[23];
    wire node11_dmem_wr = node11_memWrEn & ~node11_addr_out[23];

    reg node11_nic_sel_r;
    always @(posedge clk) begin
        if (reset) node11_nic_sel_r <= 1'b0;
        else       node11_nic_sel_r <= node11_nic_sel;
    end

    // Read-data mux
    assign node11_cpu_d_in = node11_nic_sel_r ? node11_nic_d_out : node11_dmem_out;

    // IMEM
    imem u_node11_imem (
        .memAddr(node11_pc_out[22:29]),
        .dataOut(node11_inst_in)
    );

    // DMEM
    dmem u_node11_dmem (
        .clk(clk),
        .memEn(node11_dmem_en),
        .memWrEn(node11_dmem_wr),
        .memAddr(node11_addr_out[24:31]),
        .dataIn(node11_cpu_d_out),
        .dataOut(node11_dmem_out)
    );

    // CPU
    cardinal_cpu u_node11_cpu (
        .clk(clk),
        .reset(reset),
        .inst_in(node11_inst_in),
        .d_in(node11_cpu_d_in),
        .pc_out(node11_pc_out),
        .addr_out(node11_addr_out),
        .memEn(node11_memEn),
        .memWrEn(node11_memWrEn),
        .d_out(node11_cpu_d_out)
    );

    // NIC
    cardinal_nic u_node11_nic (
        .clk(clk),
        .reset(reset),
        .addr({node11_addr_out[30], node11_addr_out[31]}),
        .d_in(node11_cpu_d_out),
        .d_out(node11_nic_d_out),
        .nicEn(node11_nic_sel),
        .nicWrEn(node11_memWrEn),
        .net_so(pe_si[5]),
        .net_ro(pe_ri[5]),
        .net_do(pe_di[320 +: 64]),
        .net_si(pe_so[5]),
        .net_ri(pe_ro[5]),
        .net_di(pe_do[320 +: 64]),
        .net_polarity(polarity)
    );

    // ============================================================
    // Node 6 (node12) — Row 1, Col 2
    // ============================================================
    wire [0:31] node12_pc_out;
    wire [0:31] node12_inst_in;
    wire [0:31] node12_addr_out;
    wire        node12_memEn;
    wire        node12_memWrEn;
    wire [0:63] node12_cpu_d_out;
    wire [0:63] node12_cpu_d_in;
    wire [0:63] node12_dmem_out;
    wire [63:0] node12_nic_d_out;

    // Address decode
    wire node12_nic_sel = node12_memEn & node12_addr_out[23];
    wire node12_dmem_en = node12_memEn & ~node12_addr_out[23];
    wire node12_dmem_wr = node12_memWrEn & ~node12_addr_out[23];

    reg node12_nic_sel_r;
    always @(posedge clk) begin
        if (reset) node12_nic_sel_r <= 1'b0;
        else       node12_nic_sel_r <= node12_nic_sel;
    end

    // Read-data mux
    assign node12_cpu_d_in = node12_nic_sel_r ? node12_nic_d_out : node12_dmem_out;

    // IMEM
    imem u_node12_imem (
        .memAddr(node12_pc_out[22:29]),
        .dataOut(node12_inst_in)
    );

    // DMEM
    dmem u_node12_dmem (
        .clk(clk),
        .memEn(node12_dmem_en),
        .memWrEn(node12_dmem_wr),
        .memAddr(node12_addr_out[24:31]),
        .dataIn(node12_cpu_d_out),
        .dataOut(node12_dmem_out)
    );

    // CPU
    cardinal_cpu u_node12_cpu (
        .clk(clk),
        .reset(reset),
        .inst_in(node12_inst_in),
        .d_in(node12_cpu_d_in),
        .pc_out(node12_pc_out),
        .addr_out(node12_addr_out),
        .memEn(node12_memEn),
        .memWrEn(node12_memWrEn),
        .d_out(node12_cpu_d_out)
    );

    // NIC
    cardinal_nic u_node12_nic (
        .clk(clk),
        .reset(reset),
        .addr({node12_addr_out[30], node12_addr_out[31]}),
        .d_in(node12_cpu_d_out),
        .d_out(node12_nic_d_out),
        .nicEn(node12_nic_sel),
        .nicWrEn(node12_memWrEn),
        .net_so(pe_si[6]),
        .net_ro(pe_ri[6]),
        .net_do(pe_di[384 +: 64]),
        .net_si(pe_so[6]),
        .net_ri(pe_ro[6]),
        .net_di(pe_do[384 +: 64]),
        .net_polarity(polarity)
    );

    // ============================================================
    // Node 7 (node13) — Row 1, Col 3
    // ============================================================
    wire [0:31] node13_pc_out;
    wire [0:31] node13_inst_in;
    wire [0:31] node13_addr_out;
    wire        node13_memEn;
    wire        node13_memWrEn;
    wire [0:63] node13_cpu_d_out;
    wire [0:63] node13_cpu_d_in;
    wire [0:63] node13_dmem_out;
    wire [63:0] node13_nic_d_out;

    // Address decode
    wire node13_nic_sel = node13_memEn & node13_addr_out[23];
    wire node13_dmem_en = node13_memEn & ~node13_addr_out[23];
    wire node13_dmem_wr = node13_memWrEn & ~node13_addr_out[23];

    reg node13_nic_sel_r;
    always @(posedge clk) begin
        if (reset) node13_nic_sel_r <= 1'b0;
        else       node13_nic_sel_r <= node13_nic_sel;
    end

    // Read-data mux
    assign node13_cpu_d_in = node13_nic_sel_r ? node13_nic_d_out : node13_dmem_out;

    // IMEM
    imem u_node13_imem (
        .memAddr(node13_pc_out[22:29]),
        .dataOut(node13_inst_in)
    );

    // DMEM
    dmem u_node13_dmem (
        .clk(clk),
        .memEn(node13_dmem_en),
        .memWrEn(node13_dmem_wr),
        .memAddr(node13_addr_out[24:31]),
        .dataIn(node13_cpu_d_out),
        .dataOut(node13_dmem_out)
    );

    // CPU
    cardinal_cpu u_node13_cpu (
        .clk(clk),
        .reset(reset),
        .inst_in(node13_inst_in),
        .d_in(node13_cpu_d_in),
        .pc_out(node13_pc_out),
        .addr_out(node13_addr_out),
        .memEn(node13_memEn),
        .memWrEn(node13_memWrEn),
        .d_out(node13_cpu_d_out)
    );

    // NIC
    cardinal_nic u_node13_nic (
        .clk(clk),
        .reset(reset),
        .addr({node13_addr_out[30], node13_addr_out[31]}),
        .d_in(node13_cpu_d_out),
        .d_out(node13_nic_d_out),
        .nicEn(node13_nic_sel),
        .nicWrEn(node13_memWrEn),
        .net_so(pe_si[7]),
        .net_ro(pe_ri[7]),
        .net_do(pe_di[448 +: 64]),
        .net_si(pe_so[7]),
        .net_ri(pe_ro[7]),
        .net_di(pe_do[448 +: 64]),
        .net_polarity(polarity)
    );

    // ============================================================
    // Node 8 (node20) — Row 2, Col 0
    // ============================================================
    wire [0:31] node20_pc_out;
    wire [0:31] node20_inst_in;
    wire [0:31] node20_addr_out;
    wire        node20_memEn;
    wire        node20_memWrEn;
    wire [0:63] node20_cpu_d_out;
    wire [0:63] node20_cpu_d_in;
    wire [0:63] node20_dmem_out;
    wire [63:0] node20_nic_d_out;

    // Address decode
    wire node20_nic_sel = node20_memEn & node20_addr_out[23];
    wire node20_dmem_en = node20_memEn & ~node20_addr_out[23];
    wire node20_dmem_wr = node20_memWrEn & ~node20_addr_out[23];

    reg node20_nic_sel_r;
    always @(posedge clk) begin
        if (reset) node20_nic_sel_r <= 1'b0;
        else       node20_nic_sel_r <= node20_nic_sel;
    end

    // Read-data mux
    assign node20_cpu_d_in = node20_nic_sel_r ? node20_nic_d_out : node20_dmem_out;

    // IMEM
    imem u_node20_imem (
        .memAddr(node20_pc_out[22:29]),
        .dataOut(node20_inst_in)
    );

    // DMEM
    dmem u_node20_dmem (
        .clk(clk),
        .memEn(node20_dmem_en),
        .memWrEn(node20_dmem_wr),
        .memAddr(node20_addr_out[24:31]),
        .dataIn(node20_cpu_d_out),
        .dataOut(node20_dmem_out)
    );

    // CPU
    cardinal_cpu u_node20_cpu (
        .clk(clk),
        .reset(reset),
        .inst_in(node20_inst_in),
        .d_in(node20_cpu_d_in),
        .pc_out(node20_pc_out),
        .addr_out(node20_addr_out),
        .memEn(node20_memEn),
        .memWrEn(node20_memWrEn),
        .d_out(node20_cpu_d_out)
    );

    // NIC
    cardinal_nic u_node20_nic (
        .clk(clk),
        .reset(reset),
        .addr({node20_addr_out[30], node20_addr_out[31]}),
        .d_in(node20_cpu_d_out),
        .d_out(node20_nic_d_out),
        .nicEn(node20_nic_sel),
        .nicWrEn(node20_memWrEn),
        .net_so(pe_si[8]),
        .net_ro(pe_ri[8]),
        .net_do(pe_di[512 +: 64]),
        .net_si(pe_so[8]),
        .net_ri(pe_ro[8]),
        .net_di(pe_do[512 +: 64]),
        .net_polarity(polarity)
    );

    // ============================================================
    // Node 9 (node21) — Row 2, Col 1
    // ============================================================
    wire [0:31] node21_pc_out;
    wire [0:31] node21_inst_in;
    wire [0:31] node21_addr_out;
    wire        node21_memEn;
    wire        node21_memWrEn;
    wire [0:63] node21_cpu_d_out;
    wire [0:63] node21_cpu_d_in;
    wire [0:63] node21_dmem_out;
    wire [63:0] node21_nic_d_out;

    // Address decode
    wire node21_nic_sel = node21_memEn & node21_addr_out[23];
    wire node21_dmem_en = node21_memEn & ~node21_addr_out[23];
    wire node21_dmem_wr = node21_memWrEn & ~node21_addr_out[23];

    reg node21_nic_sel_r;
    always @(posedge clk) begin
        if (reset) node21_nic_sel_r <= 1'b0;
        else       node21_nic_sel_r <= node21_nic_sel;
    end

    // Read-data mux
    assign node21_cpu_d_in = node21_nic_sel_r ? node21_nic_d_out : node21_dmem_out;

    // IMEM
    imem u_node21_imem (
        .memAddr(node21_pc_out[22:29]),
        .dataOut(node21_inst_in)
    );

    // DMEM
    dmem u_node21_dmem (
        .clk(clk),
        .memEn(node21_dmem_en),
        .memWrEn(node21_dmem_wr),
        .memAddr(node21_addr_out[24:31]),
        .dataIn(node21_cpu_d_out),
        .dataOut(node21_dmem_out)
    );

    // CPU
    cardinal_cpu u_node21_cpu (
        .clk(clk),
        .reset(reset),
        .inst_in(node21_inst_in),
        .d_in(node21_cpu_d_in),
        .pc_out(node21_pc_out),
        .addr_out(node21_addr_out),
        .memEn(node21_memEn),
        .memWrEn(node21_memWrEn),
        .d_out(node21_cpu_d_out)
    );

    // NIC
    cardinal_nic u_node21_nic (
        .clk(clk),
        .reset(reset),
        .addr({node21_addr_out[30], node21_addr_out[31]}),
        .d_in(node21_cpu_d_out),
        .d_out(node21_nic_d_out),
        .nicEn(node21_nic_sel),
        .nicWrEn(node21_memWrEn),
        .net_so(pe_si[9]),
        .net_ro(pe_ri[9]),
        .net_do(pe_di[576 +: 64]),
        .net_si(pe_so[9]),
        .net_ri(pe_ro[9]),
        .net_di(pe_do[576 +: 64]),
        .net_polarity(polarity)
    );

    // ============================================================
    // Node 10 (node22) — Row 2, Col 2
    // ============================================================
    wire [0:31] node22_pc_out;
    wire [0:31] node22_inst_in;
    wire [0:31] node22_addr_out;
    wire        node22_memEn;
    wire        node22_memWrEn;
    wire [0:63] node22_cpu_d_out;
    wire [0:63] node22_cpu_d_in;
    wire [0:63] node22_dmem_out;
    wire [63:0] node22_nic_d_out;

    // Address decode
    wire node22_nic_sel = node22_memEn & node22_addr_out[23];
    wire node22_dmem_en = node22_memEn & ~node22_addr_out[23];
    wire node22_dmem_wr = node22_memWrEn & ~node22_addr_out[23];

    reg node22_nic_sel_r;
    always @(posedge clk) begin
        if (reset) node22_nic_sel_r <= 1'b0;
        else       node22_nic_sel_r <= node22_nic_sel;
    end

    // Read-data mux
    assign node22_cpu_d_in = node22_nic_sel_r ? node22_nic_d_out : node22_dmem_out;

    // IMEM
    imem u_node22_imem (
        .memAddr(node22_pc_out[22:29]),
        .dataOut(node22_inst_in)
    );

    // DMEM
    dmem u_node22_dmem (
        .clk(clk),
        .memEn(node22_dmem_en),
        .memWrEn(node22_dmem_wr),
        .memAddr(node22_addr_out[24:31]),
        .dataIn(node22_cpu_d_out),
        .dataOut(node22_dmem_out)
    );

    // CPU
    cardinal_cpu u_node22_cpu (
        .clk(clk),
        .reset(reset),
        .inst_in(node22_inst_in),
        .d_in(node22_cpu_d_in),
        .pc_out(node22_pc_out),
        .addr_out(node22_addr_out),
        .memEn(node22_memEn),
        .memWrEn(node22_memWrEn),
        .d_out(node22_cpu_d_out)
    );

    // NIC
    cardinal_nic u_node22_nic (
        .clk(clk),
        .reset(reset),
        .addr({node22_addr_out[30], node22_addr_out[31]}),
        .d_in(node22_cpu_d_out),
        .d_out(node22_nic_d_out),
        .nicEn(node22_nic_sel),
        .nicWrEn(node22_memWrEn),
        .net_so(pe_si[10]),
        .net_ro(pe_ri[10]),
        .net_do(pe_di[640 +: 64]),
        .net_si(pe_so[10]),
        .net_ri(pe_ro[10]),
        .net_di(pe_do[640 +: 64]),
        .net_polarity(polarity)
    );

    // ============================================================
    // Node 11 (node23) — Row 2, Col 3
    // ============================================================
    wire [0:31] node23_pc_out;
    wire [0:31] node23_inst_in;
    wire [0:31] node23_addr_out;
    wire        node23_memEn;
    wire        node23_memWrEn;
    wire [0:63] node23_cpu_d_out;
    wire [0:63] node23_cpu_d_in;
    wire [0:63] node23_dmem_out;
    wire [63:0] node23_nic_d_out;

    // Address decode
    wire node23_nic_sel = node23_memEn & node23_addr_out[23];
    wire node23_dmem_en = node23_memEn & ~node23_addr_out[23];
    wire node23_dmem_wr = node23_memWrEn & ~node23_addr_out[23];

    reg node23_nic_sel_r;
    always @(posedge clk) begin
        if (reset) node23_nic_sel_r <= 1'b0;
        else       node23_nic_sel_r <= node23_nic_sel;
    end

    // Read-data mux
    assign node23_cpu_d_in = node23_nic_sel_r ? node23_nic_d_out : node23_dmem_out;

    // IMEM
    imem u_node23_imem (
        .memAddr(node23_pc_out[22:29]),
        .dataOut(node23_inst_in)
    );

    // DMEM
    dmem u_node23_dmem (
        .clk(clk),
        .memEn(node23_dmem_en),
        .memWrEn(node23_dmem_wr),
        .memAddr(node23_addr_out[24:31]),
        .dataIn(node23_cpu_d_out),
        .dataOut(node23_dmem_out)
    );

    // CPU
    cardinal_cpu u_node23_cpu (
        .clk(clk),
        .reset(reset),
        .inst_in(node23_inst_in),
        .d_in(node23_cpu_d_in),
        .pc_out(node23_pc_out),
        .addr_out(node23_addr_out),
        .memEn(node23_memEn),
        .memWrEn(node23_memWrEn),
        .d_out(node23_cpu_d_out)
    );

    // NIC
    cardinal_nic u_node23_nic (
        .clk(clk),
        .reset(reset),
        .addr({node23_addr_out[30], node23_addr_out[31]}),
        .d_in(node23_cpu_d_out),
        .d_out(node23_nic_d_out),
        .nicEn(node23_nic_sel),
        .nicWrEn(node23_memWrEn),
        .net_so(pe_si[11]),
        .net_ro(pe_ri[11]),
        .net_do(pe_di[704 +: 64]),
        .net_si(pe_so[11]),
        .net_ri(pe_ro[11]),
        .net_di(pe_do[704 +: 64]),
        .net_polarity(polarity)
    );

    // ============================================================
    // Node 12 (node30) — Row 3, Col 0
    // ============================================================
    wire [0:31] node30_pc_out;
    wire [0:31] node30_inst_in;
    wire [0:31] node30_addr_out;
    wire        node30_memEn;
    wire        node30_memWrEn;
    wire [0:63] node30_cpu_d_out;
    wire [0:63] node30_cpu_d_in;
    wire [0:63] node30_dmem_out;
    wire [63:0] node30_nic_d_out;

    // Address decode
    wire node30_nic_sel = node30_memEn & node30_addr_out[23];
    wire node30_dmem_en = node30_memEn & ~node30_addr_out[23];
    wire node30_dmem_wr = node30_memWrEn & ~node30_addr_out[23];

    reg node30_nic_sel_r;
    always @(posedge clk) begin
        if (reset) node30_nic_sel_r <= 1'b0;
        else       node30_nic_sel_r <= node30_nic_sel;
    end

    // Read-data mux
    assign node30_cpu_d_in = node30_nic_sel_r ? node30_nic_d_out : node30_dmem_out;

    // IMEM
    imem u_node30_imem (
        .memAddr(node30_pc_out[22:29]),
        .dataOut(node30_inst_in)
    );

    // DMEM
    dmem u_node30_dmem (
        .clk(clk),
        .memEn(node30_dmem_en),
        .memWrEn(node30_dmem_wr),
        .memAddr(node30_addr_out[24:31]),
        .dataIn(node30_cpu_d_out),
        .dataOut(node30_dmem_out)
    );

    // CPU
    cardinal_cpu u_node30_cpu (
        .clk(clk),
        .reset(reset),
        .inst_in(node30_inst_in),
        .d_in(node30_cpu_d_in),
        .pc_out(node30_pc_out),
        .addr_out(node30_addr_out),
        .memEn(node30_memEn),
        .memWrEn(node30_memWrEn),
        .d_out(node30_cpu_d_out)
    );

    // NIC
    cardinal_nic u_node30_nic (
        .clk(clk),
        .reset(reset),
        .addr({node30_addr_out[30], node30_addr_out[31]}),
        .d_in(node30_cpu_d_out),
        .d_out(node30_nic_d_out),
        .nicEn(node30_nic_sel),
        .nicWrEn(node30_memWrEn),
        .net_so(pe_si[12]),
        .net_ro(pe_ri[12]),
        .net_do(pe_di[768 +: 64]),
        .net_si(pe_so[12]),
        .net_ri(pe_ro[12]),
        .net_di(pe_do[768 +: 64]),
        .net_polarity(polarity)
    );

    // ============================================================
    // Node 13 (node31) — Row 3, Col 1
    // ============================================================
    wire [0:31] node31_pc_out;
    wire [0:31] node31_inst_in;
    wire [0:31] node31_addr_out;
    wire        node31_memEn;
    wire        node31_memWrEn;
    wire [0:63] node31_cpu_d_out;
    wire [0:63] node31_cpu_d_in;
    wire [0:63] node31_dmem_out;
    wire [63:0] node31_nic_d_out;

    // Address decode
    wire node31_nic_sel = node31_memEn & node31_addr_out[23];
    wire node31_dmem_en = node31_memEn & ~node31_addr_out[23];
    wire node31_dmem_wr = node31_memWrEn & ~node31_addr_out[23];

    reg node31_nic_sel_r;
    always @(posedge clk) begin
        if (reset) node31_nic_sel_r <= 1'b0;
        else       node31_nic_sel_r <= node31_nic_sel;
    end

    // Read-data mux
    assign node31_cpu_d_in = node31_nic_sel_r ? node31_nic_d_out : node31_dmem_out;

    // IMEM
    imem u_node31_imem (
        .memAddr(node31_pc_out[22:29]),
        .dataOut(node31_inst_in)
    );

    // DMEM
    dmem u_node31_dmem (
        .clk(clk),
        .memEn(node31_dmem_en),
        .memWrEn(node31_dmem_wr),
        .memAddr(node31_addr_out[24:31]),
        .dataIn(node31_cpu_d_out),
        .dataOut(node31_dmem_out)
    );

    // CPU
    cardinal_cpu u_node31_cpu (
        .clk(clk),
        .reset(reset),
        .inst_in(node31_inst_in),
        .d_in(node31_cpu_d_in),
        .pc_out(node31_pc_out),
        .addr_out(node31_addr_out),
        .memEn(node31_memEn),
        .memWrEn(node31_memWrEn),
        .d_out(node31_cpu_d_out)
    );

    // NIC
    cardinal_nic u_node31_nic (
        .clk(clk),
        .reset(reset),
        .addr({node31_addr_out[30], node31_addr_out[31]}),
        .d_in(node31_cpu_d_out),
        .d_out(node31_nic_d_out),
        .nicEn(node31_nic_sel),
        .nicWrEn(node31_memWrEn),
        .net_so(pe_si[13]),
        .net_ro(pe_ri[13]),
        .net_do(pe_di[832 +: 64]),
        .net_si(pe_so[13]),
        .net_ri(pe_ro[13]),
        .net_di(pe_do[832 +: 64]),
        .net_polarity(polarity)
    );

    // ============================================================
    // Node 14 (node32) — Row 3, Col 2
    // ============================================================
    wire [0:31] node32_pc_out;
    wire [0:31] node32_inst_in;
    wire [0:31] node32_addr_out;
    wire        node32_memEn;
    wire        node32_memWrEn;
    wire [0:63] node32_cpu_d_out;
    wire [0:63] node32_cpu_d_in;
    wire [0:63] node32_dmem_out;
    wire [63:0] node32_nic_d_out;

    // Address decode
    wire node32_nic_sel = node32_memEn & node32_addr_out[23];
    wire node32_dmem_en = node32_memEn & ~node32_addr_out[23];
    wire node32_dmem_wr = node32_memWrEn & ~node32_addr_out[23];

    reg node32_nic_sel_r;
    always @(posedge clk) begin
        if (reset) node32_nic_sel_r <= 1'b0;
        else       node32_nic_sel_r <= node32_nic_sel;
    end

    // Read-data mux
    assign node32_cpu_d_in = node32_nic_sel_r ? node32_nic_d_out : node32_dmem_out;

    // IMEM
    imem u_node32_imem (
        .memAddr(node32_pc_out[22:29]),
        .dataOut(node32_inst_in)
    );

    // DMEM
    dmem u_node32_dmem (
        .clk(clk),
        .memEn(node32_dmem_en),
        .memWrEn(node32_dmem_wr),
        .memAddr(node32_addr_out[24:31]),
        .dataIn(node32_cpu_d_out),
        .dataOut(node32_dmem_out)
    );

    // CPU
    cardinal_cpu u_node32_cpu (
        .clk(clk),
        .reset(reset),
        .inst_in(node32_inst_in),
        .d_in(node32_cpu_d_in),
        .pc_out(node32_pc_out),
        .addr_out(node32_addr_out),
        .memEn(node32_memEn),
        .memWrEn(node32_memWrEn),
        .d_out(node32_cpu_d_out)
    );

    // NIC
    cardinal_nic u_node32_nic (
        .clk(clk),
        .reset(reset),
        .addr({node32_addr_out[30], node32_addr_out[31]}),
        .d_in(node32_cpu_d_out),
        .d_out(node32_nic_d_out),
        .nicEn(node32_nic_sel),
        .nicWrEn(node32_memWrEn),
        .net_so(pe_si[14]),
        .net_ro(pe_ri[14]),
        .net_do(pe_di[896 +: 64]),
        .net_si(pe_so[14]),
        .net_ri(pe_ro[14]),
        .net_di(pe_do[896 +: 64]),
        .net_polarity(polarity)
    );

    // ============================================================
    // Node 15 (node33) — Row 3, Col 3
    // ============================================================
    wire [0:31] node33_pc_out;
    wire [0:31] node33_inst_in;
    wire [0:31] node33_addr_out;
    wire        node33_memEn;
    wire        node33_memWrEn;
    wire [0:63] node33_cpu_d_out;
    wire [0:63] node33_cpu_d_in;
    wire [0:63] node33_dmem_out;
    wire [63:0] node33_nic_d_out;

    // Address decode
    wire node33_nic_sel = node33_memEn & node33_addr_out[23];
    wire node33_dmem_en = node33_memEn & ~node33_addr_out[23];
    wire node33_dmem_wr = node33_memWrEn & ~node33_addr_out[23];

    reg node33_nic_sel_r;
    always @(posedge clk) begin
        if (reset) node33_nic_sel_r <= 1'b0;
        else       node33_nic_sel_r <= node33_nic_sel;
    end

    // Read-data mux
    assign node33_cpu_d_in = node33_nic_sel_r ? node33_nic_d_out : node33_dmem_out;

    // IMEM
    imem u_node33_imem (
        .memAddr(node33_pc_out[22:29]),
        .dataOut(node33_inst_in)
    );

    // DMEM
    dmem u_node33_dmem (
        .clk(clk),
        .memEn(node33_dmem_en),
        .memWrEn(node33_dmem_wr),
        .memAddr(node33_addr_out[24:31]),
        .dataIn(node33_cpu_d_out),
        .dataOut(node33_dmem_out)
    );

    // CPU
    cardinal_cpu u_node33_cpu (
        .clk(clk),
        .reset(reset),
        .inst_in(node33_inst_in),
        .d_in(node33_cpu_d_in),
        .pc_out(node33_pc_out),
        .addr_out(node33_addr_out),
        .memEn(node33_memEn),
        .memWrEn(node33_memWrEn),
        .d_out(node33_cpu_d_out)
    );

    // NIC
    cardinal_nic u_node33_nic (
        .clk(clk),
        .reset(reset),
        .addr({node33_addr_out[30], node33_addr_out[31]}),
        .d_in(node33_cpu_d_out),
        .d_out(node33_nic_d_out),
        .nicEn(node33_nic_sel),
        .nicWrEn(node33_memWrEn),
        .net_so(pe_si[15]),
        .net_ro(pe_ri[15]),
        .net_do(pe_di[960 +: 64]),
        .net_si(pe_so[15]),
        .net_ri(pe_ro[15]),
        .net_di(pe_do[960 +: 64]),
        .net_polarity(polarity)
    );

endmodule