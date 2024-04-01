-- HSPG.vhd (hobby servo pulse generator)
-- This starting point generates a pulse between 100 us and something much longer than 2.5 ms.

library IEEE;
library lpm;

use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use lpm.lpm_components.all;

-- single controller ====================================================================================================

entity HSPG_SERVO is
    port(
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
end HSPG_SERVO;

architecture a of HSPG_SERVO is

	-- user inputs
	signal position : std_logic_vector(15 downto 0);  -- POS (-100 to 100)?
	signal min_pct  : std_logic_vector(15 downto 0);  -- MIN (percent 0-100)
	signal max_pct  : std_logic_vector(15 downto 0);  -- MAX (percent 0-100)
	signal speed    : std_logic_vector(15 downto 0);  -- SPD (0=SLOW, 1=MEDIUM, 2=FAST, 3=UNCAPPED)
	 
	-- internals
    signal count    : std_logic_vector(15 downto 0);  -- internal counter

begin -- start impl

	-- set pos/min/max/spd via IO
    process (RESETN, CS_POS, CS_MIN, CS_MAX, CS_SPD) begin
        if RESETN = '0' then
            position <= x"0000"; -- 0
			min_pct <= x"0000";  -- 0%
            max_pct <= x"0064";  -- 100%
            speed <= x"0000";    -- 0=SLOW
        elsif IO_WRITE = '1' then
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

	-- pulse generator (every 200 clock cycles is 20ms)
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

-- multiplexor ====================================================================================================

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

        PULSE_0     : out std_logic;
        PULSE_1     : out std_logic;
        PULSE_2     : out std_logic;
        PULSE_3     : out std_logic
    );
end HSPG;

architecture a of HSPG is

	component HSPG_SERVO is
		port(
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
	end component HSPG_SERVO;

	-- user inputs
    signal sel : std_logic_vector(15 downto 0) := x"0000";  -- SEL (0-4) ... or (0-8)?

	-- helpers (don't need to be persistent, maybe there is a better way)
	signal en_0, en_1, en_2, en_3 : std_logic := '0';

begin -- start impl

	en_0 <= '1' when sel = x"0000" else '0';
	en_1 <= '1' when sel = x"0001" else '0';
	en_2 <= '1' when sel = x"0002" else '0';
	en_3 <= '1' when sel = x"0003" else '0';

	SERVO_0 : HSPG_SERVO port map(
		CS_POS and en_0,
		CS_MIN and en_0,
		CS_MAX and en_0,
		CS_SPD and en_0,
		IO_WRITE, IO_DATA, CLOCK, RESETN,
		PULSE_0
	);

	SERVO_1 : HSPG_SERVO port map(
		CS_POS and en_1,
		CS_MIN and en_1,
		CS_MAX and en_1,
		CS_SPD and en_1,
		IO_WRITE, IO_DATA, CLOCK, RESETN,
		PULSE_1
	);

	SERVO_2 : HSPG_SERVO port map(
		CS_POS and en_2,
		CS_MIN and en_2,
		CS_MAX and en_2,
		CS_SPD and en_2,
		IO_WRITE, IO_DATA, CLOCK, RESETN,
		PULSE_2
	);

	SERVO_3 : HSPG_SERVO port map(
		CS_POS and en_3,
		CS_MIN and en_3,
		CS_MAX and en_3,
		CS_SPD and en_3,
		IO_WRITE, IO_DATA, CLOCK, RESETN,
		PULSE_3
	);

	-- set sel via IO
    process (RESETN, CS_SEL) begin
        if RESETN = '0' then
            sel <= x"0000";
        elsif IO_WRITE = '1' and rising_edge(CS_SEL) then
            sel <= IO_DATA;
        end if;
    end process;

end a;
