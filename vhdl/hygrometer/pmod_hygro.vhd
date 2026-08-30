--------------------------------------------------------------------------------
--
--   FileName:         pmod_hygrometer.vhd
--   Dependencies:     i2c_master.vhd (Version 2.2)
--   Design Software:  Quartus Prime Version 17.0.0 Build 595 SJ Lite Edition
--
--   HDL CODE IS PROVIDED "AS IS."  DIGI-KEY EXPRESSLY DISCLAIMS ANY
--   WARRANTY OF ANY KIND, WHETHER EXPRESS OR IMPLIED, INCLUDING BUT NOT
--   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
--   PARTICULAR PURPOSE, OR NON-INFRINGEMENT. IN NO EVENT SHALL DIGI-KEY
--   BE LIABLE FOR ANY INCIDENTAL, SPECIAL, INDIRECT OR CONSEQUENTIAL
--   DAMAGES, LOST PROFITS OR LOST DATA, HARM TO YOUR EQUIPMENT, COST OF
--   PROCUREMENT OF SUBSTITUTE GOODS, TECHNOLOGY OR SERVICES, ANY CLAIMS
--   BY THIRD PARTIES (INCLUDING BUT NOT LIMITED TO ANY DEFENSE THEREOF),
--   ANY CLAIMS FOR INDEMNITY OR CONTRIBUTION, OR OTHER SIMILAR COSTS.
--
--   Version History
--   Version 1.0 05/04/2020 Scott Larson
--     Initial Public Release
-- 
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity pmod_hygrometer is
  generic (
    sys_clk_freq            : Integer := 100_000_000;       --input clock speed from user logic in Hz
    HUMIDITY_RESOLUTION     : Integer range 0 to 14 := 14;  --RH resolution in bits (must be 14, 11, or 8)
    TEMPERATURE_RESOLUTION  : Integer range 0 to 14 := 14); --temperature resolution in bits (must be 14 or 11)
  port (
    clk               : in    std_logic;                                               --system clock
    reset_n           : in    std_logic;                                               --asynchronous active-low reset
    temp_resolution   : in    std_logic_vector(7 downto 0);                            -- user set temp resolution 
    humid_resolution  : in    std_logic_vector(7 downto 0);                            -- user set humid resolution
    scl               : inout std_logic;                                               --I2C serial clock
    sda               : inout std_logic;                                               --I2C serial data
    i2c_ack_err       : out   std_logic;                                               --I2C slave acknowledge error flag
    relative_humidity : out   std_logic_vector(HUMIDITY_RESOLUTION - 1 downto 0);      --relative humidity data obtained
    temperature       : out   std_logic_vector(TEMPERATURE_RESOLUTION  - 1 downto 0)); --temperature data obtained
end pmod_hygrometer;

architecture rtl of pmod_hygrometer is
  constant c_HYGROMETER_ADDR : std_logic_vector(6 downto 0) := "1000000";         --I2C address of the hygrometer pmod
  type machine IS(start, configure, initiate, pause, read_data, output_result); --needed states
  signal state            : machine;                       --state machine
  signal i2c_ena          : std_logic;                     --i2c enable signal
  signal i2c_addr         : std_logic_vector(6 downto 0);  --i2c address signal
  signal i2c_rw           : std_logic;                     --i2c read/write command signal
  signal i2c_data_wr      : std_logic_vector(7 downto 0);  --i2c write data
  signal i2c_data_rd      : std_logic_vector(7 downto 0);  --i2c read data
  signal i2c_busy         : std_logic;                     --i2c busy signal
  signal busy_prev        : std_logic;                     --previous value of i2c busy signal
  signal rh_time          : Integer;                       --clock cycles needed for humidity measurement
  signal temp_time        : Integer;                       --clock cycles needed for temperature measurement
  signal rh_res_bits      : std_logic_vector(1 downto 0);  --bits to set humidity resolution in sensor register
  signal temp_res_bit     : std_logic;                     --bit to set temperature resolution in sensor register
  signal humidity_data    : std_logic_vector(15 downto 0); --humidity data buffer
  signal temperature_data : std_logic_vector(15 downto 0); --temperature data buffer
  
  signal r_humidity_resolution    : Integer range 0 to 14 := HUMIDITY_RESOLUTION;
  signal r_temperature_resolution : Integer range 0 to 14 := TEMPERATURE_RESOLUTION;

  component i2c_master IS
    generic (
      input_clk : Integer;  --input clock speed from user logic in Hz
      bus_clk   : Integer); --speed the i2c bus (scl) will run at in Hz
    port (
      clk       : in     std_logic;                    --system clock
      reset_n   : in     std_logic;                    --active low reset
      ena       : in     std_logic;                    --latch in command
      addr      : in     std_logic_vector(6 DOWNTO 0); --address of target slave
      rw        : in     std_logic;                    --'0' is write, '1' is read
      data_wr   : in     std_logic_vector(7 DOWNTO 0); --data to write to slave
      busy      : out    std_logic;                    --indicates transaction in progress
      data_rd   : out    std_logic_vector(7 DOWNTO 0); --data read from slave
      ack_error : buffer std_logic;                    --flag if improper acknowledge from slave
      sda       : inout  std_logic;                    --serial data output of i2c bus
      scl       : inout  std_logic);                   --serial clock output of i2c bus
  end component;

