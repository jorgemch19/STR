-- Alumnos:
   -- Jorge Moya
   -- Christian Cabañero
   -- Javier López
   -- Paulo Blas Heredia

-- Tareas implementadas:
   -- Speed : Control de velocidad de los motores (periodo 300 ms, prioridad 15)
   -- Position_Altitude : Control de cabeceo, alabeo y altitud (periodo 200 ms, prioridad 20)

-- Objetos protegidos implementados:
   -- Pitch_and_Roll : Comparte la posicion del joystick (ya limitada) entre Position_Altitude (escribe con Set_PR) y Speed (lee con Get_PR). Techo de prioridad 20

with Kernel.Serial_Output; use Kernel.Serial_Output;
with Ada.Real_Time; use Ada.Real_Time;
with System; use System;

with Tools; use Tools;
with devicesFSS_V1; use devicesFSS_V1;

-- NO ACTIVAR ESTE PAQUETE MIENTRAS NO SE TENGA PROGRAMADA LA INTERRUPCION
-- Packages needed to generate button interrupts       
-- with Ada.Interrupts.Names;
-- with Button_Interrupt; use Button_Interrupt;

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
    ----------------------------------------------------------------------

    -----------------------------------------------------------------------
    ------------- declaration of protected objects 
    -----------------------------------------------------------------------

    -- Aqui se declaran los objetos protegidos para los datos compartidos  
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
    -----------------------------------------------------------------------
    ------------- declaration of tasks 
    -----------------------------------------------------------------------

    -- Aqui se declaran las tareas que forman el STR
   task Speed is
      pragma Priority(15);
   end Speed;
   task Position_Altitude is
      pragma Priority(18);
   end Position_Altitude;
   task Collision is
      pragma Priority(20);
   end Collision;

    -----------------------------------------------------------------------
    ------------- body of tasks 
    -----------------------------------------------------------------------

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
            Display_Pilot_Power (Current_Pw);
            
            Current_J := Pitch_and_Roll.Get_PR;
            Calculated_S := Speed_Samples_type (float (Current_Pw) * 1.2); 
            
            if (Current_J(x) > 3 and (abs(Current_J(y)) > 3)) then
                Calculated_S := Calculated_S + 200;
            elsif (Current_J(x) > 3) then
                Calculated_S := Calculated_S + 150;
            elsif (abs(Current_J(y)) > 3) then
                Calculated_S := Calculated_S + 100;
            end if;
            
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
            Current_S := Read_Speed;
            Speed_Altitude.Set_Speed (Current_S);
            Display_Speed (Current_S);

            Finish_Activity ("Speed_Task");
            
            Siguiente_Instante := Siguiente_Instante + Intervalo;
            delay until Siguiente_Instante;
        end loop;
    end Speed;

   task body Position_Altitude is
      Current_J: Joystick_Samples_Type := (0, 0);
      Current_A: Altitude_Samples_Type := 8000;

      Target_Pitch: Joystick_Samples_Values := 0;
      Target_Roll: Joystick_Samples_Values := 0;
      Target_J: Joystick_Samples_Type := (0, 0);

      Maneuver : Boolean := False;

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

         if ((Current_A <= 2000 and Target_Pitch < 0) or (Current_A >= 10000 and Target_Pitch > 0)) then
            Target_Pitch := 0;
         else
            if (abs(Target_Pitch) <= 3) then
               Target_Pitch := 0;
            elsif (Target_Pitch > 30) then
               Target_Pitch := 30;
            elsif (Target_Pitch < -30) then
               Target_Pitch := -30;
            end if;
         end if;

         if Maneuver then
            Target_Roll := 45;
         else
            if (abs(Target_Roll) <= 3) then
               Target_Roll := 0;
            elsif (Target_Roll > 45) then
               Target_Roll := 45;
            elsif (Target_Roll < -45) then
               Target_Roll := -45;
            end if;

            if (Target_Roll > 35 or Target_Roll < -35) then
               Display_Message ("ALERTA ALABEO: SOBREPASANDO ANGULO DE SEGURIDAD (35 grados)");
            end if;
         end if;
         
         if (Current_A < 2500 or Current_A > 9500) then
            Light_1 (On);
         else
            Light_1 (Off);
         end if;

         Target_J := (x => Target_Pitch, y => Target_Roll);
         Pitch_and_Roll.Set_PR(Target_J);

         Set_Aircraft_Pitch (Pitch_Samples_Type(Target_Pitch));
         if (not Maneuver) then
            Set_Aircraft_Roll (Roll_Samples_Type(Target_Roll));
         end if;

         Display_Joystick (Current_J);
         Display_Pitch (Read_Pitch);
         Display_Roll (Read_Roll);
         Display_Altitude (Current_A);

         Finish_Activity ("Position_Altitude_Task");

         Siguiente_Instante := Siguiente_Instante + Intervalo;
         delay until Siguiente_Instante;
      end loop;
   end Position_Altitude;

   task body Collision is
      Current_D : Distance_Samples_Type := 0;
      Current_S : Speed_Samples_Type := 0;
      Current_Pilot_Presence : PilotPresence_Samples_Type := 0;
      Current_Light : Light_Samples_Type := 0;

      Time_Collision : Float := 0.0;
      Time_Alert : Integer := 0;
      Time_Maneuver : Integer := 0;

      Current_Maneuver : Boolean := False;
      Maneuver_Started : Time;

      Siguiente_Instante : Time := Big_Bang;
      Intervalo : Time_Span := Milliseconds (250);
   begin
      loop
         Start_Activity ("Collision_Task");

         if (Current_Maneuver) then
            if (Clock - Maneuver_Started >= Milliseconds (3000)) then
               Set_Aircraft_Roll (0);
               Speed_Altitude.Set_Maneuver (False);
               Current_Maneuver := False;
            end if;
         else
            Read_Distance (Current_D);

            if (Current_D <= 5000) then
               Current_S := Speed_Altitude.Get_Speed;

               if (Current_S > 0) then
                  Time_Collision := (Float(Current_D) * 3600.0) / (Float(Current_S) * 1000.0);
               else
                  Time_Collision := Float'Last;
               end if;

               Current_Pilot_Presence := Read_PilotPresence;
               Read_Light_Intensity (Current_Light);

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
                     Set_Aircraft_Roll (45);
                     Speed_Altitude.Set_Maneuver (True);
                     Current_Maneuver := True;
                     Maneuver_Started := Clock;
                  end if;
               end if;
            end if;

            Display_Distance (Current_D);
         end if;

         Finish_Activity ("Collision_Task");

         Siguiente_Instante := Siguiente_Instante + Intervalo;
         delay until Siguiente_Instante;
      end loop;
   end Collision;

begin
   Start_Activity ("Programa Principal");
   Finish_Activity ("Programa Principal");
end fss;



