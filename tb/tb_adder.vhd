library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.fixed_pkg.all;
use ieee.fixed_float_types.all;
entity tb_Adder is
end tb_Adder;

architecture tb of tb_Adder is
    constant N : natural := 4;
    component Adder
        generic ( N : natural );
        port (
            clk : in std_logic;
            A   : in sfixed (0 downto 1-N);
            B   : in sfixed (0 downto 1-N);
            SUM : out sfixed (1 downto 1-N)
            );
    end component;

    signal clk : std_logic;
    signal A   : sfixed (0 downto 1-N);
    signal B   : sfixed (0 downto 1-N);
    signal SUM : sfixed (1 downto 1-N);

    constant TbPeriod : time := 100 ns;
    signal TbClock : std_logic := '0';

begin

    dut : Adder
    generic map (N => N)
    port map (
        clk => clk,
        A   => A,
        B   => B,
        SUM => SUM
    );

    -- Clock generation
    TbClock <= not TbClock after TbPeriod/2;

    clk <= TbClock;

    stimuli : process
    begin
        -- Adapt initialization as needed
        A <= (others => '0');
        B <= (others => '0');

        -- Add stimuli here
        A <= "1111" after TbPeriod, "1010" after 2*TbPeriod, "0000" after 3*TbPeriod, "1100" after 4*TbPeriod;
        B <= "1111" after TbPeriod, "1100" after 2*TbPeriod, "0101" after 3*TbPeriod, "1010" after 4*TbPeriod;
        wait for 5 * TbPeriod;
        wait;
    end process;

end tb;