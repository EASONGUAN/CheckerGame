
module Checker
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
        KEY,
        SW,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
	);
	
	input			CLOCK_50;				//	50 MHz
	input   [9:0]   SW;
	input   [3:0]   KEY;
	
	// Declare your inputs and outputs here
	wire ld_xy, ld_direction, ld_player;	//	50 MHz
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
	wire resetn;
	assign resetn = KEY[3];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [7:0] y;
	wire writeEn;
	wire [2:0] final_colour;
	wire remove;
	wire continue;
	wire move;
	wire verify, reload;
	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(final_colour),
			.x(x),
			.y(y),
			.plot(writeEn),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
	// Put your code here. Your cod
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "board.mif";
		
	// Put your code here. Your code should produce signals x,y,colour and writeEn/plot
	// for the VGA controller, in addition to any other functionality your design may require.
	 
	 // Instansiate datapath
	 datapath d0(.clk(CLOCK_50),
					 .resetn(KEY[0]),
					 .X_COOR(SW[5:3]),
					 .Y_COOR(SW[2:0]),
					 .PLAYER(SW[6]),
					 .DIRECTION(SW[7]),
					 .ld_xy(ld_xy),
					 .ld_direction(ld_direction),
					 .ld_player(ld_player),
					 .writeEn(writeEn),
					 .remove(remove),
					 .move(move),
					 .continue(continue),
					 .OUT_X_COOR(x),
					 .OUT_Y_COOR(y),
					 .OUT_COLOUR(final_colour),
					 .verify(verify),
					 .reload(reload));
					
					
    // Instansiate FSM control
	 control c0(.clk(CLOCK_50),
					.resetn(KEY[0]),
					.change1(KEY[1]),
					.ld_xy(ld_xy),
					.ld_direction(ld_direction),
					.ld_player(ld_player),
					.plot(writeEn),
					.remove(remove),
					.continue(continue),
					.move(move),
					.verify(verify),
					.reload(reload));
	 
	 
endmodule
	 
module control(clk, resetn, change1, ld_xy, ld_direction, ld_player, plot, remove, continue, move, verify, reload);
	input clk;
	input resetn;
	input change1;
	output reg ld_xy,ld_direction,ld_player, plot, remove, move, verify;
	input	continue, reload;
	

	reg [2:0] current, next;
	
	localparam LOADING = 3'd0,
		   CYCLE1 = 3'd1,
			CYCLE2 = 3'd2,
			CYCLE3 = 3'd3,
			CYCLE4 = 3'd4,
			CYCLE5 = 3'd5;
				  
	always @(*)
	begin: state_table
			case (current)
					LOADING:next = change1 ? LOADING : CYCLE1;
					CYCLE1:next = reload ? LOADING : CYCLE2;
					CYCLE2:next = continue ? CYCLE2 : CYCLE3;
					CYCLE3:next = continue ? CYCLE3 : CYCLE4;
					CYCLE4:next = continue ? CYCLE4 : CYCLE5;
					CYCLE5:next = continue ? CYCLE5 : LOADING;
				default: next = LOADING;
			endcase
	end
	 
	always @(*)
    begin: enable_signals
        ld_xy <= 1'b0;
        ld_direction <= 1'b0;
		  ld_player <= 1'b0;
		  plot <= 1'b0;
		  remove <= 1'b0;
		  move <= 1'b0;
		  case (current)
            LOADING: 
				begin
					plot <= 1'b0;
					ld_xy <= 1'b1;
               ld_direction <= 1'b1;
					ld_player <= 1'b1;
            end
				CYCLE1:
				begin
					ld_xy <= 1'b0;
               ld_direction <= 1'b0;
					ld_player <= 1'b0;
					verify <= 1'b1;
				end
				CYCLE2: 
				begin
					ld_player <= 1'b0;
					ld_xy <= 1'b0;
               ld_direction <= 1'b0;
					remove <= 1'b1;
					plot <= 1'b1;
				end
				CYCLE3:
				begin
					remove <= 1'b0;
					plot <= 1'b0;
					move <= 1'b1;
				end
				CYCLE4:
				begin
					move <= 1'b0;
					plot <= 1'b1;
				end
				CYCLE5:
				begin
					plot <= 1'b0;
				end
			endcase
	 end 
	 
	 always@(posedge clk)
    begin: state_FFs
        if(!resetn)
            current <= LOADING;
        else
            current <= next;
	 end
	
endmodule
	 
