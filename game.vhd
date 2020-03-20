-- Evan Savillo
-- Fall 2018
-- I'm so sorry this is all in one file


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity game is
  port (
    clk   : in std_logic;               -- clock
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

    score : out std_logic_vector(15 downto 0)
    );

end entity;


architecture rtl of game is
  -- VGA constants
  signal hPos : signed(10 downto 0) := "01100100000";
  signal vPos : signed(10 downto 0) := "01000001101";

  -- Various clocks
  signal playerclk  : std_logic;        -- clock for player input
  signal gameclk    : std_logic;        -- clock for game logic
  signal spriteclk  : std_logic;  -- clock for cycling through sprite animations
  signal clkcounter : unsigned (24 downto 0);

  -- Linear Feedback Shift Register for random ghost movement
  signal lfsr : std_logic_vector(15 downto 0) := "1001000110000010";

  -- Sprite
  type sprite is array(15 downto 0) of std_logic_vector(15 downto 0);

  type intarray is array(15 downto 0) of integer;
  type better_sprite is array(15 downto 0) of intarray;

  -- Environment array
  type env is array (11 downto 0) of std_logic_vector(27 downto 0);

  -- Current tile
  signal tilex : integer;
  signal tiley : integer;

  --Scoring
  signal playerscore : unsigned(15 downto 0) := "0000000000000000";

  -- Some flags
  -- Power pellet eaten
  signal change_direction : std_logic := '0';
  signal power_mode       : std_logic := '0';

  -- Gameover
  signal gameover : std_logic := '0';

  -- Various signals for pacman
  -- location of pacman
  signal pacx     : integer := 14;      -- tile coords of pacman
  signal pacy     : integer := 7;
  signal lit_pacx : integer := 370;     -- literal px coordinates of pacman
  signal lit_pacy : integer := 145;

  -- Directional state of pacman
  type direction is (west, north, south, east);
  signal pacdir : direction := west;

  -- Various signals for akabei
  -- location of akabei
  signal akabeix     : integer := 25;
  signal akabeiy     : integer := 9;
  signal lit_akabeix : integer := 195;
  signal lit_akabeiy : integer := 125;

  -- for aosuke
  signal aosukex     : integer := 2;
  signal aosukey     : integer := 2;
  signal lit_aosukex : integer := 570;
  signal lit_aosukey : integer := 235;

  -- Directional state of akabei
  signal akabeidir : direction := east;
  signal aosukedir : direction := west;

  -- Various drawing signals
  signal wpxcounter : integer := 15;
  signal rowcounter : integer := 11;

  signal hpxcounter : integer := 15;
  signal colcounter : integer := 27;

  signal spritecounter : integer := 0;

  -- Various drawing constants
  constant minwidth  : integer := 159;
  constant minheight : integer := 79;
  constant maxwidth  : integer := 608;
  constant maxheight : integer := 272;

  -- Power mode timer
  signal power_timer : unsigned(10 downto 0) := "00000000000";

  -- Various Gameplay constants
  constant pacspeed  : integer := 3;
  signal akabeispeed : integer := 4;
  signal aosukespeed : integer := 4;

  signal akabei_eaten : std_logic := '0';
  signal aosuke_eaten : std_logic := '0';

  signal should_be_in_powermode : std_logic := '0';
  signal reset_power_mode       : std_logic := '0';

  constant board : env := ("1111111111111111111111111111",
                           "1000000000000110000000000001",
                           "1011110111110110111110111101",
                           "1011110111110110111110111101",
                           "1000110000000000000000110001",
                           "1110110110111111110110110111",
                           "1110110110111111110110110111",
                           "1000000110000110000110000001",
                           "1011111111110110111111111101",
                           "1011111111110110111111111101",
                           "1000000000000000000000000001",
                           "1111111111111111111111111111");

  signal pacdots : env;

  signal power_pellets : env;

  constant pacdot : sprite := ("0000000000000000",
                               "0000000000000000",
                               "0000000000000000",
                               "0000000000000000",
                               "0000000000000000",
                               "0000000000000000",
                               "0000000000000000",
                               "0000000110000000",
                               "0000000110000000",
                               "0000000000000000",
                               "0000000000000000",
                               "0000000000000000",
                               "0000000000000000",
                               "0000000000000000",
                               "0000000000000000",
                               "0000000000000000");

  constant power_pellet : sprite := ("0000000000000000",
                                     "0000000000000000",
                                     "0000000000000000",
                                     "0000000000000000",
                                     "0000001111000000",
                                     "0000011111100000",
                                     "0000111111110000",
                                     "0000111111110000",
                                     "0000111111110000",
                                     "0000111111110000",
                                     "0000011111100000",
                                     "0000001111000000",
                                     "0000000000000000",
                                     "0000000000000000",
                                     "0000000000000000",
                                     "0000000000000000");

  constant sprite_ghost0 : sprite := ("0000000000000000",
                                      "0000001111000000",
                                      "0000111111110000",
                                      "0001111111111000",
                                      "0011111111111100",
                                      "0011111111111100",
                                      "0011111111111100",
                                      "0111111111111110",
                                      "0111111111111110",
                                      "0111111111111110",
                                      "0111111111111110",
                                      "0111111111111110",
                                      "0111111111111110",
                                      "0110111001110110",
                                      "0100011001100010",
                                      "0000000000000000");

  constant sprite_ghost1 : sprite := ("0000000000000000",
                                      "0000001111000000",
                                      "0000111111110000",
                                      "0001111111111000",
                                      "0011111111111100",
                                      "0011111111111100",
                                      "0011111111111100",
                                      "0111111111111110",
                                      "0111111111111110",
                                      "0111111111111110",
                                      "0111111111111110",
                                      "0111111111111110",
                                      "0111111111111110",
                                      "0111101111011110",
                                      "0011000110001100",
                                      "0000000000000000");

  constant eyes_h : better_sprite := ((0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
                                      (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
                                      (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
                                      (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
                                      (0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0),
                                      (0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 0, 0),
                                      (0, 0, 0, 0, 1, 1, 2, 2, 0, 0, 1, 1, 2, 2, 0, 0),
                                      (0, 0, 0, 0, 1, 1, 2, 2, 0, 0, 1, 1, 2, 2, 0, 0),
                                      (0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0),
                                      (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
                                      (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
                                      (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
                                      (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
                                      (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
                                      (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
                                      (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0));

  constant eyes_up : better_sprite := ((0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
                                       (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
                                       (0, 0, 0, 0, 2, 2, 0, 0, 0, 0, 2, 2, 0, 0, 0, 0),
                                       (0, 0, 0, 1, 2, 2, 1, 0, 0, 1, 2, 2, 1, 0, 0, 0),
                                       (0, 0, 0, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 0, 0, 0),
                                       (0, 0, 0, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 0, 0, 0),
                                       (0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0),
                                       (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
                                       (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
                                       (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
                                       (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
                                       (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
                                       (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
                                       (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
                                       (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
                                       (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0));

  constant eyes_down : better_sprite := ((0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
                                         (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
                                         (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
                                         (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
                                         (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
                                         (0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0),
                                         (0, 0, 0, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 0, 0, 0),
                                         (0, 0, 0, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 0, 0, 0),
                                         (0, 0, 0, 1, 2, 2, 1, 0, 0, 1, 2, 2, 1, 0, 0, 0),
                                         (0, 0, 0, 0, 2, 2, 0, 0, 0, 0, 2, 2, 0, 0, 0, 0),
                                         (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
                                         (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
                                         (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
                                         (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
                                         (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
                                         (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0));

  constant vulnerable_face : sprite := ("0000000000000000",
                                        "0000000000000000",
                                        "0000000000000000",
                                        "0000000000000000",
                                        "0000000000000000",
                                        "0000000000000000",
                                        "0000011001100000",
                                        "0000011001100000",
                                        "0000000000000000",
                                        "0000000000000000",
                                        "0001100110011000",
                                        "0010011001100100",
                                        "0000000000000000",
                                        "0000000000000000",
                                        "0000000000000000",
                                        "0000000000000000");


  constant sprite_pac_v0 : sprite := ("0000000000000000",
                                      "0000011111000000",
                                      "0001111111110000",
                                      "0011111111111000",
                                      "0011111111111000",
                                      "0111111111111100",
                                      "0111111111111100",
                                      "0111111111111100",
                                      "0111111111111100",
                                      "0111111111111100",
                                      "0011111111111000",
                                      "0011111111111000",
                                      "0001111111110000",
                                      "0000011111000000",
                                      "0000000000000000",
                                      "0000000000000000");

  constant sprite_pac_v1 : sprite := ("0000000000000000",
                                      "0000000000000000",
                                      "0001100000110000",
                                      "0011100000111000",
                                      "0011110001111000",
                                      "0111110001111100",
                                      "0111110001111100",
                                      "0111111011111100",
                                      "0111111011111100",
                                      "0111111111111100",
                                      "0011111111111000",
                                      "0011111111111000",
                                      "0001111111110000",
                                      "0000011111000000",
                                      "0000000000000000",
                                      "0000000000000000");

  constant sprite_pac_v2 : sprite := ("0000000000000000",
                                      "0000000000000000",
                                      "0000000000000000",
                                      "0000000000000000",
                                      "0110000000001100",
                                      "0111000000011100",
                                      "0111100000111100",
                                      "0111110001111100",
                                      "0111111011111100",
                                      "0111111111111100",
                                      "0011111111111000",
                                      "0011111111111000",
                                      "0001111111110000",
                                      "0000011111000000",
                                      "0000000000000000",
                                      "0000000000000000");

  constant sprite_pac_h0 : sprite := ("0000000000000000",
                                      "0000001111100000",
                                      "0000111111111000",
                                      "0001111111111100",
                                      "0001111111111100",
                                      "0011111111111110",
                                      "0011111111111110",
                                      "0011111111111110",
                                      "0011111111111110",
                                      "0011111111111110",
                                      "0001111111111100",
                                      "0001111111111100",
                                      "0000111111111000",
                                      "0000001111100000",
                                      "0000000000000000",
                                      "0000000000000000");

  constant sprite_pac_h1 : sprite := ("0000000000000000",
                                      "0000001111100000",
                                      "0000111111111000",
                                      "0001111111111100",
                                      "0001111111111100",
                                      "0011111111110000",
                                      "0011111110000000",
                                      "0011110000000000",
                                      "0011111110000000",
                                      "0011111111110000",
                                      "0001111111111100",
                                      "0001111111111100",
                                      "0000111111111000",
                                      "0000001111100000",
                                      "0000000000000000",
                                      "0000000000000000");

  constant sprite_pac_h2 : sprite := ("0000000000000000",
                                      "0000001111110000",
                                      "0000111111110000",
                                      "0001111111000000",
                                      "0001111110000000",
                                      "0011111100000000",
                                      "0011111000000000",
                                      "0011110000000000",
                                      "0011111000000000",
                                      "0011111100000000",
                                      "0001111110000000",
                                      "0001111111000000",
                                      "0000111111110000",
                                      "0000001111110000",
                                      "0000000000000000",
                                      "0000000000000000");

begin
  score <= std_logic_vector(playerscore);

  -- clock under which the screen is drawn
  process(clk, reset)

  begin
    if (rising_edge(clk)) then
      -- logic to operate the linear feedback shift register
      lfsr(15 downto 1) <= lfsr(14 downto 0);
      lfsr(0)           <= (lfsr(15) xor lfsr(13) xor lfsr(12) xor lfsr(10));

      -- update the current tile being drawn
      tilex <= 37 - (to_integer(hPos) / 16);
      tiley <= 16 - (to_integer(vPos) / 16);

      if (hPos > minwidth) and (hPos < maxwidth) and
        (vPos > minheight) and (vPos < maxheight) then
        -- Draw the environment based on tiles or sprite
        if board(rowcounter)(colcounter) = '1' then
          r <= "0000";
          g <= "0000";
          b <= "1011";
        elsif board(rowcounter)(colcounter) = '0' then
          r <= "0000";
          g <= "0000";
          b <= "0000";
        end if;

        -- Draw the pacdots
        if pacdots(rowcounter)(colcounter) = '1' then
          if pacdot(hpxcounter)(wpxcounter) = '1' then
            r <= "1111";
            g <= "1000";
            b <= "1111";
          end if;
        end if;

        -- Draw the power pellets
        if power_pellets(rowcounter)(colcounter) = '1' then
          if power_pellet(hpxcounter)(wpxcounter) = '1' then
            r <= "1111";
            g <= "1000";
            b <= "1111";
          end if;
        end if;

        -- Draw Pacmangus
        if (pacx = tilex) and (pacy = tiley) then
          case pacdir is
            -- FACING EAST
            when east =>
              case spritecounter is
                when 0 =>
                  if sprite_pac_h0(hpxcounter)(wpxcounter) = '1' then
                    r <= "1110";
                    g <= "1110";
                    b <= "0000";
                  end if;
                when 1 =>
                  if sprite_pac_h1(hpxcounter)(wpxcounter) = '1' then
                    r <= "1110";
                    g <= "1110";
                    b <= "0000";
                  end if;
                when 2 =>
                  if sprite_pac_h2(hpxcounter)(wpxcounter) = '1' then
                    r <= "1110";
                    g <= "1110";
                    b <= "0000";
                  end if;
                when others =>
                  if sprite_pac_h1(hpxcounter)(wpxcounter) = '1' then
                    r <= "1110";
                    g <= "1110";
                    b <= "0000";
                  end if;
              end case;

            -- FACING WEST
            when west =>
              case spritecounter is
                when 0 =>
                  if sprite_pac_h0(hpxcounter)(15 - wpxcounter) = '1' then
                    r <= "1110";
                    g <= "1110";
                    b <= "0000";
                  end if;
                when 1 =>
                  if sprite_pac_h1(hpxcounter)(15 - wpxcounter) = '1' then
                    r <= "1110";
                    g <= "1110";
                    b <= "0000";
                  end if;
                when 2 =>
                  if sprite_pac_h2(hpxcounter)(15 - wpxcounter) = '1' then
                    r <= "1110";
                    g <= "1110";
                    b <= "0000";
                  end if;
                when others =>
                  if sprite_pac_h1(hpxcounter)(15 - wpxcounter) = '1' then
                    r <= "1110";
                    g <= "1110";
                    b <= "0000";
                  end if;
              end case;

            -- FACING NORTH
            when north =>
              case spritecounter is
                when 0 =>
                  if sprite_pac_v0(hpxcounter)(wpxcounter) = '1' then
                    r <= "1110";
                    g <= "1110";
                    b <= "0000";
                  end if;
                when 1 =>
                  if sprite_pac_v1(hpxcounter)(wpxcounter) = '1' then
                    r <= "1110";
                    g <= "1110";
                    b <= "0000";
                  end if;
                when 2 =>
                  if sprite_pac_v2(hpxcounter)(wpxcounter) = '1' then
                    r <= "1110";
                    g <= "1110";
                    b <= "0000";
                  end if;
                when others =>
                  if sprite_pac_v1(hpxcounter)(wpxcounter) = '1' then
                    r <= "1110";
                    g <= "1110";
                    b <= "0000";
                  end if;
              end case;

            -- FACING SOUTH
            when south =>
              case spritecounter is
                when 0 =>
                  if sprite_pac_v0(15 - hpxcounter)(wpxcounter) = '1' then
                    r <= "1110";
                    g <= "1110";
                    b <= "0000";
                  end if;
                when 1 =>
                  if sprite_pac_v1(15 - hpxcounter)(wpxcounter) = '1' then
                    r <= "1110";
                    g <= "1110";
                    b <= "0000";
                  end if;
                when 2 =>
                  if sprite_pac_v2(15 - hpxcounter)(wpxcounter) = '1' then
                    r <= "1110";
                    g <= "1110";
                    b <= "0000";
                  end if;
                when others =>
                  if sprite_pac_v1(15 - hpxcounter)(wpxcounter) = '1' then
                    r <= "1110";
                    g <= "1110";
                    b <= "0000";
                  end if;
              end case;
            when others => null;
          end case;
        end if;

        -- Draw akabei
        if (akabeix = tilex) and (akabeiy = tiley) and
          (akabei_eaten = '0') then
          case spritecounter is
            when 0 =>
              if sprite_ghost0(hpxcounter)(wpxcounter) = '1' then
                if (power_mode = '0') then
                  r <= "1111";
                  g <= "0000";
                  b <= "0000";
                else
                  r <= "0000";
                  g <= "0000";
                  b <= "1111";
                end if;
              end if;
            when 1 =>
              if sprite_ghost0(hpxcounter)(wpxcounter) = '1' then
                if (power_mode = '0') then
                  r <= "1111";
                  g <= "0000";
                  b <= "0000";
                else
                  r <= "0000";
                  g <= "0000";
                  b <= "1111";
                end if;
              end if;
            when 2 =>
              if sprite_ghost1(hpxcounter)(wpxcounter) = '1' then
                if (power_mode = '0') then
                  r <= "1111";
                  g <= "0000";
                  b <= "0000";
                else
                  r <= "0000";
                  g <= "0000";
                  b <= "1111";
                end if;
              end if;
            when others =>
              if sprite_ghost1(hpxcounter)(wpxcounter) = '1' then
                if (power_mode = '0') then
                  r <= "1111";
                  g <= "0000";
                  b <= "0000";
                else
                  r <= "0000";
                  g <= "0000";
                  b <= "1111";
                end if;
              end if;
          end case;
        end if;

        -- Draw akabei's eyes
        if (akabeix = tilex) and (akabeiy = tiley) then
          if (power_mode = '1') then
            if vulnerable_face(hpxcounter)(wpxcounter) = '1' then
              r <= "1111";
              g <= "1111";
              b <= "1111";
            end if;
          else

            case akabeidir is
              when east =>
                if eyes_h(hpxcounter)(wpxcounter) = 1 then
                  r <= "1111";
                  g <= "1111";
                  b <= "1111";
                elsif eyes_h(hpxcounter)(wpxcounter) = 2 then
                  r <= "0000";
                  g <= "0000";
                  b <= "1111";
                end if;
              when north =>
                if eyes_up(hpxcounter)(wpxcounter) = 1 then
                  r <= "1111";
                  g <= "1111";
                  b <= "1111";
                elsif eyes_up(hpxcounter)(wpxcounter) = 2 then
                  r <= "0000";
                  g <= "0000";
                  b <= "1111";
                end if;
              when south =>
                if eyes_down(hpxcounter)(wpxcounter) = 1 then
                  r <= "1111";
                  g <= "1111";
                  b <= "1111";
                elsif eyes_down(hpxcounter)(wpxcounter) = 2 then
                  r <= "0000";
                  g <= "0000";
                  b <= "1111";
                end if;
              when west =>
                if eyes_h(hpxcounter)(15 - wpxcounter) = 1 then
                  r <= "1111";
                  g <= "1111";
                  b <= "1111";
                elsif eyes_h(hpxcounter)(15 - wpxcounter) = 2 then
                  r <= "0000";
                  g <= "0000";
                  b <= "1111";
                end if;
              when others => null;
            end case;
          end if;

        end if;


        -- Draw aosuke
        if (aosukex = tilex) and (aosukey = tiley) and
          (aosuke_eaten = '0') then
          case spritecounter is
            when 0 =>
              if sprite_ghost0(hpxcounter)(wpxcounter) = '1' then
                if (power_mode = '0') then
                  r <= "0000";
                  g <= "1111";
                  b <= "1111";
                else
                  r <= "0000";
                  g <= "0000";
                  b <= "1111";
                end if;
              end if;
            when 1 =>
              if sprite_ghost0(hpxcounter)(wpxcounter) = '1' then
                if (power_mode = '0') then
                  r <= "0000";
                  g <= "1111";
                  b <= "1111";
                else
                  r <= "0000";
                  g <= "0000";
                  b <= "1111";
                end if;
              end if;
            when 2 =>
              if sprite_ghost1(hpxcounter)(wpxcounter) = '1' then
                if (power_mode = '0') then
                  r <= "0000";
                  g <= "1111";
                  b <= "1111";
                else
                  r <= "0000";
                  g <= "0000";
                  b <= "1111";
                end if;
              end if;
            when others =>
              if sprite_ghost1(hpxcounter)(wpxcounter) = '1' then
                if (power_mode = '0') then
                  r <= "0000";
                  g <= "1111";
                  b <= "1111";
                else
                  r <= "0000";
                  g <= "0000";
                  b <= "1111";
                end if;
              end if;
          end case;
        end if;

        -- Draw aosuke's eyes
        if (aosukex = tilex) and (aosukey = tiley) then
          if (power_mode = '1') then
            if vulnerable_face(hpxcounter)(wpxcounter) = '1' then
              r <= "1111";
              g <= "1111";
              b <= "1111";
            end if;
          else

            case aosukedir is
              when east =>
                if eyes_h(hpxcounter)(wpxcounter) = 1 then
                  r <= "1111";
                  g <= "1111";
                  b <= "1111";
                elsif eyes_h(hpxcounter)(wpxcounter) = 2 then
                  r <= "0000";
                  g <= "0000";
                  b <= "1111";
                end if;
              when north =>
                if eyes_up(hpxcounter)(wpxcounter) = 1 then
                  r <= "1111";
                  g <= "1111";
                  b <= "1111";
                elsif eyes_up(hpxcounter)(wpxcounter) = 2 then
                  r <= "0000";
                  g <= "0000";
                  b <= "1111";
                end if;
              when south =>
                if eyes_down(hpxcounter)(wpxcounter) = 1 then
                  r <= "1111";
                  g <= "1111";
                  b <= "1111";
                elsif eyes_down(hpxcounter)(wpxcounter) = 2 then
                  r <= "0000";
                  g <= "0000";
                  b <= "1111";
                end if;
              when west =>
                if eyes_h(hpxcounter)(15 - wpxcounter) = 1 then
                  r <= "1111";
                  g <= "1111";
                  b <= "1111";
                elsif eyes_h(hpxcounter)(15 - wpxcounter) = 2 then
                  r <= "0000";
                  g <= "0000";
                  b <= "1111";
                end if;
              when others => null;
            end case;
          end if;

        end if;



        -- counter crud
        if wpxcounter = 0 then
          wpxcounter <= 15;
          colcounter <= colcounter - 1;
        else
          wpxcounter <= wpxcounter - 1;
        end if;

      elsif (hPos = maxwidth) then
        if hpxcounter = 0 then
          hpxcounter <= 15;
          rowcounter <= rowcounter - 1;
        else
          hpxcounter <= hpxcounter - 1;
        end if;

        colcounter <= 27;
        wpxcounter <= 15;
      elsif (vPos = minheight) then
        rowcounter <= 11;
        hpxcounter <= 15;
      else
        r <= (others => '0');
        g <= (others => '0');
        b <= (others => '0');
      end if;

      -- travese row on screen
      if hPos < 800 then
        hPos <= hPos + 1;
      else
        -- reset the position within the row and increase the row number we are on
        hPos <= "00000000000";
        if vPos < 525 then
          vPos <= vPos + 1;
        else
          vPos <= "00000000000";
        end if;
      end if;

      -- account for front and back porch
      if (hPos > 96) then
        vga_hs <= '0';
      else
        vga_hs <= '1';
      end if;

      if (vPos > 2) then
        vga_vs <= '0';
      else
        vga_vs <= '1';
      end if;

      if ((hPos > 0 and hPos < 160) or (vPos > 0 and vPos < 45)) then
        r <= (others => '0');
        g <= (others => '0');
        b <= (others => '0');
      end if;
    end if;
  end process;


  -- clock under which the state of the game is updated
  process(gameclk, reset)
  begin
    if reset = '1' then
      pacx     <= 14;
      pacy     <= 7;
      lit_pacx <= 370;
      lit_pacy <= 145;

      akabeix     <= 25;
      akabeiy     <= 9;
      lit_akabeix <= 195;
      lit_akabeiy <= 125;

      aosukex     <= 2;
      aosukey     <= 2;
      lit_aosukex <= 570;
      lit_aosukey <= 245;

      playerscore <= "0000000000000000";

      gameover <= '0';

      pacdots <= ("0000000000000000000000000000",
                  "0111111111111001111111111110",
                  "0100001000001001000001000010",
                  "0100001000001001000001000010",
                  "0111001111111001111111001110",
                  "0001001001000000001001001000",
                  "0001001001000000001001001000",
                  "0111111001111001111001111110",
                  "0100000000001001000000000010",
                  "0100000000001001000000000010",
                  "0111111111111111111111111110",
                  "0000000000000000000000000000");

      power_pellets <= ("0000000000000000000000000000",
                        "0000000000000000000000000000",
                        "0000000000000000000000000000",
                        "0000000000000000000000000000",
                        "0100000000000000000000000010",
                        "0000000000000000000000000000",
                        "0000000000000000000000000000",
                        "0000000000000000000000000000",
                        "0000000000000000000000000000",
                        "0000000000000000000000000000",
                        "0000000000000000000000000000",
                        "0000000000000000000000000000");

    elsif (rising_edge(gameclk) and gameover = '0') then
      -- Movement logic
      -- move pacman according to speed in pixel space
      case pacdir is
        when west =>
          if (board(pacy)(pacx + 1) = '0') then
            lit_pacx <= lit_pacx - pacspeed;
          end if;
        when north =>
          if (board(pacy + 1)(pacx) = '0') then
            lit_pacy <= lit_pacy - pacspeed;
          end if;
        when south =>
          if (board(pacy - 1)(pacx) = '0') then
            lit_pacy <= lit_pacy + pacspeed;
          end if;
        when east =>
          if (board(pacy)(pacx - 1) = '0') then
            lit_pacx <= lit_pacx + pacspeed;
          end if;
        when others => null;
      end case;

      -- akabei movement
      case akabeidir is
        when west =>
          if (board(akabeiy)(akabeix + 1) = '0') then
            lit_akabeix <= lit_akabeix - akabeispeed;
          end if;
        when north =>
          if (board(akabeiy + 1)(akabeix) = '0') then
            lit_akabeiy <= lit_akabeiy - akabeispeed;
          end if;
        when south =>
          if (board(akabeiy - 1)(akabeix) = '0') then
            lit_akabeiy <= lit_akabeiy + akabeispeed;
          end if;
        when east =>
          if (board(akabeiy)(akabeix - 1) = '0') then
            lit_akabeix <= lit_akabeix + akabeispeed;
          end if;
        when others => null;
      end case;

      -- aosuke movement
      case aosukedir is
        when west =>
          if (board(aosukey)(aosukex + 1) = '0') then
            lit_aosukex <= lit_aosukex - aosukespeed;
          end if;
        when north =>
          if (board(aosukey + 1)(aosukex) = '0') then
            lit_aosukey <= lit_aosukey - aosukespeed;
          end if;
        when south =>
          if (board(aosukey - 1)(aosukex) = '0') then
            lit_aosukey <= lit_aosukey + aosukespeed;
          end if;
        when east =>
          if (board(aosukey)(aosukex - 1) = '0') then
            lit_aosukex <= lit_aosukex + aosukespeed;
          end if;
        when others => null;
      end case;

      -- update tile space accordingly
      pacx <= 37 - (lit_pacx / 16);
      pacy <= 16 - (lit_pacy / 16);

      if (akabei_eaten = '1') then
        akabeix     <= 25;
        akabeiy     <= 9;
        lit_akabeix <= 195;
        lit_akabeiy <= 125;
      else
        akabeix <= 37 - (lit_akabeix / 16);
        akabeiy <= 16 - (lit_akabeiy / 16);
      end if;

      if (aosuke_eaten = '1') then
        aosukex     <= 2;
        aosukey     <= 2;
        lit_aosukex <= 570;
        lit_aosukey <= 235;
      else
        aosukex <= 37 - (lit_aosukex / 16);
        aosukey <= 16 - (lit_aosukey / 16);
      end if;

      -- Interaction Logic
      if (pacdots(pacy)(pacx) = '1') then
        pacdots(pacy)(pacx) <= '0';
        playerscore         <= playerscore + 100;
      end if;

      if (power_pellets(pacy)(pacx) = '1') then
        if (power_mode = '1') then
          reset_power_mode <= '1';
        end if;
        power_pellets(pacy)(pacx) <= '0';
        playerscore               <= playerscore + 400;
        should_be_in_powermode    <= '1';
      end if;

      -- multiple driving workaround
      if (power_mode = '1' and should_be_in_powermode = '1') then
        should_be_in_powermode <= '0';
      end if;
      if (reset_power_mode = '1' and power_timer < 100) then
        reset_power_mode <= '0';
      end if;

      -- akabei
      if (pacx = akabeix and pacy = akabeiy and power_mode = '0') then
        gameover <= '1';
      elsif (pacx = akabeix and pacy = akabeiy and power_mode = '1') then
        playerscore <= playerscore + 1000;
      end if;

      -- aosuke
      if (pacx = aosukex and pacy = aosukey and power_mode = '0') then
        gameover <= '1';
      elsif (pacx = aosukex and pacy = aosukey and power_mode = '1') then
        playerscore <= playerscore + 1000;
      end if;

      -- this doesn't work for some reason
      if pacdots(11) = "000000000000000000000000000" and
        pacdots(10) = "000000000000000000000000000" and
        pacdots(9) = "000000000000000000000000000" and
        pacdots(8) = "000000000000000000000000000" and
        pacdots(7) = "000000000000000000000000000" and
        pacdots(6) = "000000000000000000000000000" and
        pacdots(5) = "000000000000000000000000000" and
        pacdots(4) = "000000000000000000000000000" and
        pacdots(3) = "000000000000000000000000000" and
        pacdots(2) = "000000000000000000000000000" and
        pacdots(1) = "000000000000000000000000000" and
        pacdots(0) = "000000000000000000000000000" then
        gameover <= '1';
      end if;

    end if;
  end process;


  -- clocks under which player input is obtained
  -- (and akabei's state is determined)
  process(playerclk, reset)
  begin
    if reset = '1' then                 --reset to default
      pacdir     <= west;
      power_mode <= '0';
    elsif (rising_edge(playerclk) and gameover = '0') then
      if (should_be_in_powermode = '1') then
        change_direction <= '1';        -- akabei flees
        akabeispeed      <= 1;
        aosukespeed      <= 1;
        power_mode       <= '1';
      end if;

      if (pacx = akabeix and pacy = akabeiy and power_mode = '1') then
        akabei_eaten <= '1';
        akabeispeed  <= 0;
      end if;

      if (pacx = aosukex and pacy = aosukey and power_mode = '1') then
        aosuke_eaten <= '1';
        aosukespeed  <= 0;
      end if;

      if (power_mode = '0') then
        akabeispeed <= 4;
        aosukespeed <= 4;
      end if;

      -- if direction is x and a valid path to take, change direction
      if (ileft = '0') and
        (iup = '1' and idown = '1' and iright = '1') and
        (board(pacy)(pacx + 1) = '0') then
        -- lit_pacx <= lit_pacx - 1;
        pacdir <= west;
      elsif (iup = '0') and
        (ileft = '1' and idown = '1' and iright = '1') and
        (board(pacy + 1)(pacx) = '0') then
        -- lit_pacy <= lit_pacy - 1;
        pacdir <= north;
      elsif (idown = '0') and
        (ileft = '1' and iup = '1' and iright = '1') and
        (board(pacy - 1)(pacx) = '0') then
        -- lit_pacy <= lit_pacy + 1;
        pacdir <= south;
      elsif (iright = '0') and
        (ileft = '1' and iup = '1' and idown = '1') and
        (board(pacy)(pacx - 1) = '0') then
        -- lit_pacx <= lit_pacx + 1;
        pacdir <= east;
      end if;

      -- Akabei moves until he hits a wall, then moves right or left randomly
      case akabeidir is
        when west =>
          if (board(akabeiy)(akabeix + 1) = '1') then
            if (board(akabeiy - 1)(akabeix) = '0') then
              if (board(akabeiy + 1)(akabeix) = '0') and
                (lfsr(0) = '1') then
                akabeidir <= north;
              else
                akabeidir <= south;
              end if;
            else
              akabeidir <= north;
            end if;
          end if;
        when north =>
          if (board(akabeiy + 1)(akabeix) = '1') then
            if (board(akabeiy)(akabeix + 1) = '0') then
              if (board(akabeiy)(akabeix - 1) = '0') and
                (lfsr(0) = '1') then
                akabeidir <= east;
              else
                akabeidir <= west;
              end if;
            else
              akabeidir <= east;
            end if;
          end if;
        when south =>
          if (board(akabeiy - 1)(akabeix) = '1') then
            if (board(akabeiy)(akabeix - 1) = '0') then
              if (board(akabeiy)(akabeix + 1) = '0') and
                (lfsr(0) = '1') then
                akabeidir <= west;
              else
                akabeidir <= east;
              end if;
            else
              akabeidir <= west;
            end if;
          end if;
        when east =>
          if (board(akabeiy)(akabeix - 1) = '1') then
            if (board(akabeiy + 1)(akabeix) = '0') then
              if (board(akabeiy - 1)(akabeix) = '0') and
                (lfsr(0) = '1') then
                akabeidir <= south;
              else
                akabeidir <= north;
              end if;
            else
              akabeidir <= south;
            end if;
          end if;
        when others => null;
      end case;



      -- Aosuke moves until he hits a wall, then moves right or left randomly
      case aosukedir is
        when west =>
          if (board(aosukey)(aosukex + 1) = '1') then
            if (board(aosukey - 1)(aosukex) = '0') then
              if (board(aosukey + 1)(aosukex) = '0') and
                (lfsr(0) = '1') then
                aosukedir <= north;
              else
                aosukedir <= south;
              end if;
            else
              aosukedir <= north;
            end if;
          end if;
        when north =>
          if (board(aosukey + 1)(aosukex) = '1') then
            if (board(aosukey)(aosukex + 1) = '0') then
              if (board(aosukey)(aosukex - 1) = '0') and
                (lfsr(0) = '1') then
                aosukedir <= east;
              else
                aosukedir <= west;
              end if;
            else
              aosukedir <= east;
            end if;
          end if;
        when south =>
          if (board(aosukey - 1)(aosukex) = '1') then
            if (board(aosukey)(aosukex - 1) = '0') then
              if (board(aosukey)(aosukex + 1) = '0') and
                (lfsr(0) = '1') then
                aosukedir <= west;
              else
                aosukedir <= east;
              end if;
            else
              aosukedir <= west;
            end if;
          end if;
        when east =>
          if (board(aosukey)(aosukex - 1) = '1') then
            if (board(aosukey + 1)(aosukex) = '0') then
              if (board(aosukey - 1)(aosukex) = '0') and
                (lfsr(0) = '1') then
                aosukedir <= south;
              else
                aosukedir <= north;
              end if;
            else
              aosukedir <= south;
            end if;
          end if;
        when others => null;
      end case;


      -- when a power pellet is eaten
      if (change_direction = '1') then
        change_direction <= '0';

        case akabeidir is
          when east =>
            akabeidir <= west;
          when north =>
            akabeidir <= south;
          when south =>
            akabeidir <= north;
          when west =>
            akabeidir <= east;
          when others => null;
        end case;

        case aosukedir is
          when east =>
            aosukedir <= west;
          when north =>
            aosukedir <= south;
          when south =>
            aosukedir <= north;
          when west =>
            aosukedir <= east;
          when others => null;
        end case;
      end if;

      if (reset_power_mode = '1') then
        power_timer <= "00000000000";
      end if;
      -- power mode timer
      if (power_mode = '1') then
        power_timer <= power_timer + 1;
        if (power_timer(10) = '1') then
          power_mode   <= '0';
          akabei_eaten <= '0';
          aosuke_eaten <= '0';
          power_timer  <= "00000000000";
        end if;
      end if;

    end if;
  end process;

  -- A simple process to cycle through sprite animation
  process(spriteclk, reset)
  begin
    if reset = '1' then
      spritecounter <= 0;
    elsif (rising_edge(spriteclk) and gameover = '0') then
      if (spritecounter = 4) then
        spritecounter <= 0;
      else
        spritecounter <= spritecounter + 1;
      end if;
    end if;
  end process;

  -- generate slower clocks for game logic to execute and to register player input
  process(clk, reset)
  begin
    if reset = '1' then
      clkcounter <= "0000000000000000000000000";
    elsif (rising_edge(clk)) then
      clkcounter <= clkcounter + 1;
    end if;
  end process;

  gameclk   <= clkcounter(19);
  playerclk <= clkcounter(17);
  spriteclk <= clkcounter(19);

end architecture;
