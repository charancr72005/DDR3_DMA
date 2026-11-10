module axis_to_bram_writer (
    // Clock and reset
    input  wire         clk,
    input  wire         resetn,

    // AXI-Stream input from AXI DMA
    input  wire [127:0] s_axis_tdata,
    input  wire         s_axis_tvalid,
    output reg          s_axis_tready,
    input  wire         s_axis_tlast,

    // BRAM interface
    output reg  [31:0]  bram_addr,
    output reg  [31:0]  bram_din,
    output reg  [3:0]   bram_we,
    output reg          bram_en
);

    // States
    localparam IDLE   = 3'd0;
    localparam WRITE0 = 3'd1;
    localparam WRITE1 = 3'd2;
    localparam WRITE2 = 3'd3;
    localparam WRITE3 = 3'd4;

    reg [2:0]   state;
    reg [127:0] data_buffer;

    always @(posedge clk) begin
        if (!resetn) begin
            state         <= IDLE;
            data_buffer   <= 128'd0;
            bram_addr     <= 32'd0;
            bram_din      <= 32'd0;
            bram_we       <= 4'd0;
            bram_en       <= 1'b0;
            s_axis_tready <= 1'b1;
        end
        else begin
            // Default: BRAM write disabled
            bram_we <= 4'd0;
            bram_en <= 1'b0;

            case (state)

                // Wait for a 128-bit word from DMA
                IDLE: begin
                    s_axis_tready <= 1'b1;

                    if (s_axis_tvalid && s_axis_tready) begin
                        data_buffer   <= s_axis_tdata;
                        s_axis_tready <= 1'b0;
                        state         <= WRITE0;
                    end
                end

                // Write bits [31:0]
                WRITE0: begin
                    bram_en   <= 1'b1;
                    bram_we   <= 4'b1111;
                    bram_din  <= data_buffer[31:0];
                    state     <= WRITE1;
                end

                // Write bits [63:32]
                WRITE1: begin
                    bram_en   <= 1'b1;
                    bram_we   <= 4'b1111;
                    bram_din  <= data_buffer[63:32];
                    bram_addr <= bram_addr + 1'b1;
                    state     <= WRITE2;
                end

                // Write bits [95:64]
                WRITE2: begin
                    bram_en   <= 1'b1;
                    bram_we   <= 4'b1111;
                    bram_din  <= data_buffer[95:64];
                    bram_addr <= bram_addr + 1'b1;
                    state     <= WRITE3;
                end

                // Write bits [127:96]
                WRITE3: begin
                    bram_en   <= 1'b1;
                    bram_we   <=4'b1111;
                    bram_din  <= data_buffer[127:96];
                    bram_addr <= bram_addr + 1'b1;

                    // Go back and accept the next DMA word
                    s_axis_tready <= 1'b1;
                    state         <= IDLE;
                end

                default: begin
                    state <= IDLE;
                end

            endcase
        end
    end

endmodule