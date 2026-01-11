library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fft_pkg.all;

entity tb_fft_shuffle is
end entity tb_fft_shuffle;

architecture tb of tb_fft_shuffle is
    constant stages : natural := 4;
begin
    process
        variable result : natural;
    begin
        for i in 0 to 2**STAGES-1 loop
            result := fft_shuffle(i, stages);
            report "Current index: " & integer'image(i) & " Next index: " & integer'image(result);
        end loop;
        wait;
    end process;
end architecture tb;