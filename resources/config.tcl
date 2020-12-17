# User config
set ::env(DESIGN_NAME) clb
set ::env(PDK_VARIANT) sky130_fd_sc_hd

# Change if needed
set ::env(VERILOG_FILES) [glob $::env(DESIGN_DIR)/src/*.v]

# Fill this
set ::env(CLOCK_PERIOD) "12"
set ::env(CLOCK_PORT) "clk"
set ::env(CLOCK_NET) $::env(CLOCK_PORT)

# Synthesis config
set ::env(SYNTH_STRATEGY) 2  ;# 1 fails

set ::env(SYNTH_READ_BLACKBOX_LIB) 1

set ::env(FP_SIZING) absolute
# I think this goes LL_X LL_Y UR_X UR_Y, where LL=lower left, UR=upper right
# Units probably microns
set ::env(DIE_AREA) [list 0 0 100 480]


# Will this help???
set ::env(PL_SKIP_INITIAL_PLACEMENT) 1

#set ::env(FP_CORE_UTIL) .2
set ::env(PL_TARGET_DENSITY) 0.35

set filename $::env(DESIGN_DIR)/$::env(PDK)_$::env(STD_CELL_LIBRARY)_config.tcl
if { [file exists $filename] == 1} {
	source $filename
}

# # threads for supporting tools
set ::env(ROUTING_CORES) 4

set ::env(PDN_CFG) $::env(DESIGN_DIR)/pdn.tcl
