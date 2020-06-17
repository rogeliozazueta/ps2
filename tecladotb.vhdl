library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.textio.all;
use ieee.std_logic_textio.all;




entity keyboard_tb is
    constant period : time := 40 ns; 
    constant bit_period : time := 60 us; 
end entity;

architecture arch of keyboard_tb is

    component keyboard is
        port(
            keyboard_clk, keyboard_data, clk_25Mhz, reset, enable : in std_logic;
            scan_code   : out std_logic_vector(7 downto 0);
            errorparidad : out std_logic; 
			scan_ready  : out std_logic
        );
    end component;
    
    signal clk : std_logic := '0';
    signal reset : std_logic;
    signal enable : std_logic := '0';
    signal kbd_clk : std_logic := 'H';
    signal kbd_data : std_logic := 'H';
    signal scan_ready :std_logic;
    signal errorparidad :std_logic;
    signal scan_code : std_logic_vector(7 downto 0);

    type code_type is array (natural range <>) of std_logic_vector(7 downto 0);
    type record_input is record
        codes : std_logic_vector(7 downto 0);
        paridad : std_logic;
    end record record_input;
    type Array_code is array(natural range <>) of record_input;

   constant c_codes : Array_code:= (("00010101",'0'), ("00011101",'0'));
begin

    UUT : keyboard port map (kbd_clk, kbd_data, clk, reset, enable, scan_code, errorparidad, scan_ready);

    clk <= not clk after (period / 2);
    reset <= '1', '0' after period;

    process
        procedure send_code ( data : std_logic_vector(7 downto 0); s_paridad : std_logic) is 
        begin
            kbd_clk <= 'H';
            kbd_data <= 'H';
            
            wait for (bit_period / 2);
            -- start bit
            kbd_data <= '0';
            wait for (bit_period / 2);
            kbd_clk <= '0'; 
            wait for (bit_period / 2);
            kbd_clk <= '1';

            -- data bits
            for i in 0 to 7 loop
            kbd_data <= data(i);
            wait for (bit_period / 2);
            kbd_clk <= '0';
            wait for (bit_period / 2);
            kbd_clk <= '1';
            end loop;

            kbd_data <= s_paridad; -- paridad bit 
            wait for (bit_period / 2);
            kbd_clk <= '0'; 
            wait for (bit_period / 2);
            kbd_clk <= '1';

            -- stop bit
            kbd_data <= '1';
            wait for (bit_period / 2);
            kbd_clk <= '0';
            wait for (bit_period / 2);
            kbd_clk <= '1';
            kbd_data <= 'H';
            wait for bit_period;
        end procedure send_code;

    begin
        wait for bit_period;
        for i in c_codes'range loop
            send_code(c_codes(i).codes,c_codes(i).paridad);
        end loop;
    end process;

    process 
        variable l : line;
    begin
        wait until scan_ready = '1';
        write (l, string'("Scan code: "));
        write (l, scan_code);
        if (errorparidad = '1') then
        write (l, string'(" error de paridad"));
        end if;
        writeline(output, l);
        wait for 300* period;
    end process;

end arch ; -- arch
