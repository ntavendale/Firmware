library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- {VHDL 2008}

entity VGA_Sync_Pulses is
  generic (
    g_TOTAL_COLS  : integer;
    g_TOTAL_ROWS  : integer;
    g_ACTIVE_COLS : integer;
    g_ACTIVE_ROWS : integer   
  );
  port (
    i_Clk       : in  std_logic;
    o_HSync     : out std_logic;
    o_VSync     : out std_logic;
    o_Col_Count : out std_logic_vector(9 downto 0);
    o_Row_Count : out std_logic_vector(9 downto 0)
  );
end VGA_Sync_Pulses;

architecture RTL of VGA_Sync_Pulses is
  signal r_Col_Count : integer range 0 to g_TOTAL_COLS-1 := 0;
  signal r_Row_Count : integer range 0 to g_TOTAL_ROWS-1 := 0;
begin
  -- Assume more colums than rows.
  p_Row_Col_Count : process(i_Clk) 
  begin
    -- A typicla CRT scans line by line.
    -- It draws the first row than, sends a horizontal sync
    -- then the second and so on until it runs out of rows, 
    -- then it sends a vertical sync.
    if rising_edge(i_Clk) then
      if r_Col_Count = g_TOTAL_COLS - 1 then
        -- we reach the end ot the current row
        -- so check and incrment row count.
        if r_Row_Count = g_TOTAL_ROWS - 1 then
          -- reached the bottom of screen, reset row count
          r_Row_Count <= 0;
        else
          -- still going down screen so increment row count 
          r_Row_Count <= r_Row_Count + 1;
        end if;
        -- reset colum count
        r_Col_Count <= 0;
      else
        -- increment column in current row
        r_Col_Count <= r_Col_Count + 1;
      end if;
    end if;
  end process;
  -- When we reach the number of ACTIVE colums send a horizontal sync pulse by 
  -- drivinmg line low to indicate no longer in horizontal viewable area
  o_HSync <= '1' when r_Col_Count < g_ACTIVE_COLS else '0';
  -- When we reach the number of ACTIVE rows send a vertical sync pulse by 
  -- driving line low to indicate no longer in vertical viewable area
  o_VSync <= '1' when r_Row_Count < g_ACTIVE_ROWS else '0';

  -- output current row and column 
  o_Col_Count <= std_logic_vector(to_unsigned(r_Col_Count, o_Col_Count'length));
  o_Row_Count <= std_logic_vector(to_unsigned(r_Row_Count, o_Row_Count'length));

end RTL;
