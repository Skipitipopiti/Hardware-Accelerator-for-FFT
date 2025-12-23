library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.fixed_pkg.all;
use ieee.fixed_float_types.all;

-- Control Unit per l'unità butterfly
entity butterfly_cu is
    generic ( N : natural := 24 );
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
        sel_sum    : out std_logic;  -- '0' per somma, '1 per sottrazione
        sel_S_or_A : out std_logic;
        sel_shift  : out std_logic;  -- '0' per moltiplicazione, '1' per shift
        sel_Ax     : out std_logic   -- '0' per Ar, '1' per Ai
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
        -- 1 = ciclo completo (fine modalit� continua)
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
    process(current_state, SF_2H_1L)
    begin
        -- Default
        done   <= '0';
        rf_en  <= (others => '0');
        r_sum_en <= '0';
        r_ar_en  <= '0';
        r_ai_en  <= '0';
        sel_sum    <= '0';
        sel_Ax     <= '0';
        sel_shift  <= '0';
        sel_S_or_A <= '0';

        case current_state.step is
            when IDLE =>
                r_ar_en <= '1';
                rf_en(0) <= '1'; -- Br

            when S1 =>
                r_ai_en <= '1';
                rf_en(1) <= '1'; -- Bi

            when S2 =>
                null;

            when S3 =>
                null;

            when S4 =>
                null;

            when S5 =>
                null;

            when S6 =>
                null;

            when others =>
                null;
        end case;
    end process;

end architecture Behavioral;