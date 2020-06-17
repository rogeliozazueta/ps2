lllibrary ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity keyboard is
    port(
        keyboard_clk, keyboard_data, clk_25Mhz, reset, enable : in std_logic;
        scan_code   : out std_logic_vector(7 downto 0);
        errorparidad: out std_logic;
		scan_ready  : out std_logic
    );
end entity;

architecture arch of keyboard is
    Type state is(ESPERA,LECTURA);
	SIGNAL present:state := ESPERA;
    signal incount : unsigned(3 downto 0) := "0000";
    signal keyboard_clk_filtered : std_logic;
    signal read_char : std_logic := '0';
    signal ready_set : std_logic := '0';
    signal shift_in : std_logic_vector(8 downto 0) :="000000000";
    signal filtros : std_logic_vector(7 downto 0);
    signal paridadcheck : std_logic := '0';
         

begin
    clock_filter : process
    begin
        wait until clk_25Mhz'event and clk_25Mhz = '1'; -- rising_edge(clk)
        filtros(6 downto 0) <= filtros(7 downto 1);
        filtros(7) <= keyboard_clk;
        if filtros = x"FF" then -- "1111111"
            keyboard_clk_filtered <= '1';
        elsif filtros = x"00" then  -- "0000000"
            keyboard_clk_filtered <= '0';
        end if;
    end process;

    process (keyboard_clk_filtered)
    begin
    if reset = '1' then
        incount <= x"0";
        read_char <= '0';
     else 
    if (keyboard_clk_filtered'event and keyboard_clk_filtered = '0') then --rising_edge(filtered)
    case present is 

       when ESPERA =>
       if keyboard_data = '0' and read_char = '0' then -- Primer bit inicio 
                shift_in <= "000000000"; 
                paridadcheck <= '0';        
                read_char <= '1';
                ready_set <= '0';
                present <= LECTURA;
        end if;

       when LECTURA => -- Shift enl siguientes 8 bits para construir el scan code
       if incount < x"9" then
              shift_in(7 downto 0) <= shift_in(8 downto 1);
              shift_in(8) <= keyboard_data;
              ready_set <= '0';
              paridadcheck <= paridadcheck xor keyboard_data;
              incount <= incount + 1;
        else 
            errorparidad <= paridadcheck xor keyboard_data;
            scan_code <= shift_in(7 downto 0);
            read_char <= '0';
            ready_set <= '1';
            incount <= x"0";
            present <= ESPERA;
        end if;
       when others => null; 
       end case;
       end if;
        end if;
       end process; 

    
    -- Proceso que habilita el controlador
    -- Cuando enable = 1, indicará que no estará listo para leer el scancode de tu teclado
    -- Cuando enable = 0, indicará el momento en el que permitirá leer el scancode del teclado
    process (enable, ready_set)
    begin
        if enable = '1' then
            scan_ready <= '0';
        elsif ready_set'event and ready_set = '1' then
            scan_ready <= '1';
            else
             scan_ready <= '0';
        end if;
    end process;
    
end arch ; -- arch
