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
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity bcd_Counter_four_digit is
  port (
    i_reset     : in std_logic;
    i_increment : in std_logic;
    o_bcd       : out std_logic_vector(15 downto 0)
   );
end bcd_Counter_four_digit;

architecture rtl of bcd_Counter_four_digit is
  signal r_Digit_0: std_logic_vector(3 downto 0) := "0000"; 
  signal r_Digit_1: std_logic_vector(3 downto 0) := "0000";
  signal r_Digit_2: std_logic_vector(3 downto 0) := "0000";
  signal r_Digit_3: std_logic_vector(3 downto 0) := "0000";
begin
  process(i_Increment, i_Reset)
  begin
    if i_Reset = '1' then
      r_Digit_0 <= "0000";
      r_Digit_1 <= "0000";
      r_Digit_2 <= "0000";
      r_Digit_3 <= "0000";
    elsif rising_edge(i_Increment) then
      if r_Digit_3 = "1001" and r_Digit_2 = "1001" and r_Digit_1 = "1001" and r_Digit_0 = "1001" then
        -- Reset
        r_Digit_0 <= "0000";
        r_Digit_1 <= "0000";
        r_Digit_2 <= "0000";
        r_Digit_3 <= "0000";
      elsif r_Digit_0 = "1001" then
        r_Digit_0 <= "0000"; 
        if r_Digit_1 = "1001" then
          r_Digit_1 <= "0000";
          if r_Digit_2 = "1001" then
            r_Digit_2 <= "0000";
            r_Digit_3 <= r_Digit_3 + "1";
          else
            r_Digit_2 <= r_Digit_2 + "1";
          end if; 
        else
          r_Digit_1 <= r_Digit_1 + "1";
        end if;
      else
        r_Digit_0 <= r_Digit_0 + "1";
      end if;
    end if;
  end process;
  o_BCD(15 downto 12) <= r_Digit_3;
  o_BCD(11 downto 8)  <= r_Digit_2;
  o_BCD(7 downto 4)   <= r_Digit_1;
  o_BCD(3 downto 0)   <= r_Digit_0;
end rtl;

