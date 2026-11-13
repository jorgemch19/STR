-- Especificacion de Visualizacion

with Ada.Real_Time; use Ada.Real_Time;
with devicesfss_v1; use devicesfss_v1;

package testing_4_1 is
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
   -- Todos los datos cambian a lo largo del escenario para comprobar que Display los muestra cada segundo, junto con los mensajes de alerta de alabeo y de maniobra de desvío
   -- Initial_Altitude: Altitude_Samples_Type := 8000;

   ---------------------------------------------------------------------
   ------ DISTANCE: obstaculo entre los 10 y los 12 s
   cantidad_datos_Distancia: constant := 200;
   type Indice_Secuencia_Distancia is mod cantidad_datos_Distancia;
   type tipo_Secuencia_Distancia is array (Indice_Secuencia_Distancia) of Distance_Samples_Type;

   Distance_Simulation: tipo_Secuencia_Distancia :=
      (
      0 .. 99 => 5555, -- 0-10 s: sin obstaculo
      100 .. 109 => 1500, -- 10-11 s: 9 s: alarma
      110 .. 119 => 700, -- 11-12 s: 4,2 s: maniobra (mensaje en Display durante 3 s)
      120 .. 199 => 5555); -- 12-20 s: sin obstaculo

   ---------------------------------------------------------------------
   ------ LIGHT: baja de 500 a partir de los 15 s
   cantidad_datos_Light: constant := 200;
   type Indice_Secuencia_Light is mod cantidad_datos_Light;
   type tipo_Secuencia_Light is array (Indice_Secuencia_Light) of Light_Samples_Type;

   Light_Intensity_Simulation: tipo_Secuencia_Light :=
      (
      0 .. 149 => 700, -- 0-15 s: buena visibilidad
      150 .. 199 => 300); -- 15-20 s: mala visibilidad

   ---------------------------------------------------------------------
   ------ JOYSTICK: alabeo > 35 grados (alerta) y alabeo durante la maniobra
   cantidad_datos_Joystick: constant := 200;
   type Indice_Secuencia_Joystick is mod cantidad_datos_Joystick;
   type tipo_Secuencia_Joystick is array (Indice_Secuencia_Joystick) of Joystick_Samples_Type;

   Joystick_Simulation: tipo_Secuencia_Joystick :=
      (
      0 .. 29 => (x => 0, y => 0), -- 0-3 s: centrado
      30 .. 59 => (x => 10, y => 40), -- 3-6 s: subida y giro, alerta de alabeo
      60 .. 89 => (x => -10, y => -20), -- 6-9 s: bajada y giro, sin alerta
      90 .. 119 => (x => 0, y => 0), -- 9-12 s: centrado
      120 .. 129 => (x => 0, y => 40), -- 12-13 s: durante la maniobra se ignora, sin alerta
      130 .. 199 => (x => 0, y => 0)); -- 13-20 s: centrado

   ---------------------------------------------------------------------
   ------ POWER
   cantidad_datos_Power: constant := 200;
   type Indice_Secuencia_Power is mod cantidad_datos_Power;
   type tipo_Secuencia_Power is array (Indice_Secuencia_Power) of Power_Samples_Type;

   Power_Simulation: tipo_Secuencia_Power :=
      (
      0 .. 59 => 750, -- 0-6 s
      60 .. 119 => 500, -- 6-12 s
      120 .. 199 => 900); -- 12-20 s

   ---------------------------------------------------------------------
   ------ PILOT'S PRESENCE 0 a partir de los 17 s
   cantidad_datos_PilotPresence: constant := 200;
   type Indice_Secuencia_PilotPresence is mod cantidad_datos_PilotPresence;
   type tipo_Secuencia_PilotPresence is array (Indice_Secuencia_PilotPresence) of PilotPresence_Samples_Type;

   PilotPresence_Simulation: tipo_Secuencia_PilotPresence :=
      (
      0 .. 169 => 1, -- 0-17 s: piloto presente
      170 .. 199 => 0); -- 17-20 s: piloto ausente

   ---------------------------------------------------------------------
   ------ PILOT'S BUTTON 0
   cantidad_datos_PilotButton: constant := 200;
   type Indice_Secuencia_PilotButton is mod cantidad_datos_PilotButton;
   type tipo_Secuencia_PilotButton is array (Indice_Secuencia_PilotButton) of PilotButton_Samples_Type;

   PilotButton_Simulation: tipo_Secuencia_PilotButton := (others => 0);

end testing_4_1;
