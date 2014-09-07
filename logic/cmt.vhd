--
-- cmt.vhd
--
-- Sharp PWM Tape I/F and Pseudo-CMT module
-- for MZ-80B/2000 on FPGA
--
-- Nibbles Lab. 2013
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity cmt is
	Port (
		-- Avalon Bus
		RRST_x  : in std_logic;								-- NiosII Reset
		RCLK	  : in std_logic;								-- NiosII Clock
		RADR	  : in std_logic_vector(15 downto 0);	-- NiosII Address Bus
		RCS_x	  : in std_logic;								-- NiosII Read Signal
		RWE_x	  : in std_logic;								-- NiosII Write Signal
		RDI	  : in std_logic_vector(7 downto 0);	-- NiosII Data Bus(in)
		RDO	  : out std_logic_vector(7 downto 0);	-- NiosII Data Bus(out)
		-- 7-SEG Dispaly
		HEX0_D  : out std_logic_vector(6 downto 0);	--	Seven Segment Digit 0
		HEX0_DP : out std_logic;							--	Seven Segment Digit DP 0
		HEX1_D  : out std_logic_vector(6 downto 0);	--	Seven Segment Digit 1
		HEX1_DP : out std_logic;							--	Seven Segment Digit DP 1
		HEX2_D  : out std_logic_vector(6 downto 0);	--	Seven Segment Digit 2
		HEX2_DP : out std_logic;							--	Seven Segment Digit DP 2
		HEX3_D  : out std_logic_vector(6 downto 0);	--	Seven Segment Digit 3
		HEX3_DP : out std_logic;							--	Seven Segment Digit DP 3
		-- LED
		LEDG	  : out std_logic_vector(9 downto 0);	--	LED Green[9:0]
		-- Interrupt
		INTO	  : out std_logic;							-- Tape action interrupt
		-- Z80 Bus
		ZCLK	  : in std_logic;
--		ZA8		 : in std_logic_vector(7 downto 0);
--		ZIWR_x	 : in std_logic;
--		ZDI		 : in std_logic_vector(7 downto 0);
--		ZDO		 : out std_logic_vector(7 downto 0);
		-- Tape signals
		T_END	  : out std_logic;							-- Sense CMT(Motor on/off)
		OPEN_x  : in std_logic;								-- Open
		PLAY_x  : in std_logic;								-- Play
		STOP_x  : in std_logic;								-- Stop
		FF_x	  : in std_logic;								-- Fast Foward
		REW_x	  : in std_logic;								-- Rewind
		APSS_x  : in std_logic;								-- APSS
		FFREW	  : in std_logic;								-- FF/REW mode
		FMOTOR  : in std_logic;								-- FF/REW start
		FLATCH  : in std_logic;								-- FF/REW latch
		WREADY  : out std_logic;							-- Write enable
		TREADY  : out std_logic;							-- Tape exist
--		EXIN		 : in std_logic;	-- CMT IN from I/O board
		RDATA	  : out std_logic;							-- to 8255
		-- Status Signal
		SCLK	  : in std_logic;								-- Slow Clock(31.25kHz)
		MZMODE  : in std_logic;								-- Hardware Mode
		DMODE   : in std_logic								-- Display Mode
	);
end cmt;

architecture RTL of cmt is

