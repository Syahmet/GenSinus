----------------------------------------------------------------------------------
-- Auteur         : Ahmet SY
-- Projet         : Comet Interceptor
-- Entreprise     : LPC2E
-- Version        : V2
-- Nom du fichier : Module_cordic.vhd
-- FPGA           : NG-Medium de NanoXplore
-- Description    :
--Ce Module permet de calculer les amplitudes échantillonées de sinus et de cos
-- x0 = G/An avec An = 1,67 et G le gain pour fixer la virgule 
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
------------------------------------------------------------------
-- Entité 
------------------------------------------------------------------

entity Module_cordic is
  generic (
    constant Nbre_iter : integer := 16;
    constant Nbre_bits : integer := 16;
    constant Freq      : integer := 50000000-- frequence du systeme
  );
  port (

    i_Clock      : in std_logic;
    i_Rst        : in std_logic;
    o_Data_Valid : out std_logic;
    o_Sinus      : out std_logic_vector(Nbre_bits - 1 downto 0);
    o_Cosinus    : out std_logic_vector(Nbre_bits - 1 downto 0)

  );
end Module_cordic;
-----------------------------------------------------------------
-- Architecture
-----------------------------------------------------------------

architecture rtl of Module_cordic is
  type reg_type is array (0 to Nbre_iter) of integer;
  type reg_angles is array (0 to Nbre_iter - 1) of integer;
  type tab_state is (s0, s1);
  signal state    : tab_state := s0;
  signal x, y, z  : reg_type; -- Registres qui contiennent les vecteurs 
  constant dz     : reg_angles := (8192, 4836, 2555, 1297, 651, 326, 163, 81, 41, 20, 10, 5, 3, 1, 1, 0);
  constant x0     : integer    := 19898; -- Valeur initiale  
  signal i        : integer    := 0;
  signal ang      : integer    := 0;
  signal quadrant : std_logic_vector(1 downto 0);
  signal v_ang    : std_logic_vector(Nbre_bits - 1 downto 0);
  signal rdy      : std_logic := '0';
begin

  process_cordic : process (i_Clock, i_Rst)
  begin
    v_ang    <= std_logic_vector(to_unsigned(ang, Nbre_bits));
    quadrant <= v_ang(Nbre_bits - 1 downto Nbre_bits - 2);
    if rising_edge(i_Clock) then
      if (i_Rst = '0') then
        state        <= s0;
        i            <= 0;
        o_Data_Valid <= '0';
        rdy          <= '0';
      else
        case state is
          when s0 =>
            o_Data_Valid <= '0';
            case quadrant is
              when "00" =>
                x(0)  <= x0;
                y(0)  <= 0;
                z(0)  <= ang;
                state <= s1;
              when "01" =>
                x(0)  <= 0;
                y(0)  <= x0;
                z(0)  <= ang - 16384;
                state <= s1;
              when "10" =>
                x(0)  <= - x0;
                y(0)  <= 0;
                z(0)  <= ang - 32768;
                state <= s1;
              when "11" =>
                x(0)  <= 0;
                y(0)  <= - x0;
                z(0)  <= ang - 49152;
                state <= s1;
              when others =>
                null;
            end case;
          when s1 =>
            if (z(i) > 0) then
              x(i + 1) <= x(i) - y(i)/(2 ** i);
              y(i + 1) <= y(i) + x(i)/(2 ** i);
              z(i + 1) <= z(i) - dz(i);
            else
              x(i + 1) <= x(i) + y(i)/(2 ** i);
              y(i + 1) <= y(i) - x(i)/(2 ** i);
              z(i + 1) <= z(i) + dz(i);
            end if;
            if (i < Nbre_iter - 1) then
              i <= i + 1;
            else
              i <= 0;
              if (ang + 2 < (2 ** 16) - 1) then
                ang <= ang + 2;
                if rdy = '0' then
                  o_Data_Valid <= '1';
                end if;
              else
                ang <= 0;
                rdy <= '1';
              end if;
              state <= s0;
            end if;
          when others =>
            state <= s0;
        end case;
      end if;
    end if;
  end process; -- pro_inst
  o_Cosinus <= std_logic_vector(to_signed(x(Nbre_iter - 1), Nbre_bits));
  o_Sinus   <= std_logic_vector(to_signed(y(Nbre_iter - 1), Nbre_bits));

end architecture;