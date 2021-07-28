----------------------------------------------------------------------------------
-- Auteur         : Ahmet SY
-- Projet         :  Comet Interceptor
-- Entreprise     : LPC2E
-- Version        : V2
-- Nom du fichier : Module_cordic.vhd
-- FPGA           : NG-Medium
-- Description    :
-- Ce Module permet de gérer l'indexage et la fréquence du sinus et du cos 
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

------------------------------------------------------------------
-- Entité 
------------------------------------------------------------------

entity Module_phase is
  generic (
    constant Nbre_echan    : unsigned(27 downto 0) := x"0008000";
    constant Nbre_max_acc  : unsigned(27 downto 0) := x"FFFFFFF";
    constant Nbre_bits_adr : integer               := 15;
    constant Nbre_bits_acc : integer               := 28;
    constant Nbre_TW       : integer               := 128; -- Nombre de bits de Tuning Word ou  reference de frequence 
    constant Freq          : integer               := 50000000-- frequence du systeme

  );
  port (
    CLK      : in std_logic;
    RST      : in std_logic;
    INC_FREQ : in std_logic;
    DEC_FREQ : in std_logic;
    RDY      : out std_logic;
    ADD1     : out std_logic_vector(Nbre_bits_adr - 1 downto 0);
    ADD2     : out std_logic_vector(Nbre_bits_adr - 1 downto 0)

  );
end Module_phase;
-----------------------------------------------------------------
-- Architecture
-----------------------------------------------------------------

architecture rtl of Module_phase is
  type reg_state is (s0, s1);
  type TW is array (0 to Nbre_TW - 1) of integer;
  constant tab_TW : TW := (447392, 467972, 489499, 512016, 535569, 560205, 585975, 612929, 641124, 670616, 701464, 733731, 767483, 802787, 839716, 878342,
  918746, 961009, 1005215, 1051455, 1099822, 1150414, 1203333, 1258686, 1316585, 1377148, 1440497, 1506760, 1576071, 1648570, 1724405, 1803727, 1886699,
  1973487, 2064267, 2159223, 2258548, 2362441, 2471113, 2584784, 2703684, 2828054, 2958144, 3094219, 3236553, 3385435, 3541165, 3704058, 3874445, 4052669,
  4239092, 4434090, 4638059, 4851409, 5074574, 5308004, 5552173, 5807573, 6074721, 6354158, 6646449, 6952186, 7271987, 7606498, 7956397, 8322391, 8705221,
  9105661, 9524522, 9962650, 10420932, 10900294, 11401708, 11926187, 12474791, 13048632, 13648869, 14276717, 14933446, 15620384, 16338922,
  17090512, 17876676, 18699003, 19559157, 20458878, 21399986, 22384386, 23414068, 24491115, 25617706, 26796120, 28028742, 29318064, 30666695,
  32077363, 33552922, 35096356, 36710788, 38399485, 40165861, 42013491, 43946111, 45967632, 48082143, 50293922, 52607442, 55027385, 57558644,
  60206342, 62975834, 65872722, 68902867, 72072399, 75387730, 78855565, 82482921, 86277136, 90245884, 94397195, 98739466, 103281481, 108032429,
  113001921, 118200009, 123637210, 129324521, 135273449);
  signal phase_acc    : unsigned(Nbre_bits_acc - 1 downto 0) := (others => '0');
  signal Idx          : integer                              := 0;
  signal Cpt_clk      : integer                              := 0; -- compteur des fronts montants 
  signal Nbre_clk_max : integer                              := 0; -- Nbre d'incrÃƒÂ©mentation max 
  signal Freq_voulue  : integer                              := 6000000;
  signal state        : reg_state                            := s0;
begin

  Nbre_clk_max <= 16;
  pro1 : process (CLK)
  begin
    if (rising_edge(CLK)) then
      if (RST = '0') then
        phase_acc <= (others => '0');
        Idx       <= 0;
        state     <= s0;
      else
        case(state) is
          when s0 => --Etat ecrire
          if Cpt_clk >= Nbre_clk_max then
            Cpt_clk <= 0;
            if (phase_acc < (Nbre_echan - x"0000001")) then
              phase_acc <= phase_acc + x"0000001";
              RDY       <= '0';
            else
              phase_acc <= (others => '0');
              RDY       <= '1';
              state     <= s1;
            end if;
          else
            Cpt_clk <= Cpt_clk + 1;
          end if;
          ADD1 <= std_logic_vector(phase_acc(Nbre_bits_adr - 1 downto 0));
          when s1 => -- Etat lire
          if (phase_acc < (Nbre_max_acc - x"0000001")) then
            phase_acc <= phase_acc + to_unsigned(tab_TW(Idx), Nbre_bits_acc);
          else
            phase_acc <= (others => '0');
            state     <= s1;
          end if;
          ADD1 <= std_logic_vector(phase_acc(Nbre_bits_acc - 1 downto 13));
          when others =>
          null;

        end case;
      end if;
      if INC_FREQ = '0' and Idx + 1 < Nbre_TW - 1 then
        Idx       <= Idx + 1;
        phase_acc <= (others => '0');
      end if;
      if DEC_FREQ = '0' and Idx > 0 then
        Idx       <= Idx - 1;
        phase_acc <= (others => '0');
      end if;
    end if;
  end process; -- pro1

end architecture;