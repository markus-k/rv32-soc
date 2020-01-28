library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity noptb is
end entity noptb;

architecture bhv of noptb is
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


  signal clk : std_logic := '0';
  signal nres : std_logic := '0';

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

  signal pcpi_valid : std_logic;
  signal pcpi_insn  : std_logic_vector(31 downto 0);
  signal pcpi_rs1   : std_logic_vector(31 downto 0);
  signal pcpi_rs2   : std_logic_vector(31 downto 0);

  signal irq : std_logic_vector(31 downto 0);
  signal eoi : std_logic_vector(31 downto 0);
  signal cpu_trap : std_logic;

  signal trace_valid : std_logic;
  signal trace_data : std_logic_vector(35 downto 0);
begin
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


  clk_gen: process is
  begin
    loop
      clk <= '1';
      wait for 10 ns;
      clk <= '0';
      wait for 10 ns;
    end loop;
  end process;

  nres_gen: process is
  begin
    nres <= '0';
    wait for 40 ns;
    nres <= '1';
    wait;
  end process;

  mem_rdata <= X"00000013";
  mem_ready <= '1';
  irq <= (others => '1');
end architecture bhv;
