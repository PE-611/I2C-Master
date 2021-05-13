///////////////////////////////////////////////////////////
// Name File : I2C Master.v 										//
// Autor : Dyomkin Pavel Mikhailovich 							//
// Company : GSC RF TRINITI										//
// Description : I2C master module							  	//
// Start design : 23.04.2021 										//
// Last revision : 26.04.2021 									//
///////////////////////////////////////////////////////////
module main (input clk, transmit_enable, reset,
				 //input reg [7:0],
				 output reg antibounce_flg,  SCL,
				 inout SDA
				);
		
reg [28:0] abnc_cnt;
		
		
		
reg [7:0] state;	
reg [7:0] next_state;
reg [7:0] state_cnt;
initial state <= IDLE;


localparam IDLE 						= 8'd0;
localparam START_CONDITION_SDA	= 8'd1;
localparam START_CONDITION_SCL   = 8'd2;
localparam BIT_SET_SDA				= 8'd3;
localparam BIT_APP_SCL_UP        = 8'd4;
localparam BIT_APP_SCL_DOWN      = 8'd5;
localparam DEC_BIT_CNT   			= 8'd6;			 
			 
reg [12:0] cnt;
reg enable_cnt;


reg [7:0] DATA [2:0];
reg [7:0] data;
initial data <= 8'd240;

reg [7:0] bit_cnt;
initial bit_cnt <= 8'd7;



assign SDA = (1'b1 == 1'b0) ? in_sda : out_sda;




reg in_sda;
initial in_sda <= 1'b1;
reg out_sda;
initial out_sda <= 1'b1;
initial SCL <= 1'b1;

always @* 	
		
		case (state)
			
			IDLE:
						
				
				if (transmit_enable <= 1'b0 && antibounce_flg <= 1'b0) begin
					next_state <= START_CONDITION_SDA;
				end
				
				else begin
					next_state <= IDLE;
				end
				
			START_CONDITION_SDA:
				
				if (cnt == 12'd500) begin
					next_state <= START_CONDITION_SCL;
				end
				
				else begin
					next_state <= START_CONDITION_SDA;
				end
				
			START_CONDITION_SCL:
				
				if (cnt == 12'd1000) begin
					next_state <= BIT_SET_SDA;
				end
				
				else begin
					next_state <= START_CONDITION_SCL;
				end
			
			BIT_SET_SDA:	
				
				if (cnt == 12'd1500) begin
					next_state <= BIT_APP_SCL_UP;
				end
				
				else begin
					next_state <= BIT_SET_SDA;
				end
				
			BIT_APP_SCL_UP:
				
				if (cnt == 12'd2000) begin;
					next_state <= BIT_APP_SCL_DOWN;
				end
				
				else begin
					next_state <= BIT_APP_SCL_UP;
				end
				
			BIT_APP_SCL_DOWN:
			
				if (cnt == 12'd2500) begin
					next_state <= DEC_BIT_CNT;
				end
				
				else begin
					next_state <= BIT_APP_SCL_DOWN;
				end
				
			DEC_BIT_CNT:
		
				if (bit_cnt == 8'b0) begin
					next_state <= IDLE;
				end
				
				else begin
					next_state <= BIT_SET_SDA;
				end

		
		endcase


always @(posedge clk) begin
	
	
	if (transmit_enable == 1'b0) begin
		antibounce_flg <= 1'b1;
	end
	
	if (antibounce_flg == 1'b1) begin
		abnc_cnt <= abnc_cnt + 1'b1;
	end
	
	if (abnc_cnt == 28'd50000000) begin
		antibounce_flg <= 1'b0;
		abnc_cnt <= 1'b0;
	end
	
		
		
	
	
	
	if (state == IDLE) begin
		out_sda <= 1'b1;
		SCL <= 1'b1;
		cnt <= 1'b0;
		bit_cnt <= 8'd7;
	end
	
	if (state == START_CONDITION_SDA) begin
		out_sda <= 1'b0;
		SCL <= 1'b1;
		cnt <= cnt + 1'b1;
	end
	
	if (state == START_CONDITION_SCL) begin
		SCL <= 1'b0;
		cnt <= cnt + 1'b1;
	end
	
	if (state == BIT_SET_SDA) begin
		out_sda <= data[bit_cnt];
		cnt <= cnt + 1'b1;
	end
	
	if (state == BIT_APP_SCL_UP) begin
		SCL <= 1'b1;
		cnt <= cnt + 1'b1;
	end
	
	if (state == BIT_APP_SCL_DOWN) begin
		SCL <= 1'b0;
		cnt <= cnt + 1'b1;
	end	
	
	if (state == DEC_BIT_CNT) begin
		bit_cnt <= bit_cnt - 1'b1;
		cnt <= 12'd1000;
	end

				
		
		
end	


always @(posedge clk or negedge reset) begin //
	
	
	if(!reset) begin
		state <= IDLE;
	end
	
	else begin
		state <= next_state;
	end
end				

		
endmodule


//data_out <=  {data_out[7:0], Rx_in}; shift reg