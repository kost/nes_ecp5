/*
The virtual NES cartridge
At the moment this stores the entire cartridge
in SPRAM, in the future it could stream data from
SQI flash, which is more than fast enough
*/

module flash_loader(
  input clock,
  input reset,
  
  input reload,
  input [3:0] index,
  
  //Flash load interface
  output flash_csn,
  output flash_sck,
  output flash_mosi,
  input flash_miso,

  input game_loader_done,
  output [7:0] load_write_data,
  output data_valid
);


localparam [16:0] END_ADDR = 17'h10000;
`ifndef SIM
localparam [23:0] FLASH_BEGIN_ADDR = 24'h200000;
`else
localparam [23:0] FLASH_BEGIN_ADDR = 24'h000000;
`endif


reg load_done;
initial load_done = 1'b0;


reg [16:0] load_addr;
reg [21:0] nes_load_address;

wire flashmem_valid = !load_done;
wire flashmem_ready;
//assign data_valid = flashmem_ready && (load_addr < END_ADDR);
assign data_valid = flashmem_ready;
wire [23:0] flashmem_addr = (FLASH_BEGIN_ADDR + (index_lat << 18)) | {load_addr};
reg [3:0] index_lat;
reg load_done_pre;

reg [2:0] flags_ctr = 0;
reg [7:0] wait_ctr = 0;

// Flash memory load interface
always @(posedge clock) 
begin
  if (reset == 1'b1) begin
    load_done_pre <= 1'b0;
    load_done <= 1'b0;
    load_addr <= 17'h0000;
    wait_ctr <= 8'h00;
    index_lat <= 4'h0;
    flags_ctr <= 3'b0;
    nes_load_address <= 22'b0;
  end else begin
    if (reload == 1'b1) begin
      load_done_pre <= 1'b0;
      load_done <= 1'b0;
      load_addr <= 17'h0000;
      wait_ctr <= 8'h00;
      flags_ctr <= 3'b0;
      index_lat <= index;
      nes_load_address <= 22'b0;
    end else begin
      if(!game_loader_done) begin
        if (flashmem_ready == 1'b1) begin
          if (load_addr > END_ADDR) begin
            load_done_pre <= 1'b1;
          end else 
            load_addr <= load_addr + 1'b1;
        end
      end else begin
        if (wait_ctr < 8'hFF)
          wait_ctr <= wait_ctr + 1;
        else
          load_done <= 1'b1;
      end
    end
  end
end

icosoc_flashmem flash_i (
  .clk(clock),
  .reset(reset),
  .valid(flashmem_valid),
  .ready(flashmem_ready),
  .addr(flashmem_addr),
  .rdata(load_write_data),

  .spi_cs(flash_csn),
  .spi_sclk(flash_sck),
  .spi_mosi(flash_mosi),
  .spi_miso(flash_miso)
);

endmodule
