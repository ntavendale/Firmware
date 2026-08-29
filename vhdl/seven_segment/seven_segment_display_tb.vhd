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
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;
use std.env.finish;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity seven_segment_display_tb is
--  Port ( );
end seven_segment_display_tb;

architecture Behavioral of seven_segment_display_tb is
  signal r_Clk, r_Reset : std_logic := '0';
  signal displayed_number: std_logic_vector(15 downto 0); -- HEX 0-F
  signal an  : std_logic_vector(3 downto 0);
  signal seg : std_logic_vector(6 downto 0);
begin
  r_Clk <= not r_Clk after 5 ns;
  
  Unit_Under_Test :  entity work.seven_segment_display
    generic map (CYCLES_PER_ANODE => 100000)
    port map (
      i_clk => r_Clk,
      i_reset => r_Reset,
      i_displayed => displayed_number,
      o_anodes => an,
      o_segments => seg
    );
  
  process is  
  begin
    displayed_number <= (others => '0');
    wait until r_Clk = '1';
    wait until r_Clk = '1';
    wait until r_Clk = '1';
    wait until r_Clk = '1';
    displayed_number <= displayed_number + x"0001";
    wait until r_Clk = '1';
    wait until r_Clk = '1';
    wait until r_Clk = '1';
    
    finish;
  end process;
     

end Behavioral;
