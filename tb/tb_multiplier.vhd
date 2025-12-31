library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.fixed_pkg.all;
use ieee.fixed_float_types.all;
entity tb_Multiplier is
end tb_Multiplier;

architecture tb of tb_Multiplier is
    constant N : natural := 4;
    component Multiplier
        generic ( N : natural );
        port (
            clk   : in std_logic;
            A     : in sfixed (0 downto 1-N);
            B     : in sfixed (0 downto 1-N);
            shift : in std_logic;
            PROD  : out sfixed (1 downto 2-2*N);
            Two_A : out sfixed (1 downto 1-N)
            );
    end component;

    signal clk   : std_logic;
    signal A     : sfixed (0 downto 1-N);
    signal B     : sfixed (0 downto 1-N);
    signal shift : std_logic;
    signal PROD  : sfixed (1 downto 2-2*N);
    signal Two_A : sfixed (1 downto 1-N);

    constant TbPeriod : time := 1000 ns;
    signal TbClock : std_logic := '0';

begin

    dut : Multiplier
    generic map (N => N)
    port map (
        clk   => clk,
        A     => A,
        B     => B,
        shift => shift,
        PROD  => PROD,
        Two_A => Two_A
        );

    -- Clock generation
    TbClock <= not TbClock after TbPeriod/2;

    clk <= TbClock;

    stimuli : process
    begin
        -- Adapt initialization as needed
        A <= (others => '0');
        B <= (others => '0');
        shift <= '0';

        -- Add stimuli here
        A <= "1111" after TbPeriod, "1010" after 2*TbPeriod, "0000" after 3*TbPeriod, "1100" after 4*TbPeriod, "1111" after 5*TbPeriod, "1010" after 6*TbPeriod, "0000" after 7*TbPeriod, "1100" after 8*TbPeriod;
        B <= "1111" after TbPeriod, "1100" after 2*TbPeriod, "0101" after 3*TbPeriod, "1010" after 4*TbPeriod;
        shift <= '1' after 4*TbPeriod;
        wait for 9 * TbPeriod;
        wait;
    end process;

end tb;

-- Configuration block below is required by some simulators. Usually no need to edit.

configuration cfg_tb_Multiplier of tb_Multiplier is
    for tb
    end for;
end cfg_tb_Multiplier;