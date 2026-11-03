-- Especificacion de Visibilidad y Presencia del Piloto

with Ada.Real_Time; use Ada.Real_Time;
with devicesfss_v1; use devicesfss_v1;

package testing_3_2 is
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
   ------ DISTANCE: la misma distancia con y sin visibilidad
   cantidad_datos_Distancia: constant := 200;
   type Indice_Secuencia_Distancia is mod cantidad_datos_Distancia;
   type tipo_Secuencia_Distancia is array (Indice_Secuencia_Distancia) of Distance_Samples_Type;

   Distance_Simulation: tipo_Secuencia_Distancia := 
      (
      0 .. 19 => 5555, -- 0-2 s: sin obstaculo
      20 .. 79 => 3000, -- 2-8 s: 12 s
      80 .. 99 => 2200, -- 8-10 s: 8,8 s
      100 .. 129 => 5555, -- 10-13 s: sin obstaculo
      130 .. 149 => 3000, -- 13-15 s: 12 s
      150 .. 169 => 2000, -- 15-17 s: 8 s
      170 .. 199 => 5555); -- 17-20 s: sin obstaculo

   ---------------------------------------------------------------------
   ------ LIGHT: baja de 500 entre los 5 y los 10 s
   cantidad_datos_Light: constant := 200;
   type Indice_Secuencia_Light is mod cantidad_datos_Light;
   type tipo_Secuencia_Light is array (Indice_Secuencia_Light) of Light_Samples_Type;

   Light_Intensity_Simulation: tipo_Secuencia_Light := 
      (
      0 .. 49 => 700, -- 0-5 s: buena visibilidad
      50 .. 99 => 300, -- 5-10 s: mala visibilidad
      100 .. 199 => 700); -- 10-20 s: buena visibilidad

   ---------------------------------------------------------------------
   ------ JOYSTICK: centrado en todo el escenario
   cantidad_datos_Joystick: constant := 200;
   type Indice_Secuencia_Joystick is mod cantidad_datos_Joystick;
   type tipo_Secuencia_Joystick is array (Indice_Secuencia_Joystick) of Joystick_Samples_Type;

   Joystick_Simulation: tipo_Secuencia_Joystick := (others => (x => 0, y => 0));

   ---------------------------------------------------------------------
   ------ POWER: constante 750 = 900 km/h
   cantidad_datos_Power: constant := 200;
   type Indice_Secuencia_Power is mod cantidad_datos_Power;
   type tipo_Secuencia_Power is array (Indice_Secuencia_Power) of Power_Samples_Type;

   Power_Simulation: tipo_Secuencia_Power := (others => 750);

   ---------------------------------------------------------------------
   ------ PILOT'S PRESENCE 0 entre los 13 y los 17 s
   cantidad_datos_PilotPresence: constant := 200;
   type Indice_Secuencia_PilotPresence is mod cantidad_datos_PilotPresence;
   type tipo_Secuencia_PilotPresence is array (Indice_Secuencia_PilotPresence) of PilotPresence_Samples_Type;

   PilotPresence_Simulation: tipo_Secuencia_PilotPresence := 
      (
      0 .. 129 => 1, -- 0-13 s: piloto presente
      130 .. 169 => 0, -- 13-17 s: piloto ausente
      170 .. 199 => 1); -- 17-20 s: piloto presente

   ---------------------------------------------------------------------
   ------ PILOT'S BUTTON 0
   cantidad_datos_PilotButton: constant := 200;
   type Indice_Secuencia_PilotButton is mod cantidad_datos_PilotButton;
   type tipo_Secuencia_PilotButton is array (Indice_Secuencia_PilotButton) of PilotButton_Samples_Type;

   PilotButton_Simulation: tipo_Secuencia_PilotButton := (others => 0);

end testing_3_2;
