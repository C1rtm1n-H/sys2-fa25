`include "core_struct.vh"
module ALU (
  input  CorePack::data_t a,
  input  CorePack::data_t b,
  input  CorePack::alu_op_enum  alu_op,
  output CorePack::data_t res
);

  import CorePack::*;

  // fill your code
  logic [31:0] res_w;
  always_comb begin
  res_w = 32'b0;
  case (alu_op)
    ALU_ADD: res = a + b;
    ALU_SUB: res = a - b;
    ALU_AND: res = a & b;
    ALU_OR:  res = a | b;
    ALU_XOR: res = a ^ b;
    ALU_SLT: res = ($signed(a) < $signed(b)) ? 1 : 0;
    ALU_SLTU:res = (a < b) ? 1 : 0;
    ALU_SLL: res = a << b[5:0];
    ALU_SRL: res = a >> b[5:0];
    ALU_SRA: res = $signed(a) >>> b[5:0];

    ALU_ADDW: begin
      res_w = a[31:0] + b[31:0];
      res = {{32{res_w[31]}}, res_w};
    end
    ALU_SUBW: begin
      res_w = a[31:0] - b[31:0];
      res = {{32{res_w[31]}}, res_w};
    end
    ALU_SLLW: begin
      res_w = a[31:0] << b[4:0];
      res = {{32{res_w[31]}}, res_w};
    end
    ALU_SRLW: begin
      res_w = a[31:0] >> b[4:0];
      res = {{32{res_w[31]}}, res_w};
    end
    ALU_SRAW: begin
      res_w = $signed(a[31:0]) >>> b[4:0];
      res = {{32{res_w[31]}}, res_w};
    end
    ALU_DEFAULT: res = 0;
    default: res = 0;
  endcase
  end
  
endmodule
