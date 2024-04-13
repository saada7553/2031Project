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
        CS_MIN_POS  : in  std_logic;
        CS_MAX_POS  : in  std_logic;
        CS_ROT_TIME : in  std_logic;
		  
        IO_DATA     : in  std_logic_vector(15 downto 0);
        IO_WRITE    : in  std_logic;
        CLOCK       : in  std_logic;
        RESETN      : in  std_logic;

        PULSE       : out std_logic;
		MOTION_DONE : out std_logic
    );
end HSPG_SERVO;

architecture a of HSPG_SERVO is
	-- ticks (clock ticks) measured via 100kHz
	constant ticks_absolute_min : unsigned(15 downto 0) := to_unsigned(60, 16); -- 0.6ms
	constant ticks_absolute_max : unsigned(15 downto 0) := to_unsigned(240, 16); -- 2.4ms

	constant ticks_min : unsigned(15 downto 0) := to_unsigned(60, 16); -- 1ms -- TODO: perhaps make configurable - edit, probably don't tbh
	constant ticks_max : unsigned(15 downto 0) := to_unsigned(240, 16); -- 2ms

	constant ticks_period : unsigned(15 downto 0) := to_unsigned(2000, 16); -- 20ms (TODO: should be 1 lower for reset (since we use ticks = 0 maybe))

	-- user inputs
	signal position      : signed(15 downto 0);   -- POS (default = 0)
	signal min_position  : signed(15 downto 0);   -- MIN (default = 0)
	signal max_position  : signed(15 downto 0);   -- MAX (default = 100)
	signal rot_time      : unsigned(15 downto 0); -- ROT_TIME (default = 0, [ms to track from MIN to MAX])
	 
	-- internals
    signal ticks                     : unsigned(15 downto 0) := x"0000"; -- internal counter
    signal current_position_ticks    : unsigned(15 downto 0) := x"0000";
    signal spd_ticks_till_move       : unsigned(15 downto 0) := x"0000";
	signal subticks                  : unsigned(15 downto 0) := x"0000";

	signal this_cycle_ticks          : unsigned(15 downto 0) := ticks_min;
