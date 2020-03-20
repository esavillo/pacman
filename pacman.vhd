-- Evan Savillo
-- pacman.vhd : Top-level wrapper file for pacman
-- also deals with scoring


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pacman is
  port(
    clk   : in std_logic;
    clk50 : in std_logic;
    reset : in std_logic;

    ps2clk  : in std_logic;
    ps2data : in std_logic;

    VGAr          : out std_logic_vector(3 downto 0);
    VGAg          : out std_logic_vector(3 downto 0);
    VGAb          : out std_logic_vector(3 downto 0);
    VGAhorizontal : out std_logic;
    VGAvertical   : out std_logic;

    digit3 : out std_logic_vector(6 downto 0);
    digit2 : out std_logic_vector(6 downto 0);
    digit1 : out std_logic_vector(6 downto 0);
    digit0 : out std_logic_vector(6 downto 0)
    );
end entity;

architecture run of pacman is

  component game
    port (
      clk   : in std_logic;             -- clock
      reset : in std_logic;  -- reset the view ( screen will be black )

      ileft  : in std_logic;  -- button to change pacman's direction left
      iup    : in std_logic;  -- button to change pacman's direction up
      idown  : in std_logic;  -- button to change pacman's direction down
      iright : in std_logic;  -- button to change pacman's direction right

      vga_hs : out std_logic;                     -- vga horizontal sync
      vga_vs : out std_logic;                     -- vga vertical sync
      r      : out std_logic_vector(3 downto 0);  -- output red
      g      : out std_logic_vector(3 downto 0);  -- output green
      b      : out std_logic_vector(3 downto 0);  -- output blue
      score  : out std_logic_vector(15 downto 0)
      );
  end component;

  component hexDigitDisplay
    port
      (
        i      : in  std_logic_vector(3 downto 0);
        h      : out std_logic_vector(6 downto 0);
        nulled : in  std_logic
        );
  end component;

  component ps2
    port(
      clk          : in  std_logic;     --system clock
      ps2_clk      : in  std_logic;     --clock signal from PS/2 keyboard
      ps2_data     : in  std_logic;     --data signal from PS/2 keyboard
      ps2_code_new : out std_logic;  --flag that new PS/2 code is available on ps2_code bus
      ps2_code     : out std_logic_vector(7 downto 0));
  end component;

  signal l : std_logic := '1';
  signal u : std_logic := '1';
  signal d : std_logic := '1';
  signal r : std_logic := '1';

  -- counter determining the currently displaying highscore
  signal selected : unsigned(1 downto 0)         := "00";
  signal code     : std_logic_vector(7 downto 0) := "00000000";
  signal code_new : std_logic                    := '1';

  signal current_score : std_logic_vector(15 downto 0) := "0000000000000000";

begin
  process(clk50, button, reset)
  begin
    if (rising_edge(clk50)) then
      case code is
        -- scan code for left arrow signal (0x6b)
        when "01101011" =>
          l <= '0';
          u <= '1';
          d <= '1';
          r <= '1';
        when "01110101" =>
          u <= '0';
          l <= '1';
          d <= '1';
          r <= '1';
        when "01110010" =>
          d <= '0';
          l <= '1';
          u <= '1';
          r <= '1';
        when "01110100" =>
          r <= '0';
          l <= '1';
          u <= '1';
          d <= '1';
        when others =>
          l <= '1';
          u <= '1';
          d <= '1';
          r <= '1';
      end case;
    end if;
  end process;

  PS20 : ps2
    port map(clk          => clk50, ps2_clk => ps2clk, ps2_data => ps2data,
             ps2_code_new => code_new, ps2_code => code);

  GAME0 : game
    port map(clk    => clk, reset => reset, ileft => l, iup => u, idown => d, iright => r,
             vga_hs => VGAhorizontal, vga_vs => VGAvertical, r => vgaR, g => vgaG, b => vgaB, score => current_score);

  HEX3 : hexDigitDisplay
    port map(i => current_score(15 downto 12), h => digit3, nulled => '0');

  HEX2 : hexDigitDisplay
    port map(i => current_score(11 downto 8), h => digit2, nulled => '0');

  HEX1 : hexDigitDisplay
    port map(i => current_score(7 downto 4), h => digit1, nulled => '0');

  HEX0 : hexDigitDisplay
    port map(i => current_score(3 downto 0), h => digit0, nulled => '0');

end architecture;
