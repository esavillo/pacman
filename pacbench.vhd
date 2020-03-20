-- Evan Savillo
-- pacbench

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pacbench is
    end pacbench;

architecture test of pacbench is
    constant num_cycles : integer := 100000000;

    signal vga_hs : std_logic;                     -- vga horizontal sync
    signal vga_vs : std_logic;                     -- vga vertical sync
    signal rd      : std_logic_vector(3 downto 0);  -- output red
    signal grn      : std_logic_vector(3 downto 0);  -- output green
    signal bl      : std_logic_vector(3 downto 0);   -- output blue

    signal clk   : std_logic := '1';
    signal reset : std_logic;

  -- component statement for pacman
    component pacman
        port(
                clk           : in  std_logic;
                reset         : in  std_logic;

                l             : in  std_logic;
                u             : in  std_logic;
                d             : in  std_logic;
                r             : in  std_logic;

                VGAr          : out std_logic_vector(3 downto 0);
                VGAg          : out std_logic_vector(3 downto 0);
                VGAb          : out std_logic_vector(3 downto 0);
                VGAhorizontal : out std_logic;
                VGAvertical   : out std_logic
            );

    end component;

begin
    pacman_instance : pacman
    port map(clk => clk, reset => reset, l => '0', u => '0', d => '0', r => '0', VGAr => rd, VGAg => grn, VGAb => bl, VGAhorizontal => vga_hs, VGAvertical => vga_vs);


  -- start off with a short reset
    reset <= '0', '1' after 1 ns;

  -- create a clock
    process
    begin
        for i in 1 to num_cycles loop
            clk <= not clk;
            wait for 1 ns;

            clk <= not clk;
            wait for 1 ns;
        end loop;
        wait;
    end process;

end test;