--
-- Status
--
signal RPLBUF : std_logic_vector(2 downto 0);
signal REG_PL : std_logic;
signal RSTBUF : std_logic_vector(2 downto 0);
signal REJBUF : std_logic_vector(2 downto 0);
signal REG_EJ : std_logic;
signal RREBUF : std_logic_vector(2 downto 0);
signal REG_RE : std_logic;
signal RFFBUF : std_logic_vector(2 downto 0);
signal REG_FF : std_logic;
signal RASBUF : std_logic_vector(2 downto 0);
signal REG_AS : std_logic;
signal RLTBUF : std_logic_vector(2 downto 0);
signal RFMBUF : std_logic_vector(2 downto 0);
signal REG_RE_M : std_logic;
signal REG_FF_M : std_logic;
signal TAPE : std_logic;
signal WP : std_logic;
signal MOTOR : std_logic;
signal PBIT : std_logic;
signal RBYTE : std_logic_vector(15 downto 0);
signal PON : std_logic;
signal LED3 : std_logic_vector(9 downto 0);
signal APSS : std_logic;
signal FA : std_logic;
--
-- Pulse Generator
--
signal POUT : std_logic;
signal PCNT : std_logic_vector(10 downto 0);
signal PBUSY : std_logic;
signal PEXT : std_logic_vector(4 downto 0);
----
---- Filters
----
--signal CNT3 : std_logic_vector(1 downto 0);
--signal PL_BTN : std_logic_vector(1 downto 0);
--signal ST_BTN : std_logic_vector(1 downto 0);
--signal T_BTN : std_logic;
----
---- Divider
----
--signal DIV : std_logic_vector(13 downto 0);
----
---- Registers for Z80
----
--signal MADR : std_logic_vector(15 downto 0);
--signal MBYTE : std_logic_vector(15 downto 0);
--signal MCMD : std_logic_vector(7 downto 0);
--signal STAT : std_logic_vector(7 downto 0);

--
-- Components
--
component seg7
	Port (
		-- 7-SEG Dispaly
		HEX0_D  : out std_logic_vector(6 downto 0);	--	Seven Segment Digit 0
		HEX0_DP : out std_logic;							--	Seven Segment Digit DP 0
		HEX1_D  : out std_logic_vector(6 downto 0);	--	Seven Segment Digit 1
		HEX1_DP : out std_logic;							--	Seven Segment Digit DP 1
		HEX2_D  : out std_logic_vector(6 downto 0);	--	Seven Segment Digit 2
		HEX2_DP : out std_logic;							--	Seven Segment Digit DP 2
		HEX3_D  : out std_logic_vector(6 downto 0);	--	Seven Segment Digit 3
		HEX3_DP : out std_logic;							--	Seven Segment Digit DP 3
		-- Status Signal
		MZMODE  : in std_logic;								-- Hardware Mode
																	-- "0" .. MZ-80B
																	-- "1" .. MZ-2000
		DMODE   : in std_logic;								-- Display Mode
																	-- "0" .. Green
																	-- "1" .. Color
		SCLK	  : in std_logic;
		APSS	  : in std_logic;
		FF		  : in std_logic;
		REW	  : in std_logic;
		NUMEN	  : in std_logic;
		NUMBER  : in std_logic_vector(15 downto 0)
	);
end component;

