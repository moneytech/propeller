{{ DS1620_full.spin
┌─────────────────────────────────────┬────────────────┬─────────────────────┬───────────────┐
│ DS1602 driver v1.0                  │ BR             │ (C)2012             │  26Nov2012    │
├─────────────────────────────────────┴────────────────┴─────────────────────┴───────────────┤
│                                                                                            │
│ A full-featured DS1620 thermostat chip driver. Supports degF and degC.  Temperatures are   │
│ returned scaled by 10X (i.e., a reading of 770F is 77.0F).  This object shamelessly robs   │
│ code snippets from two OBEX objects (thank-you Jon and Greg) and adds some new features:   │
│  http://obex.parallax.com/objects/752/                                                     │
│  http://obex.parallax.com/objects/41/                                                      │
│                                                                                            │
│ Features include:                                                                          │
│ •A simple/minimal serial-terminal-based demo (like Greg's object)                          │
│ •Convience of high level helper functions (like Jon's object)                              │
│ •A function to provide low-level (register) access and control                             │
│ •A "stop" function that returns the 1620 to standalone, free-running mode when done        │
│ •A simple/convenient method for programming and testing the thermostat functions           │
│ •Simple error trapping                                                                     │
│                                                                                            │
│ This object provides those functions, mainly by building on the excellent work             │
│ of the above-noted folks.  Also, overall code size is reduced vs original objects.         │
│                                                                                            │
│ See end of file for terms of use.                                                          │
└────────────────────────────────────────────────────────────────────────────────────────────┘

  REFERENCE CIRCUIT (for using the DS1620 in SPI mode w/ a µC):

  PROPELLER                DS1620                   +5V or +3.3V
  ────────┐   1KΩ   ┌────────────────┐              
        P0│──────│1 (DQ)    VDD    8│────────┳────┘ 
        P1│────────│2 (CLK)   T(hi)  7│NC      │
        P2│────────│3 (RST)   T(lo)  6│NC       0.1µF
          │   ┌────│4 (GND)   T(com) 5│NC      │
  ────────┘   │     └──────────────────┘        │
                                               
             GND                               GND

  NOTES:
  •Locate 0.1µF capacitor as close to the power leads as possible
  •The 1k resistor on DQ pin is not required if running at 3.3V, but is a good idea
  •A 1KΩ (or 2KΩ) resistor on DQ pin is required if running DS1620 at 5V 

  REFERENCE CIRCUIT (for using the DS1620 in standalone thermostat mode):

                           DS1620                   +5V or +3.3V
                    ┌────────────────┐               
                  NC│1 (DQ)    VDD    8│────────┳────┘ 
              ┌────│2 (CLK)   T(hi)  7│T1      │          T1 =  activated if T>Thi
              ┣────│3 (RST)   T(lo)  6│T2       0.1µF    T2 =  activated if T<Tlo
              ┣────│4 (GND)   T(com) 5│T3      │          T3 =  activated if T>Thi OR T<Tlo
              │     └──────────────────┘        │                has hysteresis band such that
                                                               it stays on until the opposite
             GND                               GND               threshhold is corssed

}} 
CON
  RdTmp         = $AA           '1010_1010              ' read temperature
  WrHi          = $01           '0000_0001              ' write TH (high temp)
  WrLo          = $02           '0000_0010              ' write TL (low temp)
  RdHi          = $A1           '1010_0001              ' read TH
  RdLo          = $A2           '1010_0010              ' read TL
  RdCntr        = $A0           '1010_0000              ' read counter
  RdSlope       = $A9           '1010_1001              ' read slope
  StartC        = $EE           '1110_1110              ' start conversion
  StopC         = $22           '0010_0010              ' stop conversion
  WrCfg         = $0C           '0000_1100              ' write config register
  RdCfg         = $AC           '1010_1100              ' read config register
                                'R  0
  #0, TempC, TempF


VAR
  byte  dpin, cpin, rst, started


OBJ
  io    : "shiftio"  
    

PUB init(data_pin, clock_pin, rst_pin)
''Initialize propeller SPI com channel with DS1620.  Call once after prop power-up.

  dpin := data_pin
  cpin := clock_pin
  rst := rst_pin

  dira[rst]~~                                           ' make rst pin an output
  rwreg(WrCfg,%10)                                      ' set for CPU, free-run
  rwreg(StartC,0)                                       ' start conversions
  started~~                                             ' flag sensor as started


PUB stop
'' Releases DS1620, sets for standalone mode (CPU=0) 

  rwreg(WrCfg,%00)
  dira[rst]~                                            ' release rst pin (make input)
  started~
                                    

PUB rwreg(cmd,val) |t1,t2
''reads or writes specified register
''cmd = command code (see constants section of this object for definitions)
''val = for write operations, value to be written to DS1620
''      for read operations, not used

  if started==0                                         ' if not started, return error code
    return -999
  outa[rst]~~                                           ' activate sensor
  io.shiftout(dpin, cpin, io#LsbFirst, cmd, 8)          ' write to config register
  if cmd==WrCfg or cmd==RdCfg                           
    t1:=8                                               ' 8 bits if acessing cfg register
  else
    t1:=9                                               ' 9 bits all other cmds
  if cmd==StartC or cmd==StopC
  elseif cmd > %1000_0000
    t2 := io.shiftin(dpin, cpin, io#LsbPre, t1)         ' read value from DS1620
  else
    io.shiftout(dpin, cpin, io#LsbFirst, val, t1)       ' write value to DS1620
    waitcnt(cnt+clkfreq/100)
  outa[rst]~                                            ' deactivate sensor
  return t2


PUB gettempc | tc
'' Returns temperature in 0.1° C units
'' -- resolution is 0.5° C

  tc := rwreg(RdTmp,0)
  tc := tc << 23 ~> 23                                ' extend sign bit
  tc *= 5                                             ' convert to 10ths
  return tc
       

PUB gettempf 
'' Returns temperature in 0.1° F units
'' -- resolution is 0.9° F

  return gettempc * 9 / 5 + 320                       ' convert to Fahrenheit


PUB setlo(alarm, tmode)
'' Sets low-level alarm
'' -- alarm level is passed in 1° units

    if tmode==TempF
      alarm := ((alarm - 32) * 5 / 9)         ' convert to °C     
    alarm <<= 1                               ' round to 0.5° units
    rwreg(WrLo,alarm)


PUB sethigh(alarm, tmode)
'' Sets high-level alarm
'' -- alarm level is passed in 1° units 

    if tmode==TempF
      alarm := ((alarm - 32) * 5 / 9)         ' convert to °C     
    alarm <<= 1                               ' round to 0.5° units
    rwreg(WrHi,alarm)


DAT
{{
┌─────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                     TERMS OF USE: MIT License                                       │                                                            
├─────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and    │
│associated documentation files (the "Software"), to deal in the Software without restriction,        │
│including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,│
│and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,│
│subject to the following conditions:                                                                 │
│                                                                                                     │                        │
│The above copyright notice and this permission notice shall be included in all copies or substantial │
│portions of the Software.                                                                            │
│                                                                                                     │                        │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT│
│LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  │
│IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER         │
│LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION│
│WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                                      │
└─────────────────────────────────────────────────────────────────────────────────────────────────────┘
}} 