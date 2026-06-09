// spi_config_reg.v
//
// Asynchronous SPI-to-parallel configuration register IP core.
//
// No system clock required. All logic is driven directly by the SPI
// signals, making this suitable for analog blocks that have no clock
// domain.
//
// Protocol:
//   - CSn active low: transaction in progress while CSn == 0
//   - Data clocked in MSB-first on the rising edge of SCLK
//   - Output latch updates on the rising edge of CSn (end of transaction)
//   - cfg_out is stable between transactions, never glitches mid-shift
//
// Clear behaviour:
//   - clr is active high, level-sensitive, asynchronous
//   - While clr is high: both shift register and cfg_out are forced to
//     DEFAULT. SPI activity is blocked externally by the wrapper.
//   - On clr release: cfg_out holds DEFAULT, shift register is clean,
//     normal SPI operation resumes immediately.
//
// Parameters:
//   N       : number of configuration bits (default 8)
//   DEFAULT : reset/clear value loaded into both registers on clr
//             (default 0; override at instantiation for a safe analog
//             operating point other than all-zeros)
//
// Ports:
//   sclk    : SPI clock from master
//   mosi    : SPI data in, MSB first
//   csn     : SPI chip select, active low
//   clr     : asynchronous clear, active high — forces both registers
//             to DEFAULT while asserted
//   cfg_out : N-bit parallel latch output → connect to analog block

`default_nettype none

`ifndef DEFAULT
  `define DEFAULT 0
`endif

module spi_config_reg #(
    parameter             N       = 8,
    parameter [N-1:0]     DEFAULT = `DEFAULT
) (
    // SPI interface (write-only, 3-wire)
    input  wire         sclk,
    input  wire         mosi,
    input  wire         csn,

    // Asynchronous clear (active high, level-sensitive)
    input  wire         clr,

    // Parallel config output (latched, stable between transactions)
    output reg  [N-1:0] cfg_out
);

    // -------------------------------------------------------------------------
    // Shift register
    // Clocked by SCLK, gated by CSn so it only shifts during a transaction.
    // Asynchronously cleared to DEFAULT while clr is high.
    // -------------------------------------------------------------------------
    reg [N-1:0] shift_reg;

    always @(posedge sclk or posedge clr) begin
        if (clr) begin
            shift_reg <= DEFAULT;
        end else if (!csn) begin
            // MSB-first: shift left, new bit enters at LSB
            shift_reg <= {shift_reg[N-2:0], mosi};
        end
    end

    // -------------------------------------------------------------------------
    // Output latch
    // Captures shift register on rising edge of CSn (end of transaction).
    // Asynchronously forced to DEFAULT while clr is high.
    // -------------------------------------------------------------------------
    always @(posedge csn or posedge clr) begin
        if (clr) begin
            cfg_out <= DEFAULT;
        end else begin
            cfg_out <= shift_reg;
        end
    end

endmodule

`default_nettype wire
