-- The purpose of this module is to modify the input HSync and VSync signals to
-- include some time for what is called the Front and Back porch.  The front
-- and back porch of a VGA interface used to have more meaning when a monitor
-- actually used a Cathode Ray Tube (CRT) to draw an image on the screen.  You
-- can read more about the details of how old VGA monitors worked here.  These
-- days, the notion of a front and back porch is maintained, due more to
-- convention than to the physics of the monitor.
-- New standards like DVI and HDMI which are meant for digital signals have
-- removed this notion of the front and back porches.  

-- Remember that VGA is an analog interface.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- {VHDL 2008}

entity VGA_Sync_Porch is
  generic (
    g_VIDEO_WIDTH : integer;
    -- VGA is 800 Colums x 525 Rows
    -- Visible (ie Active) area is 640 Colums x 480 Rows
    g_TOTAL_COLS  : integer;
    g_TOTAL_ROWS  : integer;
    g_ACTIVE_COLS : integer;
    g_ACTIVE_ROWS : integer
  );
  port (
    i_Clk       : in std_logic;
    i_HSync     : in std_logic;
    i_VSync     : in std_logic;
    
    i_Red_Video : in std_logic_vector(g_VIDEO_WIDTH-1 downto 0);
    i_Grn_Video : in std_logic_vector(g_VIDEO_WIDTH-1 downto 0);
    i_Blu_Video : in std_logic_vector(g_VIDEO_WIDTH-1 downto 0);
    --
    o_HSync     : out std_logic;
    o_VSync     : out std_logic;
    
    o_Red_Video : out std_logic_vector(g_VIDEO_WIDTH-1 downto 0);
    o_Grn_Video : out std_logic_vector(g_VIDEO_WIDTH-1 downto 0);
    o_Blu_Video : out std_logic_vector(g_VIDEO_WIDTH-1 downto 0)    
  );
end VGA_Sync_Porch;

architecture RTL of VGA_Sync_Porch is
  -- The front porch and back porch allow the active area 
  -- to be shifted around your VGA monitor. You can think 
  -- of them as modifications to your HSync and VSync pulses.
  constant FRONT_PORCH_HORZ : integer := 14; -- Last 14 Pixels before horizontal sync pulse starts, after data ends
  constant BACK_PORCH_HORZ  : integer := 4;--54; -- First 54 Pixels after horizontal sync pulse ends, before data starts
  constant FRONT_PORCH_VERT : integer := 9;
  constant BACK_PORCH_VERT  : integer := 34;
   
  component Sync_To_Count is
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
  end component Sync_To_Count;
  -- modified vertical and horizontal sync pulses
  signal r_HSync : std_logic := '0';
  signal r_VSync : std_logic := '0';

  -- signal for horizontal sync pulse from counter
  -- register to hold the column count of the horizontal sync pulse
  signal w_HSync : std_logic;
  signal w_HSync_Col_Count : std_logic_vector(9 downto 0);
  -- signal for Vertical sync pulse from counter
  -- register to hold the row count of the vertical sync pulse
  signal w_VSync : std_logic;
  signal w_VSync_Row_Count : std_logic_vector(9 downto 0);

  signal r_Red_Video : std_logic_vector(g_VIDEO_WIDTH-1 downto 0) := (others => '0');
  signal r_Grn_Video : std_logic_vector(g_VIDEO_WIDTH-1 downto 0) := (others => '0');
  signal r_Blu_Video : std_logic_vector(g_VIDEO_WIDTH-1 downto 0) := (others => '0');
begin
  Sync_To_Count_Porch_inst : Sync_To_Count
    generic map (
      g_TOTAL_COLS => g_TOTAL_COLS,
      g_TOTAL_ROWS => g_TOTAL_ROWS
    )
    port map (
      i_Clk       => i_Clk,
      i_HSync     => i_HSync,
      i_VSync     => i_VSync,
      o_HSync     => w_HSync,
      o_VSync     => w_VSync,
      o_HSync_Col_Count => w_HSync_Col_Count, -- increments each clock cycle untial sync is over 
      o_VSync_Row_Count => w_VSync_Row_Count  -- increments each clock cycle untial sync is over
    );
  
  -- expand the vertical and horizontal sync pulses to include the front and back porches.
  p_Sync_Porch : process (i_Clk) is
  begin
    if rising_edge(i_Clk) then
      if (to_integer(unsigned(w_HSync_Col_Count)) < FRONT_PORCH_HORZ + g_ACTIVE_COLS or 
          to_integer(unsigned(w_HSync_Col_Count)) > g_TOTAL_COLS - BACK_PORCH_HORZ - 1) then
        r_HSync <= '1';
      else
        r_HSync <= w_HSync;
      end if;

      if (to_integer(unsigned(w_VSync_Row_Count)) < FRONT_PORCH_VERT + g_ACTIVE_ROWS or
          to_integer(unsigned(w_VSync_Row_Count)) > g_TOTAL_ROWS - BACK_PORCH_VERT - 1) then
        r_Vsync <= '1';
      else
        r_VSync <= w_VSync;
      end if;
    end if;
  end process p_Sync_Porch;
  
  o_HSync <= r_HSync;
  o_VSync <= r_VSync;
  
   -- Purpose: Align input video to modified Sync pulses. (2 Clock Cycles of Delay)
  p_Video_Align : process (i_Clk) is
  begin
    if rising_edge(i_Clk) then
      r_Red_Video <= i_Red_Video;
      r_Grn_Video <= i_Grn_Video;
      r_Blu_Video <= i_Blu_Video;

      o_Red_Video <= r_Red_Video;
      o_Grn_Video <= r_Grn_Video;
      o_Blu_Video <= r_Blu_Video;
    end if;
  end process p_Video_Align;  
end RTL;
