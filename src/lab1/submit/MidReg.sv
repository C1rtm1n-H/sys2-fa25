`include "core_struct.vh"
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
    output PipelinePack::IFID reg_out
);

    import CorePack::*;
    import PipelinePack::*;

    IFID reg_out_tmp;
    assign reg_out = reg_out_tmp;

    always_ff @(posedge clk) begin
        if (rst) begin
            reg_out_tmp <= '{
                inst:      32'h00000013, // NOP
                valid:     '0,
                default:   '0
            };
        end else if (flush) begin
            reg_out_tmp <= '{
                pc:        64'h00000000000002b0,
                inst:      32'h00000013, // NOP
                valid:     '0,
                default:   '0
            };
        end else begin
            reg_out_tmp <= reg_in;
        end
    end
endmodule


module Reg_ID_EX (
    input clk,
    input rst,
    input PipelinePack::IDEXE reg_in,
    input flush,
    output PipelinePack::IDEXE reg_out
);
    import CorePack::*;
    import PipelinePack::*;

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
                wb_sel:   WB_SEL0,
                mem_op:   MEM_NO,
                valid:    '0,
                default:  '0
                };
        end else if (flush) begin
            reg_out_tmp <= '{
                pc:       64'h00000000000002b0,
                inst:     32'h00000013, // NOP
                npc_sel:  NPC_SEL_PC,
                alu_op:   ALU_DEFAULT,
                cmp_op:   CMP_NO,
                alu_asel: ASEL0,
                alu_bsel: BSEL0,
                wb_sel:   WB_SEL0,
                mem_op:   MEM_NO,
                valid:    '0,
                default:  '0
                };
        end else begin
            reg_out_tmp <= reg_in;
        end
    end
endmodule


module Reg_EXE_MEM (
    input clk,
    input rst,
    input PipelinePack::EXEMEM reg_in,
    output PipelinePack::EXEMEM reg_out
);
    import CorePack::*;
    import PipelinePack::*;

    EXEMEM reg_out_tmp;
    assign reg_out = reg_out_tmp;

    always_ff @(posedge clk) begin
        if (rst) begin
            reg_out_tmp <= '{
                inst:    32'h00000013, // NOP
                wb_sel:  WB_SEL0,
                mem_op:  MEM_NO,
                valid:   '0,
                default: '0
                };
        end else begin
            reg_out_tmp <= reg_in;
        end
    end
endmodule

module Reg_MEM_WB (
    input clk,
    input rst,
    input PipelinePack::MEMWB reg_in,
    output PipelinePack::MEMWB reg_out
);
    import CorePack::*;
    import PipelinePack::*;

    MEMWB reg_out_tmp;
    assign reg_out = reg_out_tmp;

    always_ff @(posedge clk) begin
        if (rst) begin
            reg_out_tmp <= '{
                inst:    32'h00000013, // NOP
                wb_sel:  WB_SEL0,
                valid:   '0,
                default: '0
                };
        end else begin
            reg_out_tmp <= reg_in;
        end
    end
endmodule
