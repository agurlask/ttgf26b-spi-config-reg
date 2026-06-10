// tt_um_spi_config_reg.v
//
// Tiny Tapeout wrapper for spi_config_reg.
//
// Pin mapping:
//
//   ui_in[0]    <- SCLK
//   ui_in[1]    <- MOSI
//   ui_in[2]    <- CSn  (active low)
//   ui_in[3]    <- CLR  (active high async clear)
//   ui_in[7:4]  -- unused (tied low)
//
//   uo_out[7:0] -> parallel latch output (cfg_out)
//                  reflects the latched SPI register contents;
//                  stable between transactions, will eventually connect
//                  to analog configuration signals
//
//   uio[7:0]    -- unused (tied low)

`default_nettype none

module tt_um_spi_config_reg (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    // -------------------------------------------------------------------------
    // SPI signals
    // -------------------------------------------------------------------------
    wire sclk    = ui_in[0];
    wire mosi    = ui_in[1];
    wire csn     = ui_in[2];
    wire clr_pin = ui_in[3];   // user-driven async clear

    // -------------------------------------------------------------------------
    // Clear signal
    // Assert clr whenever TT rst_n is low OR the user drives clr_pin high.
    // -------------------------------------------------------------------------
    wire clr = ~rst_n | clr_pin;

    // -------------------------------------------------------------------------
    // SPI signal gating
    // Block SCLK and force CSn deasserted during clear so the core cannot
    // latch a spurious transaction while clr is active.
    // -------------------------------------------------------------------------
    wire sclk_gated = sclk & ~clr;
    wire csn_gated  = csn  |  clr;

    // -------------------------------------------------------------------------
    // SPI Register instantiation
    // -------------------------------------------------------------------------
    wire [7:0] cfg_out;

    spi_config_reg #(
        .N      (8),
        .DEFAULT(8'hAA)
    ) u_spi_config_reg (
        .sclk    (sclk_gated),
        .mosi    (mosi),
        .csn     (csn_gated),
        .clr     (clr),
        .cfg_out (cfg_out)
    );

    // -------------------------------------------------------------------------
    // Output assignments
    // -------------------------------------------------------------------------
    assign uo_out  = cfg_out;
    assign uio_out = 8'h00;
    assign uio_oe  = 8'h00;

endmodule

`default_nettype wire