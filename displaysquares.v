

module displaysquares
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
	assign resetn = KEY[0];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;
	wire controla;
	wire controlb;
	wire controlc;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(1'b1),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";
			
	// Put your code here. Your code should produce signals x,y,colour and writeEn/plot
	// for the VGA controller, in addition to any other functionality your design may require.
    
    // Instansiate datapath
	specialdatapath d0(KEY[2], KEY[1], CLOCK_50, KEY[0], x, y, colour);

    // Instansiate FSM control

    
endmodule


module specialdatapath(leftsignal, rightsignal, clock, reset, xout, yout, colorout);
		input clock, reset, leftsignal, rightsignal;
		output [2:0]colorout;
		output [7:0]xout;
		output [7:0]yout;
		wire[19:0] c0;
		wire[3:0] c1;
		wire signal_x,signal_y;
		wire[7:0] x_in,y_in;
		wire[2:0] colour_1;
		
		delay_counter d1(clock,reset,c0);
		assign enable_1 = (c0 ==  20'd0) ? 1 : 0;
		frame_counter m2(clock,reset,enable_1,c1);
		assign enable_2 = (c1 == 4'b1111) ? 1 : 0;
		x_counter m3(clock,enable_2,reset, signal_x, leftsignal,rightsignal,x_in);
		y_register m4(clock, reset, y_in);
		h_register m6(clock,reset,x_in,signal_x);
		assign colorout = (c1 == 4'b1111) ? 3'b000 : 3'b111;
		datapath m7(x_in,y_in,clock,reset,xout, yout);
endmodule

module datapath(X, Y, clock, reset, xout, yout);
		input [7:0]X;
		input [7:0]Y;
		input clock;
		input reset;
		output [7:0]xout;
		output [7:0]yout;
		
		counter c1(X, Y, clock, reset, xout, yout);


endmodule


module delay_counter(clock,reset_n,q);
		input clock;
		input reset_n;
		output reg [19:0] q;

		always @(posedge clock)
		begin
			if(reset_n == 1'b0)
				q <= 20'b11001110111001100001;
			else
			begin
			   if ( q == 20'd0 )
					q <= 20'b11001110111001100001;
				else
					q <= q - 1'b1;
			end
		end
endmodule

module x_counter(clock,clock_1,reset_n, signal, leftsignal, rightsignal, q);
	input clock, reset_n, signal, leftsignal, rightsignal, clock_1;
	output reg[7:0] q;

	always@(posedge clock)
	begin
		if(reset_n == 1'b0)
			q <= 8'd78;
		if (clock_1 == 1'b0)
		begin
			if(reset_n == 1'b1 && signal == 1'b1)
				begin
				if(leftsignal == 1'b1)
					q <= q + 1'b1;
				else if (rightsignal == 1'b1)
					q <= q - 1'b1;
				end
		end
	end
endmodule

module y_register(clock, reset_n, q);
	input clock, reset_n;
	output reg[7:0] q;

   always@(posedge clock)
	begin
		if(reset_n == 1'b0)
			q <= 8'b00000000;
		else
			q <= q;
	end
endmodule


module h_register(clock,reset_n,x,direction);
	input clock,reset_n;
	input [7:0] x;
	output reg direction;

	always@(posedge clock)
	begin
		if(reset_n == 1'b0)
			direction <= 1'b1;
		else
		begin
			if(x + 1 > 8'd98 || x - 1 < 8'd62)
				direction <= 1'b0;
			else
				direction <= 1'b1;
		end
	end
endmodule




module frame_counter(clock,reset_n,enable,q);
	input clock,reset_n,enable;
	output reg [3:0] q;

	always @(posedge clock)
	begin
		if(reset_n == 1'b0)
			q <= 4'b0000;
		else if (enable == 1'b1)
		begin
		  if(q == 4'b1111)
			  q <= 4'b0000;
		  else
			  q <= q + 1'b1;
		end
   end
endmodule


module counter(X, Y, clock, reset, Xout, Yout);
		input [7:0]X;
		input [6:0]Y;
		input clock;
		input reset;
		output reg [7:0]Xout;
		output reg [6:0]Yout;
		reg [4:0]count;
		
		always @(posedge clock)
		begin
			if (reset == 1'b0)
				count <= 5'b00000;
			else
				begin
					if (count >= 5'b00100 && count <= 5'b00111)
						begin
							if (count[0] == 1'b1)
								Xout <= X + 2'b11;
							else if (count[0] == 1'b0)
								Xout <= X + 2'b10;
							if (count[1] == 1'b1)
								Yout <= Y + 1'b1;
							else if (count[1] == 1'b0)
								Yout <= Y;
						end
					else if (count >= 5'b01000 && count <= 5'b01011)
						begin
							if (count[0] == 1'b1)
								Xout <= X + 1'b1;
							else if (count[0] == 1'b0)
								Xout <= X;
							if (count[1] == 1'b1)
								Yout <= Y + 2'b11;
							else if (count[1] == 1'b0)
								Yout <= Y + 2'b10;
						end
					else if (count >= 5'b01100 && count <= 5'b01111)
						begin
							if (count[0] == 1'b1)
								Xout <= X + 2'b11;
							else if (count[0] == 1'b0)
								Xout <= X + 2'b10;
							if (count[1] == 1'b1)
								Yout <= Y + 2'b11;
							else if (count[1] == 1'b0)
								Yout <= Y + 2'b10;
						end
					else if (count >= 5'b00000 && count <= 5'b00011)
						begin
							if (count[0] == 1'b1)
								Xout <= X + 1'b1;
							else if (count[0] == 1'b0)
								Xout <= X;
							if (count[1] == 1'b1)
								Yout <= Y + 1'b1;
							else if (count[1] == 1'b0)
								Yout <= Y;
						end

					count <= count + 1'b1;
					if (count == 5'b10000)
					begin
						count <= 5'b00000;
						Xout <= X;
						Yout <= Y;
					end
			end
			
		end
endmodule
