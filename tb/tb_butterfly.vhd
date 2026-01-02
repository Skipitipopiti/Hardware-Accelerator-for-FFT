library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.fixed_pkg.all;
use ieee.fixed_float_types.all;

entity tb_butterfly is
end entity tb_butterfly;

architecture Behavioral of tb_butterfly is
    constant N : natural := 24;

    signal clk      : std_logic := '0';
    signal arst     : std_logic := '1';
    signal start    : std_logic := '0';
    signal done     : std_logic;
    signal SF_2H_1L : std_logic := '0';
    signal A        : sfixed(0 downto 1-N) := to_sfixed(0.0, 0, 1-N);
    signal B        : sfixed(0 downto 1-N) := to_sfixed(0.0, 0, 1-N);
    signal Wr       : sfixed(0 downto 1-N) := to_sfixed(0.70710678, 0, 1-N); -- cos(pi/4)
    signal Wi       : sfixed(0 downto 1-N) := to_sfixed(-0.70710678, 0, 1-N); -- -sin(pi/4)
    signal Ap       : sfixed(0 downto 1-N);
    signal Bp       : sfixed(0 downto 1-N);

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
    DUT: entity work.butterfly
        generic map ( N => N )
        port map (
            clk      => clk,
            arst     => arst,
            start    => start,
            done     => done,
            SF_2H_1L => SF_2H_1L,
            A        => A,
            B        => B,
            Wr       => Wr,
            Wi       => Wi,
            Ap       => Ap,
            Bp       => Bp
        );

    -- Stimulus process
    stim_proc: process
    begin
        -- Release reset
        wait for 3/2*CLK_PERIOD;
        arst <= '0';
        wait for CLK_PERIOD/2;

        -- Apply test vectors
        A <= to_sfixed(0.5, 0, 1-N);
        B <= to_sfixed(0.25, 0, 1-N);
        SF_2H_1L <= '0'; -- No scaling

        -- Start operation
        start <= '1';
        wait for CLK_PERIOD;
        start <= '0';

        -- Wait for done signal
        wait until done = '1';
        wait for CLK_PERIOD;

    end process;
end architecture Behavioral;