begin

	--
	-- Instantiation
	--
	LED70 : seg7 Port map(
		-- 7-SEG Dispaly
		HEX0_D => HEX0_D,				--	Seven Segment Digit 0
		HEX0_DP => HEX0_DP,			--	Seven Segment Digit DP 0
		HEX1_D => HEX1_D,				--	Seven Segment Digit 1
		HEX1_DP => HEX1_DP,			--	Seven Segment Digit DP 1
		HEX2_D => HEX2_D,				--	Seven Segment Digit 2
		HEX2_DP => HEX2_DP,			--	Seven Segment Digit DP 2
		HEX3_D => HEX3_D,				--	Seven Segment Digit 3
		HEX3_DP => HEX3_DP,			--	Seven Segment Digit DP 3
		-- Status Signal
		MZMODE => MZMODE,				-- Hardware Mode
		DMODE => DMODE,				-- Display Mode
		SCLK => SCLK,
		APSS => APSS,
		FF => REG_FF,
		REW => REG_RE,
		NUMEN => MOTOR,	--NUMEN,
		NUMBER => RBYTE
	);

	--
	-- Avalon Bus
	--
	process( RRST_x, RCLK ) begin
		if RRST_x='0' then
			WP<='0';
			MOTOR<='0';
			TAPE<='0';
			REG_PL<='0';
			REG_EJ<='0';
			REG_FF<='0';
			REG_RE<='0';
			REG_AS<='0';
			REG_FF_M<='0';
			REG_RE_M<='0';
			PBIT<='0';
			PON<='0';
			FA<='0';
			PEXT<=(others=>'0');
		elsif RCLK'event and RCLK='1' then
			-- Edge Sense
			if MZMODE='0' then
				RPLBUF<=RPLBUF(1 downto 0)&PLAY_x;			-- MZ-80B
			else
				RPLBUF<=RPLBUF(1 downto 0)&(not PLAY_x);	-- MZ-2000
			end if;
			if RPLBUF(2 downto 1)="01" then
				REG_PL<=TAPE;
				REG_AS<='0';
			end if;
			if MZMODE='0' then
				RSTBUF<=RSTBUF(1 downto 0)&STOP_x;			-- MZ-80B
			else
				RSTBUF<=RSTBUF(1 downto 0)&(not STOP_x);	-- MZ-2000
			end if;
			if RSTBUF(2 downto 1)="01" then
				MOTOR<='0';
				REG_AS<='0';
				REG_FF<='0';
				REG_RE<='0';
			end if;
			REJBUF<=REJBUF(1 downto 0)&(not OPEN_x);
			if REJBUF(2 downto 1)="01" then
				REG_EJ<='1';
				TAPE<='0';
				REG_AS<='0';
				REG_FF<='0';
				REG_RE<='0';
			end if;
			if MZMODE='0' then									-- MZ-80B
				RLTBUF<=RLTBUF(1 downto 0)&FLATCH;
				if RLTBUF(2 downto 1)="01" then
					REG_RE_M<=not FFREW;
					REG_FF_M<=FFREW;
				end if;
				RFMBUF<=RFMBUF(1 downto 0)&FMOTOR;
				if RFMBUF(2 downto 1)="01" then
					REG_RE<=REG_RE_M and TAPE;
					REG_FF<=REG_FF_M and TAPE;
					REG_AS<=TAPE;
				end if;
			else														-- MZ-2000
				RREBUF<=RREBUF(1 downto 0)&(not REW_x);
				if RREBUF(2 downto 1)="01" then
					REG_RE<=TAPE;
				end if;
				RFFBUF<=RFFBUF(1 downto 0)&(not FF_x);
				if RFFBUF(2 downto 1)="01" then
					REG_FF<=TAPE;
				end if;
				RASBUF<=RASBUF(1 downto 0)&(not APSS_x);
				if RASBUF(2 downto 1)="01" then
					REG_AS<=TAPE;
				end if;
			end if;
			-- Register
			if RCS_x='0' and RWE_x='0' then
				if RADR=X"0010" and PBUSY='0' then	-- MZ_CMT_POUT
					PBIT<=RDI(0);
					PEXT<="11111";
				else
					PEXT<=PEXT(3 downto 0)&'0';
				end if;
				if RADR=X"0011" then	-- MZ_CMT_STATUS
					REG_AS<=REG_AS and (not RDI(4));
					REG_RE<=REG_RE and (not RDI(3));
					REG_FF<=REG_FF and (not RDI(2));
					REG_PL<=REG_PL and (not RDI(1));
					REG_EJ<=REG_EJ and (not RDI(0));
				end if;
				if RADR=X"0012" then	-- MZ_CMT_COUNT
					RBYTE(7 downto 0)<=RDI;
				end if;
				if RADR=X"0013" then	-- MZ_CMT_COUNTH
					RBYTE(15 downto 8)<=RDI;
				end if;
				if RADR=X"0014" then	-- MZ_CMT_CTRL
					FA<=RDI(4);
					PON<=RDI(3);
					WP<=RDI(2);
					MOTOR<=RDI(1);
					TAPE<=RDI(0);
				end if;
			else
				PEXT<=PEXT(3 downto 0)&'0';
			end if;
		end if;
	end process;

	RDO<="0000000"&PBUSY									 when RCS_x='0' and RADR=X"0010" else	-- MZ_CMT_POUT
		  "000"&REG_AS&REG_RE&REG_FF&REG_PL&REG_EJ when RCS_x='0' and RADR=X"0011" else	-- MZ_CMT_STATUS
		  "000"&FA&PON&WP&MOTOR&TAPE					 when RCS_x='0' and RADR=X"0014" else	-- MZ_CMT_CTRL
		  "00000000";
	APSS<=REG_AS or FA;
	INTO<=REG_PL or REG_EJ or REG_RE or REG_FF;
	WREADY<=not WP;
	TREADY<=not TAPE;
	T_END<=not MOTOR;
	RDATA<=POUT or PON;
