library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity testbench is
end entity testbench;

architecture bhv of testbench is
  signal clk : std_logic := '0';
  signal nres : std_logic := '0';

  signal led : std_logic_vector(7 downto 0);
  signal gpio : std_logic_vector(31 downto 0);

  signal trap : std_logic;
begin
  -- instance "top_1"
  top_1: entity work.top
    port map (
      clk_50 => clk,
      nres   => nres,
      led    => led,
      gpio   => gpio,
      trap   => trap);

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
    wait for 200 ns;
    nres <= '0';
    wait for 40 ns;
    nres <= '1';
    wait;
  end process;
end architecture bhv;
