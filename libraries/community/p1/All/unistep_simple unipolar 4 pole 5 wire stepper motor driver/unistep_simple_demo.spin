{{ unistep_simple_demo.spin
┌──────────────────────────────────────────┬─────────────┬───────────────────┬───────────────┐
│ Unipolar 5-wire stepper motor demo v1.0  │ BR          │ (C)2018           │  14 Oct 2018  │
├──────────────────────────────────────────┴─────────────┴───────────────────┴───────────────┤
│                                                                                            │
│ Demo for unistep_simple.spin 5-wire 4-pole unipolar stepper motor driver.                  │
│                                                                                            │
│ Notes:                                                                                     │
│ •This object is set up to drive these cheap $3 Erco ebay steppers (28BYJ48 5V)             │
│    https://forums.parallax.com/discussion/141149/3-stepper-motor-board                     │
│ •Use serial terminal (115200 baud) to control stepper motor                                │
│ •See object file for reference circuit                                                     │
│                                                                                            │
│ See end of file for terms of use.                                                          │
└────────────────────────────────────────────────────────────────────────────────────────────┘
}}
CON
_clkmode      = xtal1 + pll16x                        
_xinfreq      = 5_000_000

stepperpin = 0   'hook up propeller pins 0-3
#0, full,half,wave

obj
pst: "parallax serial terminal"
stp: "unistep_simple"


pub go|cmd 

  pst.start (115200)
  waitcnt(clkfreq*5+cnt)
  
  stp.init(stepperpin, full, 200)

repeat
  pst.clear
  pst.str(string("Type in: #steps (use negative number for reverse), or 0 to set mode/speed",13))
  cmd := pst.decin
  if cmd == 0
    stp.coast
    pst.str(string("mode?, 0=full, 1=half, 2=wave steps",13))
    cmd := pst.decin
    stp.setmode(cmd)
    pst.str(string("speed?",13))
    cmd := pst.decin
    stp.setspeed(cmd)
  else
    stp.unistep(cmd)

'  waitcnt(clkfreq+cnt)
'  stp.unistep(-4096)
'  waitcnt(clkfreq+cnt)

'  setMode(1)
'  unistep(4096)
'  waitcnt(clkfreq+cnt)
'  unistep(-4096)
'  waitcnt(clkfreq+cnt)

'  stp.setMode(2)
'  stp.unistep(4096)
'  waitcnt(clkfreq+cnt)
'  stp.unistep(-4096)
'  waitcnt(clkfreq+cnt)

'  stp.SetSpeed(500)

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