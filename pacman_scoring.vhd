-- Evan Savillo
-- Fall 2018
-- CS232
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

    button : in std_logic;

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

  component scoring
    port
      (
        selector                           : in  std_logic_vector(1 downto 0);
        a, b, c, d, e                      : in  std_logic_vector(15 downto 0);
        pos1, pos2, pos3, pos4, displaying : out std_logic_vector(15 downto 0)
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
  signal selected : unsigned(1 downto 0)          := "00";
  signal score    : std_logic_vector(15 downto 0) := "0000000000000000";
  signal code     : std_logic_vector(7 downto 0)  := "00000000";
  signal code_new : std_logic                     := '1';

  signal buffer_a : std_logic_vector(15 downto 0) := "0000000000000000";
  signal buffer_b : std_logic_vector(15 downto 0) := "0000000000000000";
  signal buffer_c : std_logic_vector(15 downto 0) := "0000000000000000";
  signal buffer_d : std_logic_vector(15 downto 0) := "0000000000000000";
  signal buffer_e : std_logic_vector(15 downto 0) := "0000000000000000";

  signal score_a : std_logic_vector(15 downto 0) := "0000000000000000";
  signal score_b : std_logic_vector(15 downto 0) := "0000000000000000";
  signal score_c : std_logic_vector(15 downto 0) := "0000000000000000";
  signal score_d : std_logic_vector(15 downto 0) := "0000000000000000";

  signal current_score    : std_logic_vector(15 downto 0) := "0000000000000000";
  signal displaying_score : std_logic_vector(15 downto 0) := "0000000000000000";

  -- some states for highscoring
  type state_type is (normal, update, displaying);
  signal state : state_type := normal;

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


    case state is
      when normal =>
        current_score <= score;
        buffer_e      <= score;

        if reset = '1' then
          state         <= update;
        end if;
      when update =>
        --Advances the scores
        buffer_a <= score_a;
        buffer_b <= score_b;
        buffer_c <= score_c;
        buffer_d <= score_d;
        buffer_e <= "0000000000000000";
        state <= displaying;
      when displaying =>
        current_score <= displaying_score;

        if button = '0' then
          selected <= selected + 1;
        end if;

        if reset = '0' then
          state <= normal;
        end if;
      when others => null;
    end case;
  end process;

  PS20 : ps2
    port map(clk          => clk50, ps2_clk => ps2clk, ps2_data => ps2data,
             ps2_code_new => code_new, ps2_code => code);

  GAME0 : game
    port map(clk    => clk, reset => reset, ileft => l, iup => u, idown => d, iright => r,
             vga_hs => VGAhorizontal, vga_vs => VGAvertical, r => vgaR, g => vgaG, b => vgaB, score => score);

  HEX3 : hexDigitDisplay
    port map(i => current_score(15 downto 12), h => digit3, nulled => '0');

  HEX2 : hexDigitDisplay
    port map(i => current_score(11 downto 8), h => digit2, nulled => '0');

  HEX1 : hexDigitDisplay
    port map(i => current_score(7 downto 4), h => digit1, nulled => '0');

  HEX0 : hexDigitDisplay
    port map(i => current_score(3 downto 0), h => digit0, nulled => '0');

  SCORE0 : scoring
    port map(selector => std_logic_vector(selected), a => buffer_a, b => buffer_b, c => buffer_c, d => buffer_d, e => buffer_e,
             pos1     => score_a, pos2 => score_b, pos3 => score_c, pos4 => score_d, displaying => displaying_score);

end architecture;
