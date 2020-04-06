library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.rv32_pkg.all;

entity top is
  port (
    clk_50 : in std_logic;
    nres   : in std_logic;

    led  : out std_logic_vector(7 downto 0);
    gpio : inout std_logic_vector(31 downto 0);

    trap : out std_logic;

    dbg_cs : in std_logic;
    dbg_clk : in std_logic;
    dbg_miso : out std_logic;
    dbg_mosi : in std_logic;

    -- sdram
    sdram_clk : out std_logic;
    sdram_clr : out std_logic;
    sdram_cs : out std_logic;
    sdram_cas : out std_logic;
    sdram_ras : out std_logic;
    sdram_we : out std_logic;
    sdram_dqm : out std_logic;
    sdram_bank : out std_logic_vector(1 downto 0);
    sdram_addr : out std_logic_vector(12 downto 0);
    sdram_dq : inout std_logic_vector(7 downto 0)
    );
end entity top;

architecture rtl of top is
  component picorv32
    generic (
      ENABLE_COUNTERS      : std_logic                     := '1';
      ENABLE_COUNTERS64    : std_logic                     := '1';
      ENABLE_REGS_16_31    : std_logic                     := '1';
      ENABLE_REGS_DUALPORT : std_logic                     := '1';
      LATCHED_MEM_RDATA    : std_logic                     := '0';
      TWO_STAGE_SHIFT      : std_logic                     := '1';
      BARREL_SHIFTER       : std_logic                     := '0';
      TWO_CYCLE_COMPARE    : std_logic                     := '0';
      TWO_CYCLE_ALU        : std_logic                     := '0';
      COMPRESSED_ISA       : std_logic                     := '0';
      CATCH_MISALIGN       : std_logic                     := '1';
      CATCH_ILLINSN        : std_logic                     := '1';
      ENABLE_PCPI          : std_logic                     := '0';
      ENABLE_MUL           : std_logic                     := '0';
      ENABLE_FAST_MUL      : std_logic                     := '0';
      ENABLE_DIV           : std_logic                     := '0';
      ENABLE_IRQ           : std_logic                     := '0';
      ENABLE_IRQ_QREGS     : std_logic                     := '1';
      ENABLE_IRQ_TIMER     : std_logic                     := '1';
      ENABLE_TRACE         : std_logic                     := '0';
      REGS_INIT_ZERO       : std_logic                     := '0';
      MASKED_IRQ           : std_logic_vector(31 downto 0) := X"00000000";
      LATCHED_IRQ          : std_logic_vector(31 downto 0) := X"ffffffff";
      PROGADDR_RESET       : std_logic_vector(31 downto 0) := X"00000000";
      PROGADDR_IRQ         : std_logic_vector(31 downto 0) := X"00000010";
      STACKADDR            : std_logic_vector(31 downto 0) := X"ffffffff"
      );
    port (
      clk          : in  std_logic;
      resetn       : in  std_logic;

      mem_ready    : in  std_logic;
      mem_rdata    : in  std_logic_vector(31 downto 0);
      mem_valid    : out std_logic;
      mem_instr    : out std_logic;
      mem_addr     : out std_logic_vector(31 downto 0);
      mem_wdata    : out std_logic_vector(31 downto 0);
      mem_wstrb    : out std_logic_vector(3 downto 0);

      mem_la_read  : out std_logic;
      mem_la_write : out std_logic;
      mem_la_addr  : out std_logic_vector(31 downto 0);
      mem_la_wdata : out std_logic_vector(31 downto 0);
      mem_la_wstrb : out std_logic_vector(3 downto 0);

      pcpi_wr      : in  std_logic;
      pcpi_rd      : in  std_logic_vector(31 downto 0);
      pcpi_wait    : in  std_logic;
      pcpi_ready   : in  std_logic;
      pcpi_valid   : out std_logic;
      pcpi_insn    : out std_logic_vector(31 downto 0);
      pcpi_rs1     : out std_logic_vector(31 downto 0);
      pcpi_rs2     : out std_logic_vector(31 downto 0);

      irq          : in  std_logic_vector(31 downto 0);
      eoi          : out std_logic_vector(31 downto 0);
      trap         : out std_logic;

      trace_valid  : out std_logic;
      trace_data   : out std_logic_vector(35 downto 0)
      );
  end component;

  signal clk : std_logic;

  signal nres_cpu : std_logic;
  signal nres_periph : std_logic;

  signal mem_la_read  : std_logic;
  signal mem_la_write : std_logic;
  signal mem_la_addr  : std_logic_vector(31 downto 0);
  signal mem_la_wdata : std_logic_vector(31 downto 0);
  signal mem_la_wstrb : std_logic_vector(3 downto 0);

  signal mem_instr : std_logic;

  -- memory busses
  signal cpu_mem_bus : mem_bus;
  signal debug_mem_bus : mem_bus;

  signal rom_mem_bus : mem_bus;
  signal ram_mem_bus : mem_bus;

  signal system_mem_bus : mem_bus;

  signal gpio_mem_bus : mem_bus;
  signal uart_mem_bus : mem_bus;

  signal pcpi_valid : std_logic;
  signal pcpi_insn  : std_logic_vector(31 downto 0);
  signal pcpi_rs1   : std_logic_vector(31 downto 0);
  signal pcpi_rs2   : std_logic_vector(31 downto 0);

  signal irq : std_logic_vector(31 downto 0);
  signal eoi : std_logic_vector(31 downto 0);
  signal cpu_trap : std_logic;

  signal trace_valid : std_logic;
  signal trace_data : std_logic_vector(35 downto 0);

  signal gpio_out : std_logic_vector(31 downto 0);
  signal gpio_in  : std_logic_vector(31 downto 0);
  signal gpio_dir  : std_logic_vector(31 downto 0);
