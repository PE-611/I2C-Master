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
				 output reg antibounce_flg,  SCL, ERROR_TARNSMIT,
				 inout SDA
				);
		
reg [28:0] abnc_cnt;
		
initial ERROR_TARNSMIT <= 1'b0;		
		
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
localparam BIT_APP_ACK_DEL 		= 8'd7;
localparam BIT_APP_ACK_UP			= 8'd8;
localparam BIT_APP_ACK_DOWN		= 8'd9;
localparam DEC_BYTE_CNT          = 8'd10;
localparam WAIT_TRANSMIT         = 8'd11;
localparam ERROR_TRANSMIT_DEL    = 8'd12;
localparam TRANSMIT_RESTART      = 8'd13; 
localparam STOP_CONDITION_SCL    = 8'd14;
localparam STOP_CONDITION_SDA    = 8'd15;
			 
			 
reg [12:0] cnt;
reg enable_cnt;



reg [7:0] DATA [2:0];
reg [7:0] data;


reg [7:0] bit_cnt;
initial bit_cnt <= 8'd7;
reg [7:0] byte_cnt;
initial byte_cnt <= 8'd2;



assign SDA = (state == IDLE || state == BIT_APP_ACK_UP || state == WAIT_TRANSMIT) ? 1'bZ : out_sda; 


reg out_sda;
initial out_sda <= 1'b1;
initial SCL <= 1'b1;

always @* 	
		
		case (state)
			
			IDLE:
						
				
				if (transmit_enable <= 1'b0 && antibounce_flg <= 1'b0 && SDA == 1'b1 && SCL == 1'b1) begin
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
					next_state <= BIT_APP_ACK_DEL;
				end
				
				else begin
					next_state <= BIT_SET_SDA;
				end
				
			BIT_APP_ACK_DEL:
					
				if (cnt == 12'd1500) begin
					next_state <= BIT_APP_ACK_UP;
				end
				
				else begin
					next_state <= BIT_APP_ACK_DEL;
				end
				
			BIT_APP_ACK_UP:
				
				if (cnt == 12'd2000) begin
					next_state <= BIT_APP_ACK_DOWN;
				end
		
		
				else begin
					next_state <= BIT_APP_ACK_UP;
				end
				
			BIT_APP_ACK_DOWN:
				
				if (cnt == 12'd3000 && ERROR_TARNSMIT == 1'b0) begin
					next_state <= DEC_BYTE_CNT;
				end
				
				else if (cnt == 12'd3000 && ERROR_TARNSMIT == 1'b1) begin
					next_state <= ERROR_TRANSMIT_DEL;					//// При ошибке передачи (отсутствие бита АСК) переходим в состояние ERROR_TRANSMIT_DEL немнорго ждем
				end
				
				else begin
					next_state <= BIT_APP_ACK_DOWN;
				end
				
				
				
			DEC_BYTE_CNT:
				
				if (byte_cnt == 8'b0) begin
					next_state <= STOP_CONDITION_SCL;
				end
				
				else begin
					next_state <= WAIT_TRANSMIT;
				end
				
			
			WAIT_TRANSMIT:
			
				if (SDA == 1'b1) begin
					next_state <= BIT_SET_SDA;
				end
				
				else begin
					next_state <= WAIT_TRANSMIT;
				end
			
			
				
			ERROR_TRANSMIT_DEL:
			
				if (cnt == 12'd4000) begin
					next_state <= TRANSMIT_RESTART;						/// Немного подождали переходим в состояние TRANSMIT_RESTART
				end
			
				else begin
					next_state <= ERROR_TRANSMIT_DEL;
				end
			
			TRANSMIT_RESTART: 
				 
				 if (cnt >= 12'd4000) begin
					next_state <= BIT_SET_SDA;								/// Тут мы на один такт (перезагружаем все счетчики и т.п. для перезагрузки передачи) и переходим в состояние BIT_SET_SDA и начинаем передачу посылки заново
				 end
				 
				 else begin
					next_state <= TRANSMIT_RESTART;
				 end
				 
			
			STOP_CONDITION_SCL:
			
				if (cnt == 12'd3500) begin
					next_state <= STOP_CONDITION_SDA;
				end
				
				else begin
					next_state <= STOP_CONDITION_SCL;
				end
				
			STOP_CONDITION_SDA:
				
				if (cnt >= 12'd4000) begin
					next_state <= IDLE;
				end
				
				else begin
					next_state <= STOP_CONDITION_SDA;
				end
			

		
		endcase


always @(posedge clk) begin
DATA[0] <= 8'd255;
DATA[1] <= 8'd15;
DATA[2] <= 8'd192;
	
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
		byte_cnt <= 8'd2;
		ERROR_TARNSMIT <= 1'b0;
		data <= DATA[2];
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
	
	if (state == BIT_APP_ACK_DEL) begin
		SCL <= 1'b0;
		cnt <= cnt + 1'b1;
	end
	
	if (state == BIT_APP_ACK_UP) begin
		SCL <= 1'b1;
		cnt <= cnt + 1'b1;
		
		if (SDA == 1'b1) begin
			ERROR_TARNSMIT <= 1'b1;
		end
		else begin
			ERROR_TARNSMIT <= 1'b0;
		end
		
	end
	
	if (state == BIT_APP_ACK_DOWN) begin
		SCL <= 1'b0;
		cnt <= cnt + 1'b1;
	end
	
	if (state == DEC_BYTE_CNT) begin
		byte_cnt <= byte_cnt - 1'b1;
		bit_cnt <= 8'd7;
		cnt <= 12'd1000;
		out_sda <= 1'b1;
	end
	
	if (state == WAIT_TRANSMIT) begin
		SCL <= 1'b0;
		data <= DATA[byte_cnt];
	end
	
	if (state == ERROR_TRANSMIT_DEL) begin
		cnt <= cnt + 1'b1;
		out_sda <= 1'b1;
		SCL <= 1'b0;
	end
	
	if (state == TRANSMIT_RESTART) begin
		cnt <= 12'd1000;
		bit_cnt <= 8'd7;
	end
	
	if (state == STOP_CONDITION_SCL) begin
		SCL <= 1'b1;
		cnt <= cnt + 1'b1;
	end
	
	if (state == STOP_CONDITION_SDA) begin
		out_sda <= 1'b1;
		cnt <= cnt + 1'b1;
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