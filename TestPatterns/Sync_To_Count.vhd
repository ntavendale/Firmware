-- Original File: https://github.com/nandland/nandland/blob/master/VGA/VHDL/source/Sync_To_Count.vhd
-- Released under MIT License.
 
-- This module will take incoming horizontal and veritcal sync pulses and
-- create Row and Column counters based on these syncs.
-- It will align the Row/Col counters to the output Sync pulses.
-- Useful for any module that needs to keep track of which Row/Col position we
-- are on in the middle of a frame.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- {VHDL 2008}

entity Sync_To_Count is
   generic (
    g_TOTAL_COLS : integer;
    g_TOTAL_ROWS : integer
  );
  port (
    i_Clk             : in std_logic;
    i_HSync           : in std_logic;
    i_VSync           : in std_logic;
  
    o_HSync           : out std_logic;
    o_VSync           : out std_logic;
    
    o_HSync_Col_Count : out std_logic_vector(9 downto 0);
    o_VSync_Row_Count : out std_logic_vector(9 downto 0)
  );
end Sync_To_Count;

architecture RTL of Sync_To_Count is
  signal r_VSync           : std_logic := '0';
  signal r_HSync           : std_logic := '0';
  -- while this is true the rows and columms active area of the monitor is being
  -- rendered on the screen
  signal w_Frame_Rendering : std_logic;   
  
  -- Unsigned counters (always positive)
  signal r_Col_Count : unsigned(9 downto 0) := (others => '0');
  signal r_Row_Count : unsigned(9 downto 0) := (others => '0');
begin
   -- Register syncs to align with output data.
  p_Reg_Syncs : process (i_Clk) is
  begin
    if rising_edge(i_Clk) then
      -- Assign input sync signals to our internal sync signals
      r_VSync <= i_VSync;
      r_HSync <= i_HSync;
    end if;
  end process p_Reg_Syncs; 
  
  -- Keep track of Row/Column counters.
  p_Row_Col_Count : process (i_Clk) is
  begin
    if rising_edge(i_Clk) then
      if w_Frame_Rendering = '1' then
        -- The frame is starting to draw on monitor so we rest row and 
        -- colum count to 0
        r_Col_Count <= (others => '0');
        r_Row_Count <= (others => '0');
      else
        if r_Col_Count = to_unsigned(g_TOTAL_COLS - 1, r_Col_Count'length) then
          -- We have reached the end of the row so checkl the row count
          if r_Row_Count = to_unsigned(g_TOTAL_ROWS - 1, r_Row_Count'length) then
            r_Row_Count <= (others => '0');
          else
            -- Increment the row count and move down the screen 
            r_Row_Count <= r_Row_Count + 1;
          end if;
          -- Reset column count to set up for next row.
          r_Col_Count <= (others => '0');
        else
          -- Increment the colum count and move along the current row 
          r_Col_Count <= r_Col_Count + 1;
        end if;  
      end if;    
    end if;
  end process p_Row_Col_Count; 
    
  -- Look for rising edge on Vertical Sync to reset the counters
  -- Input vSync is '1' indicating that we are in visible area
  -- While r_VSync is 0 indicating we are in non visible area 
  -- (set by p_Reg_Syncs above). This indicate that we have reached 
  -- the end of the vertical blanking interval and are starting on 
  -- a new frame.
  -- Remember - this evaluation is happening in PARALLEL with the two 
  -- processes above. We could just as easily but thios line before them 
  -- and the outoputs would be the same. 
  -- The point is r_VSync won't be '1' untill AFTER the clock
  -- edge has risen when i_VSync is '1', so this logic works as it will still be 0
  -- here.   
  w_Frame_Rendering <= '1' when (r_VSync = '0' and i_VSync = '1') else '0'; 
  
  -- Output current syncs and colum/row counts  
  o_VSync <= r_VSync;
  o_HSync <= r_HSync;

  -- Number of rows in Vertical Sync Pulse
  o_VSync_Row_Count <= std_logic_vector(r_Row_Count);
  -- Number of colums in Horizontal Sync Pulse
  o_HSync_Col_Count <= std_logic_vector(r_Col_Count);
  
end RTL;
