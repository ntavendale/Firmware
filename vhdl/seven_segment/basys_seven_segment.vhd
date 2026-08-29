-- Copyright 2025 Nigel Tavendale
-- Permission is hereby granted, free of charge, to any person obtaining a copy of this code 
-- associated documentation files (the "Code"), to deal in the Code without restriction, including 
-- without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, 
-- and/or sell copies of the Code, and to permit persons to whom the Code is furnished to do so, 
-- subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all copies or substantial 
-- portions of the Code.
--
-- THE CODE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED 
-- TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT 
-- SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN 
-- ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE CODE OR THE USE OR 
-- OTHER DEALINGS IN THE CODE.
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

-- This project doesn't do much. Simply displays a four digit base 10 integer on the 
-- seven segment display and increments it every second.. 

entity basys_seven_segment is
  port (
    clk : in std_logic;
    btnC : in std_logic; 
    an  : out std_logic_vector(3 downto 0);
    seg : out std_logic_vector(6 downto 0) -- GFEDCAB
  );
end basys_seven_segment;

architecture rtl of basys_seven_segment
is
  -- counter for genrerating one second clockl enable
  signal one_second_counter: std_logic_vector(27 downto 0);
  -- one second enable
  signal one_second_enable : std_logic;
  signal displayed_number  : std_logic_vector(15 downto 0); -- HEX 0-F
  signal r_reset           : std_logic;
  
  component generic_debounce_filter is
    generic (
      DEBOUNCE_LIMIT : integer := 1000000;
      SIGNAl_COUNT: Integer := 1);
    port (
      i_clk           : in std_logic;
      i_noisy_signal  : in std_logic_vector(SIGNAl_COUNT -1 downto 0);
      o_debounced     : out std_logic_vector(SIGNAl_COUNT -1 downto 0)
    );
end component;
  
  component bcd_Counter_four_digit is
    port (
      i_reset     : in std_logic;
      i_increment : in std_logic;
      o_bcd       : out std_logic_vector(15 downto 0)
    );
  end component;
  
  component seven_segment_display is
    generic (CYCLES_PER_ANODE : natural);
    port (
      i_clk       : in std_logic;
      i_reset     : in std_logic;
      i_displayed : in std_logic_vector(15 downto 0); -- compact BCD. 4 BCD Values of 4 bits each
      o_anodes    : out std_logic_vector(3 downto 0);
      o_segments  : out std_logic_vector(6 downto 0)
    );
  end component;
begin
  
  Debouncer: generic_debounce_filter
    port map (
      i_clk             => clk,
      i_noisy_signal(0) => btnC,
      o_debounced(0)    => r_reset
    );
    
  Seven_Segment : seven_segment_display
    generic map (CYCLES_PER_ANODE => 100000) -- 1 KHz   
    port map (
      i_clk       => clk,
      i_reset     => r_reset,
      i_displayed => displayed_number,
      o_anodes    => an,
      o_segments  => seg
    );
    
  bcd_counter : bcd_Counter_four_digit
    port map (
      i_increment  => one_second_enable,
      i_reset     => r_reset,
      o_BCD       => displayed_number
    );
  
  -- Counting the number to be displayed on 4-digit 7-segment Display 
  -- on Basys 3 FPGA board
  process(clk, btnC)
  begin
    if (btnC = '1') then
      one_second_counter <= (others => '0');
    elsif rising_edge(clk) then
      if one_second_counter>=x"5F5E0FF" then
        one_second_counter <= (others => '0');
        one_second_enable <= '1';
      else
        one_second_counter <= one_second_counter + "0000001";
        one_second_enable <= '0';
      end if;
    end if;
  end process;
end rtl;
