`include "core_struct.vh"
`include "csr_struct.vh"
module ImmGen (
    input CorePack::inst_t inst,
    input CorePack::imm_op_enum immgen_op,
    output CorePack::data_t imm
);

    import CorePack::*;

    always_comb begin
        case (immgen_op)
            I_IMM:   imm = {{52{inst[31]}}, inst[31:20]};
            S_IMM:   imm = {{52{inst[31]}}, inst[31:25], inst[11:7]};
            B_IMM:   imm = {{51{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
            U_IMM:   imm = {{32{inst[31]}}, inst[31:12], 12'b0};
            UJ_IMM:  imm = {{43{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};
            default: imm = 64'b0;
        endcase
    end
endmodule


module Reg_IF_ID (
    input clk,
    input rst,
    input PipelinePack::IFID reg_in,
    input flush,
    input en,
    output PipelinePack::IFID reg_out
);

    import CorePack::*;
    import PipelinePack::*;

    IFID reg_out_tmp;
    assign reg_out = reg_out_tmp;

    always_ff @(posedge clk) begin
        if (rst) begin
            reg_out_tmp <= '{
                inst:   32'h00000013, // NOP
                valid:     '0,
                default:   '0
            };
        end else if (flush) begin
            reg_out_tmp <= '{
                pc:        '0,//reg_in.pc,
                inst:   32'h00000013, // NOP
                valid:     '0,
                default:   '0
            };
        end else if (en) begin
            reg_out_tmp <= reg_in;
        end
    end
endmodule


module Reg_ID_EX (
    input clk,
    input rst,
    input PipelinePack::IDEXE reg_in,
    input flush,
    input en,
    output PipelinePack::IDEXE reg_out
);

    import CorePack::*;
    import PipelinePack::*;
    import CsrPack::*;

    IDEXE reg_out_tmp;
    assign reg_out = reg_out_tmp;

    always_ff @(posedge clk) begin
        if (rst) begin
            reg_out_tmp <= '{
                inst:     32'h00000013, // NOP
                npc_sel:  NPC_SEL_PC,
                alu_op:   ALU_DEFAULT,
                cmp_op:   CMP_NO,
                alu_asel: ASEL0,
                alu_bsel: BSEL0,
                wb_sel:   WB_SEL_CSR,
                mem_op:   MEM_NO,
                csr_we:   '0,
                csr_alu_op: CSR_ALU_ADD,
                csr_alu_asel: ASEL_CSR0, // 新增显式初始化
                csr_alu_bsel: BSEL_CSR0, // 新增显式初始化
                csr_ret:  '0,
                except:   '{default: 0},
                valid:    '0,
                default:  '0
                };
        end else if (flush) begin
            reg_out_tmp <= '{
                pc:       '0,//reg_in.pc,
                inst:     32'h00000013, // NOP
                npc_sel:  NPC_SEL_PC,
                alu_op:   ALU_DEFAULT,
                cmp_op:   CMP_NO,
                alu_asel: ASEL0,
                alu_bsel: BSEL0,
                wb_sel:   WB_SEL_CSR,
                mem_op:   MEM_NO,
                csr_we:   '0,
                csr_alu_op: CSR_ALU_ADD,
                csr_alu_asel: ASEL_CSR0, // 新增显式初始化
                csr_alu_bsel: BSEL_CSR0, // 新增显式初始化
                csr_ret:  '0,
                except:   '{default: 0},
                valid:    '0,
                default:  '0
                };
        end else if (en) begin
            reg_out_tmp <= reg_in;
        end
    end
endmodule


module Reg_EXE_MEM (
    input clk,
    input rst,
    input flush,
    input en,
    input PipelinePack::EXEMEM reg_in,
    output PipelinePack::EXEMEM reg_out
);

    import CorePack::*;
    import PipelinePack::*;
    import CsrPack::*;

    EXEMEM reg_out_tmp;
    assign reg_out = reg_out_tmp;

    always_ff @(posedge clk) begin
        if (rst) begin
            reg_out_tmp <= '{
                inst:    32'h00000013, // NOP
                wb_sel:  WB_SEL_CSR,
                mem_op:  MEM_NO,
                csr_we:   '0,
                csr_alu_op: CSR_ALU_ADD,
                csr_alu_asel: ASEL_CSR0, // 新增显式初始化
                csr_alu_bsel: BSEL_CSR0, // 新增显式初始化
                csr_ret:  '0,
                except:   '{default: 0},
                valid:   '0,
                default: '0
                };
        end else if (flush) begin
            reg_out_tmp <= '{
                inst:    32'h00000013, // NOP
                wb_sel:  WB_SEL_CSR,
                mem_op:  MEM_NO,
                csr_we:   '0,
                csr_alu_op: CSR_ALU_ADD,
                csr_alu_asel: ASEL_CSR0, // 新增显式初始化
                csr_alu_bsel: BSEL_CSR0, // 新增显式初始化
                csr_ret:  '0,
                except:   '{default: 0},
                valid:   '0,
                default: '0
                };
        end else if (en) begin
            reg_out_tmp <= reg_in;
        end
    end
endmodule

