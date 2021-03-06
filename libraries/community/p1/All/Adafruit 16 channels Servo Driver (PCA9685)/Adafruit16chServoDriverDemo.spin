{{┌──────────────────────────────────────────┐
  │ Drive 16 servos via I2C bus              │
  │ Author: Jerome Decock                    │
  │                                          │
  │ See end of file for terms of use.        │
  └──────────────────────────────────────────┘
  Constantly swing servos from minimum position to max and back (TEST)
  SCL/SDA set on pins 10/11
  Base I2C address of driver (no jumpers soldered) $40
  Connect propeller 3.3V to servo driver board VCC
  Connect propeller gnd to servo driver board Gnd
  Connect propeller SCL (pin 10 in this case) to servo driver board SCL
  Connect propeller SDA (pin 11 in this case) to servo driver board SDA  

}}                                                                                                                                                
CON
  _clkmode = xtal1 + pll16x                                                      
  _xinfreq = 5_000_000

  SCL = 10  'assign correct pin numbers
  SDA = 11

  DRIVERADDRESS = $40   'Address of PCA9685 set this with solder jumper A0 to A5 (no jumper=base address $40)
  'empirical values for 50Hz PWM frequency
  SERVOMIN =80 'this is the 'minimum' pulse length count (out of 4096)
  SERVOMAX =512 ' this is the 'maximum' pulse length count (out of 4096)
  
OBJ
  SERVO  : "Adafruit16chServoDriver.spin"  'use no cog except if (optional) using of I2C PASM driver
  FDS    : "FullDuplexSerial"

PUB main | servosteps,pulselen,servonum,mode,prescale

   FDS.start(31,30,0,115_200)
   FDS.str(string("Adafruit 16ch ServoDriver Demo /////////////"))
   FDS.tx($0D)
   
   SERVO.init(DRIVERADDRESS,SCL,SDA)
   
   SERVO.setPWMFreq(50) 'servo uses 50 to 60Hz, if using 60 you will have to adapt the SERVOMIN/MAX constants
   
   PauseMSec(10)

   mode := SERVO.getmode
   FDS.str(string("PCA9685 mode %"))
   FDS.bin(mode,8)
   FDS.tx($0D)

   prescale:= SERVO.getprescale
   FDS.str(string("PCA9685 prescale "))
   FDS.dec(prescale)
   FDS.tx($0D)

   servosteps:=SERVOMAX-SERVOMIN
   
   'full swing(180°) on all servos
   
   repeat

      FDS.str(string("CW 0 - 180°"))  
      FDS.tx($0D)
      repeat pulselen from SERVOMIN to SERVOMAX step 2
        repeat servonum from 0 to 15
          SERVO.setPWM(servonum, 0, pulselen)
        'PauseMSec(5)'uncomment if using PASM I2C driver for slower motion
        'FDS.dec(pulselen)  
        'FDS.tx($0D)
        
      PauseMSec(500)
       
      FDS.str(string("CCW 180 - 0°"))  
      FDS.tx($0D)
      repeat pulselen from SERVOMAX to SERVOMIN step 2
        repeat servonum from 0 to 15
          SERVO.setPWM(servonum, 0, pulselen)
        'PauseMSec(5)'uncomment if using PASM I2C driver for slower motion 
        'FDS.dec(pulselen)  
        'FDS.tx($0D)
       
      PauseMSec(500)

PRI PauseMSec(Duration)
  waitcnt(((clkfreq / 1_000 * Duration - 3932) #> 381) + cnt)
  
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