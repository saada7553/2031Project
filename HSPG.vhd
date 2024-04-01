-- HSPG.vhd (hobby servo pulse generator)
-- This starting point generates a pulse between 100 us and something much longer than 2.5 ms.

library IEEE;
library lpm;

use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use lpm.lpm_components.all;
use IEEE.numeric_std.all;

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
	-- ticks (clock ticks) measured via 12MHz

	constant ticks_absolute_min : unsigned(15 downto 0) := to_unsigned(7200, 16); -- 0.6ms
	constant ticks_absolute_max : unsigned(15 downto 0) := to_unsigned(28800, 16); -- 2.4ms

	constant ticks_min : unsigned(15 downto 0) := to_unsigned(12000, 16); -- 1ms -- TODO: perhaps make configurable
	constant ticks_max : unsigned(15 downto 0) := to_unsigned(24000, 16); -- 2ms

	constant ticks_period : unsigned(15 downto 0) := to_unsigned(240000, 16); -- 20ms

	-- user inputs
	signal position      : signed(15 downto 0);  -- POS (-100 to 100)?
	signal min_position  : signed(15 downto 0);  -- MIN (percent 0-100)
	signal max_position  : signed(15 downto 0);  -- MAX (percent 0-100)
	signal speed         : std_logic_vector(15 downto 0);  -- SPD (0=SLOW, 1=MEDIUM, 2=FAST, 3=UNCAPPED)
	 
	-- internals
    signal ticks    : unsigned(15 downto 0) := x"0000";  -- internal counter

begin -- start impl

	-- set pos/min/max/spd via IO
    process (RESETN, CS_POS, CS_MIN, CS_MAX, CS_SPD) begin
        if RESETN = '0' then
            position <= x"0000"; -- 0
			min_position <= x"0000";  -- 0%
            max_position <= x"0064";  -- 100%
            speed <= x"0000";    -- 0=SLOW
        elsif IO_WRITE = '1' then
			if rising_edge(CS_POS) then
				position <= signed(IO_DATA);
			end if;
			if rising_edge(CS_MIN) then
				min_position <= signed(IO_DATA);
			end if;
			if rising_edge(CS_MAX) then
				max_position <= signed(IO_DATA);
			end if;
			if rising_edge(CS_SPD) then
				speed <= IO_DATA;
			end if;
        end if;
    end process;

	-- pulse generator 12MHz clock -> (every 240000 ticks is 20ms)
	-- 12000 ticks for 1ms (lower bound)
	-- 24000 ticks for 2ms (upper bound)
    process (RESETN, CLOCK)
		variable user_possibilities_raw : signed(15 downto 0);
		variable user_possibilities : unsigned(15 downto 0);
		variable user_position_raw : signed(15 downto 0); -- amount user is above min_position
		variable user_position : unsigned(15 downto 0); -- amount user is above min_position
		variable position_ticks_raw : unsigned(31 downto 0);
		variable position_ticks : unsigned(15 downto 0);
    begin
        if (RESETN = '0') then
            ticks <= x"0000";
        elsif rising_edge(CLOCK) then
			---------------------- find position_ticks
			user_possibilities_raw := (max_position - min_position) + 1;
			if (user_possibilities_raw < 0) or (user_possibilities_raw = 0) then
				user_possibilities := x"0001"; -- TODO: one or zero?
			else
				user_possibilities := unsigned(user_possibilities_raw);
			end if;
			
			user_position_raw := position - min_position;
			if user_position_raw < 0 then
				user_position := x"0000";
			else
				user_position := unsigned(user_position_raw);
			end if;

			-- TODO: configurable ticks_min/ticks_max?
			position_ticks_raw := ((user_position * (ticks_max - ticks_min)) / (user_possibilities)) + ticks_min;

			-- bound check just in case! (hopefully this isn't even possible/necessary)
			if position_ticks_raw < ticks_absolute_min then
				position_ticks := ticks_absolute_min;
			elsif position_ticks_raw > ticks_absolute_max then
				position_ticks := ticks_absolute_max;
			else
				position_ticks := resize(position_ticks_raw, 16);
			end if;

            -- Each clock cycle, a counter is incremented.
            ticks <= ticks + 1;

            -- When the counter reaches the full desired period, start the period over.
            if ticks = ticks_period then  -- 20 ms has elapsed
                -- Reset the counter and set the output high.
                ticks <= x"0000";
                PULSE <= '1';

            -- Within the period, when the counter reaches the "position" value, set the output low.
            -- This will make larger position values produce longer pulses.
            elsif ticks = position_ticks then
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
