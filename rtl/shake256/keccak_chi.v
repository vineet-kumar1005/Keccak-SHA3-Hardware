`timescale 1ns / 1ps

module keccak_chi (
    input  wire [1599:0] state_in_flat,
    output reg  [1599:0] chi_out_flat
);

    // Internal arrays for clean readability
    reg [63:0] state_in [0:4][0:4];
    reg [63:0] chi_out  [0:4][0:4];
    
    integer x, y;

    always @(*) begin
        // 1. Unpack flat input into 3D array
        for (y = 0; y < 5; y = y + 1) begin
            for (x = 0; x < 5; x = x + 1) begin
                state_in[x][y] = state_in_flat[(5*y + x)*64 +: 64];
            end
        end

        // 2. Apply Chi Non-Linear Logic
        for (y = 0; y < 5; y = y + 1) begin
            for (x = 0; x < 5; x = x + 1) begin
                chi_out[x][y] = state_in[x][y] ^ (~state_in[(x + 1) % 5][y] & state_in[(x + 2) % 5][y]);
            end
        end

        // 3. Pack 3D array back into flat output
        for (y = 0; y < 5; y = y + 1) begin
            for (x = 0; x < 5; x = x + 1) begin
                chi_out_flat[(5*y + x)*64 +: 64] = chi_out[x][y];
            end
        end
    end

endmodule