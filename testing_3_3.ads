-- Especificacion de Maniobra contra el Joystick

with Ada.Real_Time; use Ada.Real_Time;
with devicesfss_v1; use devicesfss_v1;

package testing_3_3 is
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
   ------ DISTANCE: dos obstaculos
   cantidad_datos_Distancia: constant := 200;
   type Indice_Secuencia_Distancia is mod cantidad_datos_Distancia;
   type tipo_Secuencia_Distancia is array (Indice_Secuencia_Distancia) of Distance_Samples_Type;

   Distance_Simulation: tipo_Secuencia_Distancia := 
      (
      0 .. 49 => 5555, -- 0-5 s: sin obstaculo
      50 .. 59 => 900, -- 5-6 s: menos de 5 s: maniobra
      60 .. 99 => 5555, -- 6-10 s: sin obstaculo
      100 .. 109 => 900, -- 10-11 s: menos de 5 s: maniobra
      110 .. 199 => 5555); -- 11-20 s: sin obstaculo

   ---------------------------------------------------------------------
   ------ LIGHT: buena visibilidad en todo el escenario
   cantidad_datos_Light: constant := 200;
   type Indice_Secuencia_Light is mod cantidad_datos_Light;
   type tipo_Secuencia_Light is array (Indice_Secuencia_Light) of Light_Samples_Type;

   Light_Intensity_Simulation: tipo_Secuencia_Light := (others => 700);

   ---------------------------------------------------------------------
   ------ JOYSTICK: alabeo a la izquierda durante la maniobra
   cantidad_datos_Joystick: constant := 200;
   type Indice_Secuencia_Joystick is mod cantidad_datos_Joystick;
   type tipo_Secuencia_Joystick is array (Indice_Secuencia_Joystick) of Joystick_Samples_Type;

   Joystick_Simulation: tipo_Secuencia_Joystick := 
      (
      0 .. 19 => (x => 0, y => 0), -- 0-2 s: centrado
      20 .. 39 => (x => 0, y => -40), -- 2-4 s: alabeo -40, mensaje de alabeo
      40 .. 59 => (x => 10, y => -40), -- 4-6 s: cabeceo 10 y alabeo -40
      60 .. 119 => (x => 0, y => -40), -- 6-12 s: alabeo -40
      120 .. 199 => (x => 0, y => 0)); -- 12-20 s: centrado

   ---------------------------------------------------------------------
   ------ POWER: constante 700 = 840 km/h
   cantidad_datos_Power: constant := 200;
   type Indice_Secuencia_Power is mod cantidad_datos_Power;
   type tipo_Secuencia_Power is array (Indice_Secuencia_Power) of Power_Samples_Type;

   Power_Simulation: tipo_Secuencia_Power := (others => 700);

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

end testing_3_3;
