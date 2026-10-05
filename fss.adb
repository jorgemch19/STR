-- Entrega Arranque del Proyecto FSS
-- Realizado por:
--   Jorge Moya
--   Christian Cabañero
--   Javier Lopez Peinado
--   Paulo Blas Heredia

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

    -----------------------------------------------------------------------
    ------------- declaration of tasks 
    -----------------------------------------------------------------------

    -- Aqui se declaran las tareas que forman el STR
   task Speed is
      pragma Priority(15);
   end Speed;
   task Position_Altitude is
      pragma Priority(20);
   end Position_Altitude;

    -----------------------------------------------------------------------
    ------------- body of tasks 
    -----------------------------------------------------------------------

    task body Speed is
      Current_Pw: Power_Samples_Type := 0;
      Current_S: Speed_Samples_Type := 500;
      Calculated_S: Speed_Samples_type := 0;
      
      Current_J: Joystick_Samples_Type := (0,0); 
      
      
      Siguiente_Instante : Time := Clock;
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
            Display_Speed (Current_S);
                                    
            Finish_Activity ("Speed_Task");
            
            Siguiente_Instante := Siguiente_Instante + Intervalo;
            delay until Siguiente_Instante;
        end loop;
    end Speed;

begin
   Start_Activity ("Programa Principal");
   Finish_Activity ("Programa Principal");
end fss;



