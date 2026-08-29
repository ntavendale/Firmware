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
use std.env.finish;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity bcd_counter_four_digit_tb is

end bcd_counter_four_digit_tb;

architecture Behavioral of bcd_counter_four_digit_tb is
  signal r_Clk, r_Reset: std_logic := '0';
  signal r_BCD: std_logic_vector(15 downto 0);
begin
  r_Clk <= not r_Clk after 5 ns;
  
  Unit_Under_Test :  entity work.bcd_counter_four_digit
    port map (
      i_reset => r_Reset, 
      i_increment => r_Clk,
      o_bcd => r_BCD
    );
    
  process is  
  begin
    for i in 0 to 999 loop 
      wait until r_Clk = '1'; 
    end loop;
    finish;
  end process;

end Behavioral;