module Reg_MEM_WB (
    input clk,
    input rst,
    input flush,
    input PipelinePack::MEMWB reg_in,
    output PipelinePack::MEMWB reg_out
);

    import CorePack::*;
    import PipelinePack::*;
    import CsrPack::*;

    MEMWB reg_out_tmp;
    assign reg_out = reg_out_tmp;

    always_ff @(posedge clk) begin
        if (rst) begin
            reg_out_tmp <= '{
                inst:    32'h00000013, // NOP
                wb_sel:  WB_SEL_CSR,
                csr_we:   '0,
                csr_ret:  '0,
                except:   '{default: 0},
                valid:   '0,
                default: '0
                };
        end else if (flush) begin
            reg_out_tmp <= '{
                inst:    32'h00000013, // NOP
                wb_sel:  WB_SEL_CSR,
                csr_we:   '0,
                csr_ret:  '0,
                except:   '{default: 0},
                valid:   '0,
                default: '0
                };
        end else begin
            reg_out_tmp <= reg_in;
        end
    end
endmodule

module ForwardingSelector (
    // data
    input CorePack::data_t read_data_1_id,
    input CorePack::data_t read_data_2_id,
    input CorePack::data_t alu_res_ex,
    input CorePack::data_t wb_val_mem,
    input CorePack::data_t wb_val_wb,
    // control signals
    input PipelinePack::fwd_sel_enum fwd_asel_id,
    input PipelinePack::fwd_sel_enum fwd_bsel_id,
    output CorePack::data_t fwd_data_1_id,
    output CorePack::data_t fwd_data_2_id
);

    import CorePack::*;
    import PipelinePack::*;

    always_comb begin
        // Forwarding for ALU operand A
        case (fwd_asel_id)
            FWD_SEL_ID:  fwd_data_1_id = read_data_1_id;
            FWD_SEL_EX:  fwd_data_1_id = alu_res_ex;
            FWD_SEL_MEM: fwd_data_1_id = wb_val_mem;
            FWD_SEL_WB:  fwd_data_1_id = wb_val_wb;
        endcase

        // Forwarding for ALU operand B
        case (fwd_bsel_id)
            FWD_SEL_ID:  fwd_data_2_id = read_data_2_id;
            FWD_SEL_EX:  fwd_data_2_id = alu_res_ex;
            FWD_SEL_MEM: fwd_data_2_id = wb_val_mem;
            FWD_SEL_WB:  fwd_data_2_id = wb_val_wb;
        endcase
    end

endmodule


module HazardDetector (
    // Info about instruction in ID stage
    input CorePack::inst_t inst_id,
    // Info about instruction in EX stage
    input PipelinePack::IDEXE id_ex_reg_out,
    // Info about instruction in MEM stage
    input PipelinePack::EXEMEM ex_mem_reg_out,
    // Info about instruction in WB stage
    input PipelinePack::MEMWB mem_wb_reg_out,
    // Control outputs
    output PipelinePack::fwd_sel_enum fwd_asel_id,
    output PipelinePack::fwd_sel_enum fwd_bsel_id
    //output logic stall
);

    import CorePack::*;
    import PipelinePack::*;

    // Extract register indices from the ID stage instruction
    logic [4:0] rs1_id, rs2_id;
    assign rs1_id = inst_id[19:15];
    assign rs2_id = inst_id[24:20];

    // Hazard Detection Logic
    always_comb begin
        // Default values
        fwd_asel_id = FWD_SEL_ID;
        fwd_bsel_id = FWD_SEL_ID;
        //stall = 1'b0;

        // Forward from EX to ID
        if(id_ex_reg_out.we_reg &&
           id_ex_reg_out.valid &&
           id_ex_reg_out.rd != 0) begin
            // Load-use hazard
            //if(id_ex_reg_out.wb_sel == WB_SEL_MEM) begin
                //if(id_ex_reg_out.rd == rs1_id || id_ex_reg_out.rd == rs2_id) begin
                    //stall = 1'b1;
                //end
            //end else begin // forward data to id
                if(id_ex_reg_out.rd == rs1_id) begin
                    fwd_asel_id = FWD_SEL_EX;
                end
                if(id_ex_reg_out.rd == rs2_id) begin
                    fwd_bsel_id = FWD_SEL_EX;
                end
            //end
        end

        // Forward from MEM to ID
        if(ex_mem_reg_out.we_reg &&
           ex_mem_reg_out.valid &&
           ex_mem_reg_out.rd != 0) begin
            if(ex_mem_reg_out.rd == rs1_id) begin
                if(fwd_asel_id == FWD_SEL_ID) begin
                    fwd_asel_id = FWD_SEL_MEM;
                end
            end
            if(ex_mem_reg_out.rd == rs2_id) begin
                if(fwd_bsel_id == FWD_SEL_ID) begin
                    fwd_bsel_id = FWD_SEL_MEM;
                end
            end
        end

    // Forward from WB to ID
        if(mem_wb_reg_out.we_reg &&
           mem_wb_reg_out.valid &&
           mem_wb_reg_out.rd != 0) begin
            if(mem_wb_reg_out.rd == rs1_id) begin
                if(fwd_asel_id == FWD_SEL_ID) begin
                    fwd_asel_id = FWD_SEL_WB;
                end
            end
            if(mem_wb_reg_out.rd == rs2_id) begin
                if(fwd_bsel_id == FWD_SEL_ID) begin
                    fwd_bsel_id = FWD_SEL_WB;
                end
            end
        end
    end

endmodule
