-- FSS - Prototipo 4

-- Alumnos:
   -- Jorge Moya
   -- Christian Cabañero
   -- Javier López
   -- Paulo Blas Heredia

-- Tareas implementadas:
   -- Speed : Control de velocidad de los motores (periodo 300 ms, prioridad 15)
   -- Position_Altitude : Control de cabeceo, alabeo y altitud (periodo 200 ms, prioridad 18)
   -- Collision : Control de colisiones (periodo 250 ms, prioridad 20)
   -- Display : Visualización del estado del avión, única tarea que escribe en pantalla (periodo 1000 ms, prioridad 10)

-- Objetos protegidos implementados:
   -- Pitch_and_Roll : Comparte la posicion del joystick (ya limitada) entre Position_Altitude (escribe con Set_PR) y Speed (lee con Get_PR). Techo de prioridad 18
   -- Speed_Altitude : Comparte la velocidad, altitud y estado de maniobra entre Speed, Position_Altitude y Collision. Techo de prioridad 20
   -- Status_Record : Recoge el estado que escriben Speed, Position_Altitude y Collision para que lo muestre Display. Techo de prioridad 20

with Kernel.Serial_Output; use Kernel.Serial_Output;
with Ada.Real_Time; use Ada.Real_Time;
with System; use System;

with Tools; use Tools;
with devicesFSS_V1; use devicesFSS_V1;

-- NO ACTIVAR ESTE PAQUETE MIENTRAS NO SE TENGA PROGRAMADA LA INTERRUPCION
-- Packages needed to generate button interrupts       
with Ada.Interrupts.Names;
with Button_Interrupt; use Button_Interrupt;

