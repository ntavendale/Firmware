----------------------------------------------------------------------
-- Original File: https://github.com/nandland/UART/blob/main/VHDL/source/UART_TX.vhd
-- Released under MIT License.
----------------------------------------------------------------------
-- This file contains the UART Transmitter.  This transmitter is able
-- to transmit 8 bits of serial data, one start bit, one stop bit,
-- and no parity bit.  When transmit is complete o_TX_Done will be
-- driven high for one clock cycle.
--
-- Set Generic CLKS_PER_BIT as follows:
-- CLKS_PER_BIT = (Frequency of i_Clk)/(Frequency of UART)
-- Example: 100 MHz Clock, 115200 baud UART
-- (100000000)/(115200) = 868

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

entity uart_tx is
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
end uart_tx;

architecture rtl of uart_tx is
  -- Yes, it's a Finite State Machine 
  type t_Tx_State is (IDLE, TX_START_BIT, TX_DATA_BITS, TX_STOP_BIT, CLEANUP);
  signal r_Tx_State   : t_Tx_State := IDLE;
  signal r_Clk_Count : integer range 0 to CLKS_PER_BIT - 1 := 0;
  signal r_Bit_Index : integer range 0 to 7 := 0;  -- index of which bit in r_TX_Data we are writing to 
  signal r_TX_Data   : std_logic_vector(7 downto 0) := (others => '0');
  signal r_TX_Done   : std_logic := '0';
begin
  p_UART_TX : process(i_clk)
  begin
    if rising_edge(i_clk) then
      
      r_TX_Done   <= '0';
      
      case r_Tx_State is
        when IDLE =>
          -- Reset everything
          o_tx_active <= '0';
          o_tx_serial <= '1';  -- Drive Line High for Idle
          r_Clk_Count <= 0;
          r_Bit_Index <= 0;
          if i_tx_data_valid = '1' then
            -- copy input data (i_TX_Byte) into our internal register (r_TX_Data)
            -- then move s_TX_Start_Bit to start serialization process  
            r_TX_Data <= i_TX_Byte;
            r_Tx_State <= TX_START_BIT;
          else
            -- No data ready so stay in idle
            r_Tx_State <= IDLE;
          end if;
        
        when TX_START_BIT =>
          o_tx_active <= '1'; -- Drive line high to indicate we are actively serializing data.
          o_tx_serial <= '0'; -- Send out first piece of serial data: The START BIT 
          -- Now we need to wait and transmit start bit for CLKS_PER_BIT Cycles 
          -- before moving on to the data bits
          if r_Clk_Count < CLKS_PER_BIT - 1 then
            -- stay in our current state
            r_Tx_State  <= TX_START_BIT;
            r_Clk_Count <= r_Clk_Count + 1;
          else
            -- We had the start bit low for CLKS_PER_BIT cycles.
            -- Now move on to serializing data 
            r_Clk_Count <= 0;
            r_Tx_State  <= TX_DATA_BITS;
          end if;
        
        when TX_DATA_BITS =>
          -- Put current data bit on the output.
          o_tx_serial <= r_TX_Data(r_Bit_Index);
          -- Now we need to wait and transmit start bit for CLKS_PER_BIT Cycles 
          -- before moving on to the data bits
          if r_Clk_Count < CLKS_PER_BIT - 1 then
            -- stay in our current state, transmitting out current bit
            r_Tx_State  <= TX_DATA_BITS;
            r_Clk_Count <= r_Clk_Count + 1;
          else
            -- Reset clock and increment 
            r_Clk_Count <= 0;
            -- Check bit index to see if we have transmitted  al the bits
            if r_Bit_Index < 7 then
              -- Move on to next bit and keep transmitting
              r_Tx_State   <= TX_DATA_BITS;
              r_Bit_Index <= r_Bit_Index + 1;
            else
              -- Move on to Stop Bit.
              r_Bit_Index <= 0;
              r_Tx_State <= TX_STOP_BIT;
            end if;
          end if;
          
        when TX_STOP_BIT =>
          o_tx_serial <= '1';
          -- Now we need to wait and transmit stop bit for CLKS_PER_BIT Cycles 
          -- before moving on to the data bits
          if r_Clk_Count < CLKS_PER_BIT - 1 then
            -- stay in our current state
            r_Tx_State  <= TX_STOP_BIT;
            r_Clk_Count <= r_Clk_Count + 1;
          else
            r_TX_Done <= '1'; -- Indicate done
            -- We have been transmitting stop for CLKS_PER_BIT cycles.
            -- Now move to Cleanup 
            r_Clk_Count <= 0;
            r_Tx_State  <= CLEANUP;
          end if; 
        
        when CLEANUP =>
          o_tx_active <= '0'; -- Drive line low to indicate we are no longer actively serializing data.
          r_TX_Done   <= '1';
          r_Tx_State   <= IDLE;
            
        -- Any other state or state undefined? Go to IDLE!  
        when others =>
          r_Tx_State  <= IDLE;
      end case;
    end if;
  end process p_UART_TX;
  
  o_tx_done <= r_TX_Done;
  
end rtl;