begin

  --instantiate the i2c master
  i2c_master_0:  i2c_master
    generic map (
      input_clk => sys_clk_freq, 
      bus_clk => 400_000)
    port map (
      clk => clk, 
      reset_n => reset_n, 
      ena => i2c_ena, 
      addr => i2c_addr,
      rw => i2c_rw, 
      data_wr => i2c_data_wr, 
      busy => i2c_busy,
      data_rd => i2c_data_rd, 
      ack_error => i2c_ack_err, 
      sda => sda,
      scl => scl);
      
  process_resolution: process(clk)
  begin
    if rising_edge(clk) then
      if temp_resolution = "1011" then
        r_temperature_resolution <= 11;
      else
        r_temperature_resolution <= TEMPERATURE_RESOLUTION;
      end if;
      if humid_resolution = "1000" then
        r_humidity_resolution <= 8;
      elsif humid_resolution = "1011" then
        r_humidity_resolution <= 11;
      else
        r_humidity_resolution <= HUMIDITY_RESOLUTION;
      end if;
    end if;  
  end process;    
               
  --determine the bits to set the relative humidity resolution in the sensor's configuration register
  with r_humidity_resolution select
    rh_res_bits <= "10" when 8,
                   "01" when 11,
                   "00" when others;             

  --determine the number of clock cycles required for a humidity measurement at the given resolution
  with r_humidity_resolution select
    rh_time <= sys_clk_freq/400 when 8,      --2.50ms
               sys_clk_freq/259 when 11,     --3.85ms
               sys_clk_freq/153 when others; --6.50ms
           
  --determine the bits to set the temperature resolution in the sensor's configuration register
  with r_temperature_resolution select
    temp_res_bit <= '1' when 11,
                    '0' when others;
              
  --determine the number of clock cycles required for a temperature measurement at the given resolution
  with r_temperature_resolution select
    temp_time <= sys_clk_freq/273 when 11,     --3.65ms
                 sys_clk_freq/157 when others; --6.35ms            
             
  process(clk, reset_n)
    variable busy_cnt   : Integer range 0 to 4 := 0;               --counts the I2C busy signal transistions
    variable pwr_up_cnt : Integer range 0 to sys_clk_freq/10 := 0; --counts 100ms to wait before communicating
    variable pause_cnt  : Integer;                                 --counter to wait for measurements to complete
  begin
  
    if (reset_n = '0') then                --reset activated
      pwr_up_cnt := 0;                      --clear power up counter
      i2c_ena <= '0';                       --clear I2C enable
      busy_cnt := 0;                        --clear busy counter
      pause_cnt := 0;                       --clear pause counter
      relative_humidity <= (others => '0'); --clear the relative humidity result output
      temperature <= (others => '0');       --clear the temperature result output
      state <= start;                       --return to start state

    elsif (clk'event and clk = '1') then    --rising edge of system clock
      case state is                         --state machine
      
        --give hygrometer 100ms to power up before communicating
        when start =>
          if (pwr_up_cnt < sys_clk_freq/10) then  --100ms not yet reached
            pwr_up_cnt := pwr_up_cnt + 1;          --increment power up counter
          else                                  --100ms reached
            pwr_up_cnt := 0;                       --clear power up counter
            state <= configure;                    --advance to configure the hygrometer
          end if;
        
        --configure the device (set acquisition mode to measure both temp & rh, and set resolutions)
        when configure =>
          busy_prev <= i2c_busy;                         --capture the value of the previous i2c busy signal
          if (busy_prev = '0' and i2c_busy = '1') then   --i2c busy just went high
            busy_cnt := busy_cnt + 1;                     --counts the times busy has gone from low to high during transaction
          end if;
          case busy_cnt is                                --busy_cnt keeps track of which command we are on
            when 0 =>                                     --no command latched in yet
              i2c_ena <= '1';                             --initiate the transaction
              i2c_addr <= c_HYGROMETER_ADDR;              --set the address of the hygrometer
              i2c_rw <= '0';                              --command 1 is a write
              i2c_data_wr <= "00000010";                  --set the register pointer to the Configuration Register
            when 1 =>                                     --1st busy high: command 1 latched, okay to issue command 2
              i2c_data_wr <= "00010" & temp_res_bit & rh_res_bits; --set acquisition mode and resolutions
            when 2 =>                                     --2nd busy high: command 2 latched
              i2c_data_wr <= "00000000";                  --send 2nd byte of Configuration Register
            when 3 =>                                     --3nd busy high: command 3 latched
              i2c_ena <= '0';                             --deassert enable to stop transaction after command 3
              if (i2c_busy = '0') then                     --transaction complete
                busy_cnt := 0;                            --reset busy_cnt for next transaction
                state <= initiate;                        --advance to the initiate state
              end if;
            when others => NULL;
          end case;
       
        --initiate the measurements
        when initiate =>
          busy_prev <= i2c_busy;                          --capture the value of the previous i2c busy signal
          if (busy_prev = '0' and i2c_busy = '1') then    --i2c busy just went high
            busy_cnt := busy_cnt + 1;                     --counts the times busy has gone from low to high during transaction
          end if;
          case busy_cnt is                                --busy_cnt keeps track of which command we are on
            when 0 =>                                     --no command latched in yet
              i2c_ena <= '1';                             --initiate the transaction
              i2c_addr <= c_HYGROMETER_ADDR;              --set the address of the hygrometer
              i2c_rw <= '0';                              --command 1 is a write
              i2c_data_wr <= "00000000";                  --set the register pointer to the Temperature Register
            when 1 =>                                     --1st busy high: command 1 latched
              i2c_ena <= '0';                             --deassert enable to stop transaction after command 1
              if (i2c_busy = '0') then                    --transaction complete
                busy_cnt := 0;                            --reset busy_cnt for next transaction
                state <= pause;                           --advance to the pause state
              end if;
            when others => NULL;
          end case;   
      
        --wait for humidity and temperature measurements to complete
        when pause =>
          if (pause_cnt < rh_time + temp_time) then  --measurement times not met
            pause_cnt := pause_cnt + 1;               --increment pause counter
          else                                      --measurement times met
            pause_cnt := 0;                           --reset pause counter
            state <= read_data;                       --advance to reading data results
          end if;
       
        --retreive the relative humidity and temperature measurement results 
        when read_data =>
          busy_prev <= i2c_busy;                              --capture the value of the previous i2c busy signal
          if (busy_prev = '0' and i2c_busy = '1') then        --i2c busy just went high
            busy_cnt := busy_cnt + 1;                         --counts the times busy has gone from low to high during transaction
          end if;
          case busy_cnt is                                    --busy_cnt keeps track of which command we are on
            when 0 =>                                         --no command latched in yet
              i2c_ena <= '1';                                 --initiate the transaction
              i2c_addr <= c_HYGROMETER_ADDR;                  --set the address of the hygrometer
              i2c_rw <= '1';                                  --command 1 is a read
            when 1 =>                                         --1st busy high: command 1 latched
              if (i2c_busy = '0') then                         --indicates data read in command 1 is ready
                temperature_data(15 downto 8) <= i2c_data_rd;  --retrieve temperature high-byte data from command 1
              end if;
            when 2 =>                                          --2nd busy high: command 2 latched
              if (i2c_busy = '0') then                         --indicates data read in command 2 is ready
                temperature_data(7 downto 0) <= i2c_data_rd;   --retrieve temperature low-byte data from command 2
              end if;
            when 3 =>                                          --3rd busy high: command 3 latched
              if (i2c_busy = '0') then                         --indicates data read in command 3 is ready
                humidity_data(15 downto 8) <= i2c_data_rd;     --retrieve humidity high-byte data from command 3
              end if;
            when 4 =>                                          --4th busy high: command 4 latched
              i2c_ena <= '0';                                  --deassert enable to stop transaction after command 4
              IF (i2c_busy = '0') then                         --indicates data read in command 4 is ready
                humidity_data(7 downto 0) <= i2c_data_rd;      --retrieve humidity low-byte data from command 4
                busy_cnt := 0;                                 --reset busy_cnt for next transaction
                state <= output_result;                        --advance to output the result
              end if;
            when others => NULL;
          end case;
  
        --output the relative humidity and temperature data
        when output_result =>
          relative_humidity <= humidity_data(15 downto 16 - r_humidity_resolution);  --write relative humidity data to output
          temperature <= temperature_data(15 downto 16 - r_temperature_resolution);  --write temperature data to output
          state <= initiate;                                                     --initiate next measurement

        --default to start state
        when others =>
          state <= start;

      END CASE;
    END IF;
  end process;  
end rtl;
