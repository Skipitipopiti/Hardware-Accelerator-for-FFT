library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.fixed_pkg.all;
use ieee.fixed_float_types.all;
use ieee.math_real.all;
use ieee.math_complex.all;
use work.fft_pkg.all;

entity tb_fft is
end entity tb_fft;

architecture tb of tb_fft is
    constant N      : natural := 24;
    constant STAGES : natural := 4;

    signal clk      : std_logic := '0';
    signal arst     : std_logic := '1';
    signal start    : std_logic := '0';
    signal done     : std_logic;
    signal data_in  : fft_signal_t(0 to 2**STAGES - 1)(0 downto 1-N);
    signal data_out : fft_signal_t(0 to 2**STAGES - 1)(0 downto 1-N);

    constant CLK_PERIOD : time := 10 ns;
    constant DELAY : time := CLK_PERIOD/10;

    constant sf_0  : sfixed(0 downto 1-N) := to_sfixed(0.0, 0, 1-N);
    constant sf_m1 : sfixed(0 downto 1-N) := to_sfixed(-1.0, sf_0);
    constant sf_1  : sfixed(0 downto 1-N) := to_sfixed(1.0, sf_0, fixed_saturate);

    -- Vettori di test
    constant x_in : fft_signal_array_t(0 to 4)(0 to 2**STAGES - 1)(0 downto 1-N) := (
        0 => (others => sf_m1),
        1 => (sf_m1, sf_0, sf_1, sf_0, sf_m1, sf_0, sf_1, sf_0, sf_m1, sf_0, sf_1, sf_0, sf_m1, sf_0, sf_1, sf_0),
        2 => (0 => sf_1, others => sf_0),
        3 => (8 => to_sfixed(0.75, 0, 1-N), others => sf_0),
        4 => (0 to 8 => to_sfixed(0.5, 0, 1-N), others => to_sfixed(-0.5, 0, 1-N))
    );
begin
    -- Generazione del clock
    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    -- Istanziamento DUT 
    dut : entity work.fft
        generic map ( N => N, STAGES => STAGES )
        port map (
            clk      => clk,
            arst     => arst,
            start    => start,
            done     => done,

            data_in  => data_in,
            data_out => data_out
        );

    stimuli : process
    begin
        -- Release reset
        wait until falling_edge(clk);
        wait for DELAY;
        arst <= '0';

        -- Applica vettori di test
        wait until rising_edge(clk);
        wait for DELAY;
        start <= '1', '0' after CLK_PERIOD;
        data_in <= x_in(1);

        wait until done = '1';
    wait;
    end process;
end tb;