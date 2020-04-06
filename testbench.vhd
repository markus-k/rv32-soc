library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.rv32_pkg.all;

entity testbench is
end entity testbench;

architecture bhv of testbench is
  signal clk : std_logic := '0';
  signal nres : std_logic := '0';

  signal led : std_logic_vector(7 downto 0);
  signal gpio : std_logic_vector(31 downto 0);

  signal trap : std_logic;

  signal dbg_cs : std_logic;
  signal dbg_clk : std_logic;
  signal dbg_miso : std_logic;
  signal dbg_mosi : std_logic;

  signal sdram_clk  : std_logic;
  signal sdram_clr  : std_logic;
  signal sdram_cs   : std_logic;
  signal sdram_cas  : std_logic;
  signal sdram_ras  : std_logic;
  signal sdram_we   : std_logic;
  signal sdram_dqm  : std_logic;
  signal sdram_bank : std_logic_vector(1 downto 0);
  signal sdram_addr : std_logic_vector(12 downto 0);
  signal sdram_dq   : std_logic_vector(7 downto 0);
begin


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

  -- instance "top_1"
  top_1: entity work.top
    port map (
      clk_50     => clk,
      nres       => nres,
      led        => led,
      gpio       => gpio,
      trap       => trap,
      dbg_cs     => dbg_cs,
      dbg_clk    => dbg_clk,
      dbg_miso   => dbg_miso,
      dbg_mosi   => dbg_mosi,
      sdram_clk  => sdram_clk,
      sdram_clr  => sdram_clr,
      sdram_cs   => sdram_cs,
      sdram_cas  => sdram_cas,
      sdram_ras  => sdram_ras,
      sdram_we   => sdram_we,
      sdram_dqm  => sdram_dqm,
      sdram_bank => sdram_bank,
      sdram_addr => sdram_addr,
      sdram_dq   => sdram_dq);
end architecture bhv;
