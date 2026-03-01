`include "core_struct.vh"

module DataPkg(
    input CorePack::mem_op_enum mem_op,
    input CorePack::data_t reg_data,
    input CorePack::addr_t dmem_waddr,
    output CorePack::data_t dmem_wdata
);

  import CorePack::*;

  // Data package
  // fill your code
logic [5:0] shift;
logic [63:0] temp;
always_comb begin
    dmem_wdata = 64'b0;
    temp = 64'b0;
    shift = dmem_waddr[2:0] * 8;
    case (mem_op)
      MEM_D: begin
        dmem_wdata = reg_data[63:0];
      end
      MEM_W: begin
        temp = data_t'(reg_data[31:0]);
        dmem_wdata = temp << shift;
      end
      MEM_H: begin
        temp = data_t'(reg_data[15:0]);
        dmem_wdata = temp << shift;
      end
      MEM_B: begin
        temp = data_t'(reg_data[7:0]);
        dmem_wdata = temp << shift;
      end
      MEM_NO, MEM_UB, MEM_UH, MEM_UW: begin
        dmem_wdata = 64'b0;
      end
      default: begin
        dmem_wdata = 64'b0;
      end
    endcase
end
endmodule