--	LEDG<="00"&REG_AS&REG_RE&REG_FF&'0'&LED3(9)&"000";
	LEDG<="000000"&LED3(9)&"000";

	--
	-- PWM pulse generate
	--
	process( RRST_x, ZCLK ) begin
		if RRST_x='0' then
			POUT<='0';
			PBUSY<='0';
			PCNT<=(others=>'0');
		elsif ZCLK'event and ZCLK='1' then
			if PEXT(4)='1' then
				if PBIT='0' then
					PCNT<="01010011011";	--667
				else
					PCNT<="10100110100";	--1332
				end if;
				POUT<='1';
				PBUSY<='1';
			else
				if POUT='1' and PCNT=0 then
					if PBIT='0' then
						PCNT<="01010011000";	--664
					else
						PCNT<="10100110110";	--1334
					end if;
					POUT<='0';
				elsif POUT='0' and PCNT=0 then
					PBUSY<='0';
				else
					PCNT<=PCNT-'1';
				end if;
			end if;
		end if;
	end process;

	--
	-- Status LED
	--
	process( SCLK ) begin
		if SCLK'event and SCLK='1' then
			if LED3="0000000000" then
				LED3<=MOTOR&MOTOR&MOTOR&MOTOR&MOTOR&MOTOR&MOTOR&MOTOR&MOTOR&TAPE;
			else
				LED3<=LED3(8 downto 0)&'0';
			end if;
		end if;
	end process;

--	process( RRST_x, ZCLK ) begin
--		if RRST_x='0' then
--			PCNT=(others=>'0');
--		elsif ZCLK'event and ZCLK='1' then
--			CUR<=NXT;
--			RET<=FRM;
--			if CUR=LONG or CUR=LONG_ or CUR=SHORT or CUR=SHORT_ then
--				PCNT<=CVAL;
--			end if;
--			if CUR=L_HOUT or CUR=L_LOUT or CUR=S_HOUT or CUR=S_LOUT then
--				PCNT<=PCNT+'1';
--			end if;
--		end if;
--	end process;
--
--	process( CUR ) begin
--		case CUR is
--			when L_HEAD =>
--				CVAL<=22000;
--				NXT<=L_H0;
--			when L_H0 =>			-- '0' x 22000
--				if BCNT=0 then
--					NXT<=L_H1;
--				else
--					NXT<=SHORT;
--					FRM<=L_H0;
--				end if;
--			when L_H1 =>
--				CVAL<=40;
--				NXT<=L_H2;
--			when L_H2 =>			-- '1' x 40
--				if BCNT=0 then
--					NXT<=L_H3;
--				else
--					NXT<=LONG;
--					FRM<=L_H2;
--				end if;
--			when L_H3 =>
--				CVAL<=40;
--				NXT<=L_H4;
--			when L_H4 =>			-- '0' x 40
--				if BCNT=0 then
--					NXT<=L_H5;
--				else
--					NXT<=SHORT;
--					FRM<=L_H4;
--				end if;
--			when L_H5 =>			-- '1' x 1
--				NXT<=LONG;
--				FRM<=L_H6;
--			when L_H6 =>
--
--			when L_BODY =>
--				CVAL<=11000;
--				CVAL<=20;
--				CVAL<=20;
--				CVAL<=1;
--
--			when GET1W =>
--
--			when LONG =>
--				CVAL<=1332;
--				NXT<=L_HOUT;
--			when L_HOUT =>
--				if PCNT=0 then
--					NXT<=LONG_;
--				else
--					NXT<=L_HOUT;
--				end if;
--			when LONG_ =>
--				CVAL<=1334;
--				NXT<=L_LOUT;
--			when L_LOUT =>
--				if PCNT=0 then
--					NXT<=RET;
--				else
--					NXT<=L_LOUT;
--				end if;
--
--			when SHORT =>
--				CVAL<=667;
--				NXT<=S_HOUT;
--			when S_HOUT =>
--				if PCNT=0 then
--					NXT<=SHORT_;
--				else
--					NXT<=S_HOUT;
--				end if;
--			when SHORT_ =>
--				CVAL<=664;
--				NXT<=S_LOUT;
--			when S_LOUT =>
--				if PCNT=0 then
--					NXT<=LONG_;
--				else
--					NXT<=S_LOUT;
--				end if;
--		end case;
--	end process;

