library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.fixed_pkg.all;
use ieee.fixed_float_types.all;
use ieee.math_real.all;
use ieee.math_complex.all;

package fft_pkg is
    type fft_signal_t is array (natural range<>) of sfixed;
    type fft_signal_array_t is array (natural range<>) of fft_signal_t;
    type slv_array_t is array (natural range<>) of std_logic_vector;

    function next_index(current_index : natural; stages : natural) return natural;
    function twiddle(constant k : natural; constant stages : natural) return complex;
end package fft_pkg;

package body fft_pkg is
    function reverse_array(arr : unsigned) 
        return unsigned is
        variable result : unsigned(arr'reverse_range);
    begin
        for i in arr'range loop
            result(i) := arr(i);
        end loop;
        return result;
    end function;

    -- TODO: testare
    function next_index(constant current_index : natural; constant stages : natural) return natural is
        variable current_reversed : unsigned(stages-1 downto 0);
        variable sum : unsigned(stages - 1 downto 0);
    begin
        if stages = 0 then
            return 0;
        end if;

        current_reversed := reverse_array(to_unsigned(current_index, stages));
        
        -- somma 1 con reverse carry (ignora overflow)
        sum := unsigned(current_reversed + 1);
        sum := reverse_array(sum);

        return to_integer(sum);
    end function;

    function twiddle(constant k : natural; constant stages : natural) return complex is
        variable W : complex;
        variable theta : real := 2.0 * MATH_PI / real(stages) * real(k);
    begin
        W.RE := cos(theta);
        W.IM := -sin(theta);
        return W;
    end function;
end package body fft_pkg;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.fixed_pkg.all;
use ieee.fixed_float_types.all;
use ieee.math_complex.all;
use work.fft_pkg.all;

-- Unità FFT
entity fft is
    generic ( N : positive := 24; STAGES : positive := 4 );
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
    signal butterfly_in  : fft_signal_array_t(0 to STAGES)(0 to 2**STAGES - 1)(0 downto 1-N);
    signal butterfly_start : std_logic_vector(0 to STAGES);

    -- Uscite butterfly
    signal butterfly_out : fft_signal_array_t(0 to STAGES - 1)(0 to 2**STAGES - 1)(0 downto 1-N);
    signal butterfly_dones : slv_array_t(0 to STAGES - 1)(0 to 2**(STAGES-1) - 1);
    signal butterfly_done : std_logic_vector(0 to STAGES - 1);

    signal SF_2H_1L : std_logic_vector(0 to STAGES - 1);

begin
    butterfly_in(0) <= data_in;
    butterfly_start(0) <= start;
    done <= butterfly_start(STAGES);

    SF_2H_1L(0) <= '1';
    SF_2H_1L(1 to STAGES-1) <= (others => '0');

    STAGES_INST:
    for stage_index in 0 to STAGES-1 generate
        -- Il prodotto n° butterfly/blocco * n° blocchi/stadio è costante (STAGES/2 butterfly/stadio)
        constant N_BLOCKS : natural := 2**stage_index;
        constant N_BUTTERFLIES_PER_BLOCK : natural := 2**(STAGES-1) / N_BLOCKS;
    begin
        BLOCKS_INST:
        for blk_index in 0 to N_BLOCKS-1 generate
            constant BLOCK_OFFSET : natural := blk_index * N_BUTTERFLIES_PER_BLOCK;
            constant k : natural := next_index(blk_index, stage_index) * N_BUTTERFLIES_PER_BLOCK;
            constant W : complex := twiddle(k, STAGES);
        begin
            BUTTERFLIES_INST:
            for bfly_index in 0 to N_BUTTERFLIES_PER_BLOCK - 1 generate
            begin
                butterfly_inst : entity work.butterfly
                    generic map (
                        N => N
                    )
                    port map (
                        clk => clk,
                        arst => arst,

                        start => butterfly_start(stage_index),
                        done => butterfly_dones(stage_index)(BLOCK_OFFSET + bfly_index),
                        SF_2H_1L => SF_2H_1L(stage_index),

                        A => butterfly_in(stage_index)(BLOCK_OFFSET + bfly_index),
                        B => butterfly_in(stage_index)(BLOCK_OFFSET + N_BUTTERFLIES_PER_BLOCK + bfly_index),
                        Wr => to_sfixed(W.RE, 0, 1-N, fixed_saturate, fixed_round),
                        Wi => to_sfixed(W.IM, 0, 1-N, fixed_saturate, fixed_round),

                        Ap => butterfly_out(stage_index)(BLOCK_OFFSET + bfly_index),
                        Bp => butterfly_out(stage_index)(BLOCK_OFFSET + N_BUTTERFLIES_PER_BLOCK + bfly_index)
                    );

                    butterfly_in(stage_index+1) <= butterfly_out(stage_index);
                    butterfly_start(stage_index+1) <= butterfly_done(stage_index);
            end generate;
        end generate;
        
        butterfly_done(stage_index) <= '1' when butterfly_dones(stage_index) = (butterfly_dones(stage_index)'range => '1') else '0';
    end generate;

    REORDER_OUT:
    for i in 0 to 2**STAGES - 1 generate
        data_out(i) <= butterfly_in(STAGES)(next_index(i, STAGES));
    end generate;
end architecture;