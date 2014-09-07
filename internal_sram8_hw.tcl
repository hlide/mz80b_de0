# TCL File Generated by Component Editor 13.1
# Sat Aug 23 23:35:37 GMT+09:00 2014
# DO NOT MODIFY


# 
# REG "Register Gateway" v1.0
#  2014.08.23.23:35:37
# 
# 

# 
# request TCL package from ACDS 13.1
# 
package require -exact qsys 13.1


# 
# module REG
# 
set_module_property DESCRIPTION ""
set_module_property NAME REG
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property AUTHOR ""
set_module_property DISPLAY_NAME "Register Gateway"
set_module_property INSTANTIATE_IN_SYSTEM_MODULE false
set_module_property EDITABLE true
set_module_property ANALYZE_HDL AUTO
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false


# 
# file sets
# 

# 
# parameters
# 


# 
# display items
# 


# 
# connection point avalon_int_sram_slave
# 
add_interface avalon_int_sram_slave avalon end
set_interface_property avalon_int_sram_slave addressUnits WORDS
set_interface_property avalon_int_sram_slave associatedClock clock_sink
set_interface_property avalon_int_sram_slave associatedReset reset_sink
set_interface_property avalon_int_sram_slave bitsPerSymbol 8
set_interface_property avalon_int_sram_slave burstOnBurstBoundariesOnly false
set_interface_property avalon_int_sram_slave burstcountUnits WORDS
set_interface_property avalon_int_sram_slave explicitAddressSpan 0
set_interface_property avalon_int_sram_slave holdTime 0
set_interface_property avalon_int_sram_slave linewrapBursts false
set_interface_property avalon_int_sram_slave maximumPendingReadTransactions 0
set_interface_property avalon_int_sram_slave readLatency 0
set_interface_property avalon_int_sram_slave readWaitTime 1
set_interface_property avalon_int_sram_slave setupTime 0
set_interface_property avalon_int_sram_slave timingUnits Cycles
set_interface_property avalon_int_sram_slave writeWaitTime 0
set_interface_property avalon_int_sram_slave ENABLED true
set_interface_property avalon_int_sram_slave EXPORT_OF ""
set_interface_property avalon_int_sram_slave PORT_NAME_MAP ""
set_interface_property avalon_int_sram_slave CMSIS_SVD_VARIABLES ""
set_interface_property avalon_int_sram_slave SVD_ADDRESS_GROUP ""

add_interface_port avalon_int_sram_slave ADDR address Input 16
add_interface_port avalon_int_sram_slave DATA_O readdata Output 8
add_interface_port avalon_int_sram_slave DATA_I writedata Input 8
add_interface_port avalon_int_sram_slave CS chipselect_n Input 1
add_interface_port avalon_int_sram_slave WE write_n Input 1
set_interface_assignment avalon_int_sram_slave embeddedsw.configuration.isFlash 0
set_interface_assignment avalon_int_sram_slave embeddedsw.configuration.isMemoryDevice 0
set_interface_assignment avalon_int_sram_slave embeddedsw.configuration.isNonVolatileStorage 0
set_interface_assignment avalon_int_sram_slave embeddedsw.configuration.isPrintableDevice 0


# 
# connection point clock_sink
# 
add_interface clock_sink clock end
set_interface_property clock_sink clockRate 0
set_interface_property clock_sink ENABLED true
set_interface_property clock_sink EXPORT_OF ""
set_interface_property clock_sink PORT_NAME_MAP ""
set_interface_property clock_sink CMSIS_SVD_VARIABLES ""
set_interface_property clock_sink SVD_ADDRESS_GROUP ""

add_interface_port clock_sink CLK clk Input 1


# 
# connection point reset_sink
# 
add_interface reset_sink reset end
set_interface_property reset_sink associatedClock clock_sink
set_interface_property reset_sink synchronousEdges DEASSERT
set_interface_property reset_sink ENABLED true
set_interface_property reset_sink EXPORT_OF ""
set_interface_property reset_sink PORT_NAME_MAP ""
set_interface_property reset_sink CMSIS_SVD_VARIABLES ""
set_interface_property reset_sink SVD_ADDRESS_GROUP ""

add_interface_port reset_sink RESET reset_n Input 1

