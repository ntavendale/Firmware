-- Original File: https://github.com/nandland/UART/blob/main/VHDL/source/UART_RX.vhd
-- Released under MIT License.

-- This file contains the UART Receiver.  This receiver is able to
-- receive 8 bits of serial data, one start bit, one stop bit,
-- and no parity bit.  When receive is complete o_RX_DV will be
-- driven high for one clock cycle.
-- 
-- Set Generic CLKS_PER_BIT as follows:
-- CLKS_PER_BIT = (Frequency of Clock)/(Frequency of UART)
-- Example: 100 MHz Clock, 115200 baud
-- (100000000)/(115200) = 868

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;

entity uart_rx is
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
end uart_rx;

architecture rtl of uart_rx is
  -- yes, it's a Finite State Machine!
  type t_Rx_State is (IDLE, RX_START_BIT, RX_DATA_BITS, RX_STOP_BIT, CLEANUP);
  signal r_Rx_State : t_Rx_State := IDLE; -- initial state.
  signal r_RX_Data_R : std_logic := '0'; -- intermediate buffer for incoming serial data
  signal r_RX_Data   : std_logic := '0'; -- holds incoming serial data
  
  signal r_Clk_Count : integer range 0 to CLKS_PER_BIT-1 := 0; -- track number of clock signals
  signal r_Bit_Index : integer range 0 to 7 := 0;  -- 8 Bits Total
  signal r_RX_Byte   : std_logic_vector(7 downto 0) := (others => '0');
  signal r_RX_DV     : std_logic := '0';
begin
  -- Purpose: Double-register the incoming data.
  -- This allows it to be used in the UART RX Clock Domain.
  -- (It removes problems caused by metastabiliy)
  p_SAMPLE : process (i_clk)
  begin
    if rising_edge(i_clk) then
      r_RX_Data_R <= i_RX_Serial;
      r_RX_Data   <= r_RX_Data_R; 
    end if; 
  end process p_SAMPLE;
  
  -- Purpose: Control RX state machine
  p_UART_RX : process (i_clk)
  begin
    if rising_edge(i_clk) then
      case r_Rx_State is
        when IDLE =>
          -- Reset count and index
          r_RX_DV <= '0';
          r_Clk_Count <= 0;
          r_Bit_Index <= 0;
        
         if r_RX_Data = '0' then       -- Start bit detected, data is arriving
           -- change to next state
           r_Rx_State <= RX_START_BIT;
         else
           -- stay in idle if not data
           r_Rx_State <= IDLE;
         end if;
       
        when RX_START_BIT =>
          -- Check middle of start bit to make sure it's still low
          if r_Clk_Count = (CLKS_PER_BIT-1)/2 then
            if r_RX_Data = '0' then
              -- Reset counter since we got to the middle of the start bit.
              r_Clk_Count <= 0;  
              -- Change to next state to start collecting collect data bits.
              r_Rx_State   <= RX_DATA_BITS;
            else
              -- If it's not low, it's not a start bit. So we need to go back to idle 
              -- to wait for a start bit.  
              r_Rx_State  <= IDLE;
            end if;
          else
            -- We need to spend a few cycles waiting until we get to the middle of the bit.
            -- remember 115200 may be 115 thousand bits/sec but there are 100 million 
            -- clock cycles per sec, so it will take a few clock cycles to get to the middle
            -- of the data bit.
            -- So we can just hang out in this state untie we get there. 
            r_Clk_Count <= r_Clk_Count + 1;
            r_Rx_State   <= RX_START_BIT;
          end if;
       
        when RX_DATA_BITS =>
          -- Spin in this state to get half way through the next bit and sample. 
          -- Remember we reset the count HALF WAY into the Start Bit 
          -- when were in the  s_RX_Start_Bit state  so after 
          -- CLKS_PER_BIT have elapsed wei will be HALF WAY through 
          -- the NEXT data bit, and so on...
          if r_Clk_Count < CLKS_PER_BIT - 1 then
            r_Clk_Count <= r_Clk_Count + 1;
            r_Rx_State   <= RX_DATA_BITS;
          else
            -- Once CLKS_PER_BIT cycles hae run we can extract the data bit.
            r_Clk_Count            <= 0; -- reset clock count to start the next bit
            -- take the r_RX_Data value and sore it in the correct spot in the Data vector
            -- based on the index
            r_RX_Byte(r_Bit_Index) <= r_RX_Data;
            if r_Bit_Index < 7 then
              -- Increment bit index so we know where to store the NEXT data bit
              -- while remain in s_RX_Data_Bits state to collect the next bit.
              r_Bit_Index <= r_Bit_Index + 1;
              r_Rx_State   <= RX_DATA_BITS;
            else
              -- We have collected 8 data bits. We now need to rest the bit index 
              -- and initiate the change of state to watch for the stop bit.
               r_Bit_Index <= 0;
               r_Rx_State   <= RX_STOP_BIT;
            end if;
          end if;
        when RX_STOP_BIT =>
          -- Spin in this state to get half way through the next bit. 
          -- Remember we reset the count HALF WAY into the Start Bit 
          -- when were in the  s_RX_Start_Bit state  so CLKS_PER_BIT 
          -- clock cycles will have been reached HALF WAY through each
          -- subsequent bit.
          if r_Clk_Count < CLKS_PER_BIT - 1 then
            r_Clk_Count <= r_Clk_Count + 1;
            r_Rx_State   <= RX_STOP_BIT;
          else
            -- Indicate that 8 bit data value has been collected.
            -- r_RX_DV will be high for only one clock cycle.
            r_RX_DV     <= '1';  
            r_Clk_Count <= 0;   -- reset clock count
            r_Rx_State   <= CLEANUP; -- go to cleanup state.
          end if;
          
        when CLEANUP =>
          -- We are here for one clock cycle.
          r_Rx_State <= IDLE;
          r_RX_DV   <= '0';
        
        -- Unknown or undefined state? Go to IDLE.  
        when others =>
          r_Rx_State <= IDLE;             
      end case;
    end if;
  end process p_UART_RX;
  
  -- Set Output signals
  o_rx_data_valid   <= r_RX_DV;
  o_rX_byte <= r_RX_Byte;
end rtl;
