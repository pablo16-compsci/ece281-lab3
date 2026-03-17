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
--| FILENAME      : thunderbird_fsm.vhd
--| AUTHOR(S)     : Capt Phillip Warner, Capt Dan Johnson
--| CREATED       : 03/2017 Last modified 06/25/2020
--| DESCRIPTION   : This file implements the ECE 281 Lab 2 Thunderbird tail lights
--|					FSM using enumerated types.  This was used to create the
--|					erroneous sim for GR1
--|
--|					Inputs:  i_clk 	 --> 100 MHz clock from FPGA
--|                          i_left  --> left turn signal
--|                          i_right --> right turn signal
--|                          i_reset --> FSM reset
--|
--|					Outputs:  o_lights_L (2:0) --> 3-bit left turn signal lights
--|					          o_lights_R (2:0) --> 3-bit right turn signal lights
--|
--|					Upon reset, the FSM by defaults has all lights off.
--|					Left ON - pattern of increasing lights to left
--|						(OFF, LA, LA/LB, LA/LB/LC, repeat)
--|					Right ON - pattern of increasing lights to right
--|						(OFF, RA, RA/RB, RA/RB/RC, repeat)
--|					L and R ON - hazard lights (OFF, ALL ON, repeat)
--|					A is LSB of lights output and C is MSB.
--|					Once a pattern starts, it finishes back at OFF before it 
--|					can be changed by the inputs
--|					
--|
--|                 One-Hot State Encoding key
--|                 --------------------
--|                  State | Encoding
--|                 --------------------
--|                  OFF   | 1000000
--|                  ON    | 0000001
--|                  R1    | 0001000
--|                  R2    | 0000100
--|                  R3    | 0000010
--|                  L1    | 1000000
--|                  L2    | 0100000
--|                  L3    | 0010000
--|                 --------------------
--|
--|
--+----------------------------------------------------------------------------
--|
--| REQUIRED FILES :
--|
--|    Libraries : ieee
--|    Packages  : std_logic_1164, numeric_std
--|    Files     : None
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
 
entity thunderbird_fsm is 
    port (
        i_clk, i_reset  : in    std_logic;
        i_left, i_right : in    std_logic;
        o_lights_L      : out   std_logic_vector(2 downto 0);
        o_lights_R      : out   std_logic_vector(2 downto 0)
    );
end thunderbird_fsm;

architecture thunderbird_fsm_arch of thunderbird_fsm is 

    constant Q7_OFF : std_logic_vector(7 downto 0) := "10000000";
    constant Q6_L1  : std_logic_vector(7 downto 0) := "01000000";
    constant Q5_L2  : std_logic_vector(7 downto 0) := "00100000";
    constant Q4_L3  : std_logic_vector(7 downto 0) := "00010000";
    constant Q3_R1  : std_logic_vector(7 downto 0) := "00001000";
    constant Q2_R2  : std_logic_vector(7 downto 0) := "00000100";
    constant Q1_R3  : std_logic_vector(7 downto 0) := "00000010";
    constant Q0_HAZ : std_logic_vector(7 downto 0) := "00000001";

    signal r_state      : std_logic_vector(7 downto 0) := Q7_OFF;
    signal w_next_state : std_logic_vector(7 downto 0);

    signal w_LA, w_LB, w_LC : std_logic;
    signal w_RA, w_RB, w_RC : std_logic;
  
begin

	-- CONCURRENT STATEMENTS --------------------------------------------------------

    w_next_state(7) <= (r_state(7) and (not (i_left or i_right))) or r_state(4) or r_state(1) or r_state(0);
    w_next_state(6) <= r_state(7) and i_left and (not i_right);
    w_next_state(5) <= r_state(6);
    w_next_state(4) <= r_state(5);
    w_next_state(3) <= r_state(7) and (not i_left) and i_right;
    w_next_state(2) <= r_state(3);
    w_next_state(1) <= r_state(2);
    w_next_state(0) <= r_state(7) and i_left and i_right;
    w_LA <= r_state(6) or r_state(5) or r_state(4) or r_state(0);
    w_LB <= r_state(5) or r_state(4) or r_state(0);
    w_LC <= r_state(4) or r_state(0);
    w_RA <= r_state(3) or r_state(2) or r_state(1) or r_state(0);
    w_RB <= r_state(2) or r_state(1) or r_state(0);
    w_RC <= r_state(1) or r_state(0);
    o_lights_L <= w_LC & w_LB & w_LA;
    o_lights_R <= w_RC & w_RB & w_RA;
	
    ---------------------------------------------------------------------------------
	
	-- PROCESSES --------------------------------------------------------------------
    
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            if i_reset = '1' then
                r_state <= Q7_OFF;
            else
                r_state <= w_next_state;
            end if;
        end if;
    end process;
				  
end thunderbird_fsm_arch;