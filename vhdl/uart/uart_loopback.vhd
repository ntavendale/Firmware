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

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Use at least VHDL 2008 when building.

entity uart_loopback is
  generic (
      BASYS3_CLKS_PER_BIT : integer := 868 -- 100,000,000 / 115,200 = 868 
  );
  port (
    -- Main clock 100 MHz
    clk   : in std_logic;
    -- UART Data
    RsRx : in  std_logic;
    RsTx : out std_logic;
    an   : out std_logic_vector (3 downto 0);
    seg  : out std_logic_vector (6 downto 0)
  );
end uart_loopback;

architecture RTL of uart_loopback is
  signal w_RX_DV     : std_logic;
  signal w_RX_Byte   : std_logic_vector(7 downto 0);
  signal w_TX_Active : std_logic;
  signal w_TX_Serial : std_logic;
  
  component uart_rx is
    generic (
    -- Needs to be set correctly for clock and baud rate
    -- For Basys3 it's 100MHz cklock / 115200 baud rate.
      CLKS_PER_BIT : integer := 868  
    );
    port (
      i_clk           : in  std_logic; -- clock signal.
      i_rx_Serial     : in  std_logic; -- serial data in
      o_rx_data_valid : out std_logic; -- driven high when Data Value has been deserialized
      o_rx_byte       : out std_logic_vector(7 downto 0) -- deserialized data out
    );
  end component;
  
  component uart_tx is
    generic (
      -- Needs to be set correctly for clock and baud rate
      -- For Basys3 it's 100MHz cklock / 115200 baud rate.
      CLKS_PER_BIT : integer := 868     -- Needs to be set correctly
    );
    port (
      i_clk           : in  std_logic;
      i_tx_data_valid : in  std_logic; -- Driven high when data value in i_TX_Byte ready to be serialized
      i_tx_byte       : in  std_logic_vector(7 downto 0);
      o_tx_active     : out std_logic;
      o_tx_serial     : out std_logic; -- Serial Output
      o_tx_done      : out std_logic
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
  -- UART_RX.vhd
  rx : uart_rx
    generic map (
      CLKS_PER_BIT => BASYS3_CLKS_PER_BIT)
    port map (
      i_clk           => clk,
      i_rx_serial     => RsRx,
      o_rx_data_valid => w_RX_DV,
      o_rx_byte       => w_RX_Byte);
 
 
  -- Creates a simple loopback to test TX and RX
  -- UART_TX.vhd
  tx : uart_tx
    generic map (
      CLKS_PER_BIT => BASYS3_CLKS_PER_BIT)               
    port map (
      i_clk            => clk,
      i_tx_data_valid  => w_RX_DV,
      i_tx_byte        => w_RX_Byte,
      o_tx_active      => w_TX_Active,
      o_tx_serial      => w_TX_Serial,
      o_tx_done        => open
      );
 
  --This will Drive UART line high when transmitter is not active, indicating idle.
  -- Otherwise the Byte transmitted will be echoed back. When running in a terminal 
  -- it is the echo back that causes the key characters to print, NOT the key press itself.
  -- Replace this with RsTx <= '1' and you can press the keys, and see the key code
  -- displayed on the board's seven segment display, but you won't see characters in the terminal.
  RsTx <= w_TX_Serial when w_TX_Active = '1' else '1';
  
  -- Seven_Segment_Display_Binary.vhd
  -- Drive Basys 3 Display to show scan codes of key presses
  -- The right most two of the seven segment displays wil display
  -- a nibble (0-F) each. The leftmost will display 0s.
  seven_segment : seven_segment_display
    generic map (CYCLES_PER_ANODE => 100000) -- 1 Khz
    port map (
      i_clk         => clk,
      i_reset       => '0',
      i_displayed   => (7 downto 0 => w_RX_Byte, others => '0'),
      o_anodes      => an,
      o_segments    => seg
      );

end RTL;
