`include "core_struct.vh"
module Controller (
    input CorePack::inst_t inst,
    output ControllerPack::ControllerSignals ctrl_signals
);

    import CorePack::*;
    import ControllerPack::*;
    
    // fill your code
    opcode_t opcode = inst[6:0];
    funct3_t funct3 = inst[14:12];
    funct7_t funct7 = inst[31:25];

    wire inst_load   = (opcode == LOAD_OPCODE);
    wire inst_imm    = (opcode == IMM_OPCODE);
    wire inst_auipc  = (opcode == AUIPC_OPCODE);
    wire inst_immw   = (opcode == IMMW_OPCODE);
    wire inst_store  = (opcode == STORE_OPCODE);
    wire inst_reg    = (opcode == REG_OPCODE);
    wire inst_lui    = (opcode == LUI_OPCODE);
    wire inst_regw   = (opcode == REGW_OPCODE);
    wire inst_branch = (opcode == BRANCH_OPCODE);
    wire inst_jalr   = (opcode == JALR_OPCODE);
    wire inst_jal    = (opcode == JAL_OPCODE);


    // npc_sel
    function automatic npc_sel_enum decode_npc();
        if (inst_jal | inst_jalr) decode_npc = NPC_SEL_J;
        else if (inst_branch) decode_npc = NPC_SEL_BR;
        else decode_npc = NPC_SEL_PC;
    endfunction

    //immgen_op
    function automatic imm_op_enum decode_imm();
        if(inst_imm | inst_load | inst_jalr | inst_immw) decode_imm = I_IMM;
        else if(inst_store) decode_imm = S_IMM;
        else if(inst_branch) decode_imm = B_IMM;
        else if(inst_lui | inst_auipc) decode_imm = U_IMM;
        else if(inst_jal) decode_imm = UJ_IMM;
        else decode_imm = IMM0;
    endfunction

    //alu_op
    function automatic alu_op_enum decode_alu();
        unique case (opcode)
            LOAD_OPCODE, STORE_OPCODE, AUIPC_OPCODE, JALR_OPCODE, JAL_OPCODE, LUI_OPCODE, BRANCH_OPCODE:
            decode_alu = ALU_ADD;
            IMM_OPCODE: begin
                case (funct3)
                    3'b000: decode_alu = ALU_ADD;
                    3'b001: decode_alu = ALU_SLL;
                    3'b010: decode_alu = ALU_SLT;
                    3'b011: decode_alu = ALU_SLTU;
                    3'b100: decode_alu = ALU_XOR;
                    3'b101: decode_alu = funct7[5] ? ALU_SRA : ALU_SRL;
                    3'b110: decode_alu = ALU_OR;
                    3'b111: decode_alu = ALU_AND;
                default: decode_alu = ALU_DEFAULT;
                endcase
            end
            IMMW_OPCODE: begin
                case (funct3)
                    3'b000: decode_alu = ALU_ADDW;
                    3'b001: decode_alu = ALU_SLLW;
                    3'b101: decode_alu = funct7[5] ? ALU_SRAW : ALU_SRLW;
                default: decode_alu = ALU_DEFAULT;
                endcase
            end
            REG_OPCODE: begin
                case (funct3)
                    3'b000: decode_alu = funct7[5] ? ALU_SUB : ALU_ADD;
                    3'b001: decode_alu = ALU_SLL;
                    3'b010: decode_alu = ALU_SLT;
                    3'b011: decode_alu = ALU_SLTU;
                    3'b100: decode_alu = ALU_XOR;
                    3'b101: decode_alu = funct7[5] ? ALU_SRA : ALU_SRL;
                    3'b110: decode_alu = ALU_OR;
                    3'b111: decode_alu = ALU_AND;
                default: decode_alu = ALU_DEFAULT;
                endcase
            end
            REGW_OPCODE: begin
                case (funct3)
                    3'b000: decode_alu = funct7[5] ? ALU_SUBW : ALU_ADDW;
                    3'b001: decode_alu = ALU_SLLW;
                    3'b101: decode_alu = funct7[5] ? ALU_SRAW : ALU_SRLW;
                default: decode_alu = ALU_DEFAULT;
                endcase
            end
            default: decode_alu = ALU_DEFAULT;
        endcase
    endfunction

    //cmp_op
    function automatic cmp_op_enum decode_cmp();
        if (inst_branch) begin
            case (funct3)
                3'b000: decode_cmp = CMP_EQ;
                3'b001: decode_cmp = CMP_NE;
                3'b100: decode_cmp = CMP_LT;
                3'b101: decode_cmp = CMP_GE;
                3'b110: decode_cmp = CMP_LTU;
                3'b111: decode_cmp = CMP_GEU;
            default: decode_cmp = CMP_NO;
            endcase
        end else decode_cmp = CMP_NO;
    endfunction

    //wb_sel
    function automatic wb_sel_op_enum decode_wb();
        if (inst_load) decode_wb = WB_SEL_MEM;
        else if (inst_jal | inst_jalr) decode_wb = WB_SEL_PC;
        else decode_wb = WB_SEL_ALU;
    endfunction

    //mem_op
    function automatic mem_op_enum decode_mem();
        if (inst_load) begin
            case (funct3)
                3'b000: decode_mem = MEM_B;
                3'b001: decode_mem = MEM_H;
                3'b010: decode_mem = MEM_W;
                3'b011: decode_mem = MEM_D;
                3'b100: decode_mem = MEM_UB;
                3'b101: decode_mem = MEM_UH;
                3'b110: decode_mem = MEM_UW;
            default: decode_mem = MEM_NO;
            endcase
        end else if (inst_store) begin
            case (funct3)
                3'b000: decode_mem = MEM_B;
                3'b001: decode_mem = MEM_H;
                3'b010: decode_mem = MEM_W;
                3'b011: decode_mem = MEM_D;
            default: decode_mem = MEM_NO;
            endcase
        end else decode_mem = MEM_NO;
    endfunction

    //单点赋值
    always_comb begin
        ctrl_signals.we_reg  = (inst_reg | inst_load | inst_imm | inst_auipc | inst_lui | inst_regw | inst_jal | inst_jalr | inst_immw);
        ctrl_signals.we_mem  = inst_store;
        ctrl_signals.re_mem  = inst_load;
        ctrl_signals.npc_sel = decode_npc();
        ctrl_signals.immgen_op = decode_imm();
        ctrl_signals.alu_op = decode_alu();
        ctrl_signals.cmp_op = decode_cmp();
        ctrl_signals.alu_asel = (inst_auipc | inst_jal | inst_branch) ? ASEL_PC : (inst_lui ? ASEL0 : ASEL_REG);
        ctrl_signals.alu_bsel = (inst_reg | inst_regw) ? BSEL_REG : BSEL_IMM;
        ctrl_signals.wb_sel = decode_wb();
        ctrl_signals.mem_op = decode_mem();
    end

endmodule