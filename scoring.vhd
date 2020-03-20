-- Evan Savillo
-- CS232
-- Fall 2018
-- scoring.vhd : effectively sorts the four saved scores in least to greatest order.

-- outputs the maximum of 2 numbers, as well as the 'losing' number
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity computeMax2 is
  port
    (
      a, b       : in  std_logic_vector(15 downto 0);
      max, loser : out std_logic_vector(15 downto 0)
      );
end computeMax2;

architecture lorem of computeMax2 is
begin
  max   <= a when a >= b else b;
  loser <= a when a < b else b;
end lorem;

-- outputs the maximum of 3 numbers, as well as the two 'losers'
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity computeMax3 is
  port
    (
      a, b, c             : in  std_logic_vector(15 downto 0);
      max, loser1, loser2 : out std_logic_vector(15 downto 0)
      );
end computeMax3;

architecture lorem of computeMax3 is
  component computeMax2
    port
      (
        a, b       : in  std_logic_vector(15 downto 0);
        max, loser : out std_logic_vector(15 downto 0)
        );
  end component computeMax2;

  signal max1 : std_logic_vector(15 downto 0);
  signal max2 : std_logic_vector(15 downto 0);

begin
  M0 : computeMax2
    port map (a, b, max1, loser1);
  M1 : computeMax2
    port map (max1, c, max2, loser2);

  max <= max2;
end lorem;

-- outputs the maximum of 4 numbers, as well as the 3 'losers'
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity computeMax4 is
  port
    (
      a, b, c, d                  : in  std_logic_vector(15 downto 0);
      max, loser1, loser2, loser3 : out std_logic_vector(15 downto 0)
      );
end computeMax4;

architecture lorem of computeMax4 is
  component computeMax2
    port
      (
        a, b       : in  std_logic_vector(15 downto 0);
        max, loser : out std_logic_vector(15 downto 0)
        );
  end component computeMax2;

  signal max1 : std_logic_vector(15 downto 0);
  signal max2 : std_logic_vector(15 downto 0);
  signal max3 : std_logic_vector(15 downto 0);

begin
  M0 : computeMax2
    port map (a, b, max1, loser1);
  M1 : computeMax2
    port map (max1, c, max2, loser2);
  M2 : computeMax2
    port map (max2, d, max3, loser3);

  max <= max3;
end lorem;

-- outputs the maximum of 5 numbers, as well as the 4 'losers'
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity computeMax5 is
  port
    (
      a, b, c, d, e                       : in  std_logic_vector(15 downto 0);
      max, loser1, loser2, loser3, loser4 : out std_logic_vector(15 downto 0)
      );
end computeMax5;

architecture lorem of computeMax5 is
  component computeMax2
    port
      (
        a, b       : in  std_logic_vector(15 downto 0);
        max, loser : out std_logic_vector(15 downto 0)
        );
  end component computeMax2;

  signal max1 : std_logic_vector(15 downto 0);
  signal max2 : std_logic_vector(15 downto 0);
  signal max3 : std_logic_vector(15 downto 0);
  signal max4 : std_logic_vector(15 downto 0);

begin
  M0 : computeMax2
    port map (a, b, max1, loser1);
  M1 : computeMax2
    port map (max1, c, max2, loser2);
  M2 : computeMax2
    port map (max2, d, max3, loser3);
  M3 : computeMax2
    port map (max3, e, max4, loser4);

  max <= max4;
end lorem;

-- takes 5 8-bit inputs, outputs the top 4, sorted, as well as the selected one to display
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity scoring is
  port
    (
      selector                           : in  std_logic_vector(1 downto 0);
      a, b, c, d, e                      : in  std_logic_vector(15 downto 0);
      pos1, pos2, pos3, pos4, displaying : out std_logic_vector(15 downto 0)
      );
end scoring;

architecture intricacies of scoring is
  component computeMax2
    port
      (
        a, b       : in  std_logic_vector(15 downto 0);
        max, loser : out std_logic_vector(15 downto 0)
        );
  end component computeMax2;
  component computeMax3
    port
      (
        a, b, c             : in  std_logic_vector(15 downto 0);
        max, loser1, loser2 : out std_logic_vector(15 downto 0)
        );
  end component computeMax3;
  component computeMax4
    port
      (
        a, b, c, d                  : in  std_logic_vector(15 downto 0);
        max, loser1, loser2, loser3 : out std_logic_vector(15 downto 0)
        );
  end component computeMax4;
  component computeMax5 is
    port
      (
        a, b, c, d, e                       : in  std_logic_vector(15 downto 0);
        max, loser1, loser2, loser3, loser4 : out std_logic_vector(15 downto 0)
        );
  end component computeMax5;

  -- rankings
  signal rank1 : std_logic_vector(15 downto 0);
  signal rank2 : std_logic_vector(15 downto 0);
  signal rank3 : std_logic_vector(15 downto 0);
  signal rank4 : std_logic_vector(15 downto 0);
  -- useless but it gets mapped
  signal rank5 : std_logic_vector(15 downto 0);

  -- remainders used in stage 1
  signal r11 : std_logic_vector(15 downto 0);
  signal r12 : std_logic_vector(15 downto 0);
  signal r13 : std_logic_vector(15 downto 0);
  signal r14 : std_logic_vector(15 downto 0);

  -- remainders used in stage 2
  signal r21 : std_logic_vector(15 downto 0);
  signal r22 : std_logic_vector(15 downto 0);
  signal r23 : std_logic_vector(15 downto 0);

  -- used in stage 3
  signal r31 : std_logic_vector(15 downto 0);
  signal r32 : std_logic_vector(15 downto 0);

begin

  STAGE1 : computeMax5
    port map (a, b, c, d, e, rank1, r11, r12, r13, r14);
  STAGE2 : computeMax4
    port map (r11, r12, r13, r14, rank2, r21, r22, r23);
  STAGE3 : computeMax3
    port map (r21, r22, r23, rank3, r31, r32);
  STAGE4 : computeMax2
    port map(r31, r32, rank4, rank5);

  displaying <= rank1 when selector = "00" else
                rank2 when selector = "01" else
                rank3 when selector = "10" else
                rank4 when selector = "11" else "0000000000000000";

  pos1 <= rank1;
  pos2 <= rank2;
  pos3 <= rank3;
  pos4 <= rank4;

end intricacies;
