set_false_path -hold -from [get_clocks _col7] -to [get_clocks _col7]

# PCSrc được tính ở EX stage (từ EX_MEM1)
# IF_ID enable nhận PCSrc ở cycle tiếp theo → multicycle 2
set_multicycle_path -setup -from [get_registers {EX_MEM1_buf:EX_MEM1|*}] \
                    -to   [get_registers {IF_ID_buf:IF_ID|*}] 2

set_multicycle_path -hold  -from [get_registers {EX_MEM1_buf:EX_MEM1|*}] \
                    -to   [get_registers {IF_ID_buf:IF_ID|*}] 1

# Tương tự cho ID_EX_buf
set_multicycle_path -setup -from [get_registers {EX_MEM1_buf:EX_MEM1|*}] \
                    -to   [get_registers {ID_EX_buf:ID_EX|*}] 2

set_multicycle_path -hold  -from [get_registers {EX_MEM1_buf:EX_MEM1|*}] \
                    -to   [get_registers {ID_EX_buf:ID_EX|*}] 1
# Thêm vào .sdc
set_multicycle_path -setup -from [get_registers {MEM2_WB_buf:MEM2_WB|*}] \
                    -to   [get_registers {IF_ID_buf:IF_ID|*}] 2
set_multicycle_path -hold  -from [get_registers {MEM2_WB_buf:MEM2_WB|*}] \
                    -to   [get_registers {IF_ID_buf:IF_ID|*}] 1

set_multicycle_path -setup -from [get_registers {MEM1_MEM2_buf:MEM1_MEM2|*}] \
                    -to   [get_registers {IF_ID_buf:IF_ID|*}] 2
set_multicycle_path -hold  -from [get_registers {MEM1_MEM2_buf:MEM1_MEM2|*}] \
                    -to   [get_registers {IF_ID_buf:IF_ID|*}] 1
# Tất cả path đến IF_ID và ID_EX là 2-cycle
# vì PCSrc được tính ở EX, tác dụng ở cycle tiếp theo
set_multicycle_path -setup -to [get_registers {IF_ID_buf:IF_ID|*}]  2
set_multicycle_path -hold  -to [get_registers {IF_ID_buf:IF_ID|*}]  1
set_multicycle_path -setup -to [get_registers {ID_EX_buf:ID_EX|*}]  2
set_multicycle_path -hold  -to [get_registers {ID_EX_buf:ID_EX|*}]  1