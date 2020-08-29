module blink (iclk, oClk, LED, rgmii_rx_clk, rgmii_rxd, rgmii_rx_ctl, rgmii_tx_clk, rgmii_txd, rgmii_tx_ctl, mdio_scl, mdio_sda, phy_resetn);

input iclk;
output LED;
output oClk;

/*
* RGMII interface
*/
input        rgmii_rx_clk;
input [3:0]  rgmii_rxd;
input        rgmii_rx_ctl;
output       rgmii_tx_clk;
output [3:0] rgmii_txd;
output       rgmii_tx_ctl;
/*
* MDIO interface
*/
output       mdio_scl;
output       mdio_sda;

output phy_resetn;

reg [31:0] counter;
reg LED_status;

wire clk_125;
wire clk_panel;
wire locked;
reg [3:0]            locked_reset = 4'b1111;
wire                 reset = locked_reset[3];
wire phy_init_done;


assign oClk = clk_panel;
assign LED = LED_status;

initial begin
counter <= 32'b0;
LED_status <= 1'b0;
end

pll pll_inst(
    iclk,
    clk_125,
    clk_panel,
    locked
);

drive drive_inst(
    .iSysclk(clk_125),
    .iClkFrame(clk_panel),
    .iBrightness(15),
    .iWREN(0)
);

always @ (posedge iclk) 
begin
counter <= counter + 1'b1;
if (counter > 50000000)
begin
LED_status <= !LED_status;
counter <= 32'b0;
end
end


always @(posedge clk_125 or negedge locked) begin
    if (locked == 1'b0) begin
        locked_reset <= 4'b1111;
    end else begin
        locked_reset <= {locked_reset[2:0], 1'b0};
    end
end

wire          udp_sink_valid       = 1'b0;
wire          udp_sink_last        = 1'b0;
wire          udp_sink_ready       ;
wire  [15:0]  udp_sink_src_port    = 16'b0;
wire  [15:0]  udp_sink_dst_port    = 16'b0;
wire  [31:0]  udp_sink_ip_address  = 32'b0;
wire  [15:0]  udp_sink_length      = 16'b0;
wire  [31:0]  udp_sink_data        = 32'b0;
wire  [3:0]   udp_sink_error       = 4'b0;
wire          udp_source_valid     ;
wire          udp_source_last      ;
wire          udp_source_ready     ;
wire  [15:0]  udp_source_src_port  ;
wire  [15:0]  udp_source_dst_port  ;
wire  [31:0]  udp_source_ip_address;
wire  [15:0]  udp_source_length    ;
wire  [31:0]  udp_source_data      ;
wire  [3:0]   udp_source_error     ;

phy_sequencer phy_sequencer_inst (.clock(clk_125),
                .reset(reset),
                .phy_resetn(phy_resetn),
                .mdio_scl(mdio_scl),
                .mdio_sda(mdio_sda),
                .phy_init_done(phy_init_done));

liteeth_core eternit (
    /* input         */ .sys_clock            (clk_125                ),
    /* input         */ .sys_reset            (reset & ~phy_init_done),
    /* output        */ .rgmii_eth_clocks_tx  (rgmii_tx_clk         ),
    /* input         */ .rgmii_eth_clocks_rx  (rgmii_rx_clk         ),
    /* output        */ .rgmii_eth_rst_n      (                     ),
    /* input         */ .rgmii_eth_int_n      (                     ),
    /* inout         */ .rgmii_eth_mdio       (                     ),
    /* output        */ .rgmii_eth_mdc        (                     ),
    /* input         */ .rgmii_eth_rx_ctl     (rgmii_rx_ctl         ),
    /* input  [3:0]  */ .rgmii_eth_rx_data    (rgmii_rxd            ),
    /* output        */ .rgmii_eth_tx_ctl     (rgmii_tx_ctl         ),
    /* output [3:0]  */ .rgmii_eth_tx_data    (rgmii_txd            ),
    /* input         */ .udp_sink_valid       (udp_source_valid       ),
    /* input         */ .udp_sink_last        (udp_source_last        ),
    /* output        */ .udp_sink_ready       (udp_source_ready       ),
    /* input [15:0]  */ .udp_sink_src_port    (udp_source_src_port    ),
    /* input [15:0]  */ .udp_sink_dst_port    (udp_source_dst_port    ),
    /* input [31:0]  */ .udp_sink_ip_address  (udp_source_ip_address  ),
    /* input [15:0]  */ .udp_sink_length      (udp_source_length      ),
    /* input [31:0]  */ .udp_sink_data        (udp_source_data        ),
    /* input [3:0]   */ .udp_sink_error       (udp_source_error       ),
    /* output        */ .udp_source_valid     (udp_source_valid     ),
    /* output        */ .udp_source_last      (udp_source_last      ),
    /* input         */ .udp_source_ready     (udp_source_ready     ),
    /* output [15:0] */ .udp_source_src_port  (udp_source_src_port  ),
    /* output [15:0] */ .udp_source_dst_port  (udp_source_dst_port  ),
    /* output [31:0] */ .udp_source_ip_address(udp_source_ip_address),
    /* output [15:0] */ .udp_source_length    (udp_source_length    ),
    /* output [31:0] */ .udp_source_data      (udp_source_data      ),
    /* output [3:0]  */ .udp_source_error     (udp_source_error     )
);

endmodule 