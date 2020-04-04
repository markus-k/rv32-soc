library ieee;
use ieee.std_logic_1164.all;
use work.rv32_pkg.all;

entity tb_bus_arb is

end entity tb_bus_arb;

architecture bhv of tb_bus_arb is
  constant halfClkPeriod : time := 10 ns;
  constant clkPeriod : time := 2 * halfClkPeriod;

  signal clk : std_logic := '0';
  signal nres : std_logic := '0';

  signal sim_done : boolean := false;

  signal master1 : mem_bus;
  signal master2 : mem_bus;
  signal slave : mem_bus;
begin  -- architecture bhv


  clk_gen: process is
  begin
    while not sim_done loop
      clk <= '1';
      wait for halfClkPeriod;
      clk <= '0';
      wait for halfClkPeriod;
    end loop;

    wait;
  end process;

  nres_gen: process is
  begin
    nres <= '0';
    wait for halfClkPeriod * 3;
    nres <= '1';
    wait;
  end process;

  process is
  begin
    master1.from_master.addr <= (others => '1');
    master1.from_master.wdata <= (others => '0');
    master1.from_master.wstrb <= (others => '0');
    master1.from_master.valid <= '0';
    master2.from_master.addr <= (others => '1');
    master2.from_master.wdata <= (others => '0');
    master2.from_master.wstrb <= (others => '0');
    master2.from_master.valid <= '0';

    slave.to_master.ready <= '1';
    slave.to_master.rdata <= X"01234567";

    wait for 5 * clkPeriod;

    master1.from_master.addr <= X"12345678";
    master1.from_master.wdata <= X"0000FFFF";
    master1.from_master.wstrb <= "1111";
    master1.from_master.valid <= '1';

    wait for 3 * clkPeriod;

    master2.from_master.addr <= X"ABCDEF00";
    master2.from_master.wdata <= X"ABABABAB";
    master2.from_master.wstrb <= "0000";
    master2.from_master.valid <= '1';

    wait for 3 * clkPeriod;
    master1.from_master.valid <= '0';

    wait for 5 * clkPeriod;

    sim_done <= true;

    wait;
  end process;

  -- instance "bus_arb_1"
  bus_arb_1: entity work.bus_arb
    port map (
      clk         => clk,
      nres        => nres,
      slave1_in   => master1.from_master,
      slave1_out  => master1.to_master,
      slave2_in   => master2.from_master,
      slave2_out  => master2.to_master,
      master1_in  => slave.to_master,
      master1_out => slave.from_master);
end architecture bhv;
