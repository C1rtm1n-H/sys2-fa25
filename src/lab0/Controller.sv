`include "core_struct.vh"
module Controller (
    input CorePack::inst_t inst,
    output we_reg,
    output we_mem,
    output re_mem,
    output npc_sel,
    output CorePack::imm_op_enum immgen_op,
    output CorePack::alu_op_enum alu_op,
    output CorePack::cmp_op_enum cmp_op,
    output CorePack::alu_asel_op_enum alu_asel,
    output CorePack::alu_bsel_op_enum alu_bsel,
    output CorePack::wb_sel_op_enum wb_sel,
    output CorePack::mem_op_enum mem_op
    // output ControllerPack::ControllerSignals ctrl_signals
);

    import CorePack::*;
    // import ControllerPack::*;
    
    // fill your code
    opcode_t opcode = inst[6:0];
    funct3_t funct3 = inst[14:12];
    funct7_t funct7 = inst[31:25];

    wire inst_load = opcode == LOAD_OPCODE;
    wire inst_imm = opcode == IMM_OPCODE;
    wire inst_auipc = opcode == AUIPC_OPCODE;
    wire inst_immw = opcode == IMMW_OPCODE;
    wire inst_store = opcode == STORE_OPCODE;
    wire inst_reg = opcode == REG_OPCODE;
    wire inst_lui = opcode == LUI_OPCODE;
    wire inst_regw = opcode == REGW_OPCODE;
    wire inst_branch = opcode == BRANCH_OPCODE;
    wire inst_jalr = opcode == JALR_OPCODE;
    wire inst_jal = opcode == JAL_OPCODE;

    always_comb begin
        we_reg = 1'b0;
        we_mem = 1'b0;
        re_mem = 1'b0;
        npc_sel = 1'b0;
        immgen_op = IMM0;
        alu_op = ALU_DEFAULT;
        cmp_op = CMP_NO;
        alu_asel = ASEL0;
        alu_bsel = BSEL0;
        wb_sel = WB_SEL0;
        mem_op = MEM_NO;


        we_reg = inst_reg | inst_load | inst_imm | inst_auipc | inst_lui | inst_regw | inst_jal | inst_jalr | inst_immw;
        we_mem = inst_store;
        re_mem = inst_load;
        npc_sel = inst_jal | inst_jalr;


        //immgen_op
        if (inst_imm | inst_load | inst_jalr | inst_immw) begin
            immgen_op = I_IMM;
        end else if (inst_store) begin
            immgen_op = S_IMM;
        end else if (inst_branch) begin
            immgen_op = B_IMM;
        end else if (inst_lui || inst_auipc) begin
            immgen_op = U_IMM;
        end else if (inst_jal) begin
            immgen_op = UJ_IMM;
        end else begin
            immgen_op = IMM0;
        end


        //alu_op
        if (inst_load | inst_store | inst_auipc | inst_jalr | inst_jal | inst_lui | inst_branch) begin
            alu_op = ALU_ADD;
        end else if (inst_imm) begin
            case (funct3)
                3'b000: alu_op = ALU_ADD;
                3'b001: alu_op = ALU_SLL;
                3'b010: alu_op = ALU_SLT;
                3'b011: alu_op = ALU_SLTU;
                3'b100: alu_op = ALU_XOR;
                3'b101: alu_op = funct7[5] ? ALU_SRA : ALU_SRL;
                3'b110: alu_op = ALU_OR;
                3'b111: alu_op = ALU_AND;
                default: alu_op = ALU_DEFAULT;
            endcase
        end else if (inst_immw) begin
            case (funct3)
                3'b000: alu_op = ALU_ADDW;
                3'b001: alu_op = ALU_SLLW;
                3'b101: alu_op = funct7[5] ? ALU_SRAW : ALU_SRLW;
                default: alu_op = ALU_DEFAULT;
            endcase
        end else if (inst_reg) begin
            case (funct3)
                3'b000: alu_op = funct7[5] ? ALU_SUB : ALU_ADD;
                3'b001: alu_op = ALU_SLL;
                3'b010: alu_op = ALU_SLT;
                3'b011: alu_op = ALU_SLTU;
                3'b100: alu_op = ALU_XOR;
                3'b101: alu_op = funct7[5] ? ALU_SRA : ALU_SRL;
                3'b110: alu_op = ALU_OR;
                3'b111: alu_op = ALU_AND;
                default: alu_op = ALU_DEFAULT;
            endcase
        end else if (inst_regw) begin
            case (funct3)
                3'b000: alu_op = funct7[5] ? ALU_SUBW : ALU_ADDW;
                3'b001: alu_op = ALU_SLLW;
                3'b101: alu_op = funct7[5] ? ALU_SRAW : ALU_SRLW;
                default: alu_op = ALU_DEFAULT;
            endcase
        end else begin
            alu_op = ALU_DEFAULT;
        end


        //cmp_op
        if (inst_branch) begin
            case (funct3)
                3'b000: cmp_op = CMP_EQ;
                3'b001: cmp_op = CMP_NE;
                3'b100: cmp_op = CMP_LT;
                3'b101: cmp_op = CMP_GE;
                3'b110: cmp_op = CMP_LTU;
                3'b111: cmp_op = CMP_GEU;
                default: cmp_op = CMP_NO;
            endcase
        end else begin
            cmp_op = CMP_NO;
        end


        //alu_asel
        if (inst_auipc | inst_jal | inst_branch) begin
            alu_asel = ASEL_PC;
        end else if (inst_lui) begin
            alu_asel = ASEL0;
        end else if (inst_imm | inst_immw | inst_load | inst_store | inst_reg | inst_regw | inst_branch) begin
            alu_asel = ASEL_REG;
        end else begin
            alu_asel = ASEL_REG;
        end


        //alu_bsel
        if (inst_load | inst_imm | inst_auipc | inst_store | inst_jalr | inst_jal | inst_lui | inst_immw | inst_branch) begin
            alu_bsel = BSEL_IMM;
        end else if (inst_reg | inst_regw) begin
            alu_bsel = BSEL_REG;
        end else begin
            alu_bsel = BSEL_REG;
        end


        //wb_sel
        if (inst_load) begin
            wb_sel = WB_SEL_MEM;
        end else if (inst_imm | inst_auipc | inst_lui | inst_regw | inst_reg | inst_immw) begin
            wb_sel = WB_SEL_ALU;
        end else if (inst_jal | inst_jalr) begin
            wb_sel = WB_SEL_PC;
        end else begin
            wb_sel = WB_SEL_ALU;
        end


        //mem_op
        if (inst_load) begin
            case (funct3)
                3'b000: mem_op = MEM_B;
                3'b001: mem_op = MEM_H;
                3'b010: mem_op = MEM_W;
                3'b011: mem_op = MEM_D;
                3'b100: mem_op = MEM_UB;
                3'b101: mem_op = MEM_UH;
                3'b110: mem_op = MEM_UW;
                default: mem_op = MEM_NO;
            endcase
        end else if (inst_store) begin
            case (funct3)
                3'b000: mem_op = MEM_B;
                3'b001: mem_op = MEM_H;
                3'b010: mem_op = MEM_W;
                3'b011: mem_op = MEM_D;
                default: mem_op = MEM_NO;
            endcase
        end else begin
            mem_op = MEM_NO;
        end
    end
endmodule
