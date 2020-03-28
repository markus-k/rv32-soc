library ieee;
use ieee.std_logic_1164.all;

use work.rv32_pkg.all;

entity interconnect is
  generic (
    master1_addr : std_logic_vector(31 downto 0) := X"00000000";
    master1_size : natural := 32;
    master2_addr : std_logic_vector(31 downto 0) := X"00000000";
    master2_size : natural := 0;
    master3_addr : std_logic_vector(31 downto 0) := X"00000000";
    master3_size : natural := 0;
    master4_addr : std_logic_vector(31 downto 0) := X"00000000";
    master4_size : natural := 0);

  port (
    clock : in std_logic;
    nres : in std_logic;

    slave1_in            : in mem_bus_from_master;
    slave1_out           : out mem_bus_to_master;

    master1_in           : in mem_bus_to_master;
    master1_out          : out mem_bus_from_master;

    master2_in           : in mem_bus_to_master;
    master2_out          : out mem_bus_from_master;

    master3_in           : in mem_bus_to_master;
    master3_out          : out mem_bus_from_master;

    master4_in           : in mem_bus_to_master;
    master4_out          : out mem_bus_from_master);

end entity interconnect;

architecture rtl of interconnect is
  constant NUM_MASTERS : natural := 4;

  type masters_in_t is array (natural range <>) of mem_bus_to_master;
  type masters_out_t is array (natural range <>) of mem_bus_from_master;
  type masters_addr_t is array (natural range <>) of std_logic_vector(31 downto 0);
  type masters_size_t is array (natural range <>) of natural;

  signal masters_in : masters_in_t(0 to NUM_MASTERS-1);
  signal masters_out : masters_out_t(0 to NUM_MASTERS-1);
  signal masters_addr : masters_addr_t(0 to NUM_MASTERS-1);
  signal masters_size : masters_size_t(0 to NUM_MASTERS-1);
begin  -- architecture rtl
  -- TODO maybe there is a nice way around this?
  masters_in(0) <= master1_in;
  masters_in(1) <= master2_in;
  masters_in(2) <= master3_in;
  masters_in(3) <= master4_in;
  master1_out <= masters_out(0);
  master2_out <= masters_out(1);
  master3_out <= masters_out(2);
  master4_out <= masters_out(3);
  masters_addr(0) <= master1_addr;
  masters_addr(1) <= master2_addr;
  masters_addr(2) <= master3_addr;
  masters_addr(3) <= master4_addr;
  masters_size(0) <= master1_size;
  masters_size(1) <= master2_size;
  masters_size(2) <= master3_size;
  masters_size(3) <= master4_size;

  decoder: process (slave1_in, masters_in) is
  begin  -- process decoder
    for i in 0 to NUM_MASTERS-1 loop
      masters_out(i).valid <= '0';
      masters_out(i).addr  <= slave1_in.addr;
      masters_out(i).wdata <= slave1_in.wdata;
      masters_out(i).wstrb <= slave1_in.wstrb;
    end loop;

    slave1_out.ready <= '0';
    slave1_out.rdata <= (others => '0');

    if slave1_in.valid = '1' then
      for i in 0 to NUM_MASTERS-1 loop
        if slave1_in.addr(31 downto masters_size(i)) = masters_addr(i)(31 downto masters_size(i)) then
          masters_out(i).valid <= '1';
          slave1_out.rdata <= masters_in(i).rdata;
          slave1_out.ready <= masters_in(i).ready;
        end if;
      end loop;
    end if;
  end process decoder;
end architecture rtl;
