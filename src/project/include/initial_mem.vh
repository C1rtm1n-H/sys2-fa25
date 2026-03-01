`ifdef VERILATE
     localparam ROM_PATH = "rom.hex";
    `ifdef BOARD_SIM
        localparam BUFFER_PATH = "elf.hex";
            localparam KERNEL_PATH = "dummy.hex";
    `else
        localparam BUFFER_PATH = "dummy.hex";
        localparam KERNEL_PATH = "mini_sbi.hex";
    `endif
`else
    localparam FILE_PATH = "/home/cartman/ZJU/sys2-fa25/src/project/build/verilate/testcase.hex";
`endif 