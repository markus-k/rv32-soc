library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.rv32_pkg.all;

entity gpio is
  generic (
    BASE_ADDR : std_logic_vector(31 downto 0) := X"40000000";

    REG_OUT_OFFSET : integer := 0;
    REG_DIR_OFFSET : integer := 4;
    REG_IN_OFFSET : integer := 8
    );
  port (
    clk : in std_logic;
    nres : in std_logic;

    slave_in  : in  mem_bus_from_master;
    slave_out : out mem_bus_to_master;

    gpio_out : out std_logic_vector(31 downto 0);
    gpio_in : in std_logic_vector(31 downto 0);
    gpio_dir : out std_logic_vector(31 downto 0)
    );
end entity gpio;

architecture rtl of gpio is
  pure function reg_addr (
    reg : integer)
    return std_logic_vector is
  begin  -- function reg_addr
    return std_logic_vector(to_unsigned(to_integer(unsigned(BASE_ADDR)) + reg, BASE_ADDR'length));
  end function reg_addr;

  signal gpio_out_cs : std_logic_vector(31 downto 0);
  signal gpio_out_ns : std_logic_vector(31 downto 0);

  signal gpio_in_cs : std_logic_vector(31 downto 0);

  signal gpio_dir_cs : std_logic_vector(31 downto 0);
  signal gpio_dir_ns : std_logic_vector(31 downto 0);

  signal iomem_rdata_cs : std_logic_vector(31 downto 0);
  signal iomem_rdata_ns : std_logic_vector(31 downto 0);
  signal iomem_ready_cs : std_logic;
  signal iomem_ready_ns : std_logic;
begin
  seq: process (clk, nres) is
  begin  -- process seq
    if nres = '0' then                  -- asynchronous reset (active low)
      gpio_out_cs <= (others => '0');
      gpio_in_cs <= (others => '0');
      gpio_dir_cs <= (others => '0');

      iomem_rdata_cs <= (others => '0');
      iomem_ready_cs <= '0';
    elsif clk'event and clk = '1' then  -- rising clock edge
      gpio_out_cs <= gpio_out_ns;
      gpio_in_cs <= gpio_in;
      gpio_dir_cs <= gpio_dir_ns;

      iomem_rdata_cs <= iomem_rdata_ns;
      iomem_ready_cs <= iomem_ready_ns;
    end if;
  end process seq;

  comb: process (slave_in.addr, slave_in.wdata, slave_in.wstrb, slave_in.valid, gpio_out_cs, gpio_dir_cs, gpio_in_cs) is
    variable gpio_out_v : std_logic_vector(31 downto 0);
    variable gpio_dir_v : std_logic_vector(31 downto 0);

    variable iomem_ready_v : std_logic;
    variable iomem_rdata_v : std_logic_vector(31 downto 0);
  begin  -- process comb
    gpio_out_v := gpio_out_cs;
    gpio_dir_v := gpio_dir_cs;

    iomem_rdata_v := (others => '0');
    iomem_ready_v := '0';

    if slave_in.valid = '1' then
      if slave_in.wstrb = "1111" then
        -- only supports full dword access now

        case slave_in.addr is
          when reg_addr(REG_OUT_OFFSET) =>
            gpio_out_v := slave_in.wdata;
            iomem_ready_v := '1';
          when reg_addr(REG_DIR_OFFSET) =>
            gpio_dir_v := slave_in.wdata;
            iomem_ready_v := '1';
          when others =>
            null;
        end case;
      elsif slave_in.wstrb = "0000" then
        -- read

        case slave_in.addr is
          when reg_addr(REG_OUT_OFFSET) =>
            iomem_rdata_v := gpio_out_v;
            iomem_ready_v := '1';
          when reg_addr(REG_DIR_OFFSET) =>
            iomem_rdata_v := gpio_dir_v;
            iomem_ready_v := '1';
          when reg_addr(REG_IN_OFFSET) =>
            iomem_rdata_v := gpio_in_cs;
            iomem_ready_v := '1';
          when others =>
            null;
        end case;
      end if;
    end if;

    gpio_out_ns <= gpio_out_v;
    gpio_dir_ns <= gpio_dir_v;

    iomem_rdata_ns <= iomem_rdata_v;
    iomem_ready_ns <= iomem_ready_v;
  end process comb;

  slave_out.rdata <= iomem_rdata_cs;
  slave_out.ready <= iomem_ready_cs;

  gpio_out <= gpio_out_cs;
  gpio_dir <= gpio_dir_cs;
end architecture;