begin -- start impl
	-- set pos/min/max/spd via IO
    process (RESETN, CS_POS, CS_MIN_POS, CS_MAX_POS, CS_ROT_TIME) begin
        if RESETN = '0' then
            position <= x"0000"; -- 0
			min_position <= x"0000";  -- 0
            max_position <= x"0064";  -- 100
            rot_time <= x"0000";    -- 0=SLOW
        elsif IO_WRITE = '1' then
			if rising_edge(CS_POS) then
				position <= signed(IO_DATA);
			end if;
			if rising_edge(CS_MIN_POS) then
				min_position <= signed(IO_DATA);
			end if;
			if rising_edge(CS_MAX_POS) then
				max_position <= signed(IO_DATA);
			end if;
			if rising_edge(CS_ROT_TIME) then
				rot_time <= unsigned(IO_DATA);
			end if;
        end if;
    end process;

	-- pulse generator 12MHz clock -> (every 240000 ticks is 20ms)
	-- 12000 ticks for 1ms (lower bound)
	-- 24000 ticks for 2ms (upper bound)
    process (RESETN, CLOCK)
		variable user_possibilities_raw : signed(15 downto 0);
		variable user_possibilities : unsigned(15 downto 0);
		variable user_possibilities_m1 : unsigned(15 downto 0); -- minus 1
		variable user_possibilities_div : unsigned(15 downto 0); -- =m1, unless 0, then 1 (eg range [1, ...])
		variable user_position_raw : signed(15 downto 0); -- amount user is above min_position
		variable user_position : unsigned(15 downto 0); -- amount user is above min_position
		variable position_ticks_raw : unsigned(31 downto 0);
		variable target_position_ticks : unsigned(15 downto 0);
		variable needed_spd_ticks : unsigned(15 downto 0);
    begin
        if (RESETN = '0') then
            ticks <= x"0000";
			current_position_ticks <= ticks_min;
			spd_ticks_till_move <= x"0000";
            subticks <= x"0000";
			MOTION_DONE <= '0';
        elsif rising_edge(CLOCK) then
			---------------------- find target_position_ticks
			user_possibilities_raw := (max_position - min_position) + 1;
			if (user_possibilities_raw < 0) or (user_possibilities_raw = 0) then
				user_possibilities := x"0001"; -- TODO: one or zero?
			else
				user_possibilities := unsigned(user_possibilities_raw);
			end if;
			user_possibilities_m1 := user_possibilities - 1;
			
			user_position_raw := position - min_position;
			if user_position_raw < 0 then
				user_position := x"0000";
			elsif unsigned(user_position_raw) > user_possibilities_m1 then
				user_position := unsigned(user_possibilities_m1);
			else
				user_position := unsigned(user_position_raw);
			end if;

			-- we do this to avoid divide by zero when [MIN = MAX]
			if user_possibilities_m1 = 0 then
				user_possibilities_div := x"0001";
			else
				user_possibilities_div := user_possibilities_m1;
			end if;

			-- TODO: configurable ticks_min/ticks_max?
			position_ticks_raw := ((user_position * (ticks_max - ticks_min)) / (user_possibilities_div)) + ticks_min;

			-- bound check just in case! (hopefully this isn't even possible/necessary)
			if position_ticks_raw < ticks_absolute_min then
				target_position_ticks := ticks_absolute_min;
			elsif position_ticks_raw > ticks_absolute_max then
				target_position_ticks := ticks_absolute_max;
			else
				target_position_ticks := resize(position_ticks_raw, 16);
			end if;
			------------------------------------------

			------------------------------ track curr to target via speed (rot_time)
			if rot_time = 0 or current_position_ticks = target_position_ticks then
				current_position_ticks <= target_position_ticks;
				spd_ticks_till_move <= x"0000";
			else
				-- (done?) TODO: expand to 1.8ms range! (timing will take longer currently, on 0.6-2.4ms scale)
				-- NOTE: this code assumes we only use functional range 1-2ms!! - do not change this thusforth! (1ms matches ms units -> simple impl)
				--    math gives that we move 1/rot_time ticks each tick
				--    we mock this by instead moving on tick every rot_time ticks
				needed_spd_ticks := rot_time - 1;

				if spd_ticks_till_move = needed_spd_ticks or spd_ticks_till_move > needed_spd_ticks then
					-- subticks <= subticks + 18;
					subticks <= subticks + 24;
					-- subticks <= subticks + 10;

					if subticks >= 20 then
						if target_position_ticks < current_position_ticks then
							if (current_position_ticks - 1) = target_position_ticks then
								current_position_ticks <= target_position_ticks;
							else
								current_position_ticks <= current_position_ticks - 2;
							end if;
						else
							if (current_position_ticks + 1) = target_position_ticks then
								current_position_ticks <= target_position_ticks;
							else
								current_position_ticks <= current_position_ticks + 2;
							end if;
						end if;
						subticks <= subticks - 20;
					elsif subticks >= 10 then
						if target_position_ticks < current_position_ticks then
							current_position_ticks <= current_position_ticks - 1;
						else
							current_position_ticks <= current_position_ticks + 1;
						end if;
						subticks <= subticks - 10;
					end if;

					-- move towards target!
					spd_ticks_till_move <= x"0000";
				else
					spd_ticks_till_move <= spd_ticks_till_move + 1;
				end if;

			end if;

			------------------------------------------------------------------------ 
			if current_position_ticks = target_position_ticks then
				MOTION_DONE <= '1';
			else
				MOTION_DONE <= '0';
			end if;


            -- Each clock cycle, a counter is incremented.
            ticks <= ticks + 1;

            -- When the counter reaches the full desired period, start the period over.
            if ticks = ticks_period then  -- 20 ms has elapsed
                -- Reset the counter and set the output high.
                ticks <= x"0000";
                PULSE <= '1';
				if current_position_ticks < ticks_min then
					this_cycle_ticks <= ticks_min;
				elsif current_position_ticks > ticks_max then
					this_cycle_ticks <= ticks_max;
				else
					this_cycle_ticks <= current_position_ticks;
				end if;

			-- TODO: toby, more checks on this (maybe temp per cycle?)
            -- Within the period, when the counter reaches the "position" value, set the output low.
            -- This will make larger position values produce longer pulses.
            elsif (ticks = this_cycle_ticks) or (ticks > ticks_max) then
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
        CS_MIN_POS  : in  std_logic;
        CS_MAX_POS  : in  std_logic;
        CS_ROT_TIME : in  std_logic;
		CS_DONE     : in  std_logic;
		  
        IO_WRITE    : in  std_logic;
        CLOCK       : in  std_logic;
        RESETN      : in  std_logic;

        IO_DATA     : inout  std_logic_vector(15 downto 0);

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
			CS_MIN_POS  : in  std_logic;
			CS_MAX_POS  : in  std_logic;
			CS_ROT_TIME : in  std_logic;
			  
			IO_WRITE    : in  std_logic;
			IO_DATA     : in  std_logic_vector(15 downto 0);
			CLOCK       : in  std_logic;
			RESETN      : in  std_logic;

			PULSE       : out std_logic;
			MOTION_DONE : out std_logic
		);
	end component HSPG_SERVO;

	-- user inputs
    signal sel : std_logic_vector(15 downto 0) := x"0000";  -- SEL (0-4) ... or (0-8)?

	-- helpers (don't need to be persistent, maybe there is a better way)
	signal en_0, en_1, en_2, en_3 : std_logic := '0';
	signal done_0, done_1, done_2, done_3 : std_logic := '0';

	signal MOTION_DONE : std_logic_vector(15 downto 0);
	SIGNAL IO_MOVE_DONE  : STD_LOGIC_VECTOR(15 DOWNTO 0); -- a stable copy of the done for the IO
	SIGNAL IO_OUT    : STD_LOGIC;
begin -- start impl
	IO_OUT <= (CS_DONE AND NOT(IO_WRITE));

	en_0 <= '1' when (sel = x"0000" or sel = x"FFFF") else '0';
	en_1 <= '1' when (sel = x"0001" or sel = x"FFFF") else '0';
	en_2 <= '1' when (sel = x"0002" or sel = x"FFFF") else '0';
	en_3 <= '1' when (sel = x"0003" or sel = x"FFFF") else '0';

	MOTION_DONE <= x"0001" when (
					((sel = x"FFFF") and (done_0 = '1' and done_1 = '1' and done_2 = '1' and done_3 = '1')) or
					((sel = x"0000") and done_0 = '1') or
					((sel = x"0001") and done_1 = '1') or
					((sel = x"0002") and done_2 = '1') or
					((sel = x"0003") and done_3 = '1')
    ) else x"0000";

	-- Use LPM function to create bidirection I/O data bus
	IO_BUS: lpm_bustri
	GENERIC MAP (
		lpm_width => 16
	)
	PORT MAP (
		data     => IO_MOVE_DONE,
		enabledt => IO_OUT,
		tridata  => IO_DATA
	);

	SERVO_0 : HSPG_SERVO port map(
		CS_POS and en_0,
		CS_MIN_POS and en_0,
		CS_MAX_POS and en_0,
		CS_ROT_TIME and en_0,
		IO_WRITE, IO_DATA, CLOCK, RESETN,
		PULSE_0,
		done_0
	);

	SERVO_1 : HSPG_SERVO port map(
		CS_POS and en_1,
		CS_MIN_POS and en_1,
		CS_MAX_POS and en_1,
		CS_ROT_TIME and en_1,
		IO_WRITE, IO_DATA, CLOCK, RESETN,
		PULSE_1,
		done_1
	);

	SERVO_2 : HSPG_SERVO port map(
		CS_POS and en_2,
		CS_MIN_POS and en_2,
		CS_MAX_POS and en_2,
		CS_ROT_TIME and en_2,
		IO_WRITE, IO_DATA, CLOCK, RESETN,
		PULSE_2,
		done_2
	);

	SERVO_3 : HSPG_SERVO port map(
		CS_POS and en_3,
		CS_MIN_POS and en_3,
		CS_MAX_POS and en_3,
		CS_ROT_TIME and en_3,
		IO_WRITE, IO_DATA, CLOCK, RESETN,
		PULSE_3,
		done_3
	);

	-- set sel via IO
    process (RESETN, CS_SEL) begin
        if RESETN = '0' then
            sel <= x"0000";
        elsif IO_WRITE = '1' and rising_edge(CS_SEL) then
            sel <= IO_DATA;
        end if;
    end process;

	-- set sel via IO
    process (RESETN, CS_DONE) begin
        if RESETN = '0' then
			IO_MOVE_DONE <= x"0001";
        elsif rising_edge(CS_DONE) then
			IO_MOVE_DONE <= MOTION_DONE;
        end if;
    end process;

end a;
