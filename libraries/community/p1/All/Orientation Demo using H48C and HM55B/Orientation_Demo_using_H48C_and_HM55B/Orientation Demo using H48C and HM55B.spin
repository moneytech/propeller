{{
***********************************************

  Orientation Demo using H48C 3-Axis Accelerometer
      and HM55B Compass
                                                                    
  Author: Travis, 09-Jan-09
        
***********************************************

This demo connects a PropStick USB to the H48C Accelerometer and HM55B Compass.  It outputs the
x,y,z from the H48C and the heading from the HM55B to the Parallax Serial Terminal (via FullDuplexSerial).
It also flashes the LEDs to indicate the program is running.

Objects used:

  H48C   : "Sensor.H48C.Accelerometer"  'custom SPIN file located in source folder
  HM55B  : "Sensor.HM55B.Compass"       'custom SPIN file located in source folder
  Debug  : "FullDuplexSerial"           'standard from propeller library  

Components needed:
  Breadboard w/ connector wire set
  5-9V power supply (9v battery or 4 AA batteries)
  PropStick USB - http://www.parallax.com/Store/Microcontrollers/BASICStampModules/tabid/134/txtSearch/PropStick/List/1/ProductID/411/Default.aspx?SortField=ProductName%2cProductName
  H48C Accelerometer - http://www.parallax.com/Store/Sensors/AccelerationTilt/tabid/172/txtSearch/PropStick/List/1/ProductID/97/Default.aspx?SortField=ProductName%2cProductName
  HM55B Compass - http://www.parallax.com/Store/Sensors/CompassGPS/tabid/173/txtSearch/PropStick/List/1/ProductID/98/Default.aspx?SortField=ProductName%2cProductName
  3 LEDs
  1 270 Ohm resistor
  1 - LM2940 5 volt regulator
  1 - 1000uf capacitor

Software/Downloads needed:

  Propeller Tool Software (used to program the Prop):
    http://www.parallax.com/Portals/0/Downloads/sw/propeller/Setup-Propeller-Tool-v1.2.5.exe

  FTDI USB VCP Drivers (for WinXP):
    http://www.parallax.com/Portals/0/Downloads/sw/R9052151.zip

  Parallax Serial Terminal:
    http://www.parallax.com/Portals/0/Downloads/sw/propeller/PST.exe.zip

Relevant Documentation:

  PE-Lab-Setup-for-PropStick USB v1.0.pdf (Simple LED Code and 5 volt power supply)
    http://www.parallax.com/Portals/0/Downloads/docs/prod/prop/PE-Lab-Setup-PropStick-USB-v1.0.zip

  32210-PropStickUSB-v1.1.pdf (Schematic of PropStick USB)
    http://www.parallax.com/Portals/0/Downloads/docs/prod/prop/32210-PropStickUSB-v1.1.pdf

  HitachiH48C3AxisAcelerometer.pdf (Schematic of H48C Accelerometer)
    http://www.parallax.com/Portals/0/Downloads/docs/prod/acc/HitachiH48C3AxisAccelerometer.pdf

  HM55BModDocs.pdf (Schematic of HM55B Compass)
    http://www.parallax.com/Portals/0/Downloads/docs/prod/compshop/HM55BModDocs.pdf

  WebPM-v1.01.pdf (Detailed SPIN language documentation 
    http://www.parallax.com/Portals/0/Downloads/docs/prod/prop/WebPM-v1.01.pdf
    
Basic Build Instructions:

   1. Configure the components based on the PIN diagrams below.  Use a breadboard for testing purposes.
   2. Download and install the required software (listed above).
   3. Open the Propeller Tool Software.
   4. From within the Propeller Tool Software, open this file (Orientation Demo using H48C and HM55B.spin).
   5. Connect the PropStick USB to the computer.
   6. Power on the PropStick USB with 5-9v.
   7. From within the Propeller Tool Software, hit F7 to confirm communication with PropStick USB.
   8. From within the Propeller Tool Softwere, hit F10 to compile and load program into the PropStick USB.
      Make sure this file (Orientation Demo using H48C and HM55B.spin) has the focus when you hit F10,
      otherwise the file with current focus is loaded onto the PropStick.
   9. Open the Parallax Serial Terminal.
  10. From within the Parallax Serial Terminal, make sure the COM Port is set to the COM port indicated when
      you hit F7 from the Propeller Tool Softwere and the Baud Rate is 19200 (unless you changed it in this
      file below).
  11. From within the Parallax Serial Terminal, click 'Enable' (which should be flashing anytime the PropStick
      USB is connected).
  12. Confirm the screen is output the readings from the sensors. 

Pin Diagram for PropStick USB (Direct connections between H48C,HM55B and PROP; no resistors needed)

                     ┌──────────┐
        HM55B-EN ──│P0        │
                     │          │
        M55B-CLK ──│P1        │
                     │          │
        M55B-DIN ──│P2        │
                     │          │
         H48C-CS ──│P3        │
                     │          │
        H48C-DIO ──│P4        │
                     │          │
        H48C-CLK ──│P5        │
                     │          │
          Ground ──│VSS    VDD│── 270 Ohm Resistor ── LED ── Ground  (this is the power indicator LED)
                     │          │
           +5-9V ──│VIN       │
                     │          │
 Ground ── LED ──│P15    P16│── LED ── Ground
                     │          │
                     │   USB    │
                     │   Plug   │
                     └──────────┘

Pin Diagram for HM55B

            ┌─────┬┬─────┐
  DIN ─┬──│1    6│── VCC +5V
        │   │   ├┴──┴┤   │          
 DOUT ─└──│2  │ /\ │  5│── EN
            │   │/  \│   │
    VSS ──│3  └────┘  4│── CLK
            └────────────┘

Pin Diagram for H48C

          ┌──────────┐
  CLK ──│1 ‣‣••6│── VCC +5V
          │  ┌°───┐  │            
  DIO ──│2 │ /\ │ 5│── CS
          │  └────┘  │
  VSS ──│3  4│── ZERO-G (not used in this demo) 
          └──────────┘

Pin Diagram for 5V Power Supply (Detailed diagram/photos in PE-Lab-Setup-for-PropStick USB v1.0.pdf on page 8)

                          ┌───┐┐
        VCC 6-9V (IN) ──│1  ││
                          │   ││          
         VSS ──────┐────│2  ││ <--LM2940
                    │     │   ││
                 1000uf   │   ││
                   +│     │   ││
                    │     │   ││
   VCC 5V (OUT) ───└────│3  ││
                          └───┘┘

}}
CON

  _CLKMODE = XTAL1 + PLL16X
  _XINFREQ = 5_000_000

  'Pin on Prop Chip for LED Indicator
  PIN_LED = 15

  'Pins on Prop Chip for H48C Accelerometer
  PIN_H48C_CS   = 3
  PIN_H48C_CLK  = 5
  PIN_H48C_DIO  = 4

  'Pins on Prop Chip for HM55B Compass
  PIN_HM55B_Enable = 0
  PIN_HM55B_Clock  = 1
  PIN_HM55B_Data   = 2

  'variances are used to normalize the outputs; otherwise, they vary considerably even
  'without any movement of the chip.  this decreases sensitivity.
  H48C_Variance = 5  
  HM55B_Variance = 5   

VAR

  long objH48C, objHM55B
  
OBJ
        
  H48C   : "Sensor.H48C.Accelerometer"  'custom SPIN file located in source folder
  HM55B  : "Sensor.HM55B.Compass"       'custom SPIN file located in source folder
  Debug  : "FullDuplexSerial"           'standard from propeller library  
  
PUB Begin

    'start debugger
    debug.start(31,30,0,19200)
      
    'set pin direction for LED to output
    dira[PIN_LED]~~

    'flash the LED to confirm the program is running
    repeat 10
      !outa[PIN_LED]
      waitcnt(clkfreq / 2 + cnt) '0.5 seconds

    'blank the screen
    debug.str(string(16))
    
    'start H48C accelerometer
    debug.Str(string("Starting H48C Accelerometer...", 13))
    objH48C := false
    objH48C := H48C.start (PIN_H48C_CLK, PIN_H48C_DIO, PIN_H48C_CS, H48C_Variance)

    'test startup of H48C
    if (objH48C)
      debug.Str(string("H48C Accelerometer Started Successfully!",13))
    else
      debug.Str(string("H48C Accelerometer Failed to Start!",13))

    'start HM55B compass
    debug.Str(string("Starting HM55B Compass...", 13))
    objHM55B := false
    objHM55B := HM55B.start(PIN_HM55B_Enable, PIN_HM55B_Clock, PIN_HM55B_Data)

    'test startup of HM55B
    if (objHM55B)
      debug.Str(string("HM55B Compass Started Successfully!",13))
    else
      debug.Str(string("HM55B Compass Failed to Start!",13))

    'display data from H48C & HM55B
    if (objH48C AND objHM55B)
      repeat
        Display
        waitcnt(clkfreq / 4 + cnt)
    else
      debug.str(string("Error: Either H48C or HM55B failed to start. Terminating...",13))

      
PUB Display

    'write header to debug
    debug.str(string("x (lr)",9,"y (fb)",9,"z (ud)",9,"h", 13))

    'overwrite data line to blank it out
    debug.str(string("                                                           ",13,5))
    
    'write data to debug
    debug.dec(H48C.x)
    debug.str(string(9))
    debug.dec(H48C.y)
    debug.str(string(9))
    debug.dec(H48C.z)
    debug.str(string(9))
    debug.dec(HM55B.degreesMin(HM55B_Variance))
    debug.str(string("   ", 13))
    debug.str(string(5, 5))

DAT
{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}