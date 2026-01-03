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
        clk       : in  std_logic;
        arst      : in  std_logic;
        rf_en     : in  std_logic_vector(0 to 3);
        r_sum_en  : in  std_logic;
        r_ar_en   : in  std_logic;
        r_ai_en   : in  std_logic;

        SF_2H_1L : in  std_logic;  -- fattore di scala

        sel_sum    : in  std_logic;  -- '1' per somma, '0' per sottrazione
        sel_shift  : in  std_logic;  -- '0' per moltiplicazione, '1' per shift
        sel_Ax     : in  std_logic;
        sel_Bx     : in  std_logic;
        sel_Wx     : in  std_logic;

        sel_in_bus  : in  std_logic_vector(0 to 2);
        sel_out_bus : in  std_logic_vector(0 to 2);
        sel_sum_in1 : in  std_logic_vector(1 downto 0);
        sel_sum_in2 : in  std_logic;

        A  : in  sfixed(0 downto 1-N);
        B  : in  sfixed(0 downto 1-N);
        Wr : in  sfixed(0 downto 1-N);
        Wi : in  sfixed(0 downto 1-N);
        Ap : out sfixed(0 downto 1-N);
        Bp : out sfixed(0 downto 1-N)
    );
end entity butterfly_dp;


architecture Behavioral of butterfly_dp is
    constant INTERNAL_WIDTH : natural := 2*N + 1;
    constant HI : integer := 2;
    constant LO : integer := 3 - INTERNAL_WIDTH;

    -- Parametri del ROM rounder
    constant RR_N : natural := 3;
    constant RR_M : natural := 5;

    signal Ax, Br_or_Bi : sfixed(0 downto 1-N);

    -- Il register file deve contenere valori con il parallelismo interno massimo
    type num_array_t is array (natural range <>) of sfixed(HI downto LO);
    signal rf_in  : num_array_t(0 to 3);
    signal rf_out : num_array_t(0 to 3);

    signal in_bus  : num_array_t(0 to 2);
    signal out_bus : num_array_t(0 to 3);

    -- R_Ar: Ar register
    signal r_ar_in  : sfixed(0 downto 1-N);
    signal r_ar_out : sfixed(0 downto 1-N);

    -- R_Ai: Ai register
    signal r_ai_in  : sfixed(0 downto 1-N);
    signal r_ai_out : sfixed(0 downto 1-N);

    signal r_sum_in, r_sum_out : sfixed(HI downto LO);

    signal mul_in1, mul_in2 : sfixed(0 downto 1-N);
    signal mul_out : sfixed(0 downto LO);
    signal mul_shift_out : sfixed(1 downto 1-N);

    
    signal sum_in1, sum_in2 : sfixed(HI downto LO); -- 2N + 1
    signal add_out, sub_out : sfixed(HI+1 downto LO); -- 2N + 2
    signal sum_out_raw      : sfixed(HI downto LO); -- 2N + 1
    signal sum_out_to_round : sfixed(HI downto LO); -- 2N + 1

    signal rounder_in      : sfixed(0 downto LO);
    signal rounder_raw_out : sfixed(0 downto 1-N);
    signal rounder_out     : sfixed(HI downto LO);

