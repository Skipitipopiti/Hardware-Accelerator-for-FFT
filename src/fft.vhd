library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.fixed_pkg.all;
use ieee.fixed_float_types.all;

package fft_pkg is
    type fft_signal_t is array (natural range<>) of sfixed;
    type fft_signal_array_t is array (natural range<>) of fft_signal_t;
    type slv_array_t is array (natural range<>) of std_logic_vector;

    function next_index(current_index : natural; stages : natural) return natural;
end package fft_pkg;

package body fft_pkg is
    function next_index(constant current_index : natural; constant stages : natural) return natural is
        variable cur_reverse : unsigned(stages-1 downto 0);
        variable sum : unsigned(stages - 1 downto 0);
        variable temp : std_logic;
    begin
        cur_reverse := to_unsigned(current_index, stages);

        -- inverti l'ordine dei bit
        for i in 0 to (stages / 2) - 1 loop
            -- swap
            temp := cur_reverse(i);
            cur_reverse(i) := cur_reverse(stages - 1 - i);
            cur_reverse(stages - 1 - i) := temp;
        end loop;
        
        -- somma 1 con reverse carry (ignora overflow)
        sum := unsigned(cur_reverse + 1)(stages - 1 downto 0);

        -- inverti di nuovo l'ordine dei bit
        for i in 0 to (stages / 2) - 1 loop
            -- swap
            temp := sum(i);
            sum(i) := sum(stages - 1 - i);
            sum(stages - 1 - i) := temp;
        end loop;

        return to_integer(sum);
    end function;
end package body fft_pkg;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.fixed_pkg.all;
use ieee.fixed_float_types.all;
use work.fft_pkg.all;

-- Unità FFT
entity fft is
    generic ( N : natural := 24; STAGES : natural := 4 );
    port (
        clk      : in  std_logic;
        arst     : in  std_logic;
        start    : in  std_logic;
        done     : out std_logic;

        data_in  : in  fft_signal_t(0 to 2**STAGES - 1)(0 downto 1-N);
        data_out : out fft_signal_t(0 to 2**STAGES - 1)(0 downto 1-N)
    );
end entity fft;

architecture Behavioral of fft is
    -- Ingressi butterfly
    signal As, Bs : fft_signal_array_t(0 to STAGES - 1)(0 to 2**STAGES - 1)(0 downto 1-N);
    signal butterfly_start : std_logic_vector(0 to STAGES - 1);

    -- Uscite butterfly
    signal Aps, Bps : fft_signal_array_t(0 to STAGES - 1)(0 to 2**STAGES - 1)(0 downto 1-N);
    signal butterfly_dones : slv_array_t(0 to STAGES - 1)(0 to 2**STAGES - 1);
    signal butterfly_done : std_logic_vector(0 to STAGES - 1);

    constant SF_2H_1L : std_logic_vector(0 to STAGES - 1) := (0 => '1', others => '0');

begin
    As(0) <= data_in;
    Bs(0) <= (others => (others => '0')); -- Input immaginario a 0

    STAGES_INST:
    for stage in 0 to STAGES - 1 generate
        BUTTERFLIES_INST:
        for butterfly_index in 0 to 2**STAGES - 1 generate
            BUTTERFLY_INST : entity work.butterfly
                generic map ( N => N )
                port map (
                    clk      => clk,
                    arst     => arst,
                    start    => butterfly_start(stage),
                    done     => butterfly_dones(stage)(butterfly_index), -- TODO:

                    SF_2H_1L => SF_2H_1L(stage),

                    A        => As(stage)(butterfly_index),
                    B        => Bs(stage)(butterfly_index),
                    Wr       => (others => '0'), -- TODO: calcolare i coefficienti
                    Wi       => (others => '0'), -- TODO: calcolare i coefficienti
                    Ap       => Aps(stage)(butterfly_index),
                    Bp       => Bps(stage)(butterfly_index)
                );
        end generate;
    end generate;

    -- Collegamento tra stadi
    CONNECT_STAGES: for stage in 0 to STAGES - 2 generate
        butterfly_done(stage) <= '1' when butterfly_dones(stage) = (others => '1') else '0';
        butterfly_start(stage + 1) <= butterfly_done(stage);

        CONNECT_BUTTERFLIES: for butterfly_index in 0 to 2**STAGES - 1 generate
            constant next_idx : natural := next_index(butterfly_index, STAGES);
        begin
            As(stage + 1)(butterfly_index) <= Aps(stage)(next_idx);
            Bs(stage + 1)(butterfly_index) <= Bps(stage)(next_idx);
        end generate;
    end generate;

    data_out <= Aps(STAGES - 1); -- Output immaginario a 0
end architecture;