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

    constant i : natural := n + 1;
    constant f : natural := m + 3;

    signal cs       : std_logic;
    signal data_in  : sfixed(i - 1 downto -f);
    signal data_out : sfixed(i - 1 downto 0);

    constant TbPeriod : time := 10 ns;
begin

    dut : entity work.ROM_Rounder
    generic map (
        i => n+1, f => f,
        lsb => 0,
        n => n, m => m
    )
    port map (
        cs => cs,
        data_in  => data_in,
        data_out => data_out
    );

    stimuli : process
    begin
        cs <= '0', '1' after 1.5*TbPeriod, '0' after 6.5*TbPeriod;

        wait for TbPeriod/2 + 1 ns;

        data_in <= to_sfixed(0, data_in'high, data_in'low),
            to_sfixed(0.7, data_in'high, data_in'low)  after 1*TbPeriod, -- round up 
            to_sfixed(3.2, data_in'high, data_in'low)  after 2*TbPeriod, -- round down
            to_sfixed(7.6, data_in'high, data_in'low)  after 3*TbPeriod, -- saturazione
            to_sfixed(1.5, data_in'high, data_in'low)  after 4*TbPeriod, -- nearest even
            to_sfixed(4.5, data_in'high, data_in'low)  after 5*TbPeriod, -- nearest even
            to_sfixed(4.1, data_in'high, data_in'low)  after 6*TbPeriod; -- test CS
        
        wait;
    end process;
end tb;