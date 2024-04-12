-- DIG_IN.VHD (a peripheral module for SCOMP)
-- This module reads digital inputs directly

LIBRARY IEEE;
LIBRARY LPM;

USE IEEE.STD_LOGIC_1164.ALL;
USE LPM.LPM_COMPONENTS.ALL;

ENTITY DIG_IN IS
	PORT(
			CS          : IN    STD_LOGIC;
			WHICH       : IN    STD_LOGIC; -- =CS_HSPG (0 for switch, 1 for HSPG)
			READ_EN     : IN    STD_LOGIC;
			DI_SWITCH   : IN    STD_LOGIC_VECTOR(15 DOWNTO 0); -- DI means data in
			DI_HSPG     : IN    STD_LOGIC_VECTOR(15 DOWNTO 0);
			IO_DATA     : INOUT STD_LOGIC_VECTOR(15 DOWNTO 0)
		);
END DIG_IN;

ARCHITECTURE a OF DIG_IN IS
	SIGNAL B_DI : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL T_DI : STD_LOGIC_VECTOR(15 DOWNTO 0);

BEGIN
	T_DI <= B_DI when (WHICH = '1') else x"00FF";

	-- Use LPM function to create bidirectional I/O data bus
	IO_BUS: lpm_bustri
	GENERIC MAP (
					lpm_width => 16
				)
	PORT MAP (
				 data     => T_DI,
				 enabledt => CS AND READ_EN,
				 tridata  => IO_DATA
			 );

	 -- set di via switch or hspg
    process (CS) begin
		if rising_edge(CS) then
			if WHICH = '1' then
				B_DI <= DI_HSPG; -- sample the input on the rising edge of CS
			else
				B_DI <= DI_SWITCH; -- sample the input on the rising edge of CS
			end if;
		end if;
	end process;
END a;

