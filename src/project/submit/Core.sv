`include "csr_struct.vh"
`include "core_struct.vh"
`include "mem_ift.vh"

module Core (
    input clk,
    input rst,
    input time_int,

    Mem_ift.Master imem_ift,
    Mem_ift.Master dmem_ift,

    output cosim_valid,
    output CorePack::CoreInfo cosim_core_info,
    output CsrPack::CSRPack cosim_csr_info,
    output cosim_interrupt,
    output cosim_switch_mode,
    output CorePack::data_t cosim_cause
);
    import CorePack::*;
    import PipelinePack::*;
    import ControllerPack::*;
    import CsrPack::*;
    
/*---------- 1. Declare Pipeline Register Structs ----------*/
    // These structs hold the state between pipeline stages.
    IFID   if_id_reg_in, if_id_reg_out;
    IDEXE  id_ex_reg_in, id_ex_reg_out;
    EXEMEM ex_mem_reg_in, ex_mem_reg_out;
    MEMWB  mem_wb_reg_in, mem_wb_reg_out;

/*---------- 2. Declare Wires for intermediate values ----------*/
    addr_t pc, npc_ex;
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

    csr_reg_ind_t csr_addr_id;
    data_t csr_alu_res_ex;
    data_t csr_op_b;
    data_t csr_val_id;
    logic [1:0] priv;
    logic switch_mode;
    data_t pc_csr;
    ExceptPack except_ex, except_wb; // 需要从 MEM/WB 寄存器中提取或构建


     // --- BEGIN AXI STATE MACHINE LOGIC ---
    // Combinational logic for next state
    always_comb begin
        next_state = current_state;
        case (current_state)
            IDLE: next_state = IF1;

            IF1:
                if(ex_mem_reg_out.valid && (ex_mem_reg_out.re_mem || ex_mem_reg_out.we_mem) && ~switch_mode) begin
                    next_state = WAITFOR1;
                end else if (imem_ift.r_request_valid && imem_ift.r_request_ready) begin
                    next_state = IF2;
                end
            IF2:
                if (imem_ift.r_reply_valid && imem_ift.r_reply_ready) begin
                    next_state = IDLE;
                end
            WAITFOR1:
                if(switch_mode) begin
                    next_state = IDLE;
                end else if(imem_ift.r_request_valid && imem_ift.r_request_ready) begin
                    next_state = WAITFOR2;
                end
            WAITFOR2:
                if(imem_ift.r_reply_valid && imem_ift.r_reply_ready) begin
                    next_state = MEM1;
                end
            MEM1:
                if(switch_mode) begin
                    next_state = IDLE;
                end else if((ex_mem_reg_out.re_mem && dmem_ift.r_request_valid && dmem_ift.r_request_ready) ||
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

    logic discard_next_fetch;
    
    always_ff @(posedge clk) begin
        if (rst) begin
            discard_next_fetch <= 1'b0;
        end else begin
            if (switch_mode || br_taken_ex) begin
                // 如果正在等待响应 (IF2/WAITFOR2) 且响应还没到，或者正在发送请求 (IF1/WAITFOR1) 且请求已发出
                if ((current_state == IF2 || current_state == WAITFOR2) && !(imem_ift.r_reply_valid && imem_ift.r_reply_ready)) begin
                    discard_next_fetch <= 1'b1;
                end else if ((current_state == IF1 || current_state == WAITFOR1) && imem_ift.r_request_valid && imem_ift.r_request_ready) begin
                    discard_next_fetch <= 1'b1;
                end
            end else if (imem_ift.r_reply_valid && imem_ift.r_reply_ready) begin
                // 当响应到达时，清除丢弃标记
                discard_next_fetch <= 1'b0;
            end
        end
    end

/*---------- Instruction Fetch (IF) Stage ----------*/
    // PC update logic
    always_ff @(posedge clk) begin
        if (rst) begin
            pc <= 64'b0;
        end else if (switch_mode) begin
            pc <= pc_csr; // Jump to CSR-specified address on mode switch
        end else if (br_taken_ex) begin
            pc <= alu_res_ex; // Branch taken from EX stage
        end else if(~if_stall && ~mem_stall && ~discard_next_fetch) begin
            pc <= pc + 4; // Normal PC increment
        end
    end

    // Determine next PC based on branch decision from EX stage
    assign npc_ex = br_taken_ex ? alu_res_ex : (id_ex_reg_out.pc + 4);

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
    // 修改：如果标记为丢弃，则 valid 置 0 (插入气泡)
    assign if_id_reg_in.valid      = imem_ift.r_reply_valid & imem_ift.r_reply_ready & ~discard_next_fetch;


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
        // 修改：增加 && ~mem_wb_reg_out.except.except，发生异常时不写寄存器
        .we(mem_wb_reg_out.we_reg && mem_wb_reg_out.valid && ~mem_wb_reg_out.except.except),
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

    // --- CSR Module Instantiation ---
    CSRModule csr_module (
        .clk(clk),
        .rst(rst),
        
        // 写端口 (WB Stage)
        // 修改：增加 && ~mem_wb_reg_out.except.except，发生异常时不写 CSR
        .csr_we_wb(mem_wb_reg_out.csr_we && mem_wb_reg_out.valid && ~mem_wb_reg_out.except.except), 
        .csr_addr_wb(mem_wb_reg_out.inst[31:20]), // CSR 地址在指令的高 12 位
        .csr_val_wb(mem_wb_reg_out.csr_wdata),    // 写入的新值 (从 EX 阶段计算得出并传递过来)
        
        // 读端口 (ID Stage)
        .csr_addr_id(if_id_reg_out.inst[31:20]),  // ID 阶段的 CSR 地址
        .csr_val_id(csr_val_id),                  // 输出给 ID 阶段
        
        // 异常与中断处理 (WB Stage)
        .pc_ret(mem_wb_reg_out.npc),           // 异常返回地址 (通常是下一条指令)
        .valid_wb(mem_wb_reg_out.valid),          // WB 阶段指令有效性
        .time_int(time_int),                      // 外部时钟中断信号
        .csr_ret(mem_wb_reg_out.csr_ret),         // mret/sret 信号
        .except_commit(except_wb),                // 提交的异常信息 (需要从流水线传递过来)
        
        // 输出到 Core 控制逻辑
        .priv(priv),                              // 当前特权级
        .switch_mode(switch_mode),                // 模式切换信号 (跳转/Trap)
        .pc_csr(pc_csr),                          // 跳转目标地址
        
        // Co-simulation 输出
        .cosim_interrupt(cosim_interrupt),
        .cosim_cause(cosim_cause),
        .cosim_csr_info(cosim_csr_info)
    );

    // 实例化异常检测模块
    IDExceptExamine id_except_examine (
        .clk(clk),
        .rst(rst),
        .stall(mem_stall),                  // 与 id_ex_reg 保持一致的 stall 逻辑
        .flush(br_taken_ex || switch_mode), // 与 id_ex_reg 保持一致的 flush 逻辑
        .pc_id(if_id_reg_out.pc),
        .priv(priv),                        // 来自 CSRModule 的当前特权级
        .inst_id(if_id_reg_out.inst),
        .valid_id(if_id_reg_out.valid),
        .except_id('{except:1'b0, epc:64'b0, ecause:64'b0, etval:64'b0}), // 本次实验传入空结构体
        .except_exe(except_ex),            // 输出到 EX 阶段
        .except_happen_id()                 // 可留空
    );

    // Prepare input for ID/EX register
    assign id_ex_reg_in.pc          = if_id_reg_out.pc;
    assign id_ex_reg_in.inst        = if_id_reg_out.inst;
    assign id_ex_reg_in.valid       = if_id_reg_out.valid;
    assign id_ex_reg_in.we_reg      = ctrl_signals_id.we_reg;
    assign id_ex_reg_in.we_mem      = ctrl_signals_id.we_mem;
    assign id_ex_reg_in.re_mem      = ctrl_signals_id.re_mem;
    assign id_ex_reg_in.npc_sel     = if_id_reg_out.valid ? ctrl_signals_id.npc_sel : NPC_SEL_PC;
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
    assign id_ex_reg_in.csr_we      = ctrl_signals_id.csr_we;
    assign id_ex_reg_in.csr_alu_op  = ctrl_signals_id.csr_alu_op;
    assign id_ex_reg_in.csr_alu_asel= ctrl_signals_id.csr_alu_asel;
    assign id_ex_reg_in.csr_alu_bsel= ctrl_signals_id.csr_alu_bsel;
    assign id_ex_reg_in.csr_ret     = ctrl_signals_id.csr_ret;
    assign id_ex_reg_in.zimm        = {59'b0, if_id_reg_out.inst[19:15]}; // 提取 zimm
    assign id_ex_reg_in.csr_rdata   = csr_val_id;
    // 因为使用了 IDExceptExamine 内部的寄存器，这里的 except 字段不再使用，赋空即可
    assign id_ex_reg_in.except      = '{except:1'b0, epc:64'b0, ecause:64'b0, etval:64'b0};

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

    // CSR ALU operation
    // CSR ALU operand B selection
    assign csr_op_b = (id_ex_reg_out.csr_alu_bsel == BSEL_CSRIMM) ? 
                       id_ex_reg_out.zimm : id_ex_reg_out.read_data_1; // 注意这里可能需要 forwarding

    CSRALU csr_alu1 (
        .csr_val(id_ex_reg_out.csr_rdata), // 需要从 CSR Module 读取的值
        .rs1_val(csr_op_b),
        .op(id_ex_reg_out.csr_alu_op),
        .csr_new_val(csr_alu_res_ex)
    );

    // Prepare input for EX/MEM register
    assign ex_mem_reg_in.pc        = id_ex_reg_out.pc;
    assign ex_mem_reg_in.npc       = npc_ex;
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
    assign ex_mem_reg_in.csr_we     = id_ex_reg_out.csr_we;
    assign ex_mem_reg_in.csr_alu_op = id_ex_reg_out.csr_alu_op;
    assign ex_mem_reg_in.csr_alu_asel = id_ex_reg_out.csr_alu_asel;
    assign ex_mem_reg_in.csr_alu_bsel = id_ex_reg_out.csr_alu_bsel;
    assign ex_mem_reg_in.csr_ret    = id_ex_reg_out.csr_ret;
    assign ex_mem_reg_in.zimm       = id_ex_reg_out.zimm;
    assign ex_mem_reg_in.csr_wdata  = csr_alu_res_ex;
    assign ex_mem_reg_in.csr_rdata  = id_ex_reg_out.csr_rdata;
    assign ex_mem_reg_in.except     = except_ex;

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
            WB_SEL_CSR: wb_val_mem = ex_mem_reg_out.csr_rdata;
            WB_SEL_ALU: wb_val_mem = ex_mem_reg_out.alu_res;
            WB_SEL_MEM: wb_val_mem = mem_rdata_trunc_mem;
            WB_SEL_PC:  wb_val_mem = ex_mem_reg_out.pc + 4;
            default:    wb_val_mem = 64'b0;
        endcase
    end


    // Prepare input for MEM/WB register
    assign mem_wb_reg_in.pc         = ex_mem_reg_out.pc;
    assign mem_wb_reg_in.npc        = ex_mem_reg_out.npc;
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
    assign mem_wb_reg_in.csr_we     = ex_mem_reg_out.csr_we;
    assign mem_wb_reg_in.csr_ret    = ex_mem_reg_out.csr_ret;
    assign mem_wb_reg_in.csr_rdata  = ex_mem_reg_out.csr_rdata;
    assign mem_wb_reg_in.csr_wdata  = ex_mem_reg_out.csr_wdata;
    assign mem_wb_reg_in.except     = ex_mem_reg_out.except;


/*---------- Write Back (WB) Stage ----------*/
    // Select value to write back to register file
    always_comb begin
        case (mem_wb_reg_out.wb_sel)
            WB_SEL_CSR: wb_val_wb = mem_wb_reg_out.csr_rdata;
            WB_SEL_ALU: wb_val_wb = mem_wb_reg_out.alu_res;
            WB_SEL_MEM: wb_val_wb = mem_wb_reg_out.data_trunc;
            WB_SEL_PC:  wb_val_wb = mem_wb_reg_out.pc + 4;
            default:    wb_val_wb = 64'b0;
        endcase
    end

    assign except_wb = mem_wb_reg_out.except;

/*---------- Pipeline Registers Instantiation ----------*/
    Reg_IF_ID if_id_reg (
        .clk(clk),
        .rst(rst),
        .flush(br_taken_ex || switch_mode), // Flush on taken branch
        .en(~mem_stall || if_id_reg_in.valid),
        .reg_in(if_id_reg_in),
        .reg_out(if_id_reg_out)
    );

    Reg_ID_EX id_ex_reg (
        .clk(clk),
        .rst(rst),
        .flush(br_taken_ex || switch_mode), // Flush on taken branch
        .en(~mem_stall),
        .reg_in(id_ex_reg_in),
        .reg_out(id_ex_reg_out)
    );

    Reg_EXE_MEM ex_mem_reg (
        .clk(clk),
        .rst(rst),
        .flush(switch_mode), // Flush on mode switch
        .en(~mem_stall),
        .reg_in(ex_mem_reg_in),
        .reg_out(ex_mem_reg_out)
    );

    Reg_MEM_WB mem_wb_reg (
        .clk(clk),
        .rst(rst),
        .flush(mem_stall || switch_mode),
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
    assign cosim_switch_mode         = switch_mode;

endmodule