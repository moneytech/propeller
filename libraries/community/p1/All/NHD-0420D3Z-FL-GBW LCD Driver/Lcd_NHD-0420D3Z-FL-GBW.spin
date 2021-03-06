''****************************************
''*  v1.0                                *
''*  Author: Hugh Neve                   *
''*  See end of file for terms of use.   *
''****************************************
'' Drives NHD-0420D3Z-FL-GBW display in RS232 mode. See Refr (1) documentation for jumper settings.
'' Connect Prop output pin to Pin 1 of the LCD. The LCD is expecting 5V TTL but 3.3V seems to work.
''
'' Using this object:
'' 1) Reference it in the OBJ section of a spin file.
'' 2) Call "Init" using the pin number of the pin connected to the LCD
'' Refs:
'' Ref [1] = http://www.newhavendisplay.com/specs/NHD-0420D3Z-FL-GBW.pdf  , Rev 3
'' Ref [2] = http://en.wikipedia.org/wiki/ASCII
VAR

  long  lcdLines, started

OBJ
  
  num : "simple_numbers"                                ' number to string conversion
  serial : "simple_serial"                              ' bit-bang serial driver

PUB init(pin, baud): okay

'' Qualifies pin, baud, and lines input
'' -- makes tx pin an output and sets up other values if valid

  started~                                              ' clear started flag
  if lookdown(pin : 0..27)                              ' qualify tx pin 
    if lookdown(baud : 2400, 9600, 19200)               ' qualify baud rate setting
      
        if serial.init(-1, pin, baud)                   ' tx pin only, true mode
          started~~                                     ' mark started flag true

  return started


PUB putc(txbyte)
'Ref [1], Page 6

' Send a byte to the terminal

    serial.tx(txByte)
  
  
PUB str(strAddr)
'Ref[1], Page 6
' Print a zero-terminated string  

repeat strsize(strAddr)                             ' For each character in string, send ASCII code
  serial.tx(byte[strAddr++])
 


PUB dec(value)
' Print a signed decimal number

  serial.str(num.dec(value))  


PUB decf(value, width) 
' Prints signed decimal value in space-padded, fixed-width field

  serial.str(num.decf(value, width))   
  

PUB decx(value, digits) 
' Prints zero-padded, signed-decimal string. If value is negative, field width is digits+1

  serial.str(num.decx(value, digits)) 

PUB hex(value, digits)
' Print a hexadecimal number

  serial.str(num.hex(value, digits))


PUB ihex(value, digits)

' Print an indicated hexadecimal number

  serial.str(num.ihex(value, digits))   



PUB bin(value, digits)

' Print a binary number

  serial.str(num.bin(value, digits))

    

PUB dispOn
'Turns on display.
'Ref[1], page 8

 putc($FE)
 putc($41)

PUB dispOff
'Turns off display
'Ref[1], page 8

 putc($FE)
 putc($42)

PUB home
'Sends the cursor to column 1, line 1.
'Ref[1], page 9

 putc($FE)
 putc($46)

PUB uLineOn
'Turns on underline cursor
'Ref[1], page 9

 putc($FE)
 putc($47)

PUB uLineOff
'Turns off underline cursor
'Ref[1], page 10

 putc($FE)
 putc($48)

PUB left
'Moves cursor left one space
'Ref[1], Page 10

 putc($FE)
 putc($49)

PUB right
'Moves cursor left one space
'Ref[1], Page 10

 putc($FE)
 putc($4A)

PUB blinkOn
'Turns on blinking cursor
'Ref[1], Page 10

 putc($FE)
 putc($4B)

PUB blinkOff
'Turns off blinking cursor
'Ref[1], Page 10

 putc($FE)
 putc($4C)

PUB backspace
'Moves cursor to the left one space and deletes character
'Ref[1], Page 10

 putc($FE)
 putc($4D)
 
PUB cls
'Clears the screen and sets cursor to column1 line 1
'Ref[1], Page 11

 putc($FE)
 putc(51)

PUB showFirmware
'Shows firmware version.
'Ref[1], Page 12 

 putc($FE)
 putc($70)
 
PUB showBaud
'Shows RS2332 baud rate
'Ref[1], Page 12
  putc($FE)
  putc($71)
 
PUB gotoxy(line, col)| oset
  'Moves cursor.
  'Ref[1], page 9

      if lookdown(line : 1..4)                          ' qualify line input
        if lookdown(col : 1..16)                        ' qualify column input

          case line
            1:
             oset := 0
            3:
             oset := 20
            2:
             oset := 64
            4:
             oset := 84
        
          putc($FE)
          putc($45)
          putc(oset + col-1)                     ' move to target position
          
PUB setBright(q)
'Min =1
'Max =8
 if lookdown(q : 1..8)
    putc($FE)
    putc($53)
    putc(q)

PUB setContrast(q)
'Min =1
'Max = 50
 if lookdown(q : 1..50)
   putc($FE)
   putc($52)
   putc(q)

PUB writeLine(line, strAddr)
gotoxy(line, 1)
str(strAddr)
repeat (20-strsize(strAddr))
 putc(32)
 

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