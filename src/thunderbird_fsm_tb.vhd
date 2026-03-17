--+----------------------------------------------------------------------------
--| 
--| COPYRIGHT 2017 United States Air Force Academy All rights reserved.
--| 
--| United States Air Force Academy     __  _______ ___    _________ 
--| Dept of Electrical &               / / / / ___//   |  / ____/   |
--| Computer Engineering              / / / /\__ \/ /| | / /_  / /| |
--| 2354 Fairchild Drive Ste 2F6     / /_/ /___/ / ___ |/ __/ / ___ |
--| USAF Academy, CO 80840           \____//____/_/  |_/_/   /_/  |_|
--| 
--| ---------------------------------------------------------------------------
--|
--| FILENAME      : thunderbird_fsm_tb.vhd (TEST BENCH)
--| AUTHOR(S)     : Capt Phillip Warner
--| CREATED       : 03/2017
--| DESCRIPTION   : This file tests the thunderbird_fsm modules.
--|
--|
--+----------------------------------------------------------------------------
--|
--| REQUIRED FILES :
--|
--|    Libraries : ieee
--|    Packages  : std_logic_1164, numeric_std
--|    Files     : thunderbird_fsm_enumerated.vhd, thunderbird_fsm_binary.vhd, 
--|				   or thunderbird_fsm_onehot.vhd
--|
--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  
entity thunderbird_fsm_tb is
end thunderbird_fsm_tb;

architecture test_bench of thunderbird_fsm_tb is 
	
	component thunderbird_fsm is 
	port(
        i_clk, i_reset  : in    std_logic;
        i_left, i_right : in    std_logic;
        o_lights_L      : out   std_logic_vector(2 downto 0);
        o_lights_R      : out   std_logic_vector(2 downto 0)
	  );
	end component thunderbird_fsm;

	-- test I/O signals
	signal w_clk      : std_logic := '0';
    signal w_reset    : std_logic := '0';
    signal w_left     : std_logic := '0';
    signal w_right    : std_logic := '0';
    signal w_lights_L : std_logic_vector(2 downto 0) := "000";
    signal w_lights_R : std_logic_vector(2 downto 0) := "000";
	
	-- constants
	constant k_clk_period : time := 50 ns;
	
	
