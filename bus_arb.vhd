library ieee;
use ieee.std_logic_1164.all;

use work.rv32_pkg.all;

entity bus_arb is
  port (
    clk    : in std_logic;
    nres   : in std_logic;

    slave1_in            : in mem_bus_from_master;
    slave1_out           : out mem_bus_to_master;

    slave2_in            : in mem_bus_from_master;
    slave2_out           : out mem_bus_to_master;

    master1_in           : in mem_bus_to_master;
    master1_out          : out mem_bus_from_master
    );
end entity bus_arb;

architecture rtl of bus_arb is
  constant NUM_SLAVES : natural := 2;

  type slaves_in_t is array (natural range <>) of mem_bus_from_master;
  type slaves_out_t is array (natural range <>) of mem_bus_to_master;

  signal slaves_in : slaves_in_t(0 to NUM_SLAVES-1);
  signal slaves_out : slaves_out_t(0 to NUM_SLAVES-1);
begin  -- architecture rtl
  slaves_in(0) <= slave1_in;
  slaves_in(1) <= slave2_in;
  slave1_out <= slaves_out(0);
  slave2_out <= slaves_out(1);

  arb: process (slaves_in, master1_in) is

  begin  -- process arb
    for i in 0 to NUM_SLAVES-1 loop
      slaves_out(i).ready <= '0';
      slaves_out(i).rdata <= (others => '0');
    end loop;

    master1_out.valid <= '0';
    master1_out.addr <= (others => '0');
    master1_out.wdata <= (others => '0');
    master1_out.wstrb <= (others => '0');

    for i in 0 to NUM_SLAVES-1 loop
      if slaves_in(i).valid = '1' then
        master1_out.valid <= slaves_in(i).valid;
        master1_out.addr <= slaves_in(i).addr;
        master1_out.wdata <= slaves_in(i).wdata;
        master1_out.wstrb <= slaves_in(i).wstrb;

        slaves_out(i).ready <= master1_in.ready;
        slaves_out(i).rdata <= master1_in.rdata;

        exit;
      end if;
    end loop;
  end process arb;
end architecture rtl;