begin
  -- instance "mem_1"
  mem_1 : entity work.mem
    port map (
      clk   => clk,
      nres  => nres,
      addr  => ram_mem_bus.from_master.addr,
      rdata => ram_mem_bus.to_master.rdata,
      wdata => ram_mem_bus.from_master.wdata,
      wstrb => ram_mem_bus.from_master.wstrb,
      valid => ram_mem_bus.from_master.valid,
      ready => ram_mem_bus.to_master.ready);

  bootrom_1 : entity work.rom
    port map (
      clk   => clk,
      nres  => nres,
      addr  => rom_mem_bus.from_master.addr,
      rdata => rom_mem_bus.to_master.rdata,
      wdata => rom_mem_bus.from_master.wdata,
      wstrb => rom_mem_bus.from_master.wstrb,
      valid => rom_mem_bus.from_master.valid,
      ready => rom_mem_bus.to_master.ready);

  -- instance "gpio_1"
  gpio_1 : entity work.gpio
    port map (
      clk         => clk,
      nres        => nres_periph,
      slave_in    => gpio_mem_bus.from_master,
      slave_out   => gpio_mem_bus.to_master,
      gpio_out    => gpio_out,
      gpio_in     => gpio_in,
      gpio_dir    => gpio_dir);

  -- instance "picorv32_1"
  picorv32_1 : entity work.picorv32
    port map (
      clk    => clk,
      resetn => nres_cpu,

      mem_ready => cpu_mem_bus.to_master.ready,
      mem_rdata => cpu_mem_bus.to_master.rdata,
      mem_valid => cpu_mem_bus.from_master.valid,
      mem_instr => mem_instr,
      mem_addr  => cpu_mem_bus.from_master.addr,
      mem_wdata => cpu_mem_bus.from_master.wdata,
      mem_wstrb => cpu_mem_bus.from_master.wstrb,

      mem_la_read  => mem_la_read,
      mem_la_write => mem_la_write,
      mem_la_addr  => mem_la_addr,
      mem_la_wdata => mem_la_wdata,
      mem_la_wstrb => mem_la_wstrb,

      pcpi_wr    => '0',
      pcpi_rd    => X"00000000",
      pcpi_wait  => '0',
      pcpi_ready => '0',
      pcpi_valid => pcpi_valid,
      pcpi_insn  => pcpi_insn,
      pcpi_rs1   => pcpi_rs1,
      pcpi_rs2   => pcpi_rs2,

      irq  => irq,
      eoi  => eoi,
      trap => cpu_trap,

      trace_valid => trace_valid,
      trace_data  => trace_data);

  -- instance "debug_1"
  debug_1: entity work.debug
    port map (
      clk        => clk,
      nres       => nres,
      dbg_cs     => dbg_cs,
      dbg_clk    => dbg_clk,
      dbg_miso   => dbg_miso,
      dbg_mosi   => dbg_mosi,
      nres_out   => open,
      master_in  => debug_mem_bus.to_master,
      master_out => debug_mem_bus.from_master);

  -- instance "interconnect_1"
  interconnect_1: entity work.interconnect
    generic map (
      master1_addr => X"00000000",
      master1_size => 24,
      master2_addr => X"20000000",
      master2_size => 16,
      master3_addr => X"40000000",
      master3_size => 4,
      master4_addr => X"41000000",
      master4_size => 4)
    port map (
      clock       => clk,
      nres        => nres,

      slave1_in   => system_mem_bus.from_master,
      slave1_out  => system_mem_bus.to_master,

      master1_in  => rom_mem_bus.to_master,
      master1_out => rom_mem_bus.from_master,
      master2_in  => ram_mem_bus.to_master,
      master2_out => ram_mem_bus.from_master,
      master3_in  => gpio_mem_bus.to_master,
      master3_out => gpio_mem_bus.from_master,
      master4_in  => uart_mem_bus.to_master,
      master4_out => uart_mem_bus.from_master);

  -- instance "bus_arb_1"
  bus_arb_1: entity work.bus_arb
    port map (
      clk         => clk,
      nres        => nres,
      slave1_in   => cpu_mem_bus.from_master,
      slave1_out  => cpu_mem_bus.to_master,
      slave2_in   => debug_mem_bus.from_master,
      slave2_out  => debug_mem_bus.to_master,
      master1_in  => system_mem_bus.to_master,
      master1_out => system_mem_bus.from_master);

  gpio_inout: process (gpio, gpio_out, gpio_dir) is
  begin
    for i in gpio'range loop
      if gpio_dir(i) = '1' then
        gpio(i) <= 'Z';
      else
        gpio(i) <= gpio_out(i);
      end if;

      gpio_in(i) <= gpio(i);
    end loop;
  end process gpio_inout;

  clk <= clk_50;

  led  <= gpio_out(7 downto 0);

  trap <= cpu_trap;

  irq <= (others => '0');

  nres_cpu <= nres;
  nres_periph <= nres;

  sdram_clk  <= 'Z';
  sdram_clr  <= 'Z';
  sdram_cs   <= 'Z';
  sdram_cas  <= 'Z';
  sdram_ras  <= 'Z';
  sdram_we   <= 'Z';
  sdram_dqm  <= 'Z';
  sdram_bank <= (others => 'Z');
  sdram_addr <= (others => 'Z');
  sdram_dq   <= (others => 'Z');
end architecture rtl;
