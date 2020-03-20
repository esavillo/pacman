-- Evan Savillo
-- hexDigitDisplay.vhd : displays a 4-bit number as as seven-segment-display digit


library ieee;
use ieee.std_logic_1164.all;

entity hexDigitDisplay is
  port
    (
      i      : in  std_logic_vector(3 downto 0);
      h      : out std_logic_vector(6 downto 0);
      nulled : in  std_logic
      );
end hexDigitDisplay;

architecture incantation of hexDigitDisplay is
begin
  h(0) <= '1' when nulled = '1' else
          '1' when i = "0001" or i = "0100" or i = "1011" or i = "1101"
          else '0';
  h(1) <= '1' when nulled = '1' else
          '1' when i = "0101" or i = "0110" or i = "1011" or i = "1100" or i = "1110" or i = "1111"
          else '0';
  h(2) <= '1' when nulled = '1' else
          '1' when i = "0010" or i = "1100" or i = "1110" or i = "1111"
          else '0';
  h(3) <= '1' when nulled = '1' else
          '1' when i = "0001" or i = "0100" or i = "0111" or i = "1001" or i = "1010" or i = "1111"
          else '0';
  h(4) <= '1' when nulled = '1' else
          '1' when i = "0001" or i = "0011" or i = "0100" or i = "0101" or i = "0111" or i = "1001"
          else '0';
  h(5) <= '1' when nulled = '1' else
          '1' when i = "0001" or i = "0010" or i = "0011" or i = "0111" or i = "1101"
          else '0';
  h(6) <= '0' when nulled = '1' else
          '1' when i = "0000" or i = "0001" or i = "0111" or i = "1100"
          else '0';
end incantation;