module datapath(
	input clk,
	input resetn,
	input [2:0] X_COOR,
	input [2:0] Y_COOR,
	input PLAYER,
	input DIRECTION,
	input ld_xy, ld_direction, ld_player, writeEn, remove, move, verify,
	output [7:0] OUT_X_COOR,
	output [7:0] OUT_Y_COOR,
	output [2:0] OUT_COLOUR,
	output reg continue, valid_move, reload
	);

	reg direction; 
	reg [7:0] x, y;
	reg [2:0] colour;
	reg [3:0] count = 4'b0000;
	reg player;
	
	always@(posedge clk) 
	begin //begin at the positive edge of clock signal
	    if(!resetn) 
		 begin // begin when restn is not high
			x <= 8'b0;    
			y <= 8'b0;
	    end
	    else 
		 begin
         if(ld_xy) 
			begin
				case(X_COOR)
					3'd0: x = 8'd52;
					3'd1: x = 8'd60;
					3'd2: x = 8'd68;
					3'd3: x = 8'd76;
					3'd4: x = 8'd84;
					3'd5: x = 8'd92;
					3'd6: x = 8'd100;
					3'd7: x = 8'd108;
					default: x = 8'd52;
				endcase
				case(Y_COOR) 
					3'd0: y = 8'd42;
					3'd1: y = 8'd50;
					3'd2: y = 8'd58;
					3'd3: y = 8'd66;
					3'd4: y = 8'd74;
					3'd5: y = 8'd82;
					3'd6: y = 8'd90;
					3'd7: y = 8'd98;
					default: y = 8'd42;
				endcase
			end
			if(ld_direction) 
			begin
				reload <= 1;
				direction = DIRECTION; //T = 1 GO TO T = 2
				colour <= 3'b111;
			end
			if(ld_player)
			begin
				player <= PLAYER;
			end
			if(verify)
			begin
				if ((X_COOR + Y_COOR) % 2 != 0)
				begin 
					reload <= 1'b1;
				end
				else if (X_COOR > 3'd0 && X_COOR < 3'd7)
				begin
					if (Y_COOR > 3'd0 && Y_COOR < 3'd7)
					begin
						reload <= 1'b0;
					end
					else if (Y_COOR == 3'd0)
					begin
						if (player == 1'b0)
						begin
							reload <= 1'b0;
						end
						else
						begin
							reload <= 1'b1;
						end
					end
					else
					begin
						if (player == 1'b1)
						begin
							reload <= 1'b0;
						end
						else
						begin
							reload <= 1'b1;
						end
					end
				end
				else
				begin
					if (X_COOR == 3'd0)
					begin
						if (Y_COOR == 3'd0)
						begin
							if (player == 1'b0 && direction == 1'b0)
							begin
								reload <= 1'b0;
							end
							else
							begin
								reload <= 1'b1;
							end
						end
						else if (Y_COOR == 3'd7)
						begin
							if(player == 1'b1 && direction == 0)
							begin
								reload <= 1'b0;
							end
							else
							begin 
								reload <= 1'b1;
							end
						end
						else
						begin
							if (direction == 1'b0)
							begin
								reload <= 1'b0;
							end
							else
							begin
								reload <= 1'b1;
							end
						end
					end
					else if (X_COOR == 3'd7)
					begin
						if(Y_COOR == 3'd0)
						begin
							if(player == 1'b0 && direction == 1'b1)
							begin
								reload <= 1'b0;
							end
							else
							begin
								reload <= 1'b1;
							end
						end
						else if(Y_COOR == 3'd7)
						begin
							if(player == 1'b1 && direction == 1'b1)
							begin
								reload <= 1'b0;
							end
							else
							begin
								reload <= 1'b1;
							end
						end
						else
						begin
							if (direction == 1'b1)
							begin
								reload <= 1'b0;
							end
							else
							begin
								reload <= 1'b1;
							end
						end
					end
				end
			end
			if(remove)
			begin
				colour <= 3'b111;
			end
         if(move) 
			begin
				if (player == 1'b0) 
				begin
					case(direction)
						// to the right
						1'b0: 
						begin 
								y <= y + 8'd8;
								x <= x + 8'd8;
								colour <= 3'b001;
					   end
						// to the left
						1'b1: 
						begin 
								y <= y + 8'd8;
								x <= x - 8'd8;
								colour <= 3'b001;
						end
					endcase
				end
				else if (player == 1'b1) 
				begin
					case(direction)
						// to the right
						1'b0: 
						begin 
								y <= y - 8'd8;
								x <= x + 8'd8; 
								colour <= 3'b100;
						end
						// to the left
						1'b1: 
						begin 
								y <= y - 8'd8;
								x <= x - 8'd8;
								colour <= 3'b100;
						end
					endcase
				end
			end
			if (writeEn == 1'b1)
			begin
				if(count == 4'b1111)
				begin
					continue <= 1'b0;
				end
				else if (~(count == 4'b1111))
				begin
					count <= count + 1'b1;
					continue <= 1'b1;
				end
			end
			else
			begin
				count <= 4'b0;
				continue <= 1'b1;
			end
		end 
	end
	
	
   assign OUT_Y_COOR = y + count[3:2];
	assign OUT_X_COOR = x + count[1:0];
   assign OUT_COLOUR = colour;

endmodule
	 
