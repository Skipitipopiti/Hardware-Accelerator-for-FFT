library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Command generator della butterfly
entity butterfly_command is
    port (
        step     : in  std_logic_vector(2 downto 0);
        done     : out std_logic;

        first_half  : in  std_logic;
        second_half : in  std_logic;
        shift_half  : out std_logic;


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
end entity butterfly_command;

architecture Behavioral of butterfly_command is
begin
    -- Operazioni in ogni stato
    process(step, first_half, second_half)
    begin
        -- Default
        done <= '0';
        shift_half <= '0';

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

        case step is
            when "000" =>
                -- input: Ar e Br
                r_ar_en <= '1';
                rf_en(0) <= '1'; -- Br

            when "001" =>
                if first_half = '1' then
                    -- Wr x Br
                    sel_Wx <= '0'; -- Wr
                    sel_Bx <= '0'; -- Br

                    -- input: Ai e Bi
                    r_ai_en <= '1';
                    rf_en(1) <= '1'; -- Bi
                end if;

                if second_half = '1' then
                    -- S4 + WiBr
                    sel_sum <= '0'; -- somma
                    sel_sum_in1 <= "11"; -- in1: somme
                    sel_sum_in2 <= '0'; -- in2: prodotti

                    sel_in_bus(2) <= '0'; -- shift
                    rf_en(3) <= '1'; -- 2Ai

                    sel_sum <= '0'; -- sottrazione
                    r_sum_en <= '1'; -- S2
                end if;

            when "010" =>
                if first_half = '1' then
                    -- Bi x Wr
                    sel_Wx <= '0';
                    sel_Bx <= '1';
                end if;

                if second_half = '1' then
                    -- 2Ar - S2
                    sel_sum_in1 <= "10"; -- 2Ar/2Ai
                    sel_out_bus(2) <= '0'; -- Ar
                    sel_sum_in2 <= '1'; -- somme

                    sel_sum <= '1'; -- somma
                    r_sum_en <= '1'; -- S5

                    sel_in_bus(2) <= '1'; -- rounded A'r
                    rf_en(2) <= '1'; -- A'r
                end if;

            when "011" =>
                if first_half = '1' then
                    -- Bi x Wi
                    sel_Wx <= '1';
                    sel_Bx <= '1';

                    sel_in_bus(1) <= '1'; -- prodotti
                    rf_en(1) <= '1'; -- WrBr
                end if;

                if second_half = '1' then
                    -- 2Ai - S5
                    sel_sum_in1 <= "10"; -- 2Ar/2Ai
                    sel_out_bus(2) <= '1'; -- Ai
                    sel_sum_in2 <= '1'; -- somme

                    sel_in_bus(2) <= '1'; -- rounder out
                    rf_en(3) <= '1'; -- A'i

                    sel_sum <= '0'; -- sottrazione
                    r_sum_en <= '1'; -- S3
                end if;

            when "100" =>
                if first_half = '1' then
                    -- Br x Wi
                    sel_Wx <= '1';
                    sel_Bx <= '0';

                    -- Ar + WrBr
                    sel_sum_in1 <= "00"; -- Ar
                    sel_sum_in2 <= '0'; -- prodotti

                    sel_in_bus(1) <= '1'; -- prodotti
                    rf_en(1) <= '1'; -- WrBi
                end if;

                if second_half = '1' then
                    sel_sum <= '0'; -- sottrazione
                    r_sum_en <= '1'; -- S6

                    sel_in_bus(0) <= '1'; -- rounder out
                    rf_en(0) <= '1'; -- B'r
                end if;

            when "101" =>
                if first_half = '1' then
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

                if second_half = '1' then
                    done <= '1';

                    -- output: A'r e B'r
                    sel_out_bus(2) <= '0'; -- A'r
                    sel_out_bus(0) <= '0'; -- B'r

                    sel_in_bus(2) <= '1'; -- rounder out
                    rf_en(2) <= '1'; -- rounded B'i
                end if;

            when "110" =>
                shift_half <= '1';

                -- input: Ar e Br
                r_ar_en <= '1';
                rf_en(0) <= '1'; -- Br

                if first_half = '1' then
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

                if second_half = '1' then
                    -- output: A'i e B'i
                    sel_out_bus(2) <= '1'; -- A'i
                    sel_out_bus(0) <= '1'; -- B'i
                end if;

            when others =>
                null;
        end case;
    end process;
end architecture Behavioral;