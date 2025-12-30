library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.fixed_pkg.all;
use ieee.fixed_float_types.all;
entity tb_Subtractor is
end tb_Subtractor;

architecture tb of tb_Subtractor is
    constant N : natural := 4;
    component Subtractor
        generic ( N : natural );
        port (
            clk : in  std_logic;
            A   : in  sfixed(0 downto 1-N);
            B   : in  sfixed(0 downto 1-N);
            SUB : out sfixed(1 downto 1-N)
    );
    end component;

    signal clk : std_logic;
    signal A   : sfixed (0 downto 1-N);
    signal B   : sfixed (0 downto 1-N);
    signal SUB : sfixed (1 downto 1-N);

    constant TbPeriod : time := 1000 ns;
    signal TbClock : std_logic := '0';
    signal TbSimEnded : std_logic := '0';

begin

    dut : Subtractor
    generic map (N => N)
    port map (
        clk => clk,
        A   => A,
        B   => B,
        SUB => SUB
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

-- Configuration block below is required by some simulators. Usually no need to edit.

configuration cfg_tb_Subtractor of tb_Subtractor is
    for tb
    end for;
end cfg_tb_Subtractor;