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
        clk     : in  std_logic;
        arst    : in  std_logic;
        start   : in  std_logic;
        done    : out std_logic;
        A       : in  sfixed(0 downto (1 - N));
        B       : in  sfixed(0 downto (1 - N));
        Wr      : in  sfixed(0 downto (1 - N));
        Wi      : in  sfixed(0 downto (1 - N));
        Ap      : out sfixed(0 downto (1 - N));
        Bp      : out sfixed(0 downto (1 - N))
    );
end entity butterfly;

-- Implementazione comportamentale con macchina a stati finiti
architecture Behavioral of butterfly is
    type step_t is (IDLE, S1, S2, S3, S4, S5, S6, FINISH);
    type state_t is record
        step : step_t;

        -- indica il primo ciclo di calcolo dopo lo start
        --   (serve per la modalità continua)
        first_cycle    : std_logic;

        -- finish_cycle: flag per capire se manca ancora metà ciclo di calcolo
        --   prima di andare al done
        finish_cycle : std_logic;
    end record;

    signal current_state, next_state : state_t;

    type rf_t is array (0 to 5) of sfixed(0 downto (1 - N));
    signal rf_in  : rf_t;
    signal rf_out : rf_t;
    signal rf_en  : std_logic_vector(0 to 5);
begin
    process(clk, arst)
    begin
        if arst = '1' then
            current_state <= (
                step         => IDLE,
                first_cycle  => '1',
                finish_cycle => '0'
            );
            rf_out <= (others => (others => '0'));
        elsif rising_edge(clk) then
            current_state <= next_state;

            -- Scrittura nel register file
            for i in 0 to rf_en'length - 1 loop
                if rf_en(i) = '1' then
                    rf_out(i) <= rf_in(i);
                end if;
            end loop;
        end if;
    end process;

    -- Transizioni di stato
    process(current_state, start)
    begin
        -- Default
        next_state <= current_state;

        case current_state.step is
            when IDLE =>
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
                next_state.finish_cycle <= not start;
                next_state.first_cycle <= '0';

                if current_state.finish_cycle = '1' then
                    next_state.step <= FINISH;
                else
                    next_state.step <= S1;
                end if;
            when FINISH =>
                if start = '0' then
                    next_state.step <= IDLE;
                    next_state.first_cycle <= '1';
                end if;
            when others =>
                next_state <= IDLE;
        end case;
    end process;

end