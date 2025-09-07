library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Vga_Test_Patterns is
  generic (
      -- Used with UART 
      BASYS3_CLKS_PER_BIT : integer := 868 -- 100,000,000 / 115,200 = 868 
  );
  port (
    -- 100 MHz Basys 3 clock
    clk      : in std_logic;
    -- UART
    RsRx     : in std_logic;
    RsTx     : out std_logic;
    -- Anodes and segments for Seven Segment display
    an       : out std_logic_vector(3 downto 0);
    seg      : out std_logic_vector(6 downto 0);
    -- VGA Pins
    vgaRed   : out std_logic_vector(3 downto 0);
    vgaGreen : out std_logic_vector(3 downto 0);
    vgaBlue  : out std_logic_vector(3 downto 0);
    Hsync    : out std_logic;
    Vsync    : out std_logic
  );
end Vga_Test_Patterns;

architecture RTL of Vga_Test_Patterns is
  signal w_Rx_DV     : std_logic;
  signal w_Rx_Byte   : std_logic_vector(7 downto 0);
  signal w_Tx_Active : std_logic;
  signal w_Tx_Serial : std_logic;
  
  -- VGA Constants to set Frame Size
  constant VIDEO_WIDTH : integer := 4;
  -- VGA Screen is 800 colums x 525 riows
  constant TOTAL_COLS  : integer := 800;
  constant TOTAL_ROWS  : integer := 525;
  
  -- VGA Screen Visible (ie Active) area is 640 colums x 480 riows
  constant ACTIVE_COLS : integer := 640;
  constant ACTIVE_ROWS : integer := 480;
  
  -- Selected Test Pattern index.
  signal r_TP_Index        : std_logic_vector(3 downto 0) := (others => '0');
  
  -- Internal sync pulse signals. Driven low when reach the end of the ACTIVE
  -- colums/rows 
  signal w_HSync_VGA       : std_logic;
  signal w_VSync_VGA       : std_logic;
  
  signal w_HSync_Porch     : std_logic;
  signal w_VSync_Porch     : std_logic;
  
  signal w_Red_Video_Porch   : std_logic_vector(VIDEO_WIDTH-1 downto 0);
  signal w_Green_Video_Porch : std_logic_vector(VIDEO_WIDTH-1 downto 0);
  signal w_Blue_Video_Porch  : std_logic_vector(VIDEO_WIDTH-1 downto 0);
  
  -- VGA Test Pattern Signals
  signal w_HSync_TP       : std_logic;
  signal w_VSync_TP       : std_logic;
  signal w_Red_Video_TP   : std_logic_vector(VIDEO_WIDTH-1 downto 0);
  signal w_Green_Video_TP : std_logic_vector(VIDEO_WIDTH-1 downto 0);
  signal w_Blue_Video_TP  : std_logic_vector(VIDEO_WIDTH-1 downto 0); 
  
  signal r_VGA_Clk : std_logic;
