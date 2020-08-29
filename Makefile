SOURCE :=./rtl/top.v \
		 ./rtl/pll.v \
		 ./rtl/liteeth_core.v \
		 ./rtl/phy_io.v \
		 ./rtl/serial_driver.v

YOSYS_SCRIPT:=top.ys

all : top.svf

top.json : $(YOSYS_SCRIPT) $(SOURCE)
	yosys -s $< -o $@

top.config : top.json
	nextpnr-ecp5 --pre-pack clocks.py --25k --freq 125 --timing-allow-fail --package CABGA256 --speed 6 --json top.json --lpf top.lpf --write top-post-route.json --textcfg top.config

top.bit : top.config
	ecppack top.config top.bit

top.svf : top.bit
	./bit_to_svf.py top.bit top.svf

flash.svf : top.bit
	./bit_to_flash.py top.bit flash.svf


prog : top.svf
	openocd -f openocd_ftdi.cfg -c "transport select jtag; init; scan_chain; svf top.svf; shutdown; quit"

clean :
	rm top.bit top.config top.json top.svf
