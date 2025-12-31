library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.fixed_pkg.all;
use ieee.fixed_float_types.all;

-- Unità butterfly per FFT
-- vedere timing dei segnali in ingresso A e B e dei segnali in uscita Ap e Bp
entity butterfly is
    generic ( N : natural := 24 );
    port (
        clk      : in  std_logic;
        arst     : in  std_logic;
        start    : in  std_logic;
        done     : out std_logic;
        SF_2H_1L : in  std_logic; -- fattore di scala
        A        : in  sfixed(0 downto 1-N);
        B        : in  sfixed(0 downto 1-N);
        Wr       : in  sfixed(0 downto 1-N);
        Wi       : in  sfixed(0 downto 1-N);
        Ap       : out sfixed(0 downto 1-N);
        Bp       : out sfixed(0 downto 1-N)
    );
end entity butterfly;

architecture Behavioral of butterfly is
    signal rf_en : std_logic_vector(0 to 3);
    signal r_sum_en, r_ar_en, r_ai_en : std_logic;
    signal sel_sum, sel_shift, sel_Ax, sel_Bx, sel_Wx: std_logic;
    signal sel_in_bus, sel_out_bus : std_logic_vector(0 to 2);
    signal sel_sum_in1 : std_logic_vector(1 downto 0);
    signal sel_sum_in2 : std_logic;

begin
    DATAPATH: entity work.butterfly_dp
        generic map ( N => N )
        port map (
            clk       => clk,
            arst      => arst,
            rf_en     => rf_en,
            r_sum_en  => r_sum_en,
            r_ar_en   => r_ar_en,
            r_ai_en   => r_ai_en,
            sel_sum   => sel_sum,
            sel_shift => sel_shift,
            sel_Ax    => sel_Ax,
            sel_Bx    => sel_Bx,
            sel_Wx    => sel_Wx,
            sel_in_bus  => sel_in_bus,
            sel_out_bus => sel_out_bus,
            sel_sum_in1 => sel_sum_in1,
            sel_sum_in2 => sel_sum_in2,
            A  => A,
            B  => B,
            Wr => Wr,
            Wi => Wi,
            Ap => Ap,
            Bp => Bp
        );
    
    CONTROL_UNIT: entity work.butterfly_cu
        port map (
            clk      => clk,
            arst     => arst,
            start    => start,
            done     => done,
            SF_2H_1L => SF_2H_1L,
            rf_en    => rf_en,
            r_sum_en => r_sum_en,
            r_ar_en  => r_ar_en,
            r_ai_en  => r_ai_en,

            sel_sum  => sel_sum,
            sel_shift  => sel_shift,
            sel_Ax    => sel_Ax,
            sel_Bx    => sel_Bx,
            sel_Wx    => sel_Wx,
            sel_in_bus  => sel_in_bus,
            sel_out_bus => sel_out_bus,
            sel_sum_in1 => sel_sum_in1,
            sel_sum_in2 => sel_sum_in2
        );
end architecture Behavioral;