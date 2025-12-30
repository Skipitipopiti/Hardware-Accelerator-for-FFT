-- Datapath Butterfly
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.fixed_pkg.all;
use ieee.fixed_float_types.all;

entity butterfly_dp is
    -- N: parallelismo dati in ingresso e in uscita
    generic ( N : natural := 24 );
    port (
        clk      : in  std_logic;
        arst     : in  std_logic;
        rf_en    : in  std_logic_vector(0 to 3);
        r_sum_en : in  std_logic;
        r_ar_en  : in  std_logic;
        r_ai_en  : in  std_logic;
        sum_sel  : in  std_logic;  -- sceglie il risultato da prendere: '0' per somma, '1' per sottrazione
        A        : in  sfixed(0 downto 1-N);
        B        : in  sfixed(0 downto 1-N);
        Wr       : in  sfixed(0 downto 1-N);
        Wi       : in  sfixed(0 downto 1-N);
        Ap       : out sfixed(0 downto 1-N);
        Bp       : out sfixed(0 downto 1-N)
    );
end entity butterfly_dp;


architecture Behavioral of butterfly_dp is
    constant INTERNAL_WIDTH : natural := 2*N + 2;

    -- Il register file deve contenere valori con il parallelismo interno massimo
    type rf_t is array (0 to 3) of sfixed;
    signal rf_in  : rf_t;
    signal rf_out : rf_t;

    -- R_Ar: Ar register
    signal r_ar_in  : sfixed(0 downto 1-N);
    signal r_ar_out : sfixed(0 downto 1-N);

    -- R_Ai: Ai register
    signal r_ai_in  : sfixed(0 downto 1-N);
    signal r_ai_out : sfixed(0 downto 1-N);

    -- R_sum: sum register
    signal r_sum_in  : sfixed(0 downto 1-INTERNAL_WIDTH);
    signal r_sum_out : sfixed(0 downto 1-INTERNAL_WIDTH);

    
    signal mul_in1, mul_in2 : sfixed(0 downto 1-N);
    signal mul_out : sfixed(0 downto 2-2*N);
    signal mul_shift_out : sfixed(1 downto 1-N);

    
    signal sum_in1, sum_in2 : sfixed(1 downto 1-2*N);
    signal add_out, sub_out, sum_out : sfixed(3 downto 2-2*N);
    signal sum_out_ext : sfixed(0 downto 1-INTERNAL_WIDTH);

begin
    -- Registers
    R_AR: entity work.Reg
        generic map ( N => N )
        port map (
            arst => arst,
            clk  => clk,
            en   => r_ar_en,

            d_in => std_logic_vector(r_ar_in),
            sfixed(d_out) => r_ar_out
        );

    R_AI: entity work.Reg
        generic map ( N => N )
        port map (
            arst => arst,
            clk  => clk,
            en   => r_ai_en,

            d_in => std_logic_vector(r_ai_in),
            sfixed(d_out) => r_ai_out
        );
    
    R_SUM: entity work.Reg
        generic map ( N => INTERNAL_WIDTH )
        port map (
            arst => arst,
            clk  => clk,
            en   => r_sum_en,

            d_in => std_logic_vector(r_sum_in),
            sfixed(d_out) => r_sum_out
        );


    process(clk, arst)
    begin
        if arst = '1' then
            rf_out <= (others => (others => '0'));
            r_sum_out <= (others => '0');
            r_ar_out <= (others => '0');
            r_ai_out <= (others => '0');

        elsif rising_edge(clk) then
            -- Scrittura nel register file
            for i in 0 to rf_en'length - 1 loop
                if rf_en(i) = '1' then
                    rf_out(i) <= rf_in(i);
                end if;
            end loop;
        end if;
    end process;
    
    MUL_INST: entity work.Multiplier
        generic map ( N => N )
        port map (
            clk   => clk,
            A     => mul_in1,
            B     => mul_in2,
            PROD  => mul_out,
            Two_A => mul_shift_out
        );

    
    ADD_INST: entity work.Adder
        generic map ( N => 2*N+1 )
        port map (
            clk => clk,
            A   => sum_in1,
            B   => sum_in2,
            SUM => add_out
        );

    
    SUB_INST: entity work.Subtractor
        generic map ( N => 2*N+1 )
        port map (
            clk => clk,
            A   => sum_in1,
            B   => sum_in2,
            SUM => sub_out
        );

    sum_out <= add_out when sum_sel = '0' else sub_out;
    sum_out_ext <= resize(sum_out, sum_out_ext'high, sum_out_ext'low);
    r_sum_in <= sum_out_ext;
end architecture Behavioral;