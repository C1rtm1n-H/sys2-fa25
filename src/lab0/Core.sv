`include "core_struct.vh"
module Core (
    input clk,
    input rst,

    Mem_ift.Master imem_ift,
    Mem_ift.Master dmem_ift,

    output cosim_valid,
    output CorePack::CoreInfo cosim_core_info
);
    import CorePack::*;
    
    // fill your code

    /* --- Instruction Fetch --- */

    //pc
    addr_t pc, next_pc;
    logic npc_sel;
    data_t imm;


    always_ff @(posedge clk or posedge rst) begin
        if(rst) begin
            pc <= 64'b0;
        end else begin
            pc <= next_pc;
        end
    end

    assign imem_ift.r_request_bits.raddr = pc;
    assign imem_ift.r_request_valid = 1'b1;
    assign imem_ift.r_reply_ready = 1'b1;
    assign imem_ift.w_request_valid = 1'b0;
    assign imem_ift.w_reply_ready   = 1'b1;
    assign imem_ift.w_request_bits.waddr = 64'b0;
    assign imem_ift.w_request_bits.wdata = 64'b0;
    assign imem_ift.w_request_bits.wmask = 8'b0;

    assign next_pc = (br_taken) ? alu_res : (pc + 4);

    //instruction selection
    inst_t inst;
    assign inst = (pc[2]) ? imem_ift.r_reply_bits.rdata[63:32] : imem_ift.r_reply_bits.rdata[31:0];


/* --- Instruction Decode --- */

    //controller
    logic we_reg, we_mem, re_mem;
    imm_op_enum immgen_op;
    alu_op_enum alu_op;
    cmp_op_enum cmp_op;
    alu_asel_op_enum alu_asel;
    alu_bsel_op_enum alu_bsel;
    wb_sel_op_enum wb_sel;
    mem_op_enum mem_op;


    Controller controller1 (
        .inst(inst),
        .we_reg(we_reg),
        .we_mem(we_mem),
        .re_mem(re_mem),
        .npc_sel(npc_sel),
        .immgen_op(immgen_op),
        .alu_op(alu_op),
        .cmp_op(cmp_op),
        .alu_asel(alu_asel),
        .alu_bsel(alu_bsel),
        .wb_sel(wb_sel),
        .mem_op(mem_op)
    );


    //register file
    reg_ind_t rs1, rs2, rd;
    data_t read_data_1, read_data_2, wb_val;
    assign rs1 = inst[19:15];
    assign rs2 = inst[24:20];
    assign rd = inst[11:7];


    RegFile reg1 (
        .clk(clk),
        .rst(rst),
        .we(we_reg),
        .read_addr_1(rs1),
        .read_addr_2(rs2),
        .write_addr(rd),
        .write_data(wb_val),
        .read_data_1(read_data_1),
        .read_data_2(read_data_2)
    );


    //imm
    ImmGen imm_gen (
        .inst(inst),
        .immgen_op(immgen_op),
        .imm(imm)
    );


    /* --- Execute --- */

    //alu
    data_t alu_a, alu_b, alu_res;

    always_comb begin
        case (alu_asel)
            ASEL_REG: alu_a = read_data_1;
            ASEL_PC: alu_a = pc;
            default: alu_a = 64'b0;
        endcase
    end

    always_comb begin
        case (alu_bsel)
            BSEL_REG: alu_b = read_data_2;
            BSEL_IMM: alu_b = imm;
            default: alu_b = 64'b0;
        endcase
    end

    ALU alu (
        .a(alu_a),
        .b(alu_b),
        .alu_op(alu_op),
        .res(alu_res)
    );

    //cmp
    logic cmp_res, br_taken;

    Cmp cmp (
        .a(read_data_1),
        .b(read_data_2),
        .cmp_op(cmp_op),
        .cmp_res(cmp_res)
    );

    assign br_taken = cmp_res | npc_sel;

/* --- Memory --- */

    data_t read_data;
    addr_t dmem_raddr, dmem_waddr;

    DataPkg data_pkg (
        .mem_op(mem_op),
        .reg_data(read_data_2),
        .dmem_waddr(alu_res),
        .dmem_wdata(dmem_ift.w_request_bits.wdata)
    );

    MaskGen mask_gen(
        .mem_op(mem_op),
        .dmem_waddr(alu_res),
        .dmem_wmask(dmem_ift.w_request_bits.wmask)
    );

    DataTrunc trunc(
        .dmem_rdata(dmem_ift.r_reply_bits.rdata),
        .mem_op(mem_op),
        .dmem_raddr(dmem_ift.r_request_bits.raddr),
        .read_data(read_data)
    );

    assign dmem_ift.r_request_bits.raddr = alu_res;
    assign dmem_ift.r_request_valid = re_mem;
    assign dmem_ift.r_reply_ready = 1'b1;

    assign dmem_ift.w_request_bits.waddr = alu_res;
    assign dmem_ift.w_request_valid = we_mem;
    assign dmem_ift.w_reply_ready = 1'b1;


/* --- Write Back --- */

    always_comb begin
        case (wb_sel)
            WB_SEL_ALU: wb_val = alu_res;
            WB_SEL_MEM: wb_val = read_data;
            WB_SEL_PC: wb_val = pc + 4;
            default: wb_val = 64'b0;
        endcase
    end

    assign cosim_valid = 1'b1;
    assign cosim_core_info.pc        = pc;
    assign cosim_core_info.inst      = {32'b0,inst};   
    assign cosim_core_info.rs1_id    = {59'b0, rs1};
    assign cosim_core_info.rs1_data  = read_data_1;
    assign cosim_core_info.rs2_id    = {59'b0, rs2};
    assign cosim_core_info.rs2_data  = read_data_2;
    assign cosim_core_info.alu       = alu_res;
    assign cosim_core_info.mem_addr  = dmem_ift.r_request_bits.raddr;
    assign cosim_core_info.mem_we    = {63'b0, dmem_ift.w_request_valid};
    assign cosim_core_info.mem_wdata = dmem_ift.w_request_bits.wdata;
    assign cosim_core_info.mem_rdata = dmem_ift.r_reply_bits.rdata;
    assign cosim_core_info.rd_we     = {63'b0, we_reg};
    assign cosim_core_info.rd_id     = {59'b0, rd}; 
    assign cosim_core_info.rd_data   = wb_val;
    assign cosim_core_info.br_taken  = {63'b0, br_taken};
    assign cosim_core_info.npc       = next_pc;

endmodule

module ImmGen (
    input CorePack::inst_t inst,
    input CorePack::imm_op_enum immgen_op,
    output CorePack::data_t imm
);

    import CorePack::*;

    always_comb begin
        case (immgen_op)
            I_IMM: imm = {{52{inst[31]}}, inst[31:20]};
            S_IMM: imm = {{52{inst[31]}}, inst[31:25], inst[11:7]};
            B_IMM: imm = {{51{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
            U_IMM: imm = {{32{inst[31]}}, inst[31:12], 12'b0};
            UJ_IMM: imm = {{43{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};
            default: imm = 64'b0;
        endcase
    end
endmodule