library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity rom is
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
end entity rom;

architecture rtl of rom is
  constant COL_WIDTH : integer := 8;
  constant NUM_COLS : integer := 4;

  type rom_t is array (MEM_SIZE-1 downto 0) of std_logic_vector(NUM_COLS*COL_WIDTH - 1 downto 0);

  impure function rom_init(filename : string) return rom_t is
    file rom_file : text open read_mode is filename;
    variable rom_line : line;
    variable rom_value : bit_vector(31 downto 0);
    variable temp : rom_t;
    variable swap : std_logic_vector(7 downto 0);
  begin
    temp := (others => (others => '0'));

    for rom_index in 0 to MEM_SIZE-1 loop
      if not endfile(rom_file) then
        readline(rom_file, rom_line);
        read(rom_line, rom_value);
        temp(rom_index) := to_stdlogicvector(rom_value);

        -- no idea why
        swap := temp(rom_index)(7 downto 0);
        temp(rom_index)(7 downto 0) := temp(rom_index)(31 downto 24);
        temp(rom_index)(31 downto 24) := swap;
        swap := temp(rom_index)(15 downto 8);
        temp(rom_index)(15 downto 8) := temp(rom_index)(23 downto 16);
        temp(rom_index)(23 downto 16) := swap;
      end if;
    end loop;

    return temp;
  end function;

  constant rom_cs : rom_t := rom_init("fw/fw.hex");

  signal rdata_cs : std_logic_vector(31 downto 0) := (others => '0');
  signal ready_cs : std_logic := '0';
begin
  seq : process (clk) is
    variable ready_v : std_logic;
    variable addr_v  : integer;
    variable rdata_v : std_logic_vector(31 downto 0);
  begin  -- process seq
    if clk'event and clk = '1' then  -- rising clock edge
      addr_v  := to_integer(unsigned(addr(addr'high downto 2)));
      ready_v := '0';
      rdata_v := (others => '0');

      if valid = '1' then
        ready_v := '1';
        rdata_v := rom_cs(addr_v);
      end if;

      ready_cs <= ready_v;
      rdata_cs <= rdata_v;
    end if;
  end process seq;

  ready <= ready_cs;
  rdata <= rdata_cs;
end architecture;