--	POUT<='1' when CUR=L_HOUT or CUR=S_HOUT else '0';
--	process( CUR ) begin
--		case CUR is
--			when  =>
--
--			when  =>
--
--			when others =>
--				TADR<=(others=>'0');
--				TCS_x<='1';
--				TWR_x<='1';
--		end case;
--	end process;

--	--
--	-- PWM Counter & Register
--	--
--	process( reset, clk ) begin
--		if reset='1' then
--			BUSY<='0';
--			COUNT<=(others=>'0');
--			LIMIT<=(others=>'0');
--			CNT3<=(others=>'0');
--			PL_BTN<=(others=>'1');
--			ST_BTN<=(others=>'1');
--			T_BTN<='0';
--			STAT<=(others=>'0');
--		elsif clk'event and clk='1' then
--			if write='1' and address="00" then
--				BUSY<='1';
--				if writedata(7)='1' then
--					-- Long
--					LIMIT<=conv_std_logic_vector(5437,14);		-- 7665
--					COUNT<=conv_std_logic_vector(-5562,14);	-- 7535
--				else
--					-- Short
--					LIMIT<=conv_std_logic_vector(2662,14);		-- 3885
--					COUNT<=conv_std_logic_vector(-2871,14);	-- 3830
--				end if;
--			elsif write='1' and address="01" then
--				TAPE<=writedata(0);
--				T_BTN<=T_BTN and writedata(0);	-- force stop
--			elsif write='1' and address="10" then
--				STAT<=writedata(7 downto 0);
--			elsif BUSY='1' then
--				if COUNT=LIMIT then
--					BUSY<='0';
--				elsif T_BTN='1' then
--					COUNT<=COUNT+1;
--				end if;
--			end if;
--			if CNT3="11" then
--				PL_BTN<=PL_BTN(0)&PLAY_x;	-- Tape Play
--				ST_BTN<=ST_BTN(0)&STOP_x;	-- Tape Stop
--				if PL_BTN="10" then
--					T_BTN<='1';
--				elsif ST_BTN="10" then
--					T_BTN<='0';
--				end if;
--			else
--				CNT3<=CNT3+'1';
--			end if;
--		end if;
--	end process;

--	TREADY<=not TAPE;
--	POUT<=COUNT(13) when TAPE='1' else EXIN;
--	readdata<="00000000"&T_BTN&"000000"&BUSY when address="00" else
--				 MADR											 when address="01" else
--				 MBYTE										 when address="10" else
--				 "00000000"&MCMD							 when address="11" else "0000000000000000";
--	T_END<=not T_BTN;
--	NUMEN<='1' when TAPE='1' and T_BTN='1' else '0';

--	--
--	-- Indicator Divider
--	--
--	process( reset, SCLK ) begin
--		if reset='1' then
--			DIV<=(others=>'0');
--		elsif SCLK'event and SCLK='1' then
--			DIV<=DIV+'1';
--		end if;
--	end process;

--	LED<='1'		 when TAPE='1' and T_BTN='0' else 	-- still
--		  DIV(13) when TAPE='0' and T_BTN='1' else '0';	-- blink fast

--	--
--	-- MZ-80 Action
--	--
--	process( reset, ZCLK ) begin
--		if reset='1' then
--			MADR<=(others=>'0');
--			MBYTE<=(others=>'0');
--			MCMD<=(others=>'0');
--			interrupt<='1';
--		elsif ZCLK'event and ZCLK='0' then
--			if ZIWR_x='0' and ZA8(7 downto 3)="10001" then
--				case ZA8(2 downto 0) is
--					when "000" => MADR(7 downto 0)<=ZDI; interrupt<='1';
--					when "001" => MADR(15 downto 8)<=ZDI; interrupt<='1';
--					when "010" => MBYTE(7 downto 0)<=ZDI; interrupt<='1';
--					when "011" => MBYTE(15 downto 8)<=ZDI; interrupt<='1';
--					when others => MCMD<=ZDI; interrupt<=not(ZDI(7) or ZDI(6) or ZDI(5) or ZDI(4) or ZDI(3) or ZDI(2) or ZDI(1) or ZDI(0));
--				end case;
--			end if;
--		end if;
--	end process;

--	ZDO<=STAT;

end RTL;
