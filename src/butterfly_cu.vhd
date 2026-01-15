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

architecture Microprogrammed of butterfly_cu is
    signal first_half, second_half, shift_half : std_logic;
    signal step : std_logic_vector(2 downto 0);

begin
    process(clk, arst)
    begin
        if arst = '1' then
            first_half  <= '1';
            second_half <= '0';
        elsif rising_edge(clk) then
            if shift_half = '1' then
                second_half <= first_half;
                first_half  <= start;
            elsif step = "000" then
                first_half <= '1';
                second_half <= '0';
            end if;
        end if;
    end process;

    SEQUENCER_INST: entity work.butterfly_sequencer
        port map (
            clk        => clk,
            arst       => arst,
            start      => start,
            first_half => first_half,
            state      => step
        );

    COMMAND_INST: entity work.butterfly_command
        port map (
            step       => step,
            done       => done,

            first_half => first_half,
            second_half => second_half,
            shift_half  => shift_half,

            rf_en      => rf_en,
            r_sum_en   => r_sum_en,
            r_ar_en    => r_ar_en,
            r_ai_en    => r_ai_en,

            sel_sum     => sel_sum,
            sel_shift   => sel_shift,
            sel_Ax      => sel_Ax,
            sel_Bx      => sel_Bx,
            sel_Wx      => sel_Wx,

            sel_in_bus   => sel_in_bus,
            sel_out_bus  => sel_out_bus,
            sel_sum_in1  => sel_sum_in1,
            sel_sum_in2  => sel_sum_in2
        );
end architecture Microprogrammed;

-- Implementazione comportamentale con macchina a stati finiti
architecture Behavioral of butterfly_cu is
    type step_t is (IDLE, S1, S2, S3, S4, S5, S6);
    type state_t is record
        step : step_t;

        -- Indica se eseguire la prima o la seconda iterazione del ciclo (o entrambe)
        first_half, second_half : std_logic;
    end record;

    signal current_state, next_state : state_t;

begin
    -- Aggiornamento stato
    process(clk, arst)
    begin
        if arst = '1' then
            current_state <= (
                step        => IDLE,
                first_half  => '1',
                second_half => '0'
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
                next_state.first_half  <= '1';
                next_state.second_half <= '0';

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
                -- ricomincia se start = '1'
                next_state.first_half <= start;

                -- prosegui con la seconda metà se la prima è stata eseguita
                next_state.second_half <= current_state.first_half;

                -- se non ci sono altre metà da eseguire, torna a IDLE, altrimenti vai a S1
                if start = '1' or current_state.first_half = '1' then
                    next_state.step <= S1;
                else
                    next_state.step <= IDLE;
                end if;
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
                -- input: Ar e Br
                r_ar_en <= '1';
                rf_en(0) <= '1'; -- Br

            when S1 =>
                if current_state.first_half = '1' then
                    -- Wr x Br
                    sel_Wx <= '0'; -- Wr
                    sel_Bx <= '0'; -- Br

                    -- input: Ai e Bi
                    r_ai_en <= '1';
                    rf_en(1) <= '1'; -- Bi
                end if;

                if current_state.second_half = '1' then
                    -- S4 + WiBr
                    sel_sum <= '0'; -- somma
                    sel_sum_in1 <= "11"; -- in1: somme
                    sel_sum_in2 <= '0'; -- in2: prodotti

                    sel_in_bus(2) <= '0'; -- shift
                    rf_en(3) <= '1'; -- 2Ai

                    sel_sum <= '0'; -- sottrazione
                    r_sum_en <= '1'; -- S2
                end if;

            when S2 =>
                if current_state.first_half = '1' then
                    -- Bi x Wr
                    sel_Wx <= '0';
                    sel_Bx <= '1';
                end if;

                if current_state.second_half = '1' then
                    -- 2Ar - S2
                    sel_sum_in1 <= "10"; -- 2Ar/2Ai
                    sel_out_bus(2) <= '0'; -- Ar
                    sel_sum_in2 <= '1'; -- somme

                    sel_sum <= '1'; -- somma
                    r_sum_en <= '1'; -- S5

                    sel_in_bus(2) <= '1'; -- rounded A'r
                    rf_en(2) <= '1'; -- A'r
                end if;

            when S3 =>
                if current_state.first_half = '1' then
                    -- Bi x Wi
                    sel_Wx <= '1';
                    sel_Bx <= '1';

                    sel_in_bus(1) <= '1'; -- prodotti
                    rf_en(1) <= '1'; -- WrBr
                end if;

                if current_state.second_half = '1' then
                    -- 2Ai - S5
                    sel_sum_in1 <= "10"; -- 2Ar/2Ai
                    sel_out_bus(2) <= '1'; -- Ai
                    sel_sum_in2 <= '1'; -- somme

                    sel_in_bus(2) <= '1'; -- rounder out
                    rf_en(3) <= '1'; -- A'i

                    sel_sum <= '0'; -- sottrazione
                    r_sum_en <= '1'; -- S3
                end if;

            when S4 =>
                if current_state.first_half = '1' then
                    -- Br x Wi
                    sel_Wx <= '1';
                    sel_Bx <= '0';

                    -- Ar + WrBr
                    sel_sum_in1 <= "00"; -- Ar
                    sel_sum_in2 <= '0'; -- prodotti

                    sel_in_bus(1) <= '1'; -- prodotti
                    rf_en(1) <= '1'; -- WrBi
                end if;

                if current_state.second_half = '1' then
                    sel_sum <= '0'; -- sottrazione
                    r_sum_en <= '1'; -- S6

                    sel_in_bus(0) <= '1'; -- rounder out
                    rf_en(0) <= '1'; -- B'r
                end if;

            when S5 =>
                if current_state.first_half = '1' then
                    -- Ai + WrBi
                    sel_sum_in1 <= "01"; -- Ai
                    sel_sum_in2 <= '0'; -- prodotti

                    -- 2*Ar
                    sel_shift <= '1';
                    sel_Ax <= '0'; -- Ar

                    sel_sum <= '1'; -- somma
                    r_sum_en <= '1'; -- S1

                    sel_in_bus(1) <= '1'; -- prodotto
                    rf_en(1) <= '1'; -- WiBi
                end if;

                if current_state.second_half = '1' then
                    done <= '1';

                    -- output: A'r e B'r
                    sel_out_bus(2) <= '0'; -- A'r
                    sel_out_bus(0) <= '0'; -- B'r

                    sel_in_bus(2) <= '1'; -- rounder out
                    rf_en(2) <= '1'; -- rounded B'i
                end if;

            when S6 =>
                -- input: Ar e Br
                r_ar_en <= '1';
                rf_en(0) <= '1'; -- Br

                if current_state.first_half = '1' then
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
                end if;

                if current_state.second_half = '1' then
                    -- output: A'i e B'i
                    sel_out_bus(2) <= '1'; -- A'i
                    sel_out_bus(0) <= '1'; -- B'i
                end if;

            when others =>
                null;
        end case;
    end process;

end architecture Behavioral;