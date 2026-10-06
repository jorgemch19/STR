
with Ada.Real_Time; use Ada.Real_Time;
with devicesfss_v1; use devicesfss_v1;

---------------------------------------------------------------------
-- ESCENARIO 2: CONTROL DE VUELO (requisitos 1, 2, 3 y 4)
--   * Margen de +-3 grados (1.g)
--   * Limites de pitch +-30 y roll +-45 (1.h, 2.d, 3.f)
--   * Mensaje de alabeo por encima de +-35 (3.e)
--   * Incrementos de velocidad por maniobra +150 / +100 / +200 (4.e, f, g)
--   * Limites de velocidad 300..1000 km/h y Luz 2 (4.b, c, d)
--   * Altitud: Luz 1 > 9500, nivelar e ignorar ascenso >= 10000 (2.h, i, j)
--
-- Las obstrucciones, la visibilidad, el piloto y el boton se dejan
-- en valores neutros para no interferir (ver testing_3.ads).
--
-- Cada muestra dura 100 ms: indice 10 = segundo 1, indice 100 = segundo 10.
-- Los tramos duran al menos 400 ms para que las tareas de 200 y 300 ms
-- los lean al menos una vez.
--
-- Recordatorio: Speed_Samples_Type (Float (P) * 1.2) REDONDEA al entero
-- mas cercano (833 * 1.2 = 999.6 -> 1000).
---------------------------------------------------------------------

