{{ CD_ADC0834.spin }}
{
*************************************************
    ADC0834 Interface Object
*************************************************
    Charlie Dixon  2007 
*************************************************
Parts of this program were adapted from programs
from other users.  Why reinvent the wheel?  :^)
*************************************************

  start(pin)                   : to be called first, pin = first pin, 4 pins are needed  
  AD0, AD1, AD2, AD3           : four ADC channels  
  ReadConv()                   : get 8 bits of data

Test connections to Propeller Demo Board with "start(pin)" = 0

      Vcc(+5V)                     Vcc(+5V)
      │         ADC0834            │
  ┌───┫      ┌─────────────────┐   │
  │   │  nc ─┤1 V+      Vcc  14├───┫                Vcc      = 5V
  │   │  P3 ─┤2 !cs     Din  13├───┼───┐            MAX ADx  = 5V
  │   │   ┌──┤3 AD0     sclk 12├───┼───┼───── P0    fclk     = 10kHz ~ 400kHz 
  │   ┣───┼──┤4 AD1     SARS 11├───┼───┼─── P1    sclk     = pin
  │   ──┼──┤5 AD2     Dout 10├───┼───┻─── P2    sars     = pin+1
  ──┼───┼──┤6 AD3     Vref  9├───┘                Din/Dout = pin+2  (Dout is tri-state)
  │   │   ┣──┤7 DGnc    AGND  8├───┐                !cs      = pin+3
  └───╋───┘  └─────────────────┘   │
      │                            │                Pots are 10K and resisters are 1K
      Vss                          Vss              as per 5V to 3.3V interface thread.

Notes:
1. I could only get a max value of 0111 1111 from the test setup.
   I think I am somehow missing the LSB with the MSB always being 0.
   I tried several sclk arrangements in write() but I always got
   the same result.  Maybe someone can help figure this out.

2. I also tried to set this up as a cog with the following code.
   The program would return the Cog/Success value, but it never
   started polling the ADC "ADxr := convert(0)".  Stack, Cog and
   the ADxr variables were defined of course.
________________________________________________________________________________
PUB Start(pin_): Success
  pin := pin_
  Stop
  Success := (Cog := cognew(init(pin, pin+1, pin+2, pin+3), @Stack) +1)
________________________________________________________________________________
PUB Stop
  if Cog
    cogstop(Cog~ - 1)
________________________________________________________________________________
PUB Active: YesNo
  YesNo := Cog > 0
________________________________________________________________________________
PRI init( sclk_, sars_, dataio_, cs_ )

  sclk    := sclk_
  sars    := sars_
  dataio  := dataio_
  cs      := cs_

  dira[sars] := 0                   ' set sars pin to input
  dira[cs]   := 1                   ' set Chip Select to output
  outa[cs]   := 1                   ' set Chip Select High
  dira[sclk] := 1                   ' set sclk to output
  outa[sclk] := 0                   ' Set Sclk to Low

  repeat
    AD0r := convert(0)
    AD1r := convert(1)
    AD2r := convert(2)
    AD3r := convert(3)          
________________________________________________________________________________

3. This is my first .spin program after going through the training
   in the manual and studying several user spin objects.  Any
   comments will be appretiated.

4. This program could easily be adapted for the ADC0831, ADC0832 and ADC0838
   The are only slight differences such as MUX Addressing, MSB sent first and
   timing that need to be adjusted.       
}
CON

' data for Din to start conversion for each ADx channel

  AD0 = %0011          ' Note: Shift LSB first so bits are reversed from Datasheet
  AD1 = %0111          ' Note: See Datasheet MUX Addressing for more details
  AD2 = %1011          ' Bit 0 = Start Bit, Bit 1 = SGL/DIF, Bit 3 = ODD/SIGN, Bit 4 = SELECT
  AD3 = %1111
  
VAR

  byte ADC             ' Analog to Digital Channel Din Value.  Set using CON values.
  word pin             ' Try this LOL
  word sclk            ' Serial Clock Pin - output
  word dataio          ' Din, Dout Pins - input/output.  High impedance protects Dout pin while writing Din
  word cs              ' Chip Enable Pin - output
  word sars            ' Conversion Status Pin - input
  long datar           ' 8 Bit return value from conversion

PUB start( pin_ )

  pin := pin_
  init(pin, pin+1, pin+2, pin+3)
  
PUB GetADC( chan ) : adcr | ADC_Val

  if (chan == 0)
    ADC_Val := convert(0)
  if (chan == 1)
    ADC_Val := convert(1)
  if (chan == 2)
    ADC_Val := convert(2)
  if (chan == 3)
    ADC_Val := convert(3)  

  return ADC_Val

PRI init( sclk_, sars_, dataio_, cs_ )

  sclk    := sclk_
  sars    := sars_
  dataio  := dataio_
  cs      := cs_

  dira[sars] := 0                   ' set sars pin to input
  dira[cs]   := 1                   ' set Chip Select to output
  outa[cs]   := 1                   ' set Chip Select High
  dira[sclk] := 1                   ' set sclk to output
  outa[sclk] := 0                   ' Set Sclk to Low

PRI convert( ad_chan ) : datar_val

  if (ad_chan == 0)
    ADC := AD0
  if (ad_chan == 1)
    ADC := AD1
  if (ad_chan == 2)
    ADC := AD2
  if (ad_chan == 3)
    ADC := AD3

  dira[dataio] := 1                ' Set Din/Dout to output
  outa[dataio] := 0                ' Set Din (output) Low
  
  datar := write(ADC)              ' write MUX Address to start conversion for SDC channel (delay needed???)
  return datar

PRI write( cmd ) : datar_val | i  

  outa[cs] := 0                 ' set Chip Select Low          
  writeByte( cmd )              ' Write the command to start conversion for X port
  dira[dataio] := 0             ' set data pin to input

  repeat while (ina[sars] == 1) ' SARS goes LOW when sending LSB First Dout on ADC0834 (See Datasheet)
    outa[sclk] := 1             ' toggle sclk pin High (add delay here if clock is too fast) (clue: check duty cycle)
    outa[sclk] := 0             ' toggle sclk pin Low
 
' Ok now get the Conversion for this channel  
  repeat i from 0 to 7          ' read 8 bits
    if ina[dataio] == 1         
      datar |= |< i             ' set bit i HIGH
    else
      datar &= !|< i            ' set bit i LOW
    outa[sclk] := 1             ' toggle sclk pin High
    outa[sclk] := 0             ' toggle sclk pin Low
    

  outa[cs] := 1                 ' set Chip Select High
            
  return datar

PRI writeByte( cmd ) | i  

  repeat i from 0 to 3          ' ADC0834 has 1 start bit and 3 data bits    
    outa[dataio] := cmd         ' send LSB bit
    cmd >>= 1                   ' shift to next bit
    outa[sclk] := 1             ' toggle sclk pin High (add delay here if clock is too fast) (clue: check duty cycle)
    outa[sclk] := 0             ' toggle sclk pin Low

' Use something like this if the clock seems to be too fast or duty cycle is not within specs
{
PRI delay_us( period )
  clkcycles := ( clkcycles_us * period ) #> 381
  waitcnt(clkcycles + cnt)                                   ' Wait for designated time
}

DAT
     {<end of object code>}
     
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