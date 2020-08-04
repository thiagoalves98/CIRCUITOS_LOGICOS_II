module piano(CLOCK_50, CLOCK_27, KEY, SW, I2C_SDAT, I2C_SCLK, AUD_ADCDAT, AUD_DACLRCK, AUD_DACDAT, AUD_BCLK, AUD_ADCLRCK, AUD_XCK, LEDR, LEDG);
	
	// Entradas:
		input CLOCK_27; // Clock em 27MHz.
		input CLOCK_50;
		input [3:0] KEY;
		input [17:0] SW; 
		input AUD_ADCDAT;
	
	// Inouts:
		inout I2C_SDAT;
		
	// Saidas:
		output I2C_SCLK, AUD_ADCLRCK, AUD_DACLRCK;
		output AUD_DACDAT;
		output [12:0] LEDR; // Saída dos leds alterada p/ 12, pois foram adicionadas mais notas
		output [7:0] LEDG;
		output reg AUD_BCLK, AUD_XCK;
		
	// Parametros:
		parameter REF_CLK = 18432000; // MCLK, 18.432MHz.
		parameter SAMPLE_RATE = 48000; // 48KHz.
		parameter CHANNEL_NUM = 2; // Dual Channel.
		parameter SIN_SAMPLE_DATA = 48;
		parameter DATA_WIDTH = 16; //16 bits
		
		//  Frequencia Notas Musicais baseadas na 4º oitava
			parameter DO = 264;
			parameter RE = 297;
			parameter MI = 350;
			parameter FA = 352;
			parameter SOL = 396;
			parameter LA = 440;
			parameter SI = 495;
			parameter DO1 = 528;
			
		// Frequencia das notas sustenidas adicionadas entre as notas musicais, baseadas na 4º oitava	
			parameter DOs = 279;
			parameter REs = 313;
			parameter FAs = 373;
			parameter SOLs = 419;
			parameter LAs = 470;
			
	// Regs:
		reg [19:0] count20;
		reg Reset;
		reg [3:0] BCK_DIV;
		reg [8:0] LRCK_1X_DIV;
		reg LRCK_1X;
		reg [3:0] SEL_Count;
		reg [11:0] count12;
		reg SING;
		reg [DATA_WIDTH - 1:0] SOUND1, SOUND2, SOUND3;
		reg [1:0] count2;
		reg [12:0] Octave, Notas; // Octave e Notas ajustados para suportar mais notas
		reg [3:0] volume;
		reg [29:0] contador;
		reg [29:0] contador1;
		reg [29:0] newcont, newCont, newCont2;
		
	// Funcao ... :
		i2c_codec_control u1(CLOCK_27, KEY[0], I2C_SCLK, I2C_SDAT, LEDG[7:4]);
	
	// Clock do Codec:
		always @( posedge CLOCK_27 or negedge Reset) begin
			if(!Reset)
				AUD_XCK <= 0;
			else
				AUD_XCK <= ~AUD_XCK;
		end
	
	// Delay do Reset:
		always @(posedge CLOCK_27) begin
			if( count20 != 20'hFFFFF) begin
				count20 <= count20+1;
				Reset <= 0;
			end
			else
				Reset <= 1;
		end

					  				  	
	always @( posedge AUD_XCK or negedge Reset ) begin
		if(!Reset) begin
			BCK_DIV <= 4'b0;
			AUD_BCLK <= 0;			
		end
		else begin
			if( BCK_DIV >= (REF_CLK/(SAMPLE_RATE*DATA_WIDTH*CHANNEL_NUM*2) - 1 ))
			begin
				BCK_DIV <= 4'b0;
				AUD_BCLK <= ~AUD_BCLK;
			end
			else 
				BCK_DIV <= BCK_DIV + 1;
		end
	end
	
	always @(posedge AUD_XCK or negedge Reset) begin
		if(!Reset) begin
			LRCK_1X_DIV <= 9'b0;
			LRCK_1X <= 1'b0;
		end 
		else begin
			if(LRCK_1X_DIV >= (REF_CLK/(SAMPLE_RATE*2) - 1)) begin
				LRCK_1X_DIV <= 9'b0;
				LRCK_1X <= ~LRCK_1X;
			end
			else
				LRCK_1X_DIV <= LRCK_1X_DIV + 1;
		end
	end
	
	assign AUD_ADCLRCK = LRCK_1X;
	assign AUD_DACLRCK = LRCK_1X;
	
	always @(negedge AUD_BCLK or negedge Reset) begin
		if(!Reset)
			Octave <= 13'b0000000000000; // Zerando Octave
		else
			if(SW[17])begin
				Octave <= Notas;
			end
			else begin
				if(SW[12:0]) // Ajustado Switch para 13 possibilidades baseado na quantidade de notas
					Octave <= SW[12:0];
				else
					Octave <= 13'b0000000000000;
			end
	end
	
	always @(posedge CLOCK_27) begin
		if(contador1 == 30'd15_999_999 ) begin
			if(SW[16]) begin 
				case(contador)
					0: begin
					   Notas <= 13'b0000000000001; // Seta nota Dó
					   if( newCont < 13) begin
							newCont <= newCont + 1;
							#2 Notas <= 13'b0000000000000;
							contador = 0;
					   end
					   else begin
							contador = contador + 1;
							newCont <= 0;
					   end
					   contador1 = 30'd0;
					end
					1: begin
					   Notas <= 13'b0000000000010; // Seta nota Dó sustenido
					   contador = contador + 1;
					   contador1 = 30'd0;
					end
					2: begin
					   Notas <= 13'b0000000000100; // // Seta nota Ré
					   contador = contador + 1;
					   contador1 = 30'd0;
					end
					3: begin
					   Notas <= 13'b0000000001000; // Seta nota Ré sustenido
					   contador = contador + 1;
					   contador1 = 30'd0;
					end
					4: begin
					   Notas <= 13'b0000000010000; // Seta nota Mi
					   contador = contador + 1;
					   contador1 = 30'd0;
					end
					5: begin
					   Notas <= 13'b0000000100000; // Seta nota Fa
					   if(newCont < 3) begin
						   newCont <= newCont + 1;
						   #2 Notas <= 13'b0000000000000;
						   contador = 5;
					   end
					   else begin
						   contador = contador + 1;	
						   newCont <= 0;
					   end
					   contador1 = 30'd0;
					end
					6: begin
					   Notas <= 13'b0000001000000; // Seta nota Fa sustenido
					   if( newCont < 3) begin
							newCont <= newCont + 1;
							#2 Notas <= 13'b0000000000000;
							contador = 6;
					   end
					   else begin
							contador = contador + 1;
							newCont <= 0;
					   end
					   contador1 = 30'd0;
					end
					7: begin
					   Notas <= 13'b0000010000000; // Seta nota Sol
					   if( newCont < 3) begin
							newCont <= newCont + 1;
							#2 Notas <= 13'b0000000000000;
							contador = 6;
					   end
					   else begin
							contador = contador + 1;
							newCont <= 0;
					   end
					   contador1 = 30'd0;
					end
					8: begin
					   Notas <= 13'b0000100000000; // Seta nota Sol sustenido
					   if( newCont < 3) begin
							newCont <= newCont + 1;
							#2 Notas <= 13'b0000000000000;
							contador = 6;
					   end
					   else begin
							contador = contador + 1;
							newCont <= 0;
					   end
					   contador1 = 30'd0;
					end
					9: begin
					   Notas <= 13'b0001000000000; // Seta nota La
					   if( newCont < 3) begin
							newCont <= newCont + 1;
							#2 Notas <= 13'b0000000000000;
							contador = 6;
					   end
					   else begin
							contador = contador + 1;
							newCont <= 0;
					   end
					   contador1 = 30'd0;
					end
					10: begin
					   Notas <= 13'b0010000000000; // Seta nota La sustenido
					   if( newCont < 3) begin
							newCont <= newCont + 1;
							#2 Notas <= 13'b0000000000000;
							contador = 6;
					   end
					   else begin
							contador = contador + 1;
							newCont <= 0;
					   end
					   contador1 = 30'd0;
					end
					11: begin
					   Notas <= 13'b0100000000000; // Seta nota Si
					   if( newCont < 3) begin
							newCont <= newCont + 1;
							#2 Notas <= 13'b0000000000000;
							contador = 6;
					   end
					   else begin
							contador = contador + 1;
							newCont <= 0;
					   end
					   contador1 = 30'd0;
					end
					12: begin
					   Notas <= 13'b1000000000000; // Seta nota Dó
					   if( newCont < 3) begin
							newCont <= newCont + 1;
							#2 Notas <= 13'b0000000000000;
							contador = 6;
					   end
					   else begin
							contador = contador + 1;
							newCont <= 0;
					   end
					   contador1 = 30'd0;
					end
					7: begin
					   Notas <= 13'b0000010000000; // SOL
					   contador = contador + 1;
					   contador1 = 30'd0;
					end
					8:begin
					   Notas <= 13'b0000100000000; // SOLs
					   contador = contador + 1;
					   contador1 = 30'd0;
					end
					9:begin
					   Notas <= 13'b0001000000000; // LA
					   contador = contador + 1;
					   contador1 = 30'd0;
					end
					10:begin
					   Notas <= 13'b0010000000000; // LAs
					   contador = contador + 1;
					   contador1 = 30'd0;
					end
					11:begin
					   Notas <= 13'b0100000000000; // SI
					   contador = contador + 1;
					   contador1 = 30'd0;
					end
					12: begin
					   Notas <= 13'b0100000000000; // DO1
					   contador = contador + 1;
					   contador1 = 30'd0;
					end
					13: begin
					   Notas <= 13'b1000000000000; // SI
					   if( newCont < 13) begin
							newCont <= newCont + 1;
							#2 Notas <= 13'b0000000000000;
							contador = 13;
					   end
					   else begin
							contador = contador + 1;
							newCont <= 0;
					   end
					   contador1 = 30'd0;
					end
					14: begin
						Notas <= 8'b00010000; // SOL
					    contador = contador + 1;
					    contador1 = 30'd0;
					end
					13: begin
						Notas <= 8'b00100000; // LA
					    contador = contador + 1;
					    contador1 = 30'd0;
					end
					14:begin
					   Notas <= 8'b01000000; // SI
					   contador = contador + 1;
					   contador1 = 30'd0;
					end
					15: begin
					   Notas <= 8'b10000000; // DO1
					   if(newCont < 3) begin
						   newCont <= newCont + 1;
						   #2 Notas <= 8'b00000000;
						   contador = 15;
					   end
					   else begin
						   contador = contador + 1;	
						   newCont <= 0;
					   end
					   contador1 = 30'd0;
					end
					16: begin
					   Notas <= 8'b01000000; // SI
					   if( newCont < 4) begin
							newCont <= newCont + 1;
							#2 Notas <= 8'b00000000;
							contador = 16;
					   end
					   else begin
							contador = contador + 1;
							newCont <= 0;
					   end
					   contador1 = 30'd0;
					end
					17: begin
					   Notas <= 8'b00000010; // RE
					   if( newCont < 2) begin
							newCont <= newCont + 1;
							#2 Notas <= 8'b00000000;
							contador = 17;
					   end
					   else begin
							contador = contador + 1;
							newCont <= 0;
					   end
					   contador1 = 30'd0;
					end
					18: begin
					   Notas <= 8'b00000001; // SI
					   contador = contador + 1;
					   contador1 = 30'd0;
					end
					19: begin
						Notas <= 8'b00100000; // LA
					    contador = contador + 1;
					    contador1 = 30'd0;
					end
					20: begin
						Notas <= 8'b00010000; // SOL
					    contador = contador + 1;
					    contador1 = 30'd0;
					end
					// Verso 3:
					21: begin
						Notas <= 8'b00000010; // RE
						contador = contador + 1;
						contador1 = 30'd0;
					end
					22: begin
						Notas <= 8'b00000001; // SI
					    contador = contador + 1;
					    contador1 = 30'd0;
					end
					23: begin
						Notas <= 8'b00100000; // LA
					    contador = contador + 1;
					    contador1 = 30'd0;
					end
					24: begin
						Notas <= 8'b00010000; // SOL
						if(newCont2 < 1)
							contador = 25;
						else begin
							contador = 26;
							newCont2 = 0;
						end
						newCont2 = newCont2 + 1;	
					    contador1 = 30'd0;
					end
					25: begin
						Notas <= 8'b00000010; // RE
						if(newCont < 2) begin
							contador = 25;
							newCont = newCont + 1;
							#2 Notas <= 8'b00000000;
						end
						else
							contador = 21;
						contador1 = 30'd0;
					end
					26: begin
					   Notas <= 8'b00000100; // MI
					   if(newCont < 3) begin
							contador = 26;
							newCont = newCont + 1;
							#2 Notas <= 8'b00000000;
						end
						else
							contador = 27;
						contador1 = 30'd0;
					end
					27: begin
						Notas <= 8'b00000001; // DO
						contador = contador + 1;
						contador1 = 30'd0;
					   
					end
					28: begin
						Notas <= 8'b0100000; // SI
						contador = contador + 1;
						contador1 = 30'd0;
					end
					29:begin
						Notas <= 8'b00100000; // LA
						contador = contador + 1;
						contador1 = 30'd0;
					end
					30: begin
						Notas <= 8'b00000010; // RE
						if(newCont < 3) begin
							contador = 30;
							newCont = newCont + 1;
							#2 Notas <= 8'b00000000;
						end
						else
							contador = 21;
						contador1 = 30'd0;
					end
					31: begin
						Notas <= 8'b00000100; // MI
						contador = contador + 1;
						contador1 = 30'd0;
					end
					32: begin
						Notas <= 8'b00000010; // RE
						contador = contador + 1;
						contador1 = 30'd0;
					end
					33: begin
						Notas <= 8'b00100000; // LA
						contador = contador + 1;
						contador1 = 30'd0;
					end
					34: begin
						Notas <= 8'b00000001; // DO
						contador = contador + 1;
						contador1 = 30'd0;   
					end
					35: begin
						Notas <= 8'b00000001; // SI
					    contador = contador + 1;
					    contador1 = 30'd0;
					end
					// Verso 4:
					35: begin
					   Notas <= 8'b00000010; // RE
					   contador = contador + 1;
					   contador1 = 30'd0;
					end
					36: begin
					   Notas <= 8'b00000001; // SI
					   contador = contador + 1;
					   contador1 = 30'd0;
					end
					37: begin
						Notas <= 8'b00100000; // LA
					    contador = contador + 1;
					    contador1 = 30'd0;
					end
					38: begin
						Notas <= 8'b00010000; // SOL
					    if(newCont2 < 1)
							contador = 39;
						else
							contador = 40;
					    newCont2 = newCont2 + 1;
					    contador1 = 30'd0;
					end
					39: begin
					   Notas <= 8'b00000010; // RE
					   if( newCont < 2) begin
							newCont <= newCont + 1;
							#2 Notas <= 8'b00000000;
							contador = 13;
					   end
					   else begin
							contador = contador + 1;
							newCont <= 0;
					   end
					   contador1 = 30'd0;
					end
					40: begin
					   Notas <= 8'b00000100; // MI
					   if(newCont < 2) begin
							contador = 40;
							newCont = newCont + 1;
							#2 Notas <= 8'b00000000;
						end
						else
							contador = contador + 1;
						contador1 = 30'd0;
					end
					41: begin
						Notas <= 8'b00000100; // MI
						contador = contador + 1;
						contador1 = 30'd0;
					end
					42: begin
						Notas <= 8'b00000001; // DO
						contador = contador + 1;
						contador1 = 30'd0;				   
					end
					43: begin
					   Notas <= 8'b01000000; // SI
					   contador = contador + 1;
					   contador1 = 30'd0;
					end
					44: begin
						Notas <= 8'b00100000; // LA
					    contador = contador + 1;
					    contador1 = 30'd0;
					end
					45: begin
					   Notas <= 8'b00000010; // RE
					   if( newCont < 3) begin
							newCont <= newCont + 1;
							#2 Notas <= 8'b00000000;
							contador = 13;
					   end
					   else begin
							contador = contador + 1;
							newCont <= 0;
					   end
					   contador1 = 30'd0;
					end
					46: begin
						Notas <= 8'b00000100; // MI
						contador = contador + 1;
						contador1 = 30'd0;
					end
					47: begin
						Notas <= 8'b00000010; // RE
						contador = contador + 1;
						contador1 = 30'd0;
					end
					48: begin
						Notas <= 8'b00100000; // LA
						contador = contador + 1;
						contador1 = 30'd0;
					end
					49: begin
					   Notas <= 8'b01000000; // SI
					   if( newCont < 2) begin
							newCont <= newCont + 1;
							#2 Notas <= 8'b00000000;
							contador = 16;
					   end
					   else begin
							contador = contador + 1;
							newCont <= 0;
					   end
					   contador1 = 30'd0;
					end
					50: begin
						Notas <= 8'b00000100; // MI
						contador = contador + 1;
						contador1 = 30'd0;
					end
					51: begin
						Notas <= 8'b00000010; // RE
						contador = contador + 1;
						contador1 = 30'd0;
					end
					52: begin
						Notas <= 8'b00000001; // DO
						contador = contador + 1;
						contador1 = 30'd0;
					end
					53: begin
						Notas <= 8'b00100000; // LA
						contador = contador + 1;
						contador1 = 30'd0;
					end
					54: begin
						Notas <= 8'b00010000; // SOL
						contador = 0;
						contador1 = 30'd0;
					end			
			endcase
		end
			if(SW[15]) begin //	Brilha Brilha Estrelinha:
				case(contador)
					0: begin
						Notas <= 8'b00000001; // DO
						contador = contador + 1;
						contador1 = 30'd0;
					   
					end
					1: begin
						Notas <= 8'b00000001; // DO
						contador = contador + 1;
						contador1 = 30'd0;
					end
					2: begin
						Notas <= 8'b00010000; // SOL
						contador = contador + 1;
						contador1 = 30'd0;
					end
					3: begin
						Notas <= 8'b00010000; // SOL
						contador = contador + 1;
						contador1 = 30'd0;
					end
					4: begin
						Notas <= 8'b00100000; // LA
						contador = contador + 1;
						contador1 = 30'd0;
					end
					5: begin
						Notas <= 8'b00100000; // LA
						contador = contador + 1;
						contador1 = 30'd0;
					end
					6: begin
						Notas <= 8'b00010000; // SOL
						contador = contador + 1;
						contador1 = 30'd0;
					end
					7: begin
						Notas <= 8'b00001000; // FA
						contador = contador + 1;
						contador1 = 30'd0;
					end
					8: begin
						Notas <= 8'b00001000; // FA
						contador = contador + 1;
						contador1 = 30'd0;
					end
					9: begin
						Notas <= 8'b00000100; // MI
						contador = contador + 1;
						contador1 = 30'd0;
					end
					10: begin
						Notas <= 8'b00000100; // MI
						contador = contador + 1;
						contador1 = 30'd0;
					end
					11: begin
						Notas <= 8'b00000010; // RE
						contador = contador + 1;
						contador1 = 30'd0;
					end
					12: begin
						Notas <= 8'b00000010; // RE
						contador = contador + 1;
						contador1 = 30'd0;
					end
					13: begin
						Notas <= 8'b00000001; // do
						if(newcont < 4)begin
							newcont = newcont + 1;
							contador = 7;
						end
						else contador = 0;
						contador1 = 30'd0;
					end
					default: begin
						contador = 0;
						Notas <= 8'b00000000;
					end
				endcase
			end 
		else begin
			contador1 = contador1 + 1;
		end
	end
	end
	
	// Atualiza count12 de acordo com o SW acionado, p/ modificar Sound
	always @(posedge AUD_BCLK or negedge Reset) begin
		if(!Reset)
			count12 = 12'h000;
		else begin
			if(Octave == 13'b0000000000001) begin
				if(count12 == DO)begin
					count12 = 12'h00;
				end
				else
					count12 = count12 + 1;
			end
			if(Octave == 13'b0000000000010) begin
				if( count12 == DOs)
					count12 = 12'h00;
				else
					count12 = count12 + 1;
			end
			if(Octave == 13'b0000000000100) begin
				if( count12 == RE)
					count12 = 12'h00;
				else
					count12 = count12 + 1;
			end
			if(Octave == 13'b0000000001000) begin
				if( count12 == REs)
					count12 = 12'h00;
				else
					count12 = count12 + 1;
			end
			if(Octave == 13'b0000000010000) begin
				if( count12 == MI)
					count12 = 12'h00;
				else
					count12 = count12 + 1;
			end
			if(Octave == 13'b0000000100000) begin
				if( count12 == FA)
					count12 = 12'h00;
				else
					count12 = count12 + 1;
			end
			if(Octave == 13'b0000001000000) begin
				if( count12 == FAs)
					count12 = 12'h00;
				else
					count12 = count12 + 1;
			end
			if(Octave == 13'b0000010000000) begin
				if( count12 == SOL)
					count12 = 12'h00;
				else
					count12 = count12 + 1;
			end
			if(Octave == 13'b0000100000000) begin
				if( count12 == SOLs)
					count12 = 12'h00;
				else
					count12 = count12 + 1;
			end
			if(Octave == 13'b0001000000000) begin
				if( count12 == LA)
					count12 = 12'h00;
				else
					count12 = count12 + 1;
			end
			if(Octave == 13'b0010000000000) begin
				if( count12 == LAs)
					count12 = 12'h00;
				else
					count12 = count12 + 1;
			end
			if(Octave == 13'b0100000000000) begin
				if( count12 == SI)
					count12 = 12'h00;
				else
					count12 = count12 + 1;
			end
			if(Octave == 13'b1000000000000) begin
				if( count12 == DO1)
					count12 = 12'h00;
				else
					count12 = count12 + 1;
			end
			
		end
	end
	
	// Atualiza LED quando SW referente a alguma nota musical é acionado
	assign LEDR = Octave;
	
	always @(negedge AUD_BCLK or negedge Reset) begin
		if(!Reset) begin
			SOUND1 <= 0;
			SOUND2 <= 0;
			SOUND3 <= 0;
			SING <= 1'b0;
		end
		else begin
			if(count12 == 12'h001) begin
				SOUND1 <= (SING == 1'b1)?32768+29000:32768-29000;
				SOUND2 <= (SING == 1'b1)?32768+16000:32768-16000;
				SOUND3 <= (SING == 1'b1)?32768+3000 : 32768-3000;
				SING <= ~SING;
			end
		end
	end
	
	// Atualiza count2 quando botão do volume(Key[3]) é acionado
	always @(negedge KEY[3] or negedge Reset) begin
		if(!Reset)
			count2 <= 2'b00;
		else
			count2 <= count2 + 1;
	end
	
	always @(negedge AUD_BCLK or negedge Reset) begin
		if(!Reset)
			SEL_Count <= 4'b0000;
		else
			SEL_Count <= SEL_Count + 1;
	end
	
	assign AUD_DACDAT = (count2 == 2'd1)?SOUND1[~SEL_Count]:
						(count2 == 2'd2)?SOUND2[~SEL_Count]:
						(count2 == 2'd3)?SOUND3[~SEL_Count]:1'b0;
						
	// Atualiza 'volume' indicador do Som quando Key[3] é modificado
	always @(count2) begin
		case(count2)
			0: volume <= 4'b0000;
			1: volume <= 4'b0001;
			2: volume <= 4'b0011;
			3: volume <= 4'b1111;
			default: volume <= 4'b0000;
		endcase
	end

	// Atualiza led referente ao volume do som
	assign LEDG[3:0] = volume;
	
endmodule
