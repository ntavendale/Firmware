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

-- {VHDL 2008}
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity Seven_Segment_Display_Binary is
  generic (CYCLES_PER_ANODE : natural := 100000); -- Default 1 ms (1 kHz refresh rate)
  port (
    i_Clock     : in std_logic;
    i_Reset     : in std_logic;
    i_Displayed : in std_logic_vector(15 downto 0); -- Binary
    o_Anodes    : out std_logic_vector(3 downto 0);
    o_Segments  : out std_logic_vector(6 downto 0)
  );
end Seven_Segment_Display_Binary;

architecture RTL of Seven_Segment_Display_Binary is
  constant ANODE_COUNT: natural := 4;
  signal bcd_value: std_logic_vector(3 downto 0);
  signal r_counter : natural range 0 to CYCLES_PER_ANODE - 1;  
  -- 2-bit vector for creating 4 anode-activating signals
  -- count         0    ->  1  ->  2  ->  3
  -- activates    LED1    LED2   LED3   LED4
  -- and repeat
  signal anode_counter: natural range 0 to ANODE_COUNT -1 ;
begin
  process(bcd_value)
  begin
    -- Segment turned on when it's value is driven LOW!
    -- On basys 3 the seven segments of ecach display egments are labled A to G 
    --(https://digilent.com/reference/programmable-logic/basys-3/reference-manual)
    -- segment vector values are  GFEDCBA in the o_Segments output vector 
    case bcd_value is
      when "0000" => o_Segments <= "1000000"; -- "0"     
      when "0001" => o_Segments <= "1111001"; -- "1"
      when "0010" => o_Segments <= "0100100"; -- "2"
      when "0011" => o_Segments <= "0110000"; -- "3"
      when "0100" => o_Segments <= "0011001"; -- "4"
      when "0101" => o_Segments <= "0010010"; -- "5"
       
      when "0110" => o_Segments <= "0000010"; -- "6" 
      when "0111" => o_Segments <= "1011000"; -- "7" 
      when "1000" => o_Segments <= "0000000"; -- "8"     
      when "1001" => o_Segments <= "0010000"; -- "9" 
      when "1010" => o_Segments <= "0100000"; -- a
      when "1011" => o_Segments <= "0000011"; -- b
      when "1100" => o_Segments <= "1000110"; -- C
      when "1101" => o_Segments <= "0100001"; -- d
      when "1110" => o_Segments <= "0000110"; -- E
      when "1111" => o_Segments <= "0001110"; -- F
      when others => o_Segments <= "0001110"; -- F
    end case;
  end process;
  
   -- Counting the number to be displayed on 4-digit 7-segment Display 
  -- on Basys 3 FPGA board  
  process (i_Clock, i_Reset)
  begin
    if i_Reset = '1' then
      anode_counter <= 0;
      r_Counter     <= 0;
    elsif rising_edge(i_Clock) then
      if r_Counter = CYCLES_PER_ANODE - 1 then
        -- reset counter
        r_Counter <= 0;
        -- change anode
        if anode_counter = ANODE_COUNT -1 then
          anode_counter <= 0;
        else  
          anode_counter <= anode_counter + 1;
        end if;
      else
        r_Counter <= r_Counter + 1;     
      end if;
    end if;    
  end process;
  
  process(anode_counter)
  begin
    -- Digit turned on when it's anode is driven LOW!
    case anode_counter is
      when 0 => 
        o_Anodes  <= "0111"; -- 7
        bcd_value <= i_Displayed(15 downto 12);
      when 1 => 
        o_Anodes  <= "1011"; -- B
        bcd_value <= i_Displayed(11 downto 8);
      when 2 => 
        o_Anodes  <= "1101"; -- D
        bcd_value <= i_Displayed(7 downto 4); 
      when 3 => 
        o_Anodes  <= "1110"; -- E
        bcd_value <= i_Displayed(3 downto 0); 
    end case;
  end process;  
  
end RTL;
