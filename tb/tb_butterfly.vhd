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
    signal A        : sfixed(0 downto 1-N);
    signal B        : sfixed(0 downto 1-N);
    signal Wr       : sfixed(0 downto 1-N);
    signal Wi       : sfixed(0 downto 1-N);
    signal Ap       : sfixed(0 downto 1-N);
    signal Bp       : sfixed(0 downto 1-N);

    signal Ares, Bres : sfixed(2 downto 1-N);

    constant CLK_PERIOD : time := 10 ns;
    constant DELAY : time := CLK_PERIOD/10;

begin
    process(SF_2H_1L, Ap, Bp)
    begin
        if SF_2H_1L = '0' then
            Ares <= shift_left(resize(Ap, Ares'high, Ares'low), 1);
            Bres <= shift_left(resize(Bp, Bres'high, Bres'low), 1);
        else
            Ares <= shift_left(resize(Ap, Ares'high, Ares'low), 2);
            Bres <= shift_left(resize(Bp, Bres'high, Bres'low), 2);
        end if;
    end process;

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
        wait until falling_edge(clk);
        wait for DELAY;
        Wr <= to_sfixed( 0.70711, 0, 1-N);  -- cos(pi/4)
        Wi <= to_sfixed(-0.70711, 0, 1-N); -- -sin(pi/4)
        arst <= '0';
        SF_2H_1L <= '1'; -- 4x scaling perché l'input non proviene da un'altra butterfly

        -- Apply test vectors
        wait until rising_edge(clk);
        wait for DELAY;
        start <= '1', '0' after CLK_PERIOD, '1' after 6*CLK_PERIOD, '0' after 7*CLK_PERIOD;
        A <= to_sfixed( 0.27885, 0, 1-N), to_sfixed(-0.94998, 0, 1-N) after CLK_PERIOD, -- Seed: 42 
            to_sfixed(-0.73127, 0, 1-N) after 6*CLK_PERIOD, to_sfixed( 0.69487, 0, 1-N) after 7*CLK_PERIOD; -- Seed: -1

        B <= to_sfixed(-0.44994, 0, 1-N), to_sfixed(-0.55358, 0, 1-N) after CLK_PERIOD, -- Seed: 42
            to_sfixed( 0.52755, 0, 1-N) after 6*CLK_PERIOD, to_sfixed(-0.48986, 0, 1-N) after 7*CLK_PERIOD; -- Seed: -1

        -- Wait for first done signal
        wait until done = '1';
        report "1st done reached";

        -- Wait for second done signal
        wait until done = '1';
        report "2nd done reached";

        wait;
    end process;
end architecture Behavioral;