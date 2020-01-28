library ieee;
use ieee.std_logic_1164.all;

entity top is
  port (
    clk_50 : in std_logic;
    nres   : in std_logic;

    gpio : out std_logic_vector(32 downto 0)
    );
end entity top;


architecture rtl of top is
  component picorv32_axi
    port (
      clk             : in  std_logic;
      resetn          : in  std_logic;
      trap            : out std_logic;

      -- AXI4-lite master interface
      mem_axi_awvalid : out std_logic;
      mem_axi_awready : in  std_logic;
      mem_axi_awaddr  : out std_logic_vector(31 downto 0);
      mem_axi_awprot  : out std_logic_vector(2 downto 0);

      mem_axi_wvalid  : out std_logic;
      mem_axi_wready  : in  std_logic;
      mem_axi_wdata   : out std_logic_vector(31 downto 0);
      mem_axi_wstrb   : out std_logic_vector(3 downto 0);

      mem_axi_bvalid  : in  std_logic;
      mem_axi_bready  : out std_logic;

      mem_axi_arvalid : out std_logic;
      mem_axi_arready : in  std_logic;
      mem_axi_araddr  : out std_logic_vector(31 downto 0);
      mem_axi_arprot  : out std_logic_vector(2 downto 0);

      mem_axi_rvalid  : in  std_logic;
      mem_axi_rready  : out std_logic;
      mem_axi_rdata   : in  std_logic_vector(31 downto 0);

      -- IRQ interface
      irq             : in  std_logic_vector(31 downto 0);
      eoi             : out std_logic_vector(31 downto 0);

      -- co-processor interface
      pcpi_wr         : in  std_logic;
      pcpi_rd         : in  std_logic_vector(31 downto 0);
      pcpi_wait       : in  std_logic;
      pcpi_ready      : in  std_logic;
      pcpi_valid      : out std_logic;
      pcpi_insn       : out std_logic_vector(31 downto 0);
      pcpi_rs1        : out std_logic_vector(31 downto 0);
      pcpi_rs2        : out std_logic_vector(31 downto 0);

      -- trace interface
      trace_valid     : out std_logic;
      trace_data      : out std_logic_vector(35 downto 0)
      );
  end component;

  signal clk : std_logic;

  signal mem_axi_awready : std_logic;
  signal mem_axi_wready  : std_logic;
  signal mem_axi_bvalid  : std_logic;
  signal mem_axi_arready : std_logic;
  signal mem_axi_rvalid  : std_logic;
  signal mem_axi_rdata   : std_logic_vector(31 downto 0);
  signal pcpi_wr         : std_logic;
  signal pcpi_rd         : std_logic_vector(31 downto 0);
  signal pcpi_wait       : std_logic;
  signal pcpi_ready      : std_logic;
  signal irq             : std_logic_vector(31 downto 0);
  signal trap            : std_logic;
  signal mem_axi_awvalid : std_logic;
  signal mem_axi_awaddr  : std_logic_vector(31 downto 0);
  signal mem_axi_awprot  : std_logic_vector(2 downto 0);
  signal mem_axi_wvalid  : std_logic;
  signal mem_axi_wdata   : std_logic_vector(31 downto 0);
  signal mem_axi_wstrb   : std_logic_vector(3 downto 0);
  signal mem_axi_bready  : std_logic;
  signal mem_axi_arvalid : std_logic;
  signal mem_axi_araddr  : std_logic_vector(31 downto 0);
  signal mem_axi_arprot  : std_logic_vector(2 downto 0);
  signal mem_axi_rready  : std_logic;
  signal pcpi_valid      : std_logic;
  signal pcpi_insn       : std_logic_vector(31 downto 0);
  signal pcpi_rs1        : std_logic_vector(31 downto 0);
  signal pcpi_rs2        : std_logic_vector(31 downto 0);
  signal eoi             : std_logic_vector(31 downto 0);
  signal trace_valid     : std_logic;
  signal trace_data      : std_logic_vector(35 downto 0);
begin
  clk <= clk_50;

  -- instance "picorv32_axi_1"
  picorv32_axi_1 : entity work.picorv32_axi
    port map (
      clk             => clk,
      resetn          => nres,
      mem_axi_awready => mem_axi_awready,
      mem_axi_wready  => mem_axi_wready,
      mem_axi_bvalid  => mem_axi_bvalid,
      mem_axi_arready => mem_axi_arready,
      mem_axi_rvalid  => mem_axi_rvalid,
      mem_axi_rdata   => mem_axi_rdata,
      pcpi_wr         => pcpi_wr,
      pcpi_rd         => pcpi_rd,
      pcpi_wait       => pcpi_wait,
      pcpi_ready      => pcpi_ready,
      irq             => irq,
      trap            => trap,
      mem_axi_awvalid => mem_axi_awvalid,
      mem_axi_awaddr  => mem_axi_awaddr,
      mem_axi_awprot  => mem_axi_awprot,
      mem_axi_wvalid  => mem_axi_wvalid,
      mem_axi_wdata   => mem_axi_wdata,
      mem_axi_wstrb   => mem_axi_wstrb,
      mem_axi_bready  => mem_axi_bready,
      mem_axi_arvalid => mem_axi_arvalid,
      mem_axi_araddr  => mem_axi_araddr,
      mem_axi_arprot  => mem_axi_arprot,
      mem_axi_rready  => mem_axi_rready,
      pcpi_valid      => pcpi_valid,
      pcpi_insn       => pcpi_insn,
      pcpi_rs1        => pcpi_rs1,
      pcpi_rs2        => pcpi_rs2,
      eoi             => eoi,
      trace_valid     => trace_valid,
      trace_data      => trace_data);
end architecture rtl;