begin
	-- PORT MAPS ----------------------------------------
	uut : thunderbird_fsm
    port map(
        i_clk      => w_clk,
        i_reset    => w_reset,
        i_left     => w_left,
        i_right    => w_right,
        o_lights_L => w_lights_L,
        o_lights_R => w_lights_R
    );
	
	-----------------------------------------------------
	
	-- PROCESSES ----------------------------------------	
    -- Clock process ------------------------------------
    clk_proc : process
    begin
        w_clk <= '0';
        wait for k_clk_period/2;
        w_clk <= '1';
        wait for k_clk_period/2;
    end process;
    
	-----------------------------------------------------
	
	-- Test Plan Process --------------------------------
	
	-----------------------------------------------------	
	sim_proc : process
    begin
        w_reset <= '1';
        w_left  <= '0';
        w_right <= '0';
        wait for k_clk_period;
        assert (w_lights_L = "000" and w_lights_R = "000")
            report "bad reset: lights should be off"
            severity failure;
        w_reset <= '0';
        wait for k_clk_period;
        assert (w_lights_L = "000" and w_lights_R = "000")
            report "after reset release, FSM should remain off with no inputs"
            severity failure;
        w_left <= '1';
        wait for k_clk_period;
        assert (w_lights_L = "001" and w_lights_R = "000")
            report "left sequence step 1 failed: expected LA only"
            severity failure;
        wait for k_clk_period;
        assert (w_lights_L = "011" and w_lights_R = "000")
            report "left sequence step 2 failed: expected LA and LB"
            severity failure;
        wait for k_clk_period;
        assert (w_lights_L = "111" and w_lights_R = "000")
            report "left sequence step 3 failed: expected LA, LB, and LC" severity failure;
        wait for k_clk_period;
        assert (w_lights_L = "000" and w_lights_R = "000")
            report "left sequence step 4 failed: expected all lights off" severity failure;
        wait for k_clk_period;
        assert (w_lights_L = "001" and w_lights_R = "000")
            report "left repeat failed when LEFT held down" severity failure;
        w_reset <= '1';
        wait for k_clk_period;
        w_reset <= '0';
        wait for k_clk_period;
        w_left <= '1';
        wait for k_clk_period;
        assert (w_lights_L = "001" and w_lights_R = "000")
            report "left mid-release test step 1 failed" severity failure;
        w_left <= '0';
        wait for k_clk_period;
        assert (w_lights_L = "011" and w_lights_R = "000")
            report "left sequence did not continue after LEFT released" severity failure;
        wait for k_clk_period;
        assert (w_lights_L = "111" and w_lights_R = "000")
            report "left sequence step 3 failed after LEFT released"
            severity failure;
        wait for k_clk_period;
        assert (w_lights_L = "000" and w_lights_R = "000")
            report "left sequence did not return to OFF after LEFT released"
            severity failure;
        w_right <= '1';
        wait for k_clk_period;
        assert (w_lights_L = "000" and w_lights_R = "001")
            report "right sequence step 1 failed: expected RA only"
            severity failure;
        wait for k_clk_period;
        assert (w_lights_L = "000" and w_lights_R = "011")
            report "right sequence step 2 failed: expected RA and RB"
            severity failure;
        wait for k_clk_period;
        assert (w_lights_L = "000" and w_lights_R = "111")
            report "right sequence step 3 failed: expected RA, RB, and RC"
            severity failure;
        wait for k_clk_period;
        assert (w_lights_L = "000" and w_lights_R = "000")
            report "right sequence step 4 failed: expected all lights off"
            severity failure;
        w_reset <= '1';
        wait for k_clk_period;
        w_reset <= '0';
        wait for k_clk_period;
        w_right <= '1';
        wait for k_clk_period;
        assert (w_lights_L = "000" and w_lights_R = "001")
            report "right mid-release test step 1 failed"
            severity failure;
        w_right <= '0';
        wait for k_clk_period;
        assert (w_lights_L = "000" and w_lights_R = "011")
            report "right sequence did not continue after RIGHT released"
            severity failure;

        wait for k_clk_period;
        assert (w_lights_L = "000" and w_lights_R = "111")
            report "right sequence step 3 failed after RIGHT released"
            severity failure;
        wait for k_clk_period;
        assert (w_lights_L = "000" and w_lights_R = "000")
            report "right sequence did not return to OFF after RIGHT released"
            severity failure;
        w_left  <= '1';
        w_right <= '1';
        wait for k_clk_period;
        assert (w_lights_L = "111" and w_lights_R = "111")
            report "hazard test failed: expected all lights on"
            severity failure;
        wait for k_clk_period;
        assert (w_lights_L = "000" and w_lights_R = "000")
            report "hazard test failed: expected all lights off after hazard ON"
            severity failure;
        wait for k_clk_period;
        assert (w_lights_L = "111" and w_lights_R = "111")
            report "hazard repeat failed when both switches held"
            severity failure;
        w_reset <= '1';
        wait for k_clk_period;
        w_reset <= '0';
        w_left  <= '1';
        w_right <= '0';
        wait for k_clk_period;
        assert (w_lights_L = "001" and w_lights_R = "000")
            report "input-change test failed at left step 1"
            severity failure;
        w_left  <= '1';
        w_right <= '1';
        wait for k_clk_period;
        assert (w_lights_L = "011" and w_lights_R = "000")
            report "left sequence was interrupted by input change"
            severity failure;
        wait for k_clk_period;
        assert (w_lights_L = "111" and w_lights_R = "000")
            report "left sequence step 3 was interrupted by input change"
            severity failure;
        wait for k_clk_period;
        assert (w_lights_L = "000" and w_lights_R = "000")
            report "left sequence did not finish properly after input change"
            severity failure;
        wait for k_clk_period;
        assert (w_lights_L = "111" and w_lights_R = "111")
            report "hazards did not start after returning to OFF with both inputs high"
            severity failure;
        wait;
    end process;
	
end test_bench;
