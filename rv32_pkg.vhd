library ieee;
use ieee.std_logic_1164.all;

package rv32_pkg is
  type mem_bus_to_master is record
    ready  : std_logic;
    rdata  : std_logic_vector(31 downto 0);
  end record mem_bus_to_master;

  type mem_bus_from_master is record
    valid  : std_logic;
    addr   : std_logic_vector(31 downto 0);
    wdata  : std_logic_vector(31 downto 0);
    wstrb  : std_logic_vector(3 downto 0);
  end record mem_bus_from_master;

  type mem_bus is record
    to_master : mem_bus_to_master;
    from_master : mem_bus_from_master;
  end record mem_bus;
end package rv32_pkg;
