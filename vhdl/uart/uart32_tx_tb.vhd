library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.finish;

entity uart32_tx_tb is
--  Port ( );
end uart32_tx_tb;

architecture Behavioral of uart32_tx_tb is
  constant c_CYCLES_PER_BIT : Integer := 3;
  signal r_clock : std_logic := '0';
  
  signal r_data_valid   : std_logic;
  signal r_data_to_send : std_logic_vector(31 downto 0);
  signal r_transmitting : std_logic;
  signal r_serial_out   : std_logic; -- Serial Output
  signal r_tx_done      : std_logic;
begin
  r_clock <= not r_clock after 5 ns;
  
  Unit_Under_Test : entity work.uart32_tx
    generic map (
      CLKS_PER_BIT => c_CYCLES_PER_BIT
    )
    port map (
      i_clk          => r_clock,
      i_data_valid   => r_data_valid,
      i_data_to_send => r_data_to_send,
      o_transmitting => r_transmitting,
      o_serial_out   => r_serial_out,
      o_tx_done      => r_tx_done
   );
   
   test_process: process is
   begin
     r_data_to_send <= x"F0F0F0F0";  
     r_data_valid <= '1';
     wait until r_CLOCK = '1';
     r_data_valid <= '0'; 
     wait for 10000 ns;
     finish;
  end process;   
end Behavioral;
