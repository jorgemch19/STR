-- Especificacion de Joystick

with Ada.Real_Time; use Ada.Real_Time;
with devicesfss_v1; use devicesfss_v1;

package testing_2_2 is
   ---------------------------------------------------------------------
   ------ Access time for devices
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
   ------ JOYSTICK: 200 muestras = 20 s
   cantidad_datos_Joystick: constant := 200;
   type Indice_Secuencia_Joystick is mod cantidad_datos_Joystick;
   type tipo_Secuencia_Joystick is array (Indice_Secuencia_Joystick)
                                          of Joystick_Samples_Type;

   Joystick_Simulation: tipo_Secuencia_Joystick :=
      (
      0 .. 9 => (x => 0, y => 0), -- 0-1 s: centrado

      10 .. 14 => (x => 3, y => 3), -- 1-1.5 s: margen
      15 .. 19 => (x => -3, y => -3), -- 1.5-2 s: margen
      20 .. 24 => (x => 3, y => -3), -- 2-2.5 s: margen
      25 .. 29 => (x => -3, y => 3), -- 2.5-3 s: margen
      30 .. 34 => (x => 4, y => 0), -- 3-3.5 s: fuera del margen
      35 .. 39 => (x => -4, y => 0), -- 3.5-4 s: fuera del margen
      40 .. 44 => (x => 0, y => 4), -- 4-4.5 s: fuera del margen
      45 .. 49 => (x => 0, y => -4), -- 4.5-5 s: fuera del margen

      50 .. 54 => (x => 30, y => 0), -- 5-5.5 s: pitch maximo (30)
      55 .. 59 => (x => 31, y => 0), -- 5.5-6 s: pitch limitado (30)
      60 .. 64 => (x => -30, y => 0), -- 6-6.5 s: pitch minimo (-30)
      65 .. 69 => (x => -31, y => 0), -- 6.5-7 s: pitch limitado (-30)
      70 .. 74 => (x => 90, y => 0), -- 7-7.5 s: pitch extremo (30)
      75 .. 79 => (x => -90, y => 0), -- 7.5-8 s: pitch extremo (-30)

      80 .. 84 => (x => 0, y => 35), -- 8-8.5 s: roll 35, sin mensaje
      85 .. 89 => (x => 0, y => 36), -- 8.5-9 s: roll 36, mensaje
      90 .. 94 => (x => 0, y => -35), -- 9-9.5 s: roll -35, sin mensaje
      95 .. 99 => (x => 0, y => -36), -- 9.5-10 s: roll -36, mensaje

      100 .. 104 => (x => 0, y => 45), -- 10-10.5 s: roll maximo (45)
      105 .. 109 => (x => 0, y => 46), -- 10.5-11 s: roll limitado (45)
      110 .. 114 => (x => 0, y => -45), -- 11-11.5 s: roll minimo (-45)
      115 .. 119 => (x => 0, y => -46), -- 11.5-12 s: roll limitado (-45)
      120 .. 124 => (x => 0, y => 90), -- 12-12.5 s: roll extremo (45)
      125 .. 129 => (x => 0, y => -90), -- 12.5-13 s: roll extremo (-45)

      130 .. 134 => (x => 90, y => 90), -- 13-13.5 s: esquina (30, 45)
      135 .. 139 => (x => -90, y => -90), -- 13.5-14 s: esquina (-30, -45)
      140 .. 144 => (x => 90, y => -90), -- 14-14.5 s: esquina (30, -45)
      145 .. 149 => (x => -90, y => 90), -- 14.5-15 s: esquina (-30, 45)

      150 .. 154 => (x => 10, y => 0), -- 15-15.5 s: sube, +150 (870)
      155 .. 159 => (x => 0, y => 10), -- 15.5-16 s: gira, +100 (820)
      160 .. 164 => (x => 10, y => 10), -- 16-16.5 s: sube y gira, +200 (920)
      165 .. 169 => (x => -10, y => 10), -- 16.5-17 s: baja y gira, +100 (820)
      170 .. 174 => (x => -10, y => 0), -- 17-17.5 s: baja, sin incremento (720)

      175 .. 199 => (x => 0, y => 0)); -- 17.5-20 s: centrado

   ---------------------------------------------------------------------
   ------ POWER: constante 600 = 720 km/h
   cantidad_datos_Power: constant := 200;
   type Indice_Secuencia_Power is mod cantidad_datos_Power;
   type tipo_Secuencia_Power is array (Indice_Secuencia_Power) of Power_Samples_Type;

   Power_Simulation: tipo_Secuencia_Power := (others => 600);

   ---------------------------------------------------------------------
   ------ PILOT'S PRESENCE 1
   cantidad_datos_PilotPresence: constant := 200;
   type Indice_Secuencia_PilotPresence is mod cantidad_datos_PilotPresence;
   type tipo_Secuencia_PilotPresence is array (Indice_Secuencia_PilotPresence) of PilotPresence_Samples_Type;

   PilotPresence_Simulation: tipo_Secuencia_PilotPresence := (others => 1);

   ---------------------------------------------------------------------
   ------ PILOT'S BUTTON 0
   cantidad_datos_PilotButton: constant := 200;
   type Indice_Secuencia_PilotButton is mod cantidad_datos_PilotButton;
   type tipo_Secuencia_PilotButton is array (Indice_Secuencia_PilotButton) of PilotButton_Samples_Type;

   PilotButton_Simulation: tipo_Secuencia_PilotButton := (others => 0);

end testing_2_2;