`include "core_struct.vh"

module DataTrunc (
    input CorePack::data_t dmem_rdata,
    input CorePack::mem_op_enum mem_op,
    input CorePack::addr_t dmem_raddr,
    output CorePack::data_t read_data
);

  import CorePack::*;

  // Data trunction
  // fill your code
  logic [5:0] shift;
  logic [63:0] temp;
  always_comb begin
    shift = dmem_raddr[2:0] * 8;
    temp = dmem_rdata >> shift;
    case (mem_op)
      MEM_NO: begin
        read_data = 64'b0;
      end
      MEM_D: begin
        read_data = dmem_rdata;
      end
      MEM_W: begin
        read_data = {{32{temp[31]}}, temp[31:0]};
      end
      MEM_H: begin
        read_data = {{48{temp[15]}}, temp[15:0]};
      end
      MEM_B: begin
        read_data = {{56{temp[7]}}, temp[7:0]};
      end
      MEM_UB: begin
        read_data = {56'b0, temp[7:0]};
      end
      MEM_UH: begin
        read_data = {48'b0, temp[15:0]};
      end
      MEM_UW: begin
        read_data = {32'b0, temp[31:0]};
      end
      default: begin
        read_data = 64'b0;
      end
    endcase
  end

endmodule
