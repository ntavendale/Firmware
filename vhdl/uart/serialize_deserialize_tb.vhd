library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use std.env.finish;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity serialize_deserialize_tb is
--  Port ( );
end serialize_deserialize_tb;

architecture Behavioral of serialize_deserialize_tb is
  component  uart_loopback is
    generic (
       BASYS3_CLKS_PER_BIT : integer := 6   -- Needs to be set correctly
    );
    port (
      clk   : in std_logic;
      -- UART Data
      RsRx : in  std_logic;
      RsTx : out std_logic;
      an   : out std_logic_vector (3 downto 0);
      seg  : out std_logic_vector (6 downto 0)
    );
  end component uart_loopback;

  constant c_CLKS_PER_BIT : integer := 6;
  constant c_BIT_PERIOD : time := 600 ns;
   
  signal r_CLOCK     : std_logic := '0';
  signal w_TX_SERIAL : std_logic;
  signal r_RX_SERIAL : std_logic := '1';
  
  -- Procedure for Low-level byte-write
  -- Takes in a byte and wites it out serially o_serial. 
  -- Stasrts with a start bit ands woith a stop bit, 
  -- so 10 bits written out, taking 10 clock cycles
  procedure UART_WRITE_BYTE(i_data_in : in  std_logic_vector(7 downto 0); signal o_serial : out std_logic) is
  begin
    -- Send Start Bit
    o_serial <= '0';
    wait for c_BIT_PERIOD;
    -- Send Data Byte
    for ii in 0 to 7 loop
      o_serial <= i_data_in(ii);
      wait for c_BIT_PERIOD;
    end loop;  -- ii
    -- Send Stop Bit
    o_serial <= '1';
    wait for c_BIT_PERIOD;
  end UART_WRITE_BYTE;

begin

TxRx : uart_loopback 
  generic map (
    BASYS3_CLKS_PER_BIT => c_CLKS_PER_BIT
  )
  port map (
    clk      => r_CLOCK,
    RsRx     => r_RX_SERIAL,
    RsTx     => w_TX_SERIAL,
    an       => open,
    seg      => open
  );
  
  r_CLOCK <= not r_CLOCK after 50 ns;
  
  process is
  begin
    -- Send a command to the UART
    wait until rising_edge(r_CLOCK);
      
    -- Write serial data to r_RX_SERIAL wich is wired to
    -- UART_RX 
    UART_WRITE_BYTE(X"3F", r_RX_SERIAL);
    
    
    for ii in 0 to 70 loop
      wait until rising_edge(r_CLOCK);
    end loop;
    finish;
  end process;

end Behavioral;
