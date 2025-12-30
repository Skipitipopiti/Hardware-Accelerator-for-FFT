-- Operatori aritmetici per FFT

-- Adder con uno stadio di pipeline
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.fixed_pkg.all;
use ieee.fixed_float_types.all;

entity Adder is
    generic ( N : natural );
    port (
        clk : in  std_logic;
        A   : in  sfixed(0 downto 1-N);
        B   : in  sfixed(0 downto 1-N);
        SUM : out sfixed(1 downto 1-N)
    );
end entity Adder;

architecture Behavioral of Adder is
    signal sum_reg : sfixed(1 downto 1-N);
begin
    process(clk)
    begin
        if rising_edge(clk) then
            sum_reg <= A + B;
        end if;
    end process;

    SUM <= sum_reg;
end architecture Behavioral;

-- Subtractor con uno stadio di pipeline
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.fixed_pkg.all;
use ieee.fixed_float_types.all;

entity Subtractor is
    generic ( N : natural );
    port (
        clk : in  std_logic;
        A   : in  sfixed(0 downto 1-N);
        B   : in  sfixed(0 downto 1-N);
        SUB : out sfixed(1 downto 1-N)
    );
end entity Subtractor;

architecture Behavioral of Subtractor is
    signal sub_reg : sfixed(1 downto 1-N);
begin
    process(clk)
    begin
        if rising_edge(clk) then
            sub_reg <= A - B;
        end if;
    end process;

    SUB <= sub_reg;
end architecture Behavioral;

-- Multiplier con due operazioni:
-- 1) moltiplicazione (con due stadi di pipeline)
-- 2) *2 (con uno stadio di pipeline)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.fixed_pkg.all;
use ieee.fixed_float_types.all;

entity Multiplier is
    generic ( N : natural );
    port (
        clk   : in  std_logic;
        A     : in  sfixed(0 downto 1-N);
        B     : in  sfixed(0 downto 1-N);
        shift : in  std_logic;
        PROD  : out sfixed(1 downto 2-2*N);
        Two_A : out sfixed(1 downto 1-N)
    );
end entity Multiplier;

architecture Behavioral of Multiplier is
    signal prod_reg1 : sfixed(0 downto (1 - 2*N));
    signal prod_reg2 : sfixed(0 downto (1 - 2*N));

    signal A_times2 : sfixed(1 downto 1-N);
begin
    process(clk)
        variable temp_prod : sfixed(1 downto (1 - 2*N));
    begin
        if rising_edge(clk) then
            if shift = '1' then
                -- sign extension 
                A_times2 <= shift_left(A, 1);
            else
                temp_prod := A * B;

                if temp_prod(1) = '0' and temp_prod(0) = '1' then
                    -- caso di overflow positivo
                    prod_reg1 <= ('0', others => '1');
                else
                    prod_reg1 <= sfixed(temp_prod(0 downto (1 - 2*N)));
                end if;
            end if;
        end if;
    end process;

    PROD <= prod_reg2;
    Two_A <= A_times2;
end architecture Behavioral;

-- ROM per l'arrotondatore
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.fixed_pkg.all;
use ieee.fixed_float_types.all;

entity ROM_Rounder is 
    generic ( n : natural; m : natural );  -- n : # bit interi, m : # bit frazionari
    port (
        clk      : in  std_logic;
        cs       : in  std_logic;
        addr     : in  unsigned( (m + n -1) downto 0);
        data_out : out unsigned(n-1 downto 0)
    );
end entity ROM_Rounder;

architecture Behavioral of ROM_Rounder is
    signal integer_part : unsigned(n -1 downto 0);
    signal fractional_part : unsigned(m -1 downto 0);
begin

    integer_part <= addr((m + n -1) downto m);
    fractional_part <= addr(m -1 downto 0);

    process(clk)
    variable N_Temp    : unsigned(n - 1 downto 0); -- Valore arrotondato in uscita
    --flag che mi dicese arrotondare per eccesso o meno
    variable round_up  : boolean;
    begin
        if rising_edge(clk) then
            if cs = '0' then
                N_Temp := (others => '0'); 
            else
                if fractional_part(m - 1) = '0' then                 -- < 0.5   -> arrotonda x difetto
                    round_up := false;
                else
                if (m > 1) and (fractional_part(m - 2 downto 0) /= 0) then   -- > 0.5   -> arrotonda x eccesso     !!!!! m>1 xkÃ¨ se m=1 non esistono altri bit che devo controllare
                        round_up := true;    
                    else                                             --  = 0.5  ->  vedo se pari o dispari
                        if integer_part(0) = '1' then              
                            round_up := true;                        -- dispari -> arrotonda x eccesso
                        else
                            round_up := false;                       -- pari    -> arrotonda x difetto
                        end if;
                    end if;
                end if;
                -- controllo x saturazione
                if round_up then
                    if integer_part = (N-1 downto 0 => '1') then 
                        N_Temp := integer_part;
                    else
                        N_Temp := integer_part + 1;
                    end if;
                else
                    N_Temp := integer_part;
                end if;

            end if;
            
            data_out <= N_Temp;
            
        end if;
    end process;
    
end  Behavioral;