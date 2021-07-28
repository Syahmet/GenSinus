library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

-----------------------------------------------------------------
-- Ce Module permet de stocker les cofficients de sinus et de cos 
-- dans le ram. Il permet aussi de lire les valeurs.
-----------------------------------------------------------------

-----------------------------------------------------------------
-- Entité 
-----------------------------------------------------------------
entity Write_Read_RAM is
  generic (
    constant Nbre_bits_adr : integer := 15;
    constant Nbre_echan    : integer := 32768;
    constant Nbre_bits     : integer := 16
  );

  port (
    i_CLK      : in std_logic;
    i_RST      : in std_logic;
    i_INC_FREQ : in std_logic;
    i_DEC_FREQ : in std_logic;
    o_Dout1    : out std_logic_vector(Nbre_bits - 1 downto 0)

  );
end Write_Read_RAM;

-----------------------------------------------------------------
-- Architecture
-----------------------------------------------------------------

architecture rtl of Write_Read_RAM is

  --CORDIC

  component Module_cordic is
    generic (
      constant Nbre_iter : integer := 16;
      constant Nbre_bits : integer := 16;
      constant Freq      : integer := 50000000
    );
    port (

      i_Clock      : in std_logic;
      i_Rst        : in std_logic;
      o_Data_Valid : out std_logic;
      o_Sinus      : out std_logic_vector(Nbre_bits - 1 downto 0);
      o_Cosinus    : out std_logic_vector(Nbre_bits - 1 downto 0)
  
    );
  end component;

  -- PHASE

  component Module_phase is
    generic (
      constant Nbre_echan    : unsigned(27 downto 0) := x"0008000";
      constant Nbre_max_acc  : unsigned(27 downto 0) := x"FFFFFFF";
      constant Nbre_bits_adr : integer               := 15;
      constant Nbre_TW       : integer               := 128;
      constant Freq          : integer               := 50000000
    );
    port (
      CLK      : in std_logic;
      RST      : in std_logic;
      INC_FREQ : in std_logic;
      DEC_FREQ : in std_logic;
      RDY      : out std_logic;
      ADD      : out std_logic_vector(Nbre_bits_adr - 1 downto 0)
    );
  end component;

  -- RAM

  component Module_RAM is
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
  end component;

  --signal phase : integer;
  signal idx                : std_logic_vector(Nbre_bits_adr - 1 downto 0);
  signal v_sinus, v_cosinus : std_logic_vector(Nbre_bits - 1 downto 0);
  signal rdy, we, re        : std_logic;

  signal Cpt_clk      : integer := 0; -- compteur des fronts montants 
  signal Nbre_clk_max : integer := 15; -- Nbre d'incrÃƒÂ©mentation max 
  signal Freq_voulue  : integer := 6000000;

begin

  inst_cordic : Module_cordic
  generic map(
    Nbre_iter => 16,
    Nbre_bits => 16,
    Freq      => 50000000
  )
  port map(
    i_Clock        => i_CLK,
    i_Rst        => i_RST,
    o_Data_Valid => we,
    o_Sinus      => v_sinus,
    o_Cosinus    => v_cosinus
  );

  inst_phase : Module_phase
  generic map(
    Nbre_echan    => x"0008000",
    Nbre_max_acc  => x"FFFFFFF",
    Nbre_bits_adr => 15,
    Nbre_TW       => 128,
    Freq          => 50000000
  )
  port map(
    CLK      => i_CLK,
    RST      => i_RST,
    INC_FREQ => i_INC_FREQ,
    DEC_FREQ => i_DEC_FREQ,
    RDY      => rdy,
    ADD      => idx
  );

  inst_WR_RAM : Module_RAM
  generic map(
    M_ADD => 15,
    M_MEM => 32768,
    M_DAT => 16
  )
  port map(

    CLK1 => i_CLK,
    ADD1 => idx,
    DI1  => v_sinus,
    DO1  => o_Dout1,
    RE1  => rdy,
    WE1  => we

  );
end architecture;