package body fss is
   ----------------------------------------------------------------------
   ------------- procedure exported 
   ----------------------------------------------------------------------
   procedure Background is
   begin
   loop
      null;
   end loop;
   end Background;

   -----------------------------------------------------------------------
   ------------- declaration of types
   -----------------------------------------------------------------------
   -- Datos que muestra la tarea Display. Cada tarea de control rellena su parte
   type Status_Type is record
      Joystick : Joystick_Samples_Type := (0, 0);
      Pitch : Pitch_Samples_Type := 0;
      Roll : Roll_Samples_Type := 0;
      Altitude : Altitude_Samples_Type := 8000;
      Roll_Alert : Boolean := False;
      Power : Power_Samples_Type := 0;
      Speed : Speed_Samples_Type := 0;
      Distance : Distance_Samples_Type := 0;
      Light : Light_Samples_Type := 0;
      Pilot_Presence : PilotPresence_Samples_Type := 0;
      Maneuver : Boolean := False;
   end record;

   type Mode_Type is (Automatico, Manual);

   -----------------------------------------------------------------------
   ------------- declaration of protected objects 
   -----------------------------------------------------------------------

   -- Cabeceo y alabeo ordenados al avión (ya limitados)
   --  Speed los usa para aumentar la velocidad durante las maniobras
   protected Pitch_and_Roll is
      pragma Priority (18);
      function Get_PR return Joystick_Samples_Type;
      procedure Set_PR (pitch_roll: in Joystick_Samples_Type);

   private
      Joystick : Joystick_Samples_Type := (0, 0);
   end Pitch_and_Roll;

   protected body Pitch_and_Roll is
      function Get_PR return Joystick_Samples_Type is
      begin
         return Joystick;
      end Get_PR;

      procedure Set_PR(pitch_roll: in Joystick_Samples_Type) is
      begin
         Joystick := pitch_roll;
      end Set_PR;
   end Pitch_and_Roll;

   -- Velocidad, altitud y estado de la maniobra de emergencia
   -- Collision lo usa para calcular el tiempo hasta el obstáculo y decidir si hay que activar la maniobra de emergencia
   -- Underway resuelve el conflicto de órdenes de alabeo entre Position_Altitude y Collision
   -- Position_Altitude lo usa para decidir si puede alabear o no
   protected Speed_Altitude is
      pragma Priority (20);
      function Get_Speed return Speed_Samples_Type;
      function Get_Altitude return Altitude_Samples_Type;
      function Is_Maneuver_Underway return Boolean;
      procedure Set_Speed (S: in Speed_Samples_Type);
      procedure Set_Altitude (A: in Altitude_Samples_Type);
      procedure Set_Maneuver (State : in Boolean);
   private
      Speed : Speed_Samples_Type := 0;
      Altitude : Altitude_Samples_Type := 8000;
      Underway : Boolean := False;
   end Speed_Altitude;

   protected body Speed_Altitude is
      function Get_Speed return Speed_Samples_Type is
      begin
         return Speed;
      end Get_Speed;

      function Get_Altitude return Altitude_Samples_Type is
      begin
         return Altitude;
      end Get_Altitude;

      function Is_Maneuver_Underway return Boolean is
      begin
         return Underway;
      end Is_Maneuver_Underway;

      procedure Set_Speed (S: in Speed_Samples_Type) is
      begin
         Speed := S;
      end Set_Speed;

      procedure Set_Altitude (A: in Altitude_Samples_Type) is
      begin
         Altitude := A;
      end Set_Altitude;

      procedure Set_Maneuver (state : in Boolean) is
      begin
         Underway := state;
      end Set_Maneuver;
   end Speed_Altitude;

   -- Comunica el estado del avión a la tarea Display, la única que escribe en pantalla
   -- Techo 20 porque lo usa Collision
   protected Status_Record is
      pragma Priority (20);
      procedure Set_Position_Status (J: in Joystick_Samples_Type; P: in Pitch_Samples_Type; R: in Roll_Samples_Type; A: in Altitude_Samples_Type; Alert: in Boolean);
      procedure Set_Speed_Status (Pw: in Power_Samples_Type; S: in Speed_Samples_Type);
      procedure Set_Collision_Status (D: in Distance_Samples_Type; L: in Light_Samples_Type; PP: in PilotPresence_Samples_Type; M: in Boolean);
      procedure Get_Status (Current : out Status_Type);
   private
      Status : Status_Type;
   end Status_Record;

   protected body Status_Record is
      procedure Set_Position_Status (J: in Joystick_Samples_Type; P: in Pitch_Samples_Type; R: in Roll_Samples_Type; A: in Altitude_Samples_Type; Alert: in Boolean) is
      begin
         Status.Joystick := J;
         Status.Pitch := P;
         Status.Roll := R;
         Status.Altitude := A;
         -- La alerta se mantiene hasta que Display la muestra, para no perderla
         Status.Roll_Alert := Status.Roll_Alert or Alert;
      end Set_Position_Status;

      procedure Set_Speed_Status (Pw: in Power_Samples_Type; S : in Speed_Samples_Type) is
      begin
         Status.Power := Pw;
         Status.Speed := S;
      end Set_Speed_Status;

      procedure Set_Collision_Status (D: in Distance_Samples_Type; L: in Light_Samples_Type; PP: in PilotPresence_Samples_Type; M: in Boolean) is
      begin
         Status.Distance := D;
         Status.Light := L;
         Status.Pilot_Presence := PP;
         Status.Maneuver := M;
      end Set_Collision_Status;

      procedure Get_Status (Current : out Status_Type) is
      begin
         Current := Status;
         Status.Roll_Alert := False;
      end Get_Status;
   end Status_Record;

   -- Manejador de la interrupcion del boton, contiene la RTI que alertará a la tarea Mode que el botón ha sido presionado
   protected Interrupt_Handler is
      pragma Interrupt_Priority (Priority_Of_External_Interrupts_2); -- Se define la prioridad de la interrupcion
      procedure Button_Pressed; -- RTI
      pragma Attach_Handler (Button_Pressed, Ada.Interrupts.Names.External_Interrupt_2); -- Se define el procedimiento a ejecutar cuando la interrupcion se active
      entry Wait_Button;
   private
      Pressed : Boolean := False;
   end Interrupt_Handler;

   protected body Interrupt_Handler is
      procedure Button_Pressed is
      begin
         Pressed := True;
      end Button_Pressed;

      entry Wait_Button when Pressed is
      begin
         Pressed := False;
      end Wait_Button;
   end Interrupt_Handler;

   -- Objeto que guarda el modo (Automatico o Manual), lo escribe la tarea Modo y lo lee las 3 tareas (Position_Altitude, Speed, Collision)
   protected Selected_Mode is
      pragma Priority(20);
      procedure Change_Mode;
      function Read_Mode return Mode_Type;
   private
      Current_Mode: Mode_Type := Automatico;
   end Selected_Mode;

   protected body Selected_Mode is
   procedure Change_Mode is
   begin
      if Current_Mode = Automatico then
         Current_Mode := Manual;
      else
         Current_Mode := Automatico;
      end if;
   end Change_Mode;

   function Read_Mode return Mode_Type is
   begin
      return Current_Mode;
   end Read_Mode;
