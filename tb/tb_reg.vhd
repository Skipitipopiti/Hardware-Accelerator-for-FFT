library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.fixed_pkg.all;

entity tb_reg is
end entity tb_reg;

architecture Behavioral of tb_reg is
    constant N : natural := 8;

    signal clk   : std_logic := '0';
    signal arst  : std_logic := '1';
    signal en    : std_logic := '0';
    signal d_in  : sfixed(0 downto 1-N) := to_sfixed(0.0, N-1, 0);
    signal d_out : sfixed(0 downto 1-N);

    constant CLK_PERIOD : time := 10 ns;

begin
    -- Clock generation
    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    -- DUT instantiation
    DUT: entity work.RegSfixed
        generic map ( HI => 0, LO => 1 - N )
        port map (
            clk   => clk,
            arst  => arst,
            en    => en,
            d_in  => d_in,
            d_out => d_out
        );
    
    -- Stimulus process
    stim_proc: process
    begin
        -- Reset
        arst <= '1';
        wait until falling_edge(clk);
        wait for CLK_PERIOD / 10;
        arst <= '0';

        -- Test sequence
        wait until rising_edge(clk);
        en <= '1';
        d_in <= to_sfixed(0.5, 0, 1-N);

        wait until rising_edge(clk);
        d_in <= to_sfixed(-0.25, 0, 1-N);

        wait until rising_edge(clk);
        en <= '0';
        d_in <= to_sfixed(0.75, 0, 1-N);

        wait;
    end process;
end architecture Behavioral;