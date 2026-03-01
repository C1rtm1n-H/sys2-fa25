`include "core_struct.vh"

module MaskGen(
    input CorePack::mem_op_enum mem_op,
    input CorePack::addr_t dmem_waddr,
    output CorePack::mask_t dmem_wmask
);

  import CorePack::*;

  // Mask generation
  // fill your code
  logic [2:0] shift;
  always_comb begin
    shift = dmem_waddr[2:0];
    case (mem_op)
      MEM_D: dmem_wmask = 8'b11111111;
      MEM_W: dmem_wmask = 8'b00001111 << shift;
      MEM_H: dmem_wmask = 8'b00000011 << shift;
      MEM_B: dmem_wmask = 8'b00000001 << shift;
      MEM_NO, MEM_UB, MEM_UH, MEM_UW: dmem_wmask = 8'b00000000;
      default: dmem_wmask = 8'b00000000;
    endcase
  end
endmodule
