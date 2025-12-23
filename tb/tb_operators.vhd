library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.fixed_pkg.all;
use ieee.fixed_float_types.all;

entity tb_operators is
end entity tb_operators;

architecture Behavioral of tb_operators is

    -- Parametri
    constant N : natural := 24;

    -- Segnali generali
    signal clk  : std_logic := '0';
    signal arst : std_logic := '1';

    -- Segnali per butterfly
    signal start    : std_logic := '0';
    signal done     : std_logic;
    signal SF_2H_1L : std_logic := '0';
    signal A        : sfixed(0 downto 1-N) := (others => '0');
    signal B        : sfixed(0 downto 1-N) := (others => '0');
    signal Wr       : sfixed(0 downto 1-N) := (others => '0');
    signal Wi       : sfixed(0 downto 1-N) := (others => '0');
    signal Ap       : sfixed(0 downto 1-N);
    signal Bp       : sfixed(0 downto 1-N);

begin
end architecture Behavioral;