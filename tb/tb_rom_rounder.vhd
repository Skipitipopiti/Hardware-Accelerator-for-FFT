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

    signal cs       : std_logic;
    signal addr     : ufixed(n - 1 downto -m);
    signal data_out : unsigned(n - 1 downto 0);

    constant TbPeriod : time := 10 ns;
begin

    dut : entity work.ROM_Rounder
    generic map ( n => n, m => m )
    port map (cs       => cs,
              addr     => addr,
              data_out => data_out);

    stimuli : process
    begin
        cs <= '0', '1' after 1.5*TbPeriod, '0' after 6.5*TbPeriod;

        wait for TbPeriod/2 + 1 ns;

        addr <= to_ufixed(0, addr'high, addr'low),
            to_ufixed(0.7, addr'high, addr'low)  after 1*TbPeriod, -- round up 
            to_ufixed(3.2, addr'high, addr'low)  after 2*TbPeriod, -- round down
            to_ufixed(7.6, addr'high, addr'low)  after 3*TbPeriod, -- saturazione
            to_ufixed(1.5, addr'high, addr'low)  after 4*TbPeriod, -- nearest even
            to_ufixed(4.5, addr'high, addr'low)  after 5*TbPeriod, -- nearest even
            to_ufixed(4.1, addr'high, addr'low)  after 6*TbPeriod; -- test CS
        
        wait;
    end process;
end tb;