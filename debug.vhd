library ieee;
use ieee.std_logic_1164.all;

use work.rv32_pkg.all;

entity debug is
  port (
    clk  : in std_logic;
    nres : in std_logic;

    dbg_cs : in std_logic;
    dbg_clk : in std_logic;
    dbg_miso : out std_logic;
    dbg_mosi : in std_logic;

    nres_out : out std_logic;

    master_in : in mem_bus_to_master;
    master_out : out mem_bus_from_master);
end entity debug;

architecture rtl of debug is
  type debug_state_t is (START, WRITE_MEMORY_ADDRESS, WRITE_MEMORY_DATA);

  signal rx_fifo : std_logic_vector(7 downto 0);
  signal tx_fifo : std_logic_vector(7 downto 0);

  signal fifo_ready : std_logic;

  signal write_mem_idx_cs : natural range 0 to 3;
  signal write_mem_idx_ns : natural range 0 to 3;

  signal master_out_cs : mem_bus_from_master;
  signal master_out_ns : mem_bus_from_master;

  signal state_ns : debug_state_t;
  signal state_cs : debug_state_t;
begin  -- architecture rtl
  -- instance "spi_slave_1"
  spi_slave_1: entity work.spi_slave
    port map (
      clk        => clk,
      nres       => nres,
      spi_cs     => dbg_cs,
      spi_clk    => dbg_clk,
      spi_miso   => dbg_miso,
      spi_mosi   => dbg_mosi,
      rx_fifo    => rx_fifo,
      tx_fifo    => tx_fifo,
      fifo_ready => fifo_ready);

  reg: process (clk, nres) is
  begin  -- process reg
    if clk'event and clk = '1' then  -- rising clock edge
      if nres = '0' then
        state_cs <= START;

        write_mem_idx_cs <= 0;

        master_out_cs.valid <= '0';
        master_out_cs.addr <= (others => '0');
        master_out_cs.wdata <= (others => '0');
        master_out_cs.wstrb <= (others => '0');
      else
        state_cs <= state_ns;

        write_mem_idx_cs <= write_mem_idx_ns;

        master_out_cs.valid <= master_out_ns.valid;
        master_out_cs.addr <= master_out_ns.addr;
        master_out_cs.wdata <= master_out_ns.wdata;
        master_out_cs.wstrb <= master_out_ns.wstrb;
      end if;
    end if;
  end process reg;

  comb: process (state_cs, fifo_ready, write_mem_idx_cs, master_out_cs) is
    variable state_v : debug_state_t;
    variable write_mem_idx_v : natural;

    variable master_out_v : mem_bus_from_master;
  begin  -- process comb
    state_v := state_cs;
    write_mem_idx_v := write_mem_idx_cs;
    master_out_v := master_out_cs;

    if master_in.ready = '1' then
      master_out_v.valid := '0';
      master_out_v.wstrb := "0000";
    end if;

    if fifo_ready = '1' then
      case state_cs is
        when START =>
          if rx_fifo = X"00" then
            state_v := WRITE_MEMORY_ADDRESS;
          end if;

        when WRITE_MEMORY_ADDRESS =>
          case write_mem_idx_v is
            when 3 =>
              master_out_v.addr(7 downto 0) := rx_fifo;
            when 2 =>
              master_out_v.addr(15 downto 8) := rx_fifo;
            when 1 =>
              master_out_v.addr(23 downto 16) := rx_fifo;
            when 0 =>
              master_out_v.addr(31 downto 24) := rx_fifo;
            when others =>
              report "memory address byte index out of bounds";
          end case;

          if write_mem_idx_v = 3 then
            state_v := WRITE_MEMORY_DATA;
            write_mem_idx_v := 0;
          else
            write_mem_idx_v := write_mem_idx_v + 1;
          end if;

        when WRITE_MEMORY_DATA =>
          case write_mem_idx_v is
            when 3 =>
              master_out_v.wdata(7 downto 0) := rx_fifo;
            when 2 =>
              master_out_v.wdata(15 downto 8) := rx_fifo;
            when 1 =>
              master_out_v.wdata(23 downto 16) := rx_fifo;
            when 0 =>
              master_out_v.wdata(31 downto 24) := rx_fifo;
            when others =>
              report "memory data byte index out of bounds";
          end case;

          if write_mem_idx_v = 3 then
            master_out_v.valid := '1';
            master_out_v.wstrb := "1111";
            write_mem_idx_v := 0;
          else
            master_out_v.valid := '0';
            master_out_v.wstrb := "0000";
            write_mem_idx_v := write_mem_idx_v + 1;
          end if;
      end case;
    end if;

    state_ns <= state_v;
    write_mem_idx_ns <= write_mem_idx_v;
    master_out_ns <= master_out_v;
  end process comb;

  master_out <= master_out_cs;
end architecture rtl;
