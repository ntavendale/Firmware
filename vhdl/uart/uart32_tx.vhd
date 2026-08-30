library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity uart32_tx is
  generic (
    -- Needs to be set correctly for clock and baud rate
    -- For Basys3 it's 100MHz cklock / 115200 baud rate.
    CLKS_PER_BIT : integer := 868     -- Needs to be set correctly
  );
  port (
    i_clk             : in  std_logic;
    i_data_valid      : in  std_logic; -- Driven high when data value in i_TX_Byte ready to be serialized
    i_data_to_send   : in  std_logic_vector(31 downto 0);
    o_transmitting    : out std_logic;
    o_serial_out      : out std_logic; -- Serial Output
    o_tx_done         : out std_logic
  );
end uart32_tx;

architecture rtl of uart32_tx is
  type t_TransmitState is (IDLE, TX_LOADING_BYTE, TX_TRANSMITTING_BYTE, TX_BYTE_SENT, CLEANUP);
  signal r_tx_state : t_TransmitState := IDLE;
  
  signal r_bytes_sent    : Integer range 0 to 3 := 0;
  signal r_data_to_send  : std_logic_vector(31 downto 0);
  signal r_output_byte   : std_logic_vector(7 downto 0);
  signal r_active_out    : std_logic := '0';
  signal r_transmitting  : std_logic := '0';
  signal r_byte_sent     : std_logic := '0';
  signal r_tx_data_valid : std_logic := '0';
  signal r_tx_done       : std_logic := '0'; 
  
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
    o_tx_done       : out std_logic
  );
end component;

begin
  uart_tx_0:  uart_tx
  generic map (
      CLKS_PER_BIT => CLKS_PER_BIT
    )  
    port map (
      i_clk => i_clk, 
      i_tx_data_valid => r_tx_data_valid, 
      i_tx_byte => r_output_byte,
      o_tx_active => r_active_out,
      o_tx_serial => o_serial_out, -- Serial Output
      o_tx_done => r_byte_sent
    );
      
  p_tx_out: process(i_clk)
  begin
    if rising_edge(i_clk) then
      case r_tx_state is
        when IDLE =>
          if (i_data_valid = '1') then
            r_data_to_send <= i_data_to_send;
            r_transmitting <= '1';
            r_tx_state <= TX_LOADING_BYTE;
          end if;
          
        when TX_LOADING_BYTE =>
          if (r_bytes_sent = 0) then
            r_output_byte <= r_data_to_send(7 downto 0);
          elsif (r_bytes_sent = 1) then
            r_output_byte <= r_data_to_send(15 downto 8);
          elsif (r_bytes_sent = 2) then
            r_output_byte <= r_data_to_send(23 downto 16);
          elsif (r_bytes_sent = 3) then
            r_output_byte <= r_data_to_send(31 downto 24); 
          end if;
          r_tx_data_valid <= '1';
          r_tx_state <= TX_TRANSMITTING_BYTE;
          
        when TX_TRANSMITTING_BYTE =>
          if (r_active_out = '0' and r_byte_sent = '1') then
            r_tx_state <= TX_BYTE_SENT; 
          end if;
          r_tx_data_valid <= '0';
        when TX_BYTE_SENT =>
          if (r_bytes_sent = 3) then
            r_bytes_sent <= 0;
            r_tx_done <= '1';
            r_tx_state <= CLEANUP;
          else  
            r_bytes_sent <= r_bytes_sent + 1;
            r_tx_state <= TX_LOADING_BYTE;
          end if;    
        
        when CLEANUP =>   
          r_bytes_sent <= 0;
          r_transmitting <= '0';
          r_tx_done <= '0';
          r_data_to_send <= (others => '0');
          r_tx_state <= IDLE;
          
        when others =>
          r_bytes_sent <= 0;
          r_transmitting <= '0';
          r_tx_done <= '0';
          r_data_to_send <= (others => '0');
          r_tx_state <= IDLE;
      end case;       
    end if;
  end process;
  
  o_transmitting <= r_transmitting;
  o_tx_done <= r_tx_done;
end rtl;