begin
    -- Registers
    R_SUM: entity work.Reg
        generic map ( N => INTERNAL_WIDTH )
        port map (
            arst => arst,
            clk  => clk,
            en   => r_sum_en,

            d_in => to_slv(r_sum_in),
            sfixed(d_out) => r_sum_out
        );

    r_sum_in <= sum_out_raw;

    r_ar_in <= A;
    R_AR: entity work.Reg
        generic map ( N => N )
        port map (
            arst => arst,
            clk  => clk,
            en   => r_ar_en,

            d_in => to_slv(r_ar_in),
            sfixed(d_out) => r_ar_out
        );

    r_ai_in <= A;
    R_AI: entity work.Reg
        generic map ( N => N )
        port map (
            arst => arst,
            clk  => clk,
            en   => r_ai_en,

            d_in => to_slv(r_ai_in),
            sfixed(d_out) => r_ai_out
        );
    
    Ax <= r_ar_out when sel_Ax = '0' else r_ai_out;
    
    -- Collegamento con i bus
    -- IN_BUS
    rf_in(0) <= in_bus(0);
    rf_in(1) <= in_bus(1);
    rf_in(2) <= in_bus(2); 
    rf_in(3) <= in_bus(2); -- sia rf(2) che rf(3) sono connessi allo stesso bus
    
    in_bus(0) <= resize(B, HI, LO)
        when sel_in_bus(0) = '0' else rounder_out; -- Br o B'r
    in_bus(1) <= resize(B, HI, LO)
        when sel_in_bus(1) = '0' else resize(mul_out, HI, LO); -- Bi o prodotti
    in_bus(2) <= resize(mul_shift_out, HI, LO)
        when sel_in_bus(2) = '0' else rounder_out; -- 2Ar/2Ai o A'r/A'i/B'i

    -- OUT_BUS
    out_bus(0) <= rf_out(0) when sel_out_bus(0) = '0' else rf_out(2); -- Br/B'r o A'r/B'i
    out_bus(1) <= rf_out(1); -- Bi o prodotti
    out_bus(2) <= rf_out(2) when sel_out_bus(2) = '0' else rf_out(3); -- 2Ar/A'r/B'i o 2Ai/A'i
    out_bus(3) <= r_sum_out; -- somme

    Br_or_Bi <= out_bus(0)(0 downto 1-N)
        when sel_Bx = '0' else out_bus(1)(0 downto 1-N);

    with sel_sum_in1 select sum_in1 <=
        resize(r_ar_out, HI, LO) when "00",
        resize(r_ai_out, HI, LO) when "01",
        out_bus(2)               when "10", -- 2Ar o 2Ai
        out_bus(3)               when others; -- somme

    with sel_sum_in2 select sum_in2 <=
        out_bus(1) when '0', -- Bi o prodotti
        out_bus(3) when others; -- somme
    
    Ap <= out_bus(2)(0 downto 1-N);
    Bp <= out_bus(0)(0 downto 1-N);

    process(clk, arst)
    begin
        if arst = '1' then
            rf_out <= (others => (others => '0'));

        elsif rising_edge(clk) then
            -- Scrittura nel register file
            for i in 0 to rf_en'length - 1 loop
                if rf_en(i) = '1' then
                    rf_out(i) <= rf_in(i);
                end if;
            end loop;
        end if;
    end process;

    mul_in1 <= Ax when sel_shift = '1' else Br_or_Bi;
    mul_in2 <= Wr when sel_Wx = '0' else Wi;
    MUL_INST: entity work.Multiplier
        generic map ( N => N )
        port map (
            clk   => clk,
            A     => mul_in1,
            B     => mul_in2,
            shift => sel_shift,
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
            SUB => sub_out
        );

    sum_out_raw <= add_out(sum_out_raw'high downto sum_out_raw'low) when sel_sum = '1'
        else sub_out(sum_out_raw'high downto sum_out_raw'low);

    -- Scartiamo il bit di overflow (il parallelismo garantisce che non si verifichi)
    with SF_2H_1L select sum_out_to_round <=
        shift_right(sum_out_raw, 1) when '0',
        shift_right(sum_out_raw, 2) when others;

    -- Collegamento al rounder. I bit possono essere scartati perché l'algoritmo
    -- garantisce che non si verifichi overflow
    rounder_in <= sum_out_to_round(0 downto LO);

    ROUNDER_INST: entity work.rom_rounder
        generic map (
            i => 1,
            f => -LO,
            lsb => 1 - N,
            n => RR_N, m => RR_M
        )
        port map (
            cs => '1', -- TODO: controllare il CS dalla CU
            data_in  => rounder_in,
            data_out => rounder_raw_out
        );

    rounder_out <= resize(rounder_raw_out, HI, LO);

end architecture Behavioral;