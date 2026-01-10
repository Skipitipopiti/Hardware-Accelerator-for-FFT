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
    signal done     : std_logic := '0';
    signal data_in  : fft_signal_t(0 to 2**STAGES - 1)(0 downto 1-N);
    signal data_out : fft_signal_t(0 to 2**STAGES - 1)(0 downto 1-N);

    constant CLK_PERIOD : time := 10 ns;
    constant DELAY : time := CLK_PERIOD/10;
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
        start <= '1', '0' after CLK_PERIOD, '1' after 6*CLK_PERIOD, '0' after 7*CLK_PERIOD;
        data_in(0) <= to_sfixed( 0.27885, 0, 1-N), to_sfixed(-0.94998, 0, 1-N) after CLK_PERIOD, -- Seed: 42 
            to_sfixed(-0.73127, 0, 1-N) after 6*CLK_PERIOD, to_sfixed( 0.69487, 0, 1-N) after 7*CLK_PERIOD; -- Seed: -1

        data_in(1) <= to_sfixed(-0.44994, 0, 1-N), to_sfixed(-0.55358, 0, 1-N) after CLK_PERIOD, -- Seed: 42
            to_sfixed( 0.52755, 0, 1-N) after 6*CLK_PERIOD, to_sfixed(-0.48986, 0, 1-N) after 7*CLK_PERIOD; -- Seed: -1

        -- Aspetta il primo done
        wait until done = '1';
        report "1st done reached";

        -- Aspetta il secondo done
        wait until done = '1';
        report "2nd done reached";

    wait;
    end process;
end tb;