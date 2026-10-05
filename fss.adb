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


    -----------------------------------------------------------------------
    ------------- declaration of tasks 
    -----------------------------------------------------------------------

    -- Aqui se declaran las tareas que forman el STR
    task Speed is
      pragma Priority(20);
   end Speed;
   task Prueba_Distancia is
      pragma Priority(20);
   end Prueba_Distancia;
   task Prueba_Joystick is
      pragma Priority(19);
   end Prueba_Joystick;
   task Prueba_Piloto is
      pragma Priority(18);
   end Prueba_Piloto;

    -----------------------------------------------------------------------
    ------------- body of tasks 
    -----------------------------------------------------------------------

    task body Speed is
      Current_Pw: Power_Samples_Type := 0;
      Current_S: Speed_Samples_Type := 500;
      Calculated_S: Speed_Samples_type := 0;
      
      Current_J: Joystick_Samples_Type := (0,0); 
        
    begin
        loop
            Start_Activity ("Speed_Task");        
                    
            Read_Power (Current_Pw);  
            Display_Pilot_Power (Current_Pw);
            
            Read_Joystick (Current_J);
                        
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
            
            delay until (Clock + Milliseconds (300));
        end loop;
    end Speed;

    -- Aqui se escriben los cuerpos de las tareas 
   task body Prueba_Distancia is
      Current_Pw: Power_Samples_Type := 0;
        Current_S: Speed_Samples_Type := 500; 
        Calculated_S: Speed_Samples_type := 0; 
             
        Current_D: Distance_Samples_Type := 0;
        Current_L: Light_Samples_Type := 0;
        
   begin

      loop
      Start_Activity ("Prueba_Distancia");        
                   
      -- Prueba potencia del piloto 
      Read_Power (Current_Pw);  -- lee la potencia de motor indicada por el piloto
            Display_Pilot_Power (Current_Pw);
                      
            -- transfiere la potencia/velocidad a la aeronave
            Calculated_S := Speed_Samples_type (float (Current_Pw) * 1.2); -- aplicar fórmula
            if (Calculated_S > 1000) then
               Calculated_S := 1000;
               Light_1 (On);
            else 
               Light_1 (Off);
            end if;
            Set_Speed (Calculated_S);
            
            -- Comprueba la velocidad real de la aeronave
            Current_S := Read_Speed;        -- lee la velocidad actual de la aeronave
            Display_Speed (Current_S);

            -- Prueba distancia con obstaculos
            Read_Distance (Current_D);
            if (Current_D < 1000) then
               Alarm (4);
               Set_Aircraft_Roll(Roll_Samples_Type(40));
            elsif (Current_D < 2000) then
               Alarm (4);
            elsif (Current_D < 4000) then
               Alarm (2);
            else
               Alarm (0);
            end if;
            Display_Distance (Current_D);
                                 
         Finish_Activity ("Prueba_Distancia");   
         delay until (Clock + Milliseconds (300));
         end loop;
   end Prueba_Distancia;

   task body Prueba_Joystick is
      Current_J: Joystick_Samples_Type := (0,0);
        Target_Pitch: Pitch_Samples_Type := 0;
        Target_Roll: Roll_Samples_Type := 0; 
        Aircraft_Pitch: Pitch_Samples_Type; 
        Aircraft_Roll: Roll_Samples_Type;
        
        Current_A: Altitude_Samples_Type := 8000;
        
    begin
         loop     
            Start_Activity ("Prueba_Joystick");
            
            -- Lee Joystick del piloto
            Read_Joystick (Current_J);
            
            -- establece Pitch y Roll en la aeronave
            Target_Pitch := Pitch_Samples_Type (Current_J(x));
            if (Target_Pitch > 30) then
               Target_Pitch := Pitch_Samples_Type(30);
            elsif (Target_Pitch < -30) then
               Target_Pitch := Pitch_Samples_Type(-30);
            end if;
            Target_Roll := Roll_Samples_Type (Current_J(y));
            if (Target_Roll > 45) then
               Target_Roll := Roll_Samples_Type(45);
            elsif (Target_Roll < -45) then
               Target_Roll := Roll_Samples_Type(-45);
            end if;
                                      
            Set_Aircraft_Pitch (Target_Pitch);  -- transfiere el movimiento pitch a la aeronave
            Set_Aircraft_Roll (Target_Roll);    -- transfiere el movimiento roll  a la aeronave 
                       
            Aircraft_Pitch := Read_Pitch;       -- lee la posición pitch de la aeronave
            Aircraft_Roll := Read_Roll;         -- lee la posición roll  de la aeronave
            
            Display_Joystick (Current_J);       -- muestra por display el joystick  
            Display_Pitch (Aircraft_Pitch);     -- muestra por display la posición de la aeronave  
            Display_Roll (Aircraft_Roll);

            -- Comprueba altitud
            Current_A := Read_Altitude;         -- lee y muestra por display la altitud de la aeronave  
            Display_Altitude (Current_A);
            if (Current_A > 9000) then
               Alarm (3); 
               Display_Message ("To high");
               if (Current_A > 10000) then
                  Light_2 (On);
               else
                  Light_2 (Off);
               end if;
            else
               Light_2 (Off);
            end if; 
               
            Finish_Activity ("Prueba_Joystick");                      
         delay until (Clock + Milliseconds (300));
         end loop;
   end Prueba_Joystick;

   task body Prueba_Piloto is
      Current_Pp: PilotPresence_Samples_Type := 1;
        Current_Pb: PilotButton_Samples_Type := 0;
    begin

         loop
            Start_Activity ("Prueba_Piloto");                
            -- Prueba presencia piloto
            Current_Pp := Read_PilotPresence;
            if (Current_Pp = 0) then Alarm (1); end if;   
            Display_Pilot_Presence (Current_Pp);
                 
            -- Prueba botón para selección de modo 
            Current_Pb := Read_PilotButton;            
            Display_Pilot_Button (Current_Pb); 
            
            Finish_Activity ("Prueba_Piloto");  
         delay until (Clock + Milliseconds (300));
         end loop;
   end Prueba_Piloto;
    ----------------------------------------------------------------------
    ------------- procedimientos para probar los dispositivos 
    ------------- SE DEBERÁN QUITAR PARA EL PROYECTO
    ----------------------------------------------------------------------

begin
   Start_Activity ("Programa Principal");
   Finish_Activity ("Programa Principal");
end fss;



