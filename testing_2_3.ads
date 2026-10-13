-- Especificacion de Velocidad

with Ada.Real_Time; use Ada.Real_Time;
with devicesfss_v1; use devicesfss_v1;

package testing_2_3 is
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
   ------ JOYSTICK: centrado salvo en las pruebas de incrementos
   -- Lo que sube y lo que baja esta compensado, la altitud se queda cerca de 8000
   cantidad_datos_Joystick: constant := 200;
   type Indice_Secuencia_Joystick is mod cantidad_datos_Joystick;
   type tipo_Secuencia_Joystick is array (Indice_Secuencia_Joystick)
                                          of Joystick_Samples_Type;

   Joystick_Simulation: tipo_Secuencia_Joystick :=
      (
      60 .. 64 => (x => 10, y => 0), -- 6-6.5 s: sube, +150
      65 .. 69 => (x => 0, y => 10), -- 6.5-7 s: gira, +100
      70 .. 74 => (x => 10, y => 10), -- 7-7.5 s: sube y gira, +200
      75 .. 79 => (x => 10, y => -10), -- 7.5-8 s: sube y gira izquierda, +200
      80 .. 84 => (x => -10, y => 10), -- 8-8.5 s: baja y gira, +100
      85 .. 89 => (x => -10, y => 0), -- 8.5-9 s: baja, sin incremento
      90 .. 94 => (x => 3, y => 3), -- 9-9.5 s: margen, sin incremento

      95 .. 99 => (x => 10, y => 0), -- 9.5-10 s: sube, +150
      100 .. 104 => (x => 0, y => 10), -- 10-10.5 s: gira, +100
      105 .. 109 => (x => 10, y => 10), -- 10.5-11 s: sube y gira, +200

      110 .. 114 => (x => 10, y => 10), -- 11-11.5 s: sube y gira, +200
      115 .. 119 => (x => 0, y => 10), -- 11.5-12 s: gira, +100
      120 .. 124 => (x => 10, y => 0), -- 12-12.5 s: sube, +150

      170 .. 194 => (x => -10, y => 0), -- 17-19.5 s: baja para compensar la altitud
      others => (x => 0, y => 0)); -- resto: centrado

   ---------------------------------------------------------------------
   ------ POWER: velocidad = potencia * 1.2 (redondeada)
   cantidad_datos_Power: constant := 200;
   type Indice_Secuencia_Power is mod cantidad_datos_Power;
   type tipo_Secuencia_Power is array (Indice_Secuencia_Power) of Power_Samples_Type;

   Power_Simulation: tipo_Secuencia_Power :=
      (
      0 .. 9 => 800, -- 0-1 s: 960, normal

      10 .. 14 => 0, -- 1-1.5 s: 0, sube a 300, Luz 2
      15 .. 19 => 100, -- 1.5-2 s: 120, sube a 300, Luz 2
      20 .. 24 => 249, -- 2-2.5 s: 299, sube a 300, Luz 2
      25 .. 29 => 250, -- 2.5-3 s: 300, limite, Luz 2
      30 .. 34 => 251, -- 3-3.5 s: 301, sin luz
      35 .. 39 => 500, -- 3.5-4 s: 600, sin luz
      40 .. 44 => 832, -- 4-4.5 s: 998, sin luz
      45 .. 49 => 833, -- 4.5-5 s: 1000 (redondeo de 999.6), Luz 2
      50 .. 54 => 834, -- 5-5.5 s: 1001, baja a 1000, Luz 2
      55 .. 59 => 1023, -- 5.5-6 s: 1228, baja a 1000, Luz 2

      60 .. 94 => 600, -- 6-9.5 s: base 720
      
      95 .. 109 => 800, -- 9.5-11 s: base 960, con incremento baja a 1000, Luz 2

      110 .. 129 => 100, -- 11-13 s: base 120 (+200 = 320 sin luz, +100 = 220 y +150 = 270 suben a 300, Luz 2)

      130 .. 139 => 0, -- 13-14 s: cambio brusco, 300, Luz 2
      140 .. 149 => 1023, -- 14-15 s: cambio brusco, 1000, Luz 2
      150 .. 159 => 0, -- 15-16 s: cambio brusco, 300, Luz 2
      160 .. 169 => 700, -- 16-17 s: 840, sin luz
      170 .. 199 => 800); -- 17-20 s: 960, sin luz

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

end testing_2_3;