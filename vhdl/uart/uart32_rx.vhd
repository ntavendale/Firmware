-- Copyright 2026 Nigel Tavendale
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

-- Serial interface that wraps a serial uart_rx to receive 4 bytes (32 bits)

entity uart32_rx is
 generic (
    -- Needs to be set correctly for clock and baud rate
    -- For Basys3 it's 100MHz cklock / 115200 baud rate.
    CLKS_PER_BIT : Integer := 868     -- Needs to be set correctly
  );
  port (
    i_clk        : in  std_logic; -- clock signal.
    i_Serial     : in  std_logic; -- serial data in
    o_data_valid : out std_logic; -- driven high when Data Value has been deserialized
    o_data       : out std_logic_vector(31 downto 0) -- deserialized data out
  );
end uart32_rx;

architecture rtl of uart32_rx is
  signal r_RX_Data_R         : std_logic := '0'; -- intermediate buffer for incoming serial data
  signal r_RX_Data           : std_logic := '0'; -- holds incoming serial data
  signal r_byte_count        : Integer range 0 to 3 := 0;
  signal r_byte_valid        : std_logic := '0';
  signal r_deserialized_byte : std_logic_vector(7 downto 0) := (others => '0');
  signal r_output            : std_logic_vector(31 downto 0) := (others => '0'); 
  
  component uart_rx is
    generic (
      CLKS_PER_BIT : Integer 
    );
    port (
      i_clk           : in  std_logic; -- clock signal.
      i_rx_serial     : in  std_logic; -- serial data in
      o_rx_data_valid : out std_logic; -- driven high when Data Value has been deserialized
      o_rx_byte       : out std_logic_vector(7 downto 0) -- deserialized data out
   );   
  end component;  
begin
   -- Purpose: Double-register the incoming data.
  -- This allows it to be used in the UART RX Clock Domain.
  -- (It removes problems caused by metastabiliy)
  p_sample : process (i_clk)
  begin
    if rising_edge(i_clk) then
      r_RX_Data_R <= i_Serial;
      r_RX_Data   <= r_RX_Data_R; 
    end if; 
  end process p_sample;
  
  --instantiate the i2c master
  uart_rx_0:  uart_rx
  generic map (
      CLKS_PER_BIT => CLKS_PER_BIT
    )  
    port map (
      i_clk => i_clk, 
      i_rx_serial => r_RX_Data, 
      o_rx_data_valid => r_byte_valid,
      o_rx_byte => r_deserialized_byte
   );
      
  p_get_byte: process(i_clk)
  begin
    if rising_edge(i_clk) then
      o_data_valid <= '0';
      if (r_byte_valid = '1') then
        if (r_byte_count = 0) then
          r_output(7 downto 0) <= r_deserialized_byte;
          r_byte_count <= r_byte_count + 1;
        elsif (r_byte_count = 1) then
          r_output(15 downto 8) <= r_deserialized_byte;
          r_byte_count <= r_byte_count + 1;
        elsif (r_byte_count = 2) then
          r_output(23 downto 16) <= r_deserialized_byte;
          r_byte_count <= r_byte_count + 1;
        elsif (r_byte_count = 3) then
          r_output(31 downto 24) <= r_deserialized_byte;
          r_byte_count <= 0;
          o_data_valid <= '1';
        end if;
      end if;       
    end if;
  end process;
  
  o_data <= r_output when r_byte_count = 0;
end rtl;
