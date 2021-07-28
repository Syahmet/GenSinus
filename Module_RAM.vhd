library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

--library NX;
--use NX.nxPackage.all;

entity Module_RAM is
  generic (
    M_ADD : integer := 15;
    M_MEM : integer := 32768;
    M_DAT : integer := 16
  );
  port (
    CLK1 : in std_logic;
    ADD1 : in std_logic_vector((M_ADD - 1) downto 0);
    DI1  : in std_logic_vector((M_DAT - 1) downto 0);
    DO1  : out std_logic_vector((M_DAT - 1) downto 0);
    RE1  : in std_logic;
    WE1  : in std_logic
  );
end Module_RAM;

-- Design

architecture behavioral of Module_RAM is

  signal DOB1 : std_logic_vector((M_DAT - 1) downto 0);
  signal DOB2 : std_logic_vector((M_DAT - 1) downto 0);

  -- Infered Signals

  type mem_array is array(0 to (M_MEM - 1)) of std_logic_vector((M_DAT - 1) downto 0);

  signal mem_R : mem_array;

begin

  DO1 <= DOB1;

  process (CLK1)
  begin

    if rising_edge(CLK1) then
      if WE1 = '1' then
        mem_R(to_integer(unsigned(ADD1))) <= DI1;
      end if;
      if RE1 = '1' then
        DOB1 <= mem_R(to_integer(unsigned(ADD1)));
      end if;
    end if;

  end process;
end architecture;