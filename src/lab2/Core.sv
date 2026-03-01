`include "core_struct.vh"
module Core (
    input clk,
    input rst,

    Mem_ift.Master imem_ift,
    Mem_ift.Master dmem_ift,

    output cosim_valid,
    output CorePack::CoreInfo cosim_core_info
);
    import CorePack::*;
    import PipelinePack::*;
    import ControllerPack::*;
    
/*---------- 1. Declare Pipeline Register Structs ----------*/
    // These structs hold the state between pipeline stages.
    IFID   if_id_reg_in, if_id_reg_out;
    IDEXE  id_ex_reg_in, id_ex_reg_out;
    EXEMEM ex_mem_reg_in, ex_mem_reg_out;
    MEMWB  mem_wb_reg_in, mem_wb_reg_out;

/*---------- 2. Declare Wires for intermediate values ----------*/
    addr_t pc, next_pc;
    inst_t inst;
    logic  br_taken_ex;
    data_t imm_id;
    data_t read_data_1_id, read_data_2_id;
    data_t alu_a_ex, alu_b_ex, alu_res_ex;
    logic  cmp_res_ex;
    data_t wb_val_mem, wb_val_wb;
    ControllerSignals ctrl_signals_id;
    data_t dmem_wdata_mem, dmem_rdata_mem, mem_rdata_trunc_mem;
    mask_t dmem_wmask_mem;

    fwd_sel_enum fwd_asel_id, fwd_bsel_id;
    data_t fwd_data_1_id, fwd_data_2_id;

    axi_state_enum current_state, next_state;
    logic if_stall, mem_stall;

     // --- BEGIN AXI STATE MACHINE LOGIC ---
    // Combinational logic for next state
    always_comb begin
        next_state = current_state;
        case (current_state)
            IDLE: next_state = IF1;

            IF1:
                if(ex_mem_reg_out.valid && (ex_mem_reg_out.re_mem || ex_mem_reg_out.we_mem)) begin
                    next_state = WAITFOR1;
                end else if (imem_ift.r_request_valid && imem_ift.r_request_ready) begin
                    next_state = IF2;
                end
            IF2:
                if (imem_ift.r_reply_valid && imem_ift.r_reply_ready) begin
                    next_state = IDLE;
                end
            WAITFOR1:
                if(imem_ift.r_request_valid && imem_ift.r_request_ready) begin
                    next_state = WAITFOR2;
                end
            WAITFOR2:
                if(imem_ift.r_reply_valid && imem_ift.r_reply_ready) begin
                    next_state = MEM1;
                end
            MEM1:
                if((ex_mem_reg_out.re_mem && dmem_ift.r_request_valid && dmem_ift.r_request_ready) ||
                   (ex_mem_reg_out.we_mem && dmem_ift.w_request_valid && dmem_ift.w_request_ready)) begin
                    next_state = MEM2;
                end
            MEM2:
                if ((ex_mem_reg_out.re_mem && dmem_ift.r_reply_valid && dmem_ift.r_reply_ready) ||
                    (ex_mem_reg_out.we_mem && dmem_ift.w_reply_valid && dmem_ift.w_reply_ready)) begin
                    next_state = IDLE;
                end
            default: next_state = IDLE;
        endcase
    end

    // Sequential logic for state transition
    always_ff @(posedge clk) begin
        if (rst) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end
    // --- END AXI STATE MACHINE LOGIC ---

    // --- BEGIN STALL SIGNAL GENERATION ---
    always_comb begin
        // Default no stalls
        if_stall = 1'b0;
        mem_stall = 1'b0;

        imem_ift.r_request_valid = 1'b0;
        imem_ift.r_reply_ready   = 1'b0;
        dmem_ift.r_request_valid = 1'b0;
        dmem_ift.r_reply_ready   = 1'b0;
        dmem_ift.w_request_valid = 1'b0;
        dmem_ift.w_reply_ready   = 1'b0;

        case (current_state)
            IDLE: begin
                if_stall = 1'b1;
            end
            IF1: begin
                if_stall = 1'b1;
                imem_ift.r_request_valid = 1'b1;
                if(ex_mem_reg_out.valid && (ex_mem_reg_out.re_mem || ex_mem_reg_out.we_mem)) begin
                    // Stall to wait for memory access to complete
                    mem_stall = 1'b1;
                end
            end
            IF2: begin
                if_stall = 1'b1;
                imem_ift.r_reply_ready = 1'b1;
                if(imem_ift.r_reply_valid && imem_ift.r_reply_ready) begin
                    // Instruction fetched, no stall needed
                    if_stall = 1'b0;
                end
            end
            WAITFOR1: begin
                if_stall = 1'b1;
                mem_stall = 1'b1;
                imem_ift.r_request_valid = 1'b1;
            end
            WAITFOR2: begin
                mem_stall = 1'b1;
                imem_ift.r_reply_ready = 1'b1;
            end
            MEM1: begin
                mem_stall = 1'b1;
                dmem_ift.r_request_valid = (ex_mem_reg_out.re_mem == 1'b1);
                dmem_ift.w_request_valid = (ex_mem_reg_out.we_mem == 1'b1);
            end
            MEM2: begin
                mem_stall = 1'b1;
                if (ex_mem_reg_out.re_mem) begin
                    dmem_ift.r_reply_ready = 1'b1;
                    mem_stall = ~(dmem_ift.r_reply_valid & dmem_ift.r_reply_ready);
                end
                if (ex_mem_reg_out.we_mem) begin
                    dmem_ift.w_reply_ready = 1'b1;
                    mem_stall = ~(dmem_ift.w_reply_valid & dmem_ift.w_reply_ready);
                end
            end
            default: begin
                mem_stall = 1'b0;
            end
        endcase
    end
    // --- END STALL SIGNAL GENERATION ---

/*---------- Instruction Fetch (IF) Stage ----------*/
    // PC update logic
    always_ff @(posedge clk) begin
        if (rst) begin
            pc <= 64'b0;
        end else if (br_taken_ex) begin
            pc <= alu_res_ex; // Branch taken from EX stage
        end else if(~if_stall && ~mem_stall) begin
            pc <= pc + 4; // Normal PC increment
        end
    end

    // Determine next PC based on branch decision from EX stage
    assign next_pc = br_taken_ex ? alu_res_ex : (pc + 4);

    // Memory interface for instruction fetch
    assign imem_ift.r_request_bits.raddr = pc;
    assign inst = (imem_ift.r_reply_valid & imem_ift.r_reply_ready) ? 
                  ((pc[2]) ? imem_ift.r_reply_bits.rdata[63:32] : imem_ift.r_reply_bits.rdata[31:0]) :
                  32'h00000013;
    
    // Unused write ports for instruction memory
    assign imem_ift.w_request_valid = 1'b0;
    assign imem_ift.w_reply_ready   = 1'b1;
    assign imem_ift.w_request_bits  = '{default:'0};

    // Prepare input for IF/ID register
    assign if_id_reg_in.pc         = pc;
    assign if_id_reg_in.inst       = inst;
    assign if_id_reg_in.valid      = imem_ift.r_reply_valid & imem_ift.r_reply_ready;


/*---------- Instruction Decode (ID) Stage ----------*/

    Controller ctrl (
        .inst(if_id_reg_out.inst),
        .ctrl_signals(ctrl_signals_id)
    );

    ImmGen imm_gen (
        .inst(if_id_reg_out.inst),
        .immgen_op(ctrl_signals_id.immgen_op),
        .imm(imm_id)
    );

    RegFile regfile (
        .clk(clk),
        .rst(rst),
        // Write port is from WB stage
        .we(mem_wb_reg_out.we_reg && mem_wb_reg_out.valid),
        .write_addr(mem_wb_reg_out.rd),
        .write_data(wb_val_wb),
        // Read ports are from ID stage
        .read_addr_1(if_id_reg_out.inst[19:15]), // rs1
        .read_addr_2(if_id_reg_out.inst[24:20]), // rs2
        .read_data_1(read_data_1_id),
        .read_data_2(read_data_2_id)
    );

    // Hazard detection
    HazardDetector hazard_det (
        .inst_id(if_id_reg_out.inst),
        .id_ex_reg_out(id_ex_reg_out),
        .ex_mem_reg_out(ex_mem_reg_out),
        .mem_wb_reg_out(mem_wb_reg_out),
        .fwd_asel_id(fwd_asel_id),
        .fwd_bsel_id(fwd_bsel_id)
        //.stall(stall)
    );

    // Forwarding selector
    ForwardingSelector fwd_sel (
        .read_data_1_id(read_data_1_id),
        .read_data_2_id(read_data_2_id),
        .alu_res_ex(alu_res_ex), // Data from EX stage
        .wb_val_mem(wb_val_mem), // Data from MEM stage
        .wb_val_wb(wb_val_wb),               // Data from WB stage
        .fwd_asel_id(fwd_asel_id),
        .fwd_bsel_id(fwd_bsel_id),
        .fwd_data_1_id(fwd_data_1_id),
        .fwd_data_2_id(fwd_data_2_id)
    );

    // Prepare input for ID/EX register
    assign id_ex_reg_in.pc          = if_id_reg_out.pc;
    assign id_ex_reg_in.inst        = if_id_reg_out.inst;
    assign id_ex_reg_in.valid       = if_id_reg_out.valid;
    assign id_ex_reg_in.we_reg      = ctrl_signals_id.we_reg;
    assign id_ex_reg_in.we_mem      = ctrl_signals_id.we_mem;
    assign id_ex_reg_in.re_mem      = ctrl_signals_id.re_mem;
    assign id_ex_reg_in.npc_sel     = ctrl_signals_id.npc_sel;
    assign id_ex_reg_in.alu_op      = ctrl_signals_id.alu_op;
    assign id_ex_reg_in.cmp_op      = ctrl_signals_id.cmp_op;
    assign id_ex_reg_in.alu_asel    = ctrl_signals_id.alu_asel;
    assign id_ex_reg_in.alu_bsel    = ctrl_signals_id.alu_bsel;
    assign id_ex_reg_in.wb_sel      = ctrl_signals_id.wb_sel;
    assign id_ex_reg_in.mem_op      = ctrl_signals_id.mem_op;
    assign id_ex_reg_in.imm         = imm_id;
    assign id_ex_reg_in.read_data_1 = fwd_data_1_id;
    assign id_ex_reg_in.read_data_2 = fwd_data_2_id;
    assign id_ex_reg_in.rd          = if_id_reg_out.inst[11:7];
    assign id_ex_reg_in.rs1         = if_id_reg_out.inst[19:15];
    assign id_ex_reg_in.rs2         = if_id_reg_out.inst[24:20];

/*---------- Execute (EX) Stage ----------*/

    // ALU operand selection
    always_comb begin
        // Operand A selection
        case (id_ex_reg_out.alu_asel)
            ASEL_REG: alu_a_ex = id_ex_reg_out.read_data_1;
            ASEL_PC:  alu_a_ex = id_ex_reg_out.pc;
            default:  alu_a_ex = 64'b0;
        endcase

        // Operand B selection
        case (id_ex_reg_out.alu_bsel)
            BSEL_REG: alu_b_ex = id_ex_reg_out.read_data_2;
            BSEL_IMM: alu_b_ex = id_ex_reg_out.imm;
            default:  alu_b_ex = 64'b0;
        endcase
    end


    ALU alu1 (
        .a(alu_a_ex),
        .b(alu_b_ex),
        .alu_op(id_ex_reg_out.alu_op),
        .res(alu_res_ex)
    );

    Cmp cmp1 (
        .a(id_ex_reg_out.read_data_1),
        .b(id_ex_reg_out.read_data_2),
        .cmp_op(id_ex_reg_out.cmp_op),
        .cmp_res(cmp_res_ex)
    );

    // Branch taken logic
    assign br_taken_ex = (id_ex_reg_out.npc_sel == NPC_SEL_BR & cmp_res_ex) | (id_ex_reg_out.npc_sel == NPC_SEL_J);

    // Prepare input for EX/MEM register
    assign ex_mem_reg_in.pc        = id_ex_reg_out.pc;
    assign ex_mem_reg_in.inst      = id_ex_reg_out.inst;
    assign ex_mem_reg_in.valid     = id_ex_reg_out.valid;
    assign ex_mem_reg_in.we_reg    = id_ex_reg_out.we_reg;
    assign ex_mem_reg_in.we_mem    = id_ex_reg_out.we_mem;
    assign ex_mem_reg_in.re_mem    = id_ex_reg_out.re_mem;
    assign ex_mem_reg_in.br_taken  = br_taken_ex;
    assign ex_mem_reg_in.wb_sel    = id_ex_reg_out.wb_sel;
    assign ex_mem_reg_in.mem_op    = id_ex_reg_out.mem_op;
    assign ex_mem_reg_in.rd        = id_ex_reg_out.rd;
    assign ex_mem_reg_in.alu_res   = alu_res_ex;
    assign ex_mem_reg_in.mem_wdata = id_ex_reg_out.read_data_2; // Data for store instruction

/*---------- Memory (MEM) Stage ----------*/
    // Data memory access
    assign dmem_ift.r_request_bits.raddr = ex_mem_reg_out.alu_res;
    assign dmem_rdata_mem                = dmem_ift.r_reply_bits.rdata;

    assign dmem_ift.w_request_bits.waddr = ex_mem_reg_out.alu_res;
    assign dmem_ift.w_request_bits.wdata = dmem_wdata_mem;
    assign dmem_ift.w_request_bits.wmask = dmem_wmask_mem;

    DataPkg data_pkg (
        .mem_op(ex_mem_reg_out.mem_op),
        .reg_data(ex_mem_reg_out.mem_wdata),
        .dmem_waddr(ex_mem_reg_out.alu_res),    //不能使用dmem_ift，否则会形成回路
        .dmem_wdata(dmem_wdata_mem)
    );

    MaskGen mask_gen (
        .mem_op(ex_mem_reg_out.mem_op),
        .dmem_waddr(ex_mem_reg_out.alu_res),
        .dmem_wmask(dmem_wmask_mem)
    );

    DataTrunc trunc (
        .dmem_rdata(dmem_rdata_mem),
        .mem_op(ex_mem_reg_out.mem_op),
        .dmem_raddr(ex_mem_reg_out.alu_res),
        .read_data(mem_rdata_trunc_mem)
    );

    always_comb begin
        case (ex_mem_reg_out.wb_sel)
            WB_SEL_ALU: wb_val_mem = ex_mem_reg_out.alu_res;
            WB_SEL_MEM: wb_val_mem = mem_rdata_trunc_mem;
            WB_SEL_PC:  wb_val_mem = ex_mem_reg_out.pc + 4;
            default:    wb_val_mem = 64'b0;
        endcase
    end


    // Prepare input for MEM/WB register
    assign mem_wb_reg_in.pc         = ex_mem_reg_out.pc;
    assign mem_wb_reg_in.inst       = ex_mem_reg_out.inst;
    assign mem_wb_reg_in.valid      = ex_mem_reg_out.valid;
    assign mem_wb_reg_in.we_reg     = ex_mem_reg_out.we_reg;
    assign mem_wb_reg_in.re_mem     = ex_mem_reg_out.re_mem;
    assign mem_wb_reg_in.we_mem     = ex_mem_reg_out.we_mem;
    assign mem_wb_reg_in.br_taken   = ex_mem_reg_out.br_taken;
    assign mem_wb_reg_in.wb_sel     = ex_mem_reg_out.wb_sel;
    assign mem_wb_reg_in.rd         = ex_mem_reg_out.rd;
    assign mem_wb_reg_in.alu_res    = ex_mem_reg_out.alu_res;
    assign mem_wb_reg_in.data_trunc = mem_rdata_trunc_mem;

/*---------- Write Back (WB) Stage ----------*/
    // Select value to write back to register file
    always_comb begin
        case (mem_wb_reg_out.wb_sel)
            WB_SEL_ALU: wb_val_wb = mem_wb_reg_out.alu_res;
            WB_SEL_MEM: wb_val_wb = mem_wb_reg_out.data_trunc;
            WB_SEL_PC:  wb_val_wb = mem_wb_reg_out.pc + 4;
            default:    wb_val_wb = 64'b0;
        endcase
    end

/*---------- Pipeline Registers Instantiation ----------*/
    Reg_IF_ID if_id_reg (
        .clk(clk),
        .rst(rst),
        .flush(br_taken_ex), // Flush on taken branch
        .en(~mem_stall || if_id_reg_in.valid),
        .reg_in(if_id_reg_in),
        .reg_out(if_id_reg_out)
    );

    Reg_ID_EX id_ex_reg (
        .clk(clk),
        .rst(rst),
        .flush(br_taken_ex), // Flush on taken branch
        .en(~mem_stall),
        .reg_in(id_ex_reg_in),
        .reg_out(id_ex_reg_out)
    );

    Reg_EXE_MEM ex_mem_reg (
        .clk(clk),
        .rst(rst),
        .en(~mem_stall),
        .reg_in(ex_mem_reg_in),
        .reg_out(ex_mem_reg_out)
    );

    Reg_MEM_WB mem_wb_reg (
        .clk(clk),
        .rst(rst),
        .flush(mem_stall),
        .reg_in(mem_wb_reg_in),
        .reg_out(mem_wb_reg_out)
    );

/*---------- Co-simulation Outputs ----------*/
    // Connect cosim outputs from the WB stage for final instruction state
    assign cosim_valid               = mem_wb_reg_out.valid;
    assign cosim_core_info.pc        = mem_wb_reg_out.pc;
    assign cosim_core_info.inst      = {32'b0, mem_wb_reg_out.inst};
    //assign cosim_core_info.rs1_id    = {59'b0, mem_wb_reg_out.rs1};
    //assign cosim_core_info.rs1_data  = mem_wb_reg_out.read_data_1;
    //assign cosim_core_info.rs2_id    = {59'b0, mem_wb_reg_out.rs2};
    //assign cosim_core_info.rs2_data  = mem_wb_reg_out.read_data_2;
    //assign cosim_core_info.alu       = mem_wb_reg_out.alu_res;
    //assign cosim_core_info.mem_addr  = dmem_ift.r_request_bits.raddr;
    //assign cosim_core_info.mem_we    = {63'b0, dmem_ift.w_request_valid};
    //assign cosim_core_info.mem_wdata = dmem_ift.w_request_bits.wdata;
    //assign cosim_core_info.mem_rdata = dmem_ift.r_reply_bits.rdata;
    assign cosim_core_info.rd_we     = {63'b0, mem_wb_reg_out.we_reg};
    assign cosim_core_info.rd_id     = {59'b0, mem_wb_reg_out.rd};
    assign cosim_core_info.rd_data   = wb_val_wb;
    //assign cosim_core_info.br_taken  = {63'b0, mem_wb_reg_out.br_taken};
    //assign cosim_core_info.npc       = next_pc;

endmodule