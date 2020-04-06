library ieee;
use ieee.std_logic_1164.all;
use work.rv32_pkg.all;

entity tb_debug is

end entity tb_debug;

architecture bhv of tb_debug is
  constant halfClkPeriod : time := 10 ns;
  constant clkPeriod : time := 2 * halfClkPeriod;

  signal clk : std_logic := '0';
  signal nres : std_logic := '0';

  signal sim_done : boolean := false;

  signal spi_cs : std_logic := '0';
  signal spi_clk : std_logic := '0';
  signal spi_mosi : std_logic := '0';
  signal spi_miso : std_logic := '0';

  signal master : mem_bus;
begin  -- architecture bhv
  -- instance "debug_1"
  debug_1: entity work.debug
    port map (
      clk        => clk,
      nres       => nres,
      dbg_cs     => spi_cs,
      dbg_clk    => spi_clk,
      dbg_miso   => spi_miso,
      dbg_mosi   => spi_mosi,
      nres_out   => open,
      master_in  => master.to_master,
      master_out => master.from_master);

  clk_gen: process is
  begin
    while not sim_done loop
      clk <= '1';
      wait for halfClkPeriod;
      clk <= '0';
      wait for halfClkPeriod;
    end loop;

    wait;
  end process;

  nres_gen: process is
  begin
    nres <= '0';
    wait for halfClkPeriod * 3;
    nres <= '1';
    wait;
  end process;

  process is
    variable rx_data : std_logic_vector(8*(1+4+3*4)-1 downto 0);
  begin
    rx_data := X"00" & X"00000000" & X"ABCDEF12" & X"12345678" & X"0000FFFF";

    wait for 5 * halfClkPeriod;

    spi_cs <= '1';

    wait for 2 * clkPeriod;

    for i in rx_data'range loop
      wait for 4 * clkPeriod;
      spi_clk <= '0';
      spi_mosi <= rx_data(i);
      wait for 4 * clkPeriod;
      spi_clk <= '1';

      if i mod 8 = 0 and master.from_master.valid = '1' then
        master.to_master.ready <= '1';
      else
        master.to_master.ready <= '0';
      end if;
    end loop;

    wait until rising_edge(clk);
    wait until rising_edge(clk);
    wait for halfClkPeriod;

    sim_done <= true;

    wait;
  end process;
end architecture bhv;
