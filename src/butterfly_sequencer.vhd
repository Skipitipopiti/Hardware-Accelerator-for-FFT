library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Sequenziatore per la CU della butterfly
-- TODO: CC validation
entity butterfly_sequencer is
    port (
        clk        : in  std_logic;
        arst       : in  std_logic;
        start      : in  std_logic;
        first_half : in  std_logic;
        state      : out std_logic_vector(2 downto 0)
    );
end entity butterfly_sequencer;

architecture Behavioral of butterfly_sequencer is
    type matrix_t is array (natural range<>) of std_logic_vector;

    constant ROM_addr_size : natural := 3;
    constant ROM_width : natural := 2 + ROM_addr_size;

    -- CC: 00 -> unconditional sequencing
    -- CC: 01 -> controllo di first_half (non si verifica)
    -- CC: 10 -> controllo di start
    -- CC: 11 -> controllo di start o first_half
    -- Il salto avviene se almeno una delle condizioni di controllo è vera

    -- CC[1..0] = data[4..3]
    -- CC[1] = controllo di start
    -- CC[0] = controllo di first_half
    -- NEXT[2..0] = data[2..0]

    -- I CC nelle ROM sono riferiti allo stato SUCCESSIVO (i.e. quello in NEXT)

    constant ROM_even : matrix_t(0 to 6)(ROM_width-1 downto 0) := (
        "10" & "000", -- IDLE -> IDLE
        "00" & "010", -- S1 -> S2
        "00" & "011", -- S2 -> S3
        "00" & "100", -- S3 -> S4
        "00" & "101", -- S4 -> S5
        "11" & "110", -- S5 -> S6
        "10" & "000"  -- S6 -> IDLE
    );

    constant ROM_odd  : matrix_t(0 to 6)(ROM_width-1 downto 0) := (
        "00" & "001", -- IDLE -> S1
        "00" & "010", -- S1 (non si verifica)
        "00" & "011", -- S2 (non si verifica)
        "00" & "100", -- S3 (non si verifica)
        "00" & "101", -- S4 (non si verifica)
        "00" & "110", -- S5 (non si verifica)
        "00" & "001"  -- S6 -> S1
    );

    signal r_ar_in, r_ar_out : std_logic_vector(ROM_addr_size downto 0);
    alias jump_bit : std_logic is r_ar_out(0);

    alias rom_addr : std_logic_vector(ROM_addr_size-1 downto 0) is r_ar_out(ROM_addr_size downto 1);
    signal rom_out : std_logic_vector(ROM_width-1 downto 0);

    -- Contiene CC e indirizzo del prossimo stato
    signal r_ir_in, r_ir_out : std_logic_vector(ROM_width-1 downto 0);
    alias cc_bits   : std_logic_vector(1 downto 0) is r_ir_out(ROM_width-1 downto ROM_width-2);
    alias next_addr : std_logic_vector(ROM_addr_size-1 downto 0) is r_ir_out(ROM_addr_size-1 downto 0);

begin
    uAR: entity work.Reg
        generic map ( N => ROM_addr_size + 1, ON_RISING_EDGE => false )
        port map (
            clk   => clk,
            arst  => arst,
            d_in  => r_ar_in,
            en    => '1', -- TODO: ?
            d_out => r_ar_out
        );

    uIR: entity work.Reg
        generic map ( N => ROM_width, ON_RISING_EDGE => true )
        port map (
            clk   => clk,
            arst  => arst,
            d_in  => r_ir_in,
            en    => '1', -- TODO: ?
            d_out => r_ir_out
        );
    
    with jump_bit select rom_out <=
        ROM_even(to_integer(unsigned(rom_addr))) when '0',
        ROM_odd(to_integer(unsigned(rom_addr)))  when others;
    
    -- late status PLA
    r_ar_in(0) <= (start and cc_bits(1)) or (first_half and cc_bits(0));
    r_ar_in(ROM_addr_size downto 1) <= next_addr;

    r_ir_in <= rom_out;

    state <= r_ir_out(ROM_addr_size-1 downto 0);
end architecture Behavioral;