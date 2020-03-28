library ieee;
use ieee.std_logic_1164.all;

use work.rv32_pkg.all;

entity spi_slave is
  port (
    clk  : in std_logic;
    nres : in std_logic;

    spi_cs : in std_logic;
    spi_clk : in std_logic;
    spi_miso : out std_logic;
    spi_mosi : in std_logic;

    rx_fifo : out std_logic_vector(7 downto 0);
    tx_fifo : in std_logic_vector(7 downto 0);

    fifo_ready : out std_logic);
end entity spi_slave;

architecture rtl of spi_slave is
  constant FIFO_SIZE : natural := 8;
  constant FIFO_MSB : natural := FIFO_SIZE - 1;

  signal rx_fifo_cs : std_logic_vector(FIFO_MSB downto 0) := (others => '0');
  signal rx_fifo_ns : std_logic_vector(FIFO_MSB downto 0);
  signal tx_fifo_cs : std_logic_vector(FIFO_MSB downto 0) := (others => '0');
  signal tx_fifo_ns : std_logic_vector(FIFO_MSB downto 0);

  signal fifo_idx_cs : natural;
  signal fifo_idx_ns : natural;
  signal fifo_ready_cs : std_logic;
  signal fifo_ready_ns : std_logic;

  signal spi_cs_prev_cs : std_logic;
  signal spi_cs_prev_ns : std_logic;
  signal spi_cs_cs : std_logic;
  signal spi_cs_ns : std_logic;
  signal spi_clk_prev_cs : std_logic;
  signal spi_clk_prev_ns : std_logic;
  signal spi_clk_cs : std_logic;
  signal spi_clk_ns : std_logic;

  signal spi_miso_cs : std_logic;
  signal spi_miso_ns : std_logic;
  signal spi_mosi_cs : std_logic;
  signal spi_mosi_ns : std_logic;
begin  -- architecture rtl
  reg: process (clk, nres) is
  begin  -- process reg
    if clk'event and clk = '1' then  -- rising clock edge
      if nres = '0' then
        spi_cs_cs <= '0';
        spi_cs_prev_cs <= '0';
        spi_clk_cs <= '0';
        spi_clk_prev_cs <= '0';
        spi_miso_cs <= '0';
        spi_mosi_cs <= '0';

        rx_fifo_cs <= (others => '0');
        tx_fifo_cs <= (others => '0');
        fifo_idx_cs <= 0;
        fifo_ready_cs <= '0';
      else
        spi_cs_cs <= spi_cs_ns;
        spi_cs_prev_cs <= spi_cs_prev_ns;
        spi_clk_cs <= spi_clk_ns;
        spi_clk_prev_cs <= spi_clk_prev_ns;
        spi_miso_cs <= spi_miso_ns;
        spi_mosi_cs <= spi_mosi_ns;

        rx_fifo_cs <= rx_fifo_ns;
        tx_fifo_cs <= tx_fifo_ns;
        fifo_idx_cs <= fifo_idx_ns;
        fifo_ready_cs <= fifo_ready_ns;
      end if;
    end if;
  end process reg;

  comb: process (spi_cs_cs, spi_cs_prev_cs, spi_clk_cs, spi_clk_prev_ns, spi_miso_cs, spi_mosi_cs, fifo_idx_cs, rx_fifo_cs, tx_fifo_cs) is
    variable spi_cs_edge_v : std_logic;
    variable spi_clk_edge_v : std_logic;

    variable spi_miso_v : std_logic;
    variable rx_fifo_v : std_logic_vector(FIFO_MSB downto 0);
    variable fifo_idx_v : natural;
    variable fifo_ready_v : std_logic;
  begin  -- process comb
    spi_cs_edge_v := not spi_cs_prev_cs and spi_cs_cs;
    spi_clk_edge_v := not spi_clk_prev_cs and spi_clk_cs;

    spi_miso_v := spi_miso_cs;

    rx_fifo_v := rx_fifo_cs;
    fifo_idx_v := fifo_idx_cs;
    fifo_ready_v := '0';

    if spi_cs_edge_v = '1' then
      fifo_idx_v := FIFO_MSB;
    end if;

    if spi_clk_edge_v = '1' then
      rx_fifo_v(fifo_idx_v) := spi_mosi_cs;
      spi_miso_v := tx_fifo_cs(fifo_idx_v);

      if fifo_idx_v = 0 then
        fifo_idx_v := FIFO_MSB;
        fifo_ready_v := '1';
      else
        fifo_idx_v := fifo_idx_v - 1;
      end if;
    end if;

    spi_cs_prev_ns <= spi_cs_cs;
    spi_clk_prev_ns <= spi_clk_cs;
    spi_miso_ns <= spi_miso_v;

    rx_fifo_ns <= rx_fifo_v;
    fifo_idx_ns <= fifo_idx_v;
    fifo_ready_ns <= fifo_ready_v;
  end process comb;

  spi_cs_ns <= spi_cs;
  spi_clk_ns <= spi_clk;
  spi_mosi_ns <= spi_mosi;
  spi_miso <= spi_miso_cs;

  rx_fifo <= rx_fifo_cs;
  tx_fifo_ns <= tx_fifo;

  fifo_ready <= fifo_ready_cs;
end architecture rtl;
