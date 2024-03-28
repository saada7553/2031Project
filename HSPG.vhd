-- HSPG.vhd (hobby servo pulse generator)
-- This starting point generates a pulse between 100 us and something much longer than 2.5 ms.

library IEEE;
library lpm;

use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use lpm.lpm_components.all;

entity HSPG is
    port(
        CS_SEL      : in  std_logic;
        CS_POS      : in  std_logic;
        CS_MIN      : in  std_logic;
        CS_MAX      : in  std_logic;
        CS_SPD      : in  std_logic;
		  
        IO_WRITE    : in  std_logic;
        IO_DATA     : in  std_logic_vector(15 downto 0);
        CLOCK       : in  std_logic;
        RESETN      : in  std_logic;
        PULSE       : out std_logic
    );
end HSPG;

architecture a of HSPG is

	 -- user inputs
    signal sel      : std_logic_vector(15 downto 0);  -- SEL (0-4) ... or (0-8)?
	 signal position : std_logic_vector(15 downto 0);  -- POS (-100 to 100)?
	 signal min_pct  : std_logic_vector(15 downto 0);  -- MIN (percent 0-100)
	 signal max_pct  : std_logic_vector(15 downto 0);  -- MAX (percent 0-100)
	 signal speed    : std_logic_vector(15 downto 0);  -- SPD (0=SLOW, 1=MEDIUM, 2=FAST, 3=UNCAPPED)
	 
	 -- internals
    signal count    : std_logic_vector(15 downto 0);  -- internal counter

begin

    -- Latch data on rising edge of CS's
    process (RESETN, CS_SEL, CS_POS, CS_MIN, CS_MAX, CS_SPD) begin
        if RESETN = '0' then
			   sel <= x"0000";
            position <= x"0000"; -- 0
				min_pct <= x"0000";  -- 0%
            max_pct <= x"0064";  -- 100%
            speed <= x"0000";    -- 0=SLOW
        elsif IO_WRITE = '1' then
		  
				if rising_edge(CS_SEL) then
					sel <= IO_DATA;
				end if;
				if rising_edge(CS_POS) then
					position <= IO_DATA;
				end if;
				if rising_edge(CS_MIN) then
					min_pct <= IO_DATA;
				end if;
				if rising_edge(CS_MAX) then
					max_pct <= IO_DATA;
				end if;
				if rising_edge(CS_SPD) then
					speed <= IO_DATA;
				end if;
				
        end if;
    end process;

    -- This is a VERY SIMPLE way to generate a pulse.  This is not particularly
    -- flexible and it has some issues.  It works, but you need to consider how
    -- to improve this as part of the project.
    process (RESETN, CLOCK)
    begin
        if (RESETN = '0') then
            count <= x"0000";
        elsif rising_edge(CLOCK) then
            -- Each clock cycle, a counter is incremented.
            count <= count + 1;

            -- When the counter reaches the full desired period, start the period over.
            if count = x"00C7" then  -- 20 ms has elapsed
                -- Reset the counter and set the output high.
                count <= x"0000";
                PULSE <= '1';

            -- Within the period, when the counter reaches the "position" value, set the output low.
            -- This will make larger position values produce longer pulses.
            elsif count = position then
                PULSE <= '0';
            end if;
        end if;
    end process;

end a;