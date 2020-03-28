library ieee;
use ieee.std_logic_1164.all;
use work.rv32_pkg.all;

entity tb_spi_core is

end entity tb_spi_core;

architecture bhv of tb_spi_core is
  constant halfClkPeriod : time := 10 ns;
  constant clkPeriod : time := 2 * halfClkPeriod;

  signal clk : std_logic := '0';
  signal nres : std_logic := '0';

  signal spi_cs : std_logic := '0';
  signal spi_clk : std_logic := '0';
  signal spi_mosi : std_logic := '0';
  signal spi_miso : std_logic := '0';

  signal rx_fifo : std_logic_vector(7 downto 0) := (others => '0');
  signal tx_fifo : std_logic_vector(7 downto 0) := (others => '0');
  signal fifo_ready : std_logic := '0';
begin  -- architecture bhv
  -- instance "spi_slave_1"
  spi_slave_1: entity work.spi_slave
    port map (
      clk        => clk,
      nres       => nres,
      spi_cs     => spi_cs,
      spi_clk    => spi_clk,
      spi_miso   => spi_miso,
      spi_mosi   => spi_mosi,
      rx_fifo    => rx_fifo,
      tx_fifo    => tx_fifo,
      fifo_ready => fifo_ready);

  clk_gen: process is
  begin
    loop
      clk <= '1';
      wait for halfClkPeriod;
      clk <= '0';
      wait for halfClkPeriod;
    end loop;
  end process;

  nres_gen: process is
  begin
    nres <= '0';
    wait for halfClkPeriod * 3;
    nres <= '1';
    wait;
  end process;

  process is
    variable rx_data : std_logic_vector(7 downto 0);
  begin
    rx_data := "01011100";
    tx_fifo <= "11001010";

    wait for 5 * halfClkPeriod;

    spi_cs <= '1';

    wait for 2 * clkPeriod;

    assert fifo_ready = '0';

    for i in 7 downto 0 loop
      wait for 4 * clkPeriod;
      spi_clk <= '0';
      spi_mosi <= rx_data(i);
      wait for 4 * clkPeriod;
      spi_clk <= '1';
    end loop;

    wait until rising_edge(clk);
    wait until rising_edge(clk);
    wait for halfClkPeriod;

    assert fifo_ready = '1' report "fifo is not ready";
    assert rx_fifo = rx_data report "rx_fifo content wrong";

    rx_data := "11110000";
    tx_fifo <= "00001111";

    for i in 7 downto 0 loop
      wait for 4 * clkPeriod;
      spi_clk <= '0';
      spi_mosi <= rx_data(i);
      wait for 4 * clkPeriod;
      spi_clk <= '1';
    end loop;

    wait until rising_edge(clk);
    wait until rising_edge(clk);
    wait for halfClkPeriod;

    assert fifo_ready = '1' report "fifo is not ready";
    assert rx_fifo = rx_data report "rx_fifo content wrong";

    wait;
  end process;
end architecture bhv;
