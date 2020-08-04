module i2c_codec_control( iClK, iRST_N, I2C_SCLK, I2C_SDAT, LUT_INDEX);
	input iClK, iRST_N;
	inout I2C_SDAT;
	output I2C_SCLK;
	output [3:0] LUT_INDEX;
	
	reg [15:0] mI2C_CLK_DIV;
	reg [23:0] mI2C_DATA;
	reg mI2C_CTRL_CLK, mI2C_SCLK;
	reg mI2C_GO, mI2C_END;
	reg [2:0] mSetup_ST;
	reg [15:0] LUT_DATA;
	reg [3:0] LUT_INDEX;
	reg [23:0] SD;
	reg [5:0] SD_COUNT;
	reg SDO;
	reg [2:0] ACK;
	
	wire I2C_SCLK = mI2C_SCLK|(((SD_COUNT>=4)&&(SD_COUNT<=30))?~mI2C_CTRL_CLK:0);
	wire mI2C_ACK = ACK[0]|ACK[1]|ACK[2];
	
	parameter CLK_Freq = 50000000; // 50MHz.
	parameter I2C_Freq = 20000; // 20MHz.
	parameter LUT_SIZE = 11;
	
	always @(posedge iClK or negedge iRST_N) begin
		if(!iRST_N) begin
			mI2C_CTRL_CLK <= 1'b0;
			mI2C_CLK_DIV <= 16'h0000;
		end 
		else begin
			if(mI2C_CLK_DIV < (CLK_Freq/I2C_Freq))
				mI2C_CLK_DIV <= mI2C_CLK_DIV + 1;
			else  begin
				mI2C_CLK_DIV <= 16'h0000;
				mI2C_CTRL_CLK <= ~mI2C_CTRL_CLK;
			end
		end
	end
	
	always @(negedge iRST_N or negedge mI2C_CTRL_CLK) begin
		if(!iRST_N)
			SD_COUNT <= 6'b111111;
		else begin
			if(mI2C_GO == 1'b0)
				SD_COUNT <= 6'b000000;
			else if(SD_COUNT < 6'b111111)
				SD_COUNT <= SD_COUNT + 1;
		end
	end
	
	always@(negedge iRST_N or posedge mI2C_CTRL_CLK) begin
		if(!iRST_N) begin
			mI2C_SCLK<=1'b1;
			SD<=24'h000000;
			SDO<=1'b1;
			ACK<=3'b000;
			mI2C_END<=1'b1;
		end
		else begin
			case(SD_COUNT)
				0: begin
					ACK<=3'b000;
					mI2C_END<=1'b0;
					SDO<=1'b1;
					mI2C_SCLK<=1'b1;
				end
				1: begin
					SD<=mI2C_DATA;
					SDO<=1'b0;
				end
				2: mI2C_SCLK<=1'b0;
				3: SDO<=SD[23];//SLAVE ADDR
				4: SDO<=SD[22];
				5: SDO<=SD[21];
				6: SDO<=SD[20];
				7: SDO<=SD[19];
				8: SDO<=SD[18];
				9: SDO<=SD[17];
				10:SDO<=SD[16];
				11:SDO<=1'b1; //ACK
				12: begin
					SDO<=SD[15];
					ACK[0]<=I2C_SDAT;
				end
				13:SDO<=SD[14];
				14:SDO<=SD[13];
				15:SDO<=SD[12];
				16:SDO<=SD[11];
				17:SDO<=SD[10];
				18:SDO<=SD[9];
				19:SDO<=SD[8];
				20:SDO<=1'b1;//ACK
				21: begin
					SDO<=SD[7];
					ACK[1]<=I2C_SDAT;
				end
				22:SDO<=SD[6];
				23:SDO<=SD[5];
				24:SDO<=SD[4];
				25:SDO<=SD[3];
				26:SDO<=SD[2];
				27:SDO<=SD[1];
				28:SDO<=SD[0];
				29:SDO<=1'b1;//ACK
				30: begin
					SDO<=1'b0;
					mI2C_SCLK<=1'b0;
					ACK[2]<=I2C_SDAT;
				end
				31:mI2C_SCLK<=1'b1;
				32: begin
					SDO<=1'b1;
					mI2C_END<=1'b1;
				end
			endcase
		end
	end
	
	always@(negedge mI2C_CTRL_CLK or negedge iRST_N) begin
		if(!iRST_N) begin
			LUT_INDEX<=4'b0000;
			mSetup_ST<=3'b000;
			mI2C_GO<=1'b0;
			mI2C_DATA<=24'h000000;
		end
		else begin
			if(LUT_INDEX<LUT_SIZE) begin
				case(mSetup_ST)
					0: begin
						mI2C_DATA<={8'h34,LUT_DATA};
						mI2C_GO<=1'b1;
						mSetup_ST<=1;
					end
					1: begin
						if(mI2C_END) begin
							mI2C_GO<=1'b0;
							if(!mI2C_ACK)
								mSetup_ST<=2;
							else
								mSetup_ST<=0;
						end
					end
					2: begin
						LUT_INDEX<=LUT_INDEX+1;
						mSetup_ST<=0;
					end
				endcase
			end
		end
	end
	
	always@(LUT_INDEX) begin
		case(LUT_INDEX)
			0: LUT_DATA<=16'h0000; //Dummy_DATA
			1: LUT_DATA<=16'h001A; //SET_LIN_L
			2: LUT_DATA<=16'h021A; //SET_LIN_R
			3: LUT_DATA<=16'h047B; //SET_HEAD_L
			4: LUT_DATA<=16'h067B; //SET_HEAD_R
			5: LUT_DATA<=16'h08F8; //A_PATH_CTRL
			6: LUT_DATA<=16'h0A06; //D_PATH_CTRL
			7: LUT_DATA<=16'h0C00; //POWER_ON
			8: LUT_DATA<=16'h0E01; //SET_FORMAT
			9: LUT_DATA<=16'h1002; //SAMPLE_CTRL
			10: LUT_DATA<=16'h1201; //SET_ACTIVE
			default: LUT_DATA<=16'h0000;
		endcase
	end
endmodule
