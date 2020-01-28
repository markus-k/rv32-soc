library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity top is
  port (
    clk_50 : in std_logic;
    nres   : in std_logic;

    led  : out std_logic_vector(7 downto 0);
    gpio : inout std_logic_vector(31 downto 0);

    trap : out std_logic
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

  signal ram_ready : std_logic;
  signal ram_rdata : std_logic_vector(31 downto 0);
  signal ram_valid : std_logic;
  signal ram_addr  : std_logic_vector(31 downto 0);
  signal ram_wdata : std_logic_vector(31 downto 0);
  signal ram_wstrb : std_logic_vector(3 downto 0);

  signal rom_ready : std_logic;
  signal rom_rdata : std_logic_vector(31 downto 0);
  signal rom_valid : std_logic;
  signal rom_addr  : std_logic_vector(31 downto 0);
  signal rom_wdata : std_logic_vector(31 downto 0);
  signal rom_wstrb : std_logic_vector(3 downto 0);

  signal mem_la_read  : std_logic;
  signal mem_la_write : std_logic;
  signal mem_la_addr  : std_logic_vector(31 downto 0);
  signal mem_la_wdata : std_logic_vector(31 downto 0);
  signal mem_la_wstrb : std_logic_vector(3 downto 0);

  signal mem_ready : std_logic;
  signal mem_rdata : std_logic_vector(31 downto 0);
  signal mem_valid : std_logic;
  signal mem_instr : std_logic;
  signal mem_addr  : std_logic_vector(31 downto 0);
  signal mem_wdata : std_logic_vector(31 downto 0);
  signal mem_wstrb : std_logic_vector(3 downto 0);

  signal iomem_ready : std_logic;
  signal iomem_rdata : std_logic_vector(31 downto 0);
  signal iomem_valid : std_logic;
  signal iomem_addr  : std_logic_vector(31 downto 0);
  signal iomem_wdata : std_logic_vector(31 downto 0);
  signal iomem_wstrb : std_logic_vector(3 downto 0);

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
      addr  => ram_addr,
      rdata => ram_rdata,
      wdata => ram_wdata,
      wstrb => ram_wstrb,
      valid => ram_valid,
      ready => ram_ready);

  bootrom_1 : entity work.rom
    port map (
      clk   => clk,
      nres  => nres,
      addr  => rom_addr,
      rdata => rom_rdata,
      wdata => rom_wdata,
      wstrb => rom_wstrb,
      valid => rom_valid,
      ready => rom_ready);

  -- instance "gpio_1"
  gpio_1 : entity work.gpio
    port map (
      clk         => clk,
      nres        => nres,
      iomem_addr  => iomem_addr,
      iomem_rdata => iomem_rdata,
      iomem_wdata => iomem_wdata,
      iomem_wstrb => iomem_wstrb,
      iomem_valid => iomem_valid,
      iomem_ready => iomem_ready,
      gpio_out    => gpio_out,
      gpio_in     => gpio_in,
      gpio_dir    => gpio_dir);

  -- instance "picorv32_1"
  picorv32_1 : entity work.picorv32
    port map (
      clk    => clk,
      resetn => nres,

      mem_ready => mem_ready,
      mem_rdata => mem_rdata,
      mem_valid => mem_valid,
      mem_instr => mem_instr,
      mem_addr  => mem_addr,
      mem_wdata => mem_wdata,
      mem_wstrb => mem_wstrb,

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

  -- purpose: memory bus arbiter
  -- type   : combinational
  -- inputs : mem_addr
  -- outputs:
  --
  -- Address low | Address high | Peripheral
  -- 0x00000000  | 0x00000fff   | ROM
  -- 0x20000000  | 0x20000fff   | RAM
  -- 0x40000000  | 0x4fffffff   | IO
  mem_arb : process (mem_addr, mem_valid, ram_rdata, ram_ready, rom_rdata, rom_ready, iomem_rdata, iomem_ready) is
  begin  -- process mem_arb
    iomem_valid <= '0';
    ram_valid   <= '0';
    rom_valid   <= '0';
    mem_rdata   <= (others => '0');
    mem_ready   <= '0';

    if mem_valid = '1' then
      if mem_addr(31 downto 12) = X"00000" then
        -- program space
        rom_valid <= '1';
        mem_rdata <= rom_rdata;
        mem_ready <= rom_ready;
      elsif mem_addr(31 downto 28) = X"2" then
        -- ram space
        ram_valid <= '1';
        mem_rdata <= ram_rdata;
        mem_ready <= ram_ready;
      elsif mem_addr(31 downto 28) = X"4" then
        -- peripheral space
        iomem_valid <= '1';
        mem_rdata <= iomem_rdata;
        mem_ready <= iomem_ready;
      else
        -- invalid memory region
      end if;
    end if;
  end process mem_arb;

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

  iomem_addr  <= mem_addr;
  iomem_wdata <= mem_wdata;
  iomem_wstrb <= mem_wstrb;

  ram_addr  <= mem_addr;
  ram_wdata <= mem_wdata;
  ram_wstrb <= mem_wstrb;

  rom_addr <= mem_addr;
  rom_wdata <= mem_wdata;
  rom_wstrb <= mem_wstrb;

  clk <= clk_50;

  led  <= gpio_out(7 downto 0);

  trap <= cpu_trap;

  irq <= (others => '0');
end architecture rtl;
