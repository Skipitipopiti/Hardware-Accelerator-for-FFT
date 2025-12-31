library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.fixed_pkg.all;
use ieee.fixed_float_types.all;

entity tb_ROM_Rounder is
end tb_ROM_Rounder;

architecture tb of tb_ROM_Rounder is
    constant n : natural := 3;
    constant m : natural := 5;

    component ROM_Rounder
        generic ( n : natural; m : natural);
        port (cs       : in std_logic;
              addr     : in std_logic_vector ( (m + n - 1) downto 0);
              data_out : out std_logic_vector (n-1 downto 0));
    end component;

    signal cs       : std_logic;
    signal addr     : std_logic_vector ( (m + n - 1) downto 0);
    signal data_out : std_logic_vector (n-1 downto 0);

    constant TbPeriod : time := 100 ns;
begin

    dut : ROM_Rounder
    generic map ( n => n, m => m)
    port map (cs       => cs,
              addr     => addr,
              data_out => data_out);

    stimuli : process
    begin
        cs <= '0', '1' after 1.5*TbPeriod, '0' after 5.5*TbPeriod;
        addr <= (others => '0'), "11110000" after TbPeriod, "00001111" after 2*TbPeriod,
        "10101010" after 3*TbPeriod, "11111111" after 4*TbPeriod, "11001100" after 5*TbPeriod,
        "11001100" after 6*TbPeriod;
        wait;
    end process;

end tb;