library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity mem is
  generic (
    MEM_SIZE : natural := 4 * 1024);

  port (
    clk  : in std_logic;
    nres : in std_logic;

    addr  : in  std_logic_vector(31 downto 0);
    rdata : out std_logic_vector(31 downto 0);
    wdata : in  std_logic_vector(31 downto 0);
    wstrb : in  std_logic_vector(3 downto 0);
    valid : in  std_logic;
    ready : out std_logic
    );
end entity;

architecture rtl of mem is
  constant COL_WIDTH : integer := 8;
  constant NUM_COLS : integer := 4;

  type ram_t is array (MEM_SIZE-1 downto 0) of std_logic_vector(NUM_COLS*COL_WIDTH - 1 downto 0);

  signal mem_cs : ram_t := (others => (others => '0'));

  signal rdata_cs : std_logic_vector(31 downto 0) := (others => '0');
  signal ready_cs : std_logic := '0';
begin
  seq : process (clk) is
    variable ready_v : std_logic;
    variable addr_v  : integer;
    variable rdata_v : std_logic_vector(31 downto 0);
  begin  -- process seq
    if clk'event and clk = '1' then  -- rising clock edge
      ready_v := '0';
      addr_v  := to_integer(unsigned(addr(16 downto 2)));
      rdata_v := (others => '0');

      if valid = '1' then
        for i in 0 to NUM_COLS-1 loop
          if wstrb(i) = '1' then
            mem_cs(addr_v)((i+1)*COL_WIDTH-1 downto i*COL_WIDTH) <= wdata((i+1)*COL_WIDTH-1 downto i*COL_WIDTH);
          end if;
        end loop;

        ready_v := '1';
        rdata_v := mem_cs(addr_v);
      end if;

      ready_cs <= ready_v;
      rdata_cs <= rdata_v;
    end if;
  end process seq;

  ready <= ready_cs;
  rdata <= rdata_cs;
end architecture;
