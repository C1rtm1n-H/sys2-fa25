`include "core_struct.vh"
`include "csr_struct.vh"

module CSRALU (
    input  CorePack::data_t csr_val,    // CSR 的旧值 (从 CSRModule 读取)
    input  CorePack::data_t rs1_val,    // rs1 的值 (或 zimm)
    input  CsrPack::csr_alu_op_enum op, // CSR ALU 操作码
    output CorePack::data_t csr_new_val // 计算出的 CSR 新值
);
    import CsrPack::*;

    always_comb begin
        case (op)
            CSR_ALU_ADD:    csr_new_val = rs1_val;                // csrrw: new = rs1
            CSR_ALU_OR:     csr_new_val = csr_val | rs1_val;      // csrrs: new = old | rs1
            CSR_ALU_ANDNOT: csr_new_val = csr_val & (~rs1_val);   // csrrc: new = old & ~rs1
            default:        csr_new_val = csr_val;
        endcase
    end
endmodule