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
    signal sum_reg : sfixed(0 downto -N);
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
        SUM : out sfixed(1 downto 1-N)
    );
end entity Subtractor;

architecture Behavioral of Subtractor is
    signal sum_reg : sfixed(0 downto -N);
begin
    process(clk)
    begin
        if rising_edge(clk) then
            sum_reg <= A - B;
        end if;
    end process;

    SUM <= sum_reg;
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
    begin
        if rising_edge(clk) then
            prod_reg1 <= A * B;
            prod_reg2 <= prod_reg1;

            -- sign extension 
            -- TODO: controllare
            A_times2 <= shift_left(A, 1);
        end if;
    end process;

    PROD <= prod_reg2;
    Two_A <= A_times2;
end architecture Behavioral;