library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.fixed_pkg.all;
use ieee.fixed_float_types.all;

-- Control Unit per l'unità butterfly
entity butterfly_cu is
    port (
        clk      : in  std_logic;
        arst     : in  std_logic;
        start    : in  std_logic;
        done     : out std_logic;
        SF_2H_1L : in  std_logic; -- fattore di scala
        rf_en    : out std_logic_vector(0 to 3);
        r_sum_en : out std_logic;
        r_ar_en  : out std_logic;
        r_ai_en  : out std_logic;

        sel_sum    : out std_logic; -- '0' per somma, '1 per sottrazione
        sel_shift  : out std_logic; -- '0' per moltiplicazione, '1' per shift
        sel_Ax     : out std_logic; -- '0' per Ar, '1' per Ai
        sel_Bx     : out std_logic; -- '0' per Br, '1' per Bi
        sel_Wx     : out std_logic; -- '0' per Wr, '1' per Wi

        sel_in_bus  : out std_logic_vector(0 to 2);
        sel_out_bus : out std_logic_vector(0 to 2);
        sel_sum_in1 : out std_logic_vector(1 downto 0);
        sel_sum_in2 : out std_logic
    );
end entity butterfly_cu;

-- Implementazione comportamentale con macchina a stati finiti
architecture Behavioral of butterfly_cu is
    type step_t is (IDLE, S1, S2, S3, S4, S5, S6);
    type state_t is record
        step : step_t;

        -- finish_cycle: flag per capire se manca ancora metà ciclo di calcolo
        -- prima di andare al done
        -- 0 = manca metà ciclo
        -- 1 = ciclo completo (fine modalità continua)
        finish_cycle : std_logic;
    end record;

    signal current_state, next_state : state_t;

begin
    -- Aggiornamento stato
    process(clk, arst)
    begin
        if arst = '1' then
            current_state <= (
                step         => IDLE,
                finish_cycle => '0'
            );
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process;

    -- Transizioni di stato
    process(current_state, start)
    begin
        -- Default
        next_state <= current_state;

        case current_state.step is
            when IDLE =>
                next_state.finish_cycle <= '0';

                if start = '1' then
                    next_state.step <= S1;
                end if;
            when S1 =>
                next_state.step <= S2;
            when S2 =>
                next_state.step <= S3;
            when S3 =>
                next_state.step <= S4;
            when S4 =>
                next_state.step <= S5;
            when S5 =>
                next_state.step <= S6;
            when S6 =>
                if current_state.finish_cycle = '1' then
                    next_state.step <= IDLE;
                else
                    next_state.step <= S1;
                end if;

                next_state.finish_cycle <= not start;
            
            when others =>
                next_state.step <= IDLE;
        end case;
    end process;

    -- Operazioni in ogni stato
    process(current_state)
    begin
        -- Default
        done <= '0';

        rf_en    <= (others => '0');
        r_sum_en <= '0';
        r_ar_en  <= '0';
        r_ai_en  <= '0';

        sel_sum    <= '0';
        sel_shift  <= '0';

        sel_Ax     <= '0';
        sel_Bx     <= '0';
        sel_Wx     <= '0';

        sel_in_bus  <= "000";
        sel_out_bus <= "000";

        case current_state.step is
            when IDLE =>
                -- Ar e Br
                r_ar_en <= '1';
                rf_en(0) <= '1'; -- Br

            when S1 =>
                -- Wr x Br
                sel_Wx <= '0'; -- Wr
                sel_Bx <= '0'; -- Br

                -- input: Ai e Bi
                r_ai_en <= '1';
                rf_en(1) <= '1'; -- Bi

                --

                -- S4 + WiBr
                sel_sum <= '0'; -- somma
                sel_sum_in1 <= "11"; -- in1: somme
                sel_sum_in2 <= '0'; -- in2: prodotti

                sel_in_bus(2) <= '0'; -- shift
                rf_en(3) <= '1'; -- 2Ai

                sel_sum <= '0'; -- sottrazione
                r_sum_en <= '1'; -- S2

            when S2 =>
                -- Bi x Wr
                sel_Wx <= '0';
                sel_Bx <= '1';

                --

                -- 2Ar - S2
                sel_sum_in1 <= "10"; -- 2Ar/2Ai
                sel_out_bus(2) <= '0'; -- Ar
                sel_sum_in2 <= '1'; -- somme

                sel_sum <= '1'; -- somma
                r_sum_en <= '1'; -- S5

                sel_in_bus(2) <= '1'; -- rounded A'r
                rf_en(2) <= '1'; -- A'r

            when S3 =>
                -- Bi x Wi
                sel_Wx <= '1';
                sel_Bx <= '1';

                sel_in_bus(1) <= '1'; -- prodotti
                rf_en(1) <= '1'; -- WrBr

                --

                -- 2Ai - S5
                sel_sum_in1 <= "10"; -- 2Ar/2Ai
                sel_out_bus(2) <= '1'; -- Ai
                sel_sum_in2 <= '1'; -- somme

                sel_in_bus(2) <= '1'; -- rounder out
                rf_en(3) <= '1'; -- A'i

                sel_sum <= '0'; -- sottrazione
                r_sum_en <= '1'; -- S3

            when S4 =>
                -- Br x Wi
                sel_Wx <= '1';
                sel_Bx <= '0';

                -- Ar + WrBr
                sel_sum_in1 <= "00"; -- Ar
                sel_sum_in2 <= '0'; -- prodotti

                sel_in_bus(1) <= '1'; -- prodotti
                rf_en(1) <= '1'; -- WrBi

                --

                sel_sum <= '0'; -- sottrazione
                r_sum_en <= '1'; -- S6

                sel_in_bus(0) <= '1'; -- rounder out
                rf_en(0) <= '1'; -- B'r

            when S5 =>
                -- Ai + WrBi
                sel_sum_in1 <= "01"; -- Ai
                sel_sum_in2 <= '0'; -- prodotti

                -- 2*Ar
                sel_shift <= '1';
                sel_Ax <= '0'; -- Ar

                sel_sum <= '1'; -- somma
                r_sum_en <= '1'; -- S1

                rf_en(2) <= '1'; -- WiBi

                --

                -- output: A'r e B'r
                sel_out_bus(2) <= '0'; -- A'r
                sel_out_bus(0) <= '0'; -- B'r

                sel_in_bus(2) <= '1'; -- rounder out
                rf_en(2) <= '1'; -- rounded B'i

            when S6 =>
                -- 2*Ai
                sel_shift <= '1';
                sel_Ax <= '1'; -- Ai

                -- S1 - WiBi
                sel_sum_in1 <= "11"; -- somme
                sel_sum_in2 <= '0'; -- prodotti

                sel_in_bus(1) <= '1'; -- prodotto
                rf_en(1) <= '1'; -- WiBr

                sel_sum <= '1'; -- addizione
                r_sum_en <= '1'; -- S4

                rf_en(2) <= '1'; -- 2Ar

                --

                -- output: A'r e B'r
                sel_out_bus(2) <= '1'; -- A'i
                sel_out_bus(0) <= '1'; -- B'i

                r_ar_en <= '1'; -- Ar
                rf_en(0) <= '1'; -- Br

            when others =>
                null;
        end case;
    end process;

end architecture Behavioral;