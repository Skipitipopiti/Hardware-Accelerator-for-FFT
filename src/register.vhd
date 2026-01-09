library ieee;
use ieee.std_logic_1164.all;

-- Registro semplice generico con Enable e Reset Asincrono
entity Reg is
    generic (N : natural; ON_RISING_EDGE : boolean := true);
	port
    (
        en    : in std_logic;
        clk   : in std_logic;
        arst  : in std_logic := '0';
        d_in  : in std_logic_vector(N-1 downto 0);
		d_out : out std_logic_vector(N-1 downto 0)
    );
end Reg;

architecture Behavior of Reg is
begin
	process (clk, arst)
    begin
		if arst = '1' then
			d_out <= (N-1 downto 0 => '0');
        elsif ON_RISING_EDGE then
        	if rising_edge(clk) then
            	if en = '1' then
                	d_out <= d_in;
            	end if;
        	end if;
        else
        	if falling_edge(clk) then
            	if en = '1' then
                	d_out <= d_in;
            	end if;
        	end if;
        end if;
	end process;
end Behavior;

-- SFIXED

library ieee;
use ieee.std_logic_1164.all;
use ieee.fixed_pkg.all;

-- Registro con Enable e Reset Asincrono per sfixed
entity RegSfixed is
    generic (HI, LO: integer; ON_RISING_EDGE : boolean := true);
	port
    (
        en    : in  std_logic;
        clk   : in  std_logic;
        arst  : in  std_logic := '0';
        d_in  : in  sfixed(HI downto LO);
		d_out : out sfixed(HI downto LO)
    );
end RegSfixed;

architecture Behavior of RegSfixed is
begin
	process (clk, arst)
    begin
		if arst = '1' then
			d_out <= (HI downto LO => '0');
        elsif ON_RISING_EDGE then
        	if rising_edge(clk) then
            	if en = '1' then
                	d_out <= d_in;
            	end if;
        	end if;
        else
        	if falling_edge(clk) then
            	if en = '1' then
                	d_out <= d_in;
            	end if;
        	end if;
        end if;
	end process;
end Behavior;