begin
  UART_Rx_Inst : entity work.UART_RX
    generic map (
      CLKS_PER_BIT => BASYS3_CLKS_PER_BIT)            
    port map (
      i_Rx_Clk     => clk,
      i_RX_Serial => RsRx,
      o_RX_DV     => w_RX_DV,
      o_RX_Byte   => w_RX_Byte
    );
 
  -- Creates a simple loopback to test TX and RX
  UART_Tx_Inst : entity work.UART_TX
    generic map (
      CLKS_PER_BIT => BASYS3_CLKS_PER_BIT) 
    port map (
      i_Tx_Clk       => clk,
      i_TX_DV     => w_RX_DV,
      i_TX_Byte   => w_RX_Byte,
      o_TX_Active => w_TX_Active,
      o_TX_Serial => w_TX_Serial,
      o_TX_Done   => open
    );
  -- Drive UART line high when transmitter is not active
  RsTx <= w_TX_Serial when w_TX_Active = '1' else '1';  

  SevenSeg_Inst : entity work.Seven_Segment_Display_Binary
    port map (
      i_Clock       => clk,
      i_Reset       => '0',
      i_Displayed   => (7 downto 0 => w_RX_Byte, others => '0'),
      o_Anodes      => an,
      o_Segments    => seg
      );
   
   -- At 1 clock cycle per pixel VGA Monito needs a clock rate of arounfd 25 MHz.
   -- The Basys 3 is clocked at 100MHz, so we need a clock divider to create a
   -- 25 MHz clock we can use with the VGA Modules.   
   VGA_Clock: entity work.Clock_Divider
   port map (
     i_Clk_In    => clk,
     i_Reset     => '0',
     o_Clock_Out => r_VGA_Clk
   );
  ------------------------------------------------------------------------------
  -- VGA Test Patterns
  ------------------------------------------------------------------------------
  -- Purpose: Set the index of the test pattern we will display from the incoming
  -- UART Rx
  -- Only least significant 4 bits are needed from whole byte.
  p_TP_Index : process (clk)
  begin
    if rising_edge(clk) then
      if w_RX_DV = '1' then
        r_TP_Index <= w_RX_Byte(3 downto 0);
      end if;
     end if;
  end process p_TP_Index;
   
  -- Get Sync pulses from counter and wire them up to the 
  -- internal horizontal/vertical sync pulse signals  
  VGA_Sync_Pulses_inst : entity work.VGA_Sync_Pulses
    generic map (
      g_TOTAL_COLS  => TOTAL_COLS,
      g_TOTAL_ROWS  => TOTAL_ROWS,
      g_ACTIVE_COLS => ACTIVE_COLS,
      g_ACTIVE_ROWS => ACTIVE_ROWS
    )
    port map (
      i_Clk       => r_VGA_Clk,
      o_HSync     => w_HSync_VGA,
      o_VSync     => w_VSync_VGA,
      o_Col_Count => open,
      o_Row_Count => open
    );  
    
  Test_Pattern_Gen_inst : entity work.Test_Pattern_Generator
    generic map (
      g_Video_Width => VIDEO_WIDTH,
      g_TOTAL_COLS  => TOTAL_COLS,
      g_TOTAL_ROWS  => TOTAL_ROWS,
      g_ACTIVE_COLS => ACTIVE_COLS,
      g_ACTIVE_ROWS => ACTIVE_ROWS
      )
    port map (
      i_Clk       => r_VGA_Clk,
      i_Pattern   => r_TP_Index,
      i_HSync     => w_HSync_VGA,
      i_VSync     => w_VSync_VGA,
      --
      o_HSync     => w_HSync_TP,
      o_VSync     => w_VSync_TP,
      o_Red_Video => w_Red_Video_TP,
      o_Blue_Video => w_Blue_Video_TP,
      o_Green_Video => w_Green_Video_TP
      );
   
  VGA_Sync_Porch_Inst : entity work.VGA_Sync_Porch
    generic map (
      g_Video_Width => VIDEO_WIDTH,
      g_TOTAL_COLS  => TOTAL_COLS,
      g_TOTAL_ROWS  => TOTAL_ROWS,
      g_ACTIVE_COLS => ACTIVE_COLS,
      g_ACTIVE_ROWS => ACTIVE_ROWS 
      )
    port map (
      i_Clk       => r_VGA_Clk,
      i_HSync     => w_HSync_VGA,
      i_VSync     => w_VSync_VGA,
      i_Red_Video => w_Red_Video_TP,
      i_Grn_Video => w_Blue_Video_TP,
      i_Blu_Video => w_Green_Video_TP,
      --
      o_HSync     => w_HSync_Porch,
      o_VSync     => w_VSync_Porch,
      o_Red_Video => w_Red_Video_Porch,
      o_Grn_Video => w_Blue_Video_Porch,
      o_Blu_Video => w_Green_Video_Porch
      );  
      
  HSync <= w_HSync_Porch;
  VSync <= w_VSync_Porch;
       
  vgaRed <= w_Red_Video_Porch;
  vgaGreen <= w_Green_Video_Porch;
  vgaBlue <= w_Blue_Video_Porch;
end RTL;