package testing_1 is

    ---------------------------------------------------------------------
    ------ Access time for devices (sin cambios)
    ---------------------------------------------------------------------
    WCET_Distance: constant Ada.Real_Time.Time_Span := Ada.Real_Time.Milliseconds(5);
    WCET_Light: constant Ada.Real_Time.Time_Span := Ada.Real_Time.Milliseconds(5);

    WCET_Joystick: constant Ada.Real_Time.Time_Span := Ada.Real_Time.Milliseconds(5);
    WCET_PilotPresence: constant Ada.Real_Time.Time_Span := Ada.Real_Time.Milliseconds(5);
    WCET_PilotButton: constant Ada.Real_Time.Time_Span := Ada.Real_Time.Milliseconds(5);

    WCET_Power: constant Ada.Real_Time.Time_Span := Ada.Real_Time.Milliseconds(4);

    WCET_Speed: constant Ada.Real_Time.Time_Span := Ada.Real_Time.Milliseconds(7);
    WCET_Altitude: constant Ada.Real_Time.Time_Span := Ada.Real_Time.Milliseconds(18);

    WCET_Pitch: constant Ada.Real_Time.Time_Span := Ada.Real_Time.Milliseconds(20);
    WCET_Roll: constant Ada.Real_Time.Time_Span := Ada.Real_Time.Milliseconds(18);

    WCET_Display: constant Ada.Real_Time.Time_Span := Ada.Real_Time.Milliseconds(15);
    WCET_Alarm: constant Ada.Real_Time.Time_Span := Ada.Real_Time.Milliseconds(5);

    ---------------------------------------------------------------------
    ------ SCENARIO -----------------------------------------------------
    ---------------------------------------------------------------------
    -- Initial_Altitude: Altitude_Samples_Type := 8000;

    ---------------------------------------------------------------------
    ------ DISTANCE: sin obstaculos en todo el escenario
    cantidad_datos_Distancia: constant := 200;
    type Indice_Secuencia_Distancia is mod cantidad_datos_Distancia;
    type tipo_Secuencia_Distancia is array (Indice_Secuencia_Distancia) of Distance_Samples_Type;

    Distance_Simulation: tipo_Secuencia_Distancia := (others => 5555);

    ---------------------------------------------------------------------
    ------ LIGHT: buena visibilidad en todo el escenario
    cantidad_datos_Light: constant := 200;
    type Indice_Secuencia_Light is mod cantidad_datos_Light;
    type tipo_Secuencia_Light is array (Indice_Secuencia_Light) of Light_Samples_Type;

    Light_Intensity_Simulation: tipo_Secuencia_Light := (others => 700);

    ---------------------------------------------------------------------
    ------ JOYSTICK
    --  Columna "Esperado": Pitch / Roll de la nave, incremento de velocidad
    cantidad_datos_Joystick: constant := 200;
    type Indice_Secuencia_Joystick is mod cantidad_datos_Joystick;
    type tipo_Secuencia_Joystick is array (Indice_Secuencia_Joystick)
                                             of Joystick_Samples_Type;

    Joystick_Simulation: tipo_Secuencia_Joystick :=
       ( -- 0-2 s: MARGEN DE +-3 (1.g)                Esperado
        0   .. 4   => (x =>   3, y =>   3),   -- P 0,   R 0,   +0
        5   .. 9   => (x =>  -3, y =>  -3),   -- P 0,   R 0,   +0
        10  .. 14  => (x =>   3, y =>  -3),   -- P 0,   R 0,   +0
        15  .. 19  => (x =>  -3, y =>   3),   -- P 0,   R 0,   +0

         -- 2-5 s: LIMITES Y MENSAJE DE ALABEO (1.h, 2.d, 3.e, 3.f)
        20  .. 24  => (x =>  30, y =>  45),   -- P 30,  R 45,  +200, mensaje alabeo
        25  .. 29  => (x =>  31, y =>  46),   -- P 30,  R 45,  +200, mensaje alabeo
        30  .. 34  => (x => -31, y => -46),   -- P -30, R -45, +100, mensaje alabeo
        35  .. 39  => (x =>  90, y => -90),   -- P 30,  R -45, +200, mensaje alabeo
        40  .. 44  => (x =>   0, y =>  35),   -- P 0,   R 35,  +100, SIN mensaje
        45  .. 49  => (x =>   0, y => -36),   -- P 0,   R -36, +100, mensaje alabeo

         -- 5-7 s: INCREMENTOS DE VELOCIDAD (4.e, f, g)  (potencia 600 -> 720 km/h)
        50  .. 54  => (x =>  10, y =>   0),   -- solo cabeceo subiendo -> 870
        55  .. 59  => (x =>   0, y =>  10),   -- solo alabeo           -> 820
        60  .. 64  => (x =>  10, y => -10),   -- cabeceo y alabeo      -> 920
        65  .. 69  => (x => -10, y =>   0),   -- cabeceo BAJANDO       -> 720 (sin incremento)

         -- 7-9 s: LIMITES DE VELOCIDAD (ver POWER), joystick neutro
        70  .. 89  => (x =>   0, y =>   0),

         -- 9-20 s: ALTITUD (2.h, 2.i, 2.j)
         -- Ascenso continuo (limitado a 30). Al pasar de 9500 -> Luz 1.
         -- Al llegar a 10000 -> la nave se nivela (P 0) aunque el piloto siga subiendo.
         -- PARA PROBAR 2500/2000 (2.e, f, g): cambiar x => 60 por x => -60.
        90  .. 199 => (x =>  -60, y =>   0));

    ---------------------------------------------------------------------
    ------ POWER  (velocidad = potencia * 1.2, redondeada)
    cantidad_datos_Power: constant := 200;
    type Indice_Secuencia_Power is mod cantidad_datos_Power;
    type tipo_Secuencia_Power is array (Indice_Secuencia_Power) of Power_Samples_Type;

    Power_Simulation: tipo_Secuencia_Power :=
       ( -- 0-2 s                                       Esperado
        0   .. 19  => 800,    -- 960 km/h, Luz 2 apagada

         -- 2-7 s: base baja para ver los incrementos sin llegar al limite
        20  .. 69  => 600,    -- 720 km/h + incremento (ver JOYSTICK)

         -- 7-9 s: LIMITES DE VELOCIDAD (4.b, c, d)
        70  .. 73  => 832,    -- 998 km/h  -> Luz 2 apagada
        74  .. 77  => 833,    -- 1000 km/h -> Luz 2 encendida (redondeo de 999.6)
        78  .. 81  => 1023,   -- 1228 km/h -> limitada a 1000, Luz 2 encendida
        82  .. 85  => 251,    -- 301 km/h  -> Luz 2 apagada
        86  .. 89  => 0,      -- 0 km/h    -> limitada a 300, Luz 2 encendida

         -- 9-20 s: ascenso con cabeceo (+150)
        90  .. 199 => 800);   -- 960 + 150 = 1110 -> limitada a 1000 (4.e), Luz 2 encendida
                              -- al nivelarse a 10000 m -> 960, Luz 2 apagada

    ---------------------------------------------------------------------
    ------ PILOT'S PRESENCE: piloto siempre presente
    cantidad_datos_PilotPresence: constant := 200;
    type Indice_Secuencia_PilotPresence is mod cantidad_datos_PilotPresence;
    type tipo_Secuencia_PilotPresence is array (Indice_Secuencia_PilotPresence) of PilotPresence_Samples_Type;

    PilotPresence_Simulation: tipo_Secuencia_PilotPresence := (others => 1);

    ---------------------------------------------------------------------
    ------ PILOT'S BUTTON: sin pulsaciones (siempre modo automatico)
    cantidad_datos_PilotButton: constant := 200;
    type Indice_Secuencia_PilotButton is mod cantidad_datos_PilotButton;
    type tipo_Secuencia_PilotButton is array (Indice_Secuencia_PilotButton) of PilotButton_Samples_Type;

    PilotButton_Simulation: tipo_Secuencia_PilotButton := (others => 0);

end testing_1;