`default_nettype none

module tt_um_funproj (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,  
    input  wire [7:0] uio_in, 
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena, 
    input  wire       clk, 
    input  wire       rst_n
);
    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;

    tiny_cpu my_cpu (
        .clk(clk),
        .reset(~rst_n), 
        .keyboard_in(ui_in), 
        .screen_out(uo_out)
    );
endmodule

module tiny_cpu (
    input wire clk,
    input wire reset,
    input wire [7:0] keyboard_in,
    output reg [7:0] screen_out
);
    reg [2:0] pc;
    reg [7:0] reg_a, reg_b;
    
    // REDUCED TO 32 BYTES: Cuts flip-flops and MUX trees in half.
    // This is the Goldilocks zone for ~70% utilization on a 1x1 tile.
    reg [7:0] ram [31:0];  
    
    wire [7:0] instruction;
    
    wire [1:0] opcode = instruction[7:6];
    wire [2:0] jump_addr = instruction[2:0]; 
    wire reg_sel = instruction[3];  
    wire imm_mode = instruction[4];
    
    // Use the bottom 5 bits of reg_b as the RAM address (0 to 31)
    wire [4:0] ram_addr = reg_b[4:0];
    wire [7:0] alu_result = reg_a + ram[ram_addr];

    // HARDWIRED ROM
    // pc=0: 0x10 -> LOAD reg_a from keyboard_in ('W')
    // pc=1: 0x18 -> LOAD reg_b from keyboard_in (Address pointer)
    // pc=2: 0x40 -> STORE reg_a to ram[reg_b]   (Forces tool to keep RAM)
    // pc=3: 0x80 -> LOAD reg_a from ram[reg_b]  (Proves RAM works)
    // pc=4: 0xC0 -> STORE reg_a to screen       (Outputs 'W')
    // pc=5: 0xD5 -> JUMP to pc=5                (Halt)
    assign instruction = (pc == 3'd0) ? 8'h10 :
                         (pc == 3'd1) ? 8'h18 :
                         (pc == 3'd2) ? 8'h40 :
                         (pc == 3'd3) ? 8'h80 :
                         (pc == 3'd4) ? 8'hC0 :
                         (pc == 3'd5) ? 8'hD5 : 8'h00;
    
    always @(posedge clk) begin
        if (reset) begin
            pc <= 3'b000;
            reg_a <= 8'h00;
            reg_b <= 8'h00;
            screen_out <= 8'h20;  // Space character
        end else begin
            case (opcode)
                2'b00: begin  // ADD/LOAD
                    if (imm_mode) begin
                        if (reg_sel) reg_b <= keyboard_in;
                        else reg_a <= keyboard_in;
                    end else begin
                        if (reg_sel) reg_b <= alu_result;
                        else reg_a <= alu_result;
                    end
                    pc <= pc + 1;
                end
                
                2'b01: begin  // STORE to RAM
                    ram[ram_addr] <= reg_sel ? reg_b : reg_a;
                    pc <= pc + 1;
                end
                
                2'b10: begin  // LOAD from RAM
                    if (imm_mode) begin
                        if (reg_sel) reg_b <= keyboard_in;
                        else reg_a <= keyboard_in;
                    end else begin
                        if (reg_sel) reg_b <= ram[ram_addr];
                        else reg_a <= ram[ram_addr];
                    end
                    pc <= pc + 1;
                end
                
                2'b11: begin  // STORE to screen / JUMP
                    if (imm_mode) begin
                        pc <= jump_addr;  // JUMP
                    end else begin
                        screen_out <= reg_sel ? reg_b : reg_a;
                        pc <= pc + 1;
                    end
                end
            endcase
        end
    end
endmodule
