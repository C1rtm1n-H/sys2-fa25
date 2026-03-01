`include"core_struct.vh"
module Cmp (
    input CorePack::data_t a,
    input CorePack::data_t b,
    input CorePack::cmp_op_enum cmp_op,
    output cmp_res
);

    import CorePack::*;

    // fill your code
        logic result;
    assign cmp_res = result;
    always_comb begin
        case (cmp_op)
            CMP_NO: result = 0;
            CMP_EQ: result = (a == b) ? 1 : 0;
            CMP_NE: result = (a != b) ? 1 : 0;
            CMP_LT: result = ($signed(a) < $signed(b)) ? 1 : 0;
            CMP_GE: result = ($signed(a) >= $signed(b)) ? 1 : 0;
            CMP_LTU: result = (a < b) ? 1 : 0;
            CMP_GEU: result = (a >= b) ? 1 : 0;
            default: result = 0;
        endcase
    end
endmodule