`timescale 1ns / 1ps

module keccak_theta (
    input  wire [1599:0] state_in_flat,
    output reg  [1599:0] theta_out_flat
);

    // Internal arrays for clean math
    reg [63:0] state_in  [0:4][0:4];
    reg [63:0] theta_out [0:4][0:4];
    
    // Internal wires for C and D (Combinational)
    reg [63:0] C [0:4];
    reg [63:0] D [0:4];
    
    integer x, y;

    always @(*) begin
        // ==========================================
        // 1. Unpack flat input into 3D array
        // ==========================================
        for (y = 0; y < 5; y = y + 1) begin
            for (x = 0; x < 5; x = x + 1) begin
                state_in[x][y] = state_in_flat[(5*y + x)*64 +: 64];
            end
        end

        // ==========================================
        // 2. Calculate Column Parities (C)
        // ==========================================
        for (x = 0; x < 5; x = x + 1) begin
            C[x] = state_in[x][0] ^ state_in[x][1] ^ state_in[x][2] ^ state_in[x][3] ^ state_in[x][4];
        end
        
        // ==========================================
        // 3. Calculate Diffusion Effect (D)
        // ==========================================
        D[0] = C[4] ^ {C[1][62:0], C[1][63]}; // Left: 4, Right: 1
        D[1] = C[0] ^ {C[2][62:0], C[2][63]}; // Left: 0, Right: 2
        D[2] = C[1] ^ {C[3][62:0], C[3][63]}; // Left: 1, Right: 3
        D[3] = C[2] ^ {C[4][62:0], C[4][63]}; // Left: 2, Right: 4
        D[4] = C[3] ^ {C[0][62:0], C[0][63]}; // Left: 3, Right: 0

        // ==========================================
        // 4. Apply to State
        // ==========================================
        for (x = 0; x < 5; x = x + 1) begin
            for (y = 0; y < 5; y = y + 1) begin
                theta_out[x][y] = state_in[x][y] ^ D[x];
            end
        end

        // ==========================================
        // 5. Pack 3D array back into flat output
        // ==========================================
        for (y = 0; y < 5; y = y + 1) begin
            for (x = 0; x < 5; x = x + 1) begin
                theta_out_flat[(5*y + x)*64 +: 64] = theta_out[x][y];
            end
        end
    end

endmodule