end Selected_Mode;

   -----------------------------------------------------------------------
   ------------- declaration of tasks 
   -----------------------------------------------------------------------

   -- Prioridades por Deadline Monotonic: a menor plazo, mayor prioridad
   -- Collision es la más prioritaria por su plazo de 80 ms
   task Speed is
      pragma Priority(15);
   end Speed;

   task Position_Altitude is
      pragma Priority(18);
   end Position_Altitude;

   task Collision is
      pragma Priority(20);
   end Collision;

   task Display is
      pragma Priority(10);
   end Display;

   task Mode is
      pragma Priority(12);
   end Mode;

   -----------------------------------------------------------------------
   ------------- body of tasks 
   -----------------------------------------------------------------------

   -- Calcula la velocidad a partir de la potencia del piloto y de la posición del joystick, y la comunica al avión
   -- La velocidad se limita a 300-1000 km/h y se enciende la luz 2 si se sale de ese rango
   task body Speed is
   Current_Pw: Power_Samples_Type := 0;
   Current_S: Speed_Samples_Type := 0;
   Calculated_S: Speed_Samples_type := 0;
   
   Current_J: Joystick_Samples_Type := (0,0); 
   
   Siguiente_Instante : Time := Big_Bang;
   Intervalo : Time_Span := Milliseconds (300);
   begin
      loop
         Start_Activity ("Speed_Task");        
                  
         Read_Power (Current_Pw);  
         
         Current_J := Pitch_and_Roll.Get_PR;
         Calculated_S := Speed_Samples_type (float (Current_Pw) * 1.2); 
         
         -- Incremento de velocidad para compensar la maniobra:
         -- subida y giro +200, solo subida +150, solo giro +100
         if (Current_J(x) > 3 and (abs(Current_J(y)) > 3)) then
               Calculated_S := Calculated_S + 200;
         elsif (Current_J(x) > 3) then
               Calculated_S := Calculated_S + 150;
         elsif (abs(Current_J(y)) > 3) then
               Calculated_S := Calculated_S + 100;
         end if;
         
         -- Light_2 avisa al piloto de que la velocidad está en un límite.
         if (Calculated_S >= 1000) then
               Calculated_S := 1000;
               Light_2 (On);
         elsif (Calculated_S <= 300) then
               Calculated_S := 300;
               Light_2 (On);
         else 
               Light_2 (Off);
         end if;
         
         Set_Speed (Calculated_S);
          -- Se publica la velocidad real, no la ordenada
         Current_S := Read_Speed;
         Speed_Altitude.Set_Speed (Current_S);
         Status_Record.Set_Speed_Status (Current_Pw, Current_S);

         Finish_Activity ("Speed_Task");
         
         Siguiente_Instante := Siguiente_Instante + Intervalo;
         delay until Siguiente_Instante;
      end loop;
   end Speed;

   -- Controla el cabeceo y alabeo del avión a partir de la posición del joystick, y la altitud a partir del altímetro
   task body Position_Altitude is
      Current_J: Joystick_Samples_Type := (0, 0);
      Current_A: Altitude_Samples_Type := 8000;

      Target_Pitch: Joystick_Samples_Values := 0;
      Target_Roll: Joystick_Samples_Values := 0;
      Target_J: Joystick_Samples_Type := (0, 0);

      Maneuver : Boolean := False;

      Roll_Alert : Boolean := False; -- Variable local para avisar a Display de que se ha sobrepasado el ángulo de seguridad de alabeo

      Siguiente_Instante : Time := Big_Bang;
      Intervalo : Time_Span := Milliseconds (200);
   begin
      loop
         Start_Activity ("Position_Altitude_Task");
         
         Read_Joystick (Current_J);
         Current_A := Read_Altitude;
         Speed_Altitude.Set_Altitude (Current_A);
         Maneuver := Speed_Altitude.Is_Maneuver_Underway;

         Target_Pitch := Current_J(x);
         Target_Roll := Current_J(y);

         -- Fuera del rango 2000-10000 metros, se ignora el cabeceo que aleje aún más el avión
         if ((Current_A <= 2000 and Target_Pitch < 0) or (Current_A >= 10000 and Target_Pitch > 0)) then
            Target_Pitch := 0;
         else
            -- Margen de +/- 3 grados y límites de +/- 30 grados para el cabeceo
            if (abs(Target_Pitch) <= 3) then
               Target_Pitch := 0;
            elsif (Target_Pitch > 30) then
               Target_Pitch := 30;
            elsif (Target_Pitch < -30) then
               Target_Pitch := -30;
            end if;
         end if;

         -- Se ignora el alabeo durante la maniobra de emergencia, y se limita a 45 grados en cualquier caso
         if Maneuver then
            Target_Roll := 45;
            Roll_Alert := False;
         else
            -- Margen de +/- 3 grados y límites de +/- 45 grados para el alabeo
            if (abs(Target_Roll) <= 3) then
               Target_Roll := 0;
            elsif (Target_Roll > 45) then
               Target_Roll := 45;
            elsif (Target_Roll < -45) then
               Target_Roll := -45;
            end if;

            if (Target_Roll > 35 or Target_Roll < -35) then
               Roll_Alert := True;
            else
               Roll_Alert := False;
            end if;
         end if;
         
         -- Light_1 avisa al piloto de que la altitud está cerca de un límite.
         if (Current_A < 2500 or Current_A > 9500) then
            Light_1 (On);
         else
            Light_1 (Off);
         end if;

         Target_J := (x => Target_Pitch, y => Target_Roll);
         Pitch_and_Roll.Set_PR(Target_J);

         Set_Aircraft_Pitch (Pitch_Samples_Type(Target_Pitch));
         -- Se ignora el alabeo durante la maniobra de emergencia. Collision es el que da la orden de alabeo
         if (not Maneuver) then
            Set_Aircraft_Roll (Roll_Samples_Type(Target_Roll));
         end if;

         Status_Record.Set_Position_Status (Current_J, Read_Pitch, Read_Roll, Current_A, Roll_Alert);

         Finish_Activity ("Position_Altitude_Task");

         Siguiente_Instante := Siguiente_Instante + Intervalo;
         delay until Siguiente_Instante;
      end loop;
   end Position_Altitude;

   -- Detecta obstáculos y decide si hay que activar la maniobra de emergencia, y la activa si es necesario
   -- Maniobra de emergencia: alabeo a 45 grados durante 3 segundos, con un plazo de 80 ms desde la activación hasta la orden
   task body Collision is
      Current_D : Distance_Samples_Type := 0;
      Current_S : Speed_Samples_Type := 0;
      Current_Pilot_Presence : PilotPresence_Samples_Type := 0;
      Current_Light : Light_Samples_Type := 0;

      Time_Collision : Float := 0.0;
      Time_Alert : Integer := 0;
      Time_Maneuver : Integer := 0;

      -- Copia local de la variable protegida Speed_Altitude.Underway, para saber si hay una maniobra en curso
      Current_Maneuver : Boolean := False;
      Maneuver_Started : Time;

      Siguiente_Instante : Time := Big_Bang;
      Intervalo : Time_Span := Milliseconds (250);
   begin
      loop
         Start_Activity ("Collision_Task");

         
         if (Current_Maneuver) then
            -- La duración de la maniobra se mide con el reloj
            if (Clock - Maneuver_Started >= Milliseconds (3000)) then
               Set_Aircraft_Roll (0);
               Speed_Altitude.Set_Maneuver (False);
               Current_Maneuver := False;
            else
               -- Se repite la orden por si Position_Altitude la ha sobreescrito
               Set_Aircraft_Roll (45);
            end if;
         else
            Read_Distance (Current_D);

            Current_Pilot_Presence := Read_PilotPresence;
            Read_Light_Intensity (Current_Light);

            if (Current_D <= 5000) then
               Current_S := Speed_Altitude.Get_Speed;

               -- Distancia a obstáculo en metros, velocidad en km/h, tiempo hasta colisión en segundos
               if (Current_S > 0) then
                  Time_Collision := (Float(Current_D) * 3600.0) / (Float(Current_S) * 1000.0);
               else
                  -- Con el avión parado, no hay colisión
                  Time_Collision := Float'Last;
               end if;

               -- Con poca visibilidad o sin piloto en el asiento, se da más tiempo de alerta y maniobra
               if (Current_Light < 500 or Current_Pilot_Presence /= 1) then
                  Time_Alert := 15;
                  Time_Maneuver := 10;
               else
                  Time_Alert := 10;
                  Time_Maneuver := 5;
               end if;

               if (Time_Collision < Float(Time_Alert)) then
                  Alarm(4);
                  if (Time_Collision < Float(Time_Maneuver)) then
                     -- La orden va primero para cumplir el plazo de 80 ms
                     Set_Aircraft_Roll (45);
                     Speed_Altitude.Set_Maneuver (True);
                     Current_Maneuver := True;
                     Maneuver_Started := Clock;
                  end if;
               end if;
            end if;
         end if;

         Status_Record.Set_Collision_Status (Current_D, Current_Light, Current_Pilot_Presence, Current_Maneuver);

         Finish_Activity ("Collision_Task");

         Siguiente_Instante := Siguiente_Instante + Intervalo;
         delay until Siguiente_Instante;
      end loop;
   end Collision;

   -- Muestra cada segundo el estado que las tareas dejan en Status_Record
   task body Display is
      Current_Status : Status_Type;

      Siguiente_Instante : Time := Big_Bang;
      Intervalo : Time_Span := Milliseconds (1000);
   begin
      loop
         Start_Activity ("Display_Task");

         Status_Record.Get_Status (Current_Status);

         Display_Joystick (Current_Status.Joystick);
         Display_Pitch (Current_Status.Pitch);
         Display_Roll (Current_Status.Roll);
         Display_Altitude (Current_Status.Altitude);
         Display_Pilot_Power (Current_Status.Power);
         Display_Speed (Current_Status.Speed);
         Display_Distance (Current_Status.Distance);
         Display_Light_Intensity (Current_Status.Light);
         Display_Pilot_Presence (Current_Status.Pilot_Presence);

         if Current_Status.Roll_Alert then
            Display_Message ("ALERTA ALABEO: SOBREPASANDO ANGULO DE SEGURIDAD (35 grados)");
         end if;

         if Current_Status.Maneuver then
            Display_Message ("MANIOBRA DE DESVIO AUTOMATICO EN CURSO");
         end if;

         Finish_Activity ("Display_Task");

         Siguiente_Instante := Siguiente_Instante + Intervalo;
         delay until Siguiente_Instante;
      end loop;
   end Display;

   task body Mode is
      Activation_Time : Time;
      Minimum_Separation : Time_Span := Milliseconds (330);
   begin
      loop
         Interrupt_Handler.Wait_Button;
         Activation_Time := Clock;
         Start_Activity ("Mode_Task");

         Selected_Mode.Change_Mode;

         Finish_Activity ("Mode_Task");

         delay until Activation_Time + Minimum_Separation;
      end loop;
   end Mode;

begin
   Start_Activity ("Programa Principal");
   Finish_Activity ("Programa Principal");
end fss;



