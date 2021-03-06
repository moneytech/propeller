{ Testing   ADC838  Analog to Digit Converter 

              ┌────────┳──────────DIDO
    ┳────────┼────────┼──┳──┐
  Vcc│     CS │    Busy│  SE │    AGND
     │ free DI CLK   DO │ Vref┌───┐
    ┌┴──┴──┴──┴──┴──┴──┴──┴──┴──┴─┐ │
    │20 19 18 17 16 15 14 13 12 11│ │
     ]           ADC838           │ │
    │1  2  3  4  5  6  7  8  9  10│ │
    └┬──┬──┬──┬──┬──┬──┬──┬──┬───┬┘ │
   ch0  1  2  3  4  5  6  7  └───┻──┻─ GND
                            COM  DGND
CS  - latch pin
CLK - clock pin
DIDI- data  pin used to set ch# & read 8-bit ADC value
Busy - optional output indicating ADC is still converting
ch0..7 - analog inputs to be digitized,
         ground unused inputs

}
CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000
   cr=13 'carrage return
   pinTV=12
   
 'assign pins fir ADC383
  CLK=3
  CS=4
  DIDA=1
VAR 
  byte pCS,pCLK,pSER 'assign pins 
  byte addr
OBJ
  tv: "TV_text"
  adc: "J-ADC838"
PUB main |ch ,val ,k
  tv.start(pinTV)  'initialize TV
  tv.str(string("==Test 8-chan ADC838==",cr))

  if adc.init(CS,clk,DIDA)
    tv.str(string("Error in pin assignemnt,STOP",cr)) 
    abort

  k:=0
  repeat  '50
    tv.str(string($A,1,$B,1))
    tv.str(string("readout ="))
    tv.dec(k)
    K++
    ch:=0
    repeat 8
      tv.str(string(cr,"ch"))
      tv.dec(ch)
      val:=adc.read(ch) 'valid channals are 0-7
      tv.str(string(" adc="))
      tv.dec(val)
     ch++   
      waitcnt(1_000_000 + cnt)
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