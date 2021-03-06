
{{    Simple 4D systems OLED-96-G1 driver


File: OLED-96-G1
Version: 1
Author: Harrison Saunders(Aka, Ravenkallen)
Date of publication: 10/16/10
Date of latest revison: 1/23/11


See end of file for terms of use:


General info:

This is a simple/small driver for the OLED-96-G1. This driver does not include support for the SD card functions of the display
and was created to be minimalist. This driver uses the common Parallax serial terminal as it's main comunication system
This OLED is a good choice for many reasons and seems to have a little bit of everything
It can draw boxes, lines, triangles. It can display text and graphics and makes it relatively easy to understand. It is capable
of 65 thousand colors in two bytes or 256 colors in one byte and has a resolution of 96x64 pixels.
It also uses a reliable communication system and has a handy auto-baud feature..
In order to use this display, the user must first declare the "start" method. This will intilize the display and start communication
at the desired baud rate...It is then imperative to declare the "choosecolor" or "customcolor" methods to get the right color.
You should also set the desired font... Depending on your baudrate, you may need to add a small delay between all commands invloving
the OLED. 10 milliseconds works for most commands. Erase commands will take a little more time.


Features(from the datasheet):

0.96” diagonal. Module Size: 32.7 x 23.0 x 4.9mm. Active Display Area: 20mm x 14mm.
No backlighting with near 180° viewing angle.
Easy 5 pin interface to any host device: VCC, TX, RX, GND, RESET
Voltage supply from 3.3V to 6.0V, current @ 40mA nominal when using a 5.0V
   supply source. Note: The module may need to be supplied with a voltage greater than
   4.0 volts when using it with a SD memory card.
Serial RS-232 (0V to 3.3V) with auto-baud feature (300 to 256K baud). If interfacing to
   a system greater than 3.6V supply, a series resistor (100 to 220 Ohms) is required on
   the RX line.
Powered by the 4D-LABS GOLDELOX processor (also available as separate OEM chips
   for volume users).
Optional USB to Serial interface via the 4D micro-USB (μUSB-MB5 or μUSB-CE5)
   modules
Three selectable font sizes (5x7, 8x8 and 8x12) for ASCII characters as well as userdefined
   bitmapped characters (32 @ 8x8)


Setup: Seeing as the Propeller uses(and outputs) 3.3 volts, no special wiring is needed
Simply connect the TX and RX pins to the prop pins of your choice of your choice, hook up power and ground and then pullup the
reset pin and you are all set..


Notes: Check out the datasheet for this device to know more about it.


Update: 1/23/11...
Added erasechar function











}}
con

''-------------------------------------------------------------------
''Constants used for communication...


colormode256 = 8
colormode65K = 16
Adduserchar = "A"
Setbackgroundcolor = "B"
Textbutton = "b"
Drawcircle = "C"
Blockcopypaste = "c"
Displayuserchar = "D"
EraseOLED = "E"
Setfontsize = "F"
Drawtriangle ="G"
Drawpolygon = "g"
Displayimage = "I"
Drawline = "L"
OpaqueTransparenttext = "O"
Putpixel = "P"
Wireframeorfull = "p"
Readpixel = "R"
Drawrectangle = "r"
Stringoftextunformatted = "S"
Stringoftextformatted = "s"
Placecharformatted = "T"
Placecharunformatted = "t"
Controlfunctions = "Y"
Requestdata = "V"


''------------------------------------------------------------------------------
''Colors...

Lightblue2   = %00000_000000_11111
Darkblue2    = %00000_000000_00011
Lightgreen2  = %00000_011111_00000  
Darkgreen2   = %00000_000011_00000
Lightred2    = %11111_000000_00000
Darkred2     = %00010_000000_00000
Darkyellow2  = %00010_000100_00000 
Lightyellow2 = %11111_111110_00000
Darkpurple2  = %00010_000000_00010
Lightpurple2 = %00111_000000_00111
Brightwhite2 = %11111_111111_11111
Orange2      = %10011_001111_00000
Hotpink2     = %11111_000111_01011
Dark2        = %00000_000000_00000



obj
ser: "parallax serial terminal"

var

byte chararray[256], dataarray[8], counter, varstore, fontdata
word color, backcolor



pub start(rxpin, txpin, Baud)'' This method must be called first to start up the serial com port, the auto baud feature and
''Erase the display


Ser.startrxtx(rxpin, txpin, 0, Baud)
waitcnt(clkfreq/3 + cnt)
ser.char("U")
waitcnt(clkfreq/3 + cnt)
ser.char(EraseOLED)
waitcnt(clkfreq/3 + cnt)



Pub erase'' This will just erase the OLED...

ser.char(EraseOLED)
waitcnt(clkfreq/70 + cnt)


 
 



pub bmpchar(charID, Data)'' This method will allow the user to create a custom 8x8 Bitmap that can be displayed later...
''The charID parameter is used for specifying as to which address the new Bitmap is located at(0- 31)
''The method needs 8 bytes of character data to complete the command...

counter := 0
ser.char(Adduserchar)
ser.char(charID)
repeat 8
 varstore := byte[data++]
 ser.char(varstore)

counter := 0




pub backgroundcolor'' This will set the background into a solid color based on the current color in the "color" variable


ser.char(setbackgroundcolor)
ser.char(color.byte[1])
ser.char(color.byte[0])
waitcnt(clkfreq/20 + cnt)
backcolor := color

pub circle(x, y, radius)'' This command will draw a circle based upon the input values. "x" represents the horizontal position and "y"
''represents the vertical. "radius" = the radius size of the circle. The color is represented by the color variable set earlier


ser.char(drawcircle)
ser.char(x)
ser.char(y)
ser.char(radius)
ser.char(color.byte[1])
ser.char(color.byte[0])  




pub displaybmpchar(charID, x, y)''This will display that custom character that you generated earlier. "charID" is
''the ID number of the custom character. "x" and "y" are the position cordinates of the character to be displayed

ser.char(displayuserchar)
ser.char(charID)
ser.char(x)
ser.char(y)
ser.char(color.byte[1])
ser.char(color.byte[0])



pub setfont(font)'' This will set the font size to 5x7, 8x8 or 8x12...0 = 5x7, 1 = 8x8, 2 = 8x12

ser.char(setfontsize)
ser.char(font)
fontdata := font


pub triangle(x1, y1, x2, y2, x3, y3)''This command will draw a triangle based upon the three sets of cordinates...

ser.char(drawtriangle)
ser.char(x1)
ser.char(y1)
ser.char(x2)
ser.char(y2)
ser.char(x3)
ser.char(y3)
ser.char(color.byte[1])
ser.char(color.byte[0])
 
pub image(x, y, h, w, colormode, data)''This command will display a image based upon the
''string of data input in the "data" parameter. This string can be kilobytes long if necessary. "x" and "y" are used to
''tell the display where to start drawing the image(what pixel). "h" and "w" are for the height and width of the image
''The "colormode" parameter is used only if you want to change the pixel data to use only one byte(256 colors compared to 65K)
''instead of the normal two bytes used in most of the other functions(This command is used only if you want to save space)
''Send a decimal "8" to this parameter if you want to revert to 256 colors, otherwise, send a decimal "16" to remain the same
''You will have to use your own color scheme for the data contained in the string
''(you can't ues the predefined colors directly, but you can copy the binary of the color constants and use them as the data) 

ser.char(displayimage)
ser.char(x)
ser.char(y)
ser.char(h)
ser.char(w)
ser.char(colormode)
ser.str(data)



pub line(x1, y1, x2, y2)''This will draw a simple line to the display based upon the parameters
''"x1" and "y1" is the start position and "x2" and "y2" are the end positions

ser.char(drawline)
ser.char(x1)
ser.char(y1)
ser.char(x2)
ser.char(y2)
ser.char(color.byte[1])
ser.char(color.byte[0])




pub opaquetext(data)''This command will change the attribute of the text so that an object
''behind the text can either be blocked or transparent. Changes take place after the
''command is sent. 0 = transparent text, 1 = opaque text

ser.char(opaquetransparenttext)
ser.char(data)




pub pixel(x, y)'' This command will just write a single pixel based upon the "x" and "w" cordinates..

ser.char(putpixel)
ser.char(x)
ser.char(y)
ser.char(color.byte[1])
ser.char(color.byte[0])



pub pensize(size)''This will set the OLED to use either a wire frame or solid filling
''0 = solid, 1 = wire frame


ser.char(wireframeorfull)
ser.char(size)





pub pixelread(x, y)''This will read a pixel and transfer it to the TX pin on the OLED


ser.char(readpixel)
ser.char(x)
ser.char(y)



pub rectangle(x1, y1, x2, y2)'' This command will draw a rectangle. "x1" and "y1" are for the top right corner. "x2" and "y2"
'' are for the lower right corner..


ser.char(drawrectangle)
ser.char(x1)
ser.char(y1)
ser.char(x2)
ser.char(y2)
ser.char(color.byte[1])
ser.char(color.byte[0])



pub placestring(Column, row, data, size)'' This will place a string of text on the display. It will start at the column and row
''specified in the first two parameters..."data" is the parameter used for passing along the array of characters. "size" is
'' the number of bytes of data that are to be sent


ser.char(stringoftextformatted)
ser.char(column)
ser.char(row)
ser.char(fontdata)
ser.char(color.byte[1])
ser.char(color.byte[0])
repeat until size == 0
 varstore := byte[data++]
 ser.char(varstore)
 size--

ser.char(0)

pub char(Chardata, c, r)'' This command will simply place a ASCII character onto the display at the appropriate column and row


ser.char(placecharformatted)
ser.char(chardata)
ser.char(c)
ser.char(r)
ser.char(color.byte[1])
ser.char(color.byte[0])


pub displaycontrol(mode, value)''This command will access the display control functions.
''there are two different commands that can be given. "mode" sets the command, while "value" is the data used by the command
''
''Display on or off...Mode = 1, value = 1(on) or 0(off)
''OLED contrast....Mode = 2, value = 0 - 15(15 being highest setting and 0 being lowest setting)

ser.char(controlfunctions)
ser.char(mode)
ser.char(value)


pub Powerdown''It is recommended by the company(4D systems) to power down the OLED after use, instead of turning off the power
''Damage may occur to the display(I have used it otherwise and have not noticed any problem) over time if not powered down
''in this way

ser.char(controlfunctions)
ser.char(3)
ser.char(0)

pub requestinfo'' This command will access and display the Version and firmware number, the type of display and the resolution

ser.char(requestdata)
ser.char(1)


pub customcolor(colordata)''This is for chosing you own colors. The input must be a 16 bit representation of the color

color := colordata


pub dec(data, r, c)''Simply displays a byte, word or long as a series of ASCII characters representing their number in decimal
''"r" and "c" are the starting column and row


ser.char(stringoftextformatted)
ser.char(r)
ser.char(c)
ser.char(fontdata)
ser.char(color.byte[1])
ser.char(color.byte[0])
ser.dec(data)
ser.char(0)


pub binary(data, digits, r,c)''This is used to display binary data onto the screen. "Digits" is the number of digits in the sequence
''"r" and "c" are the starting column and row

ser.char(stringoftextformatted)
ser.char(r)
ser.char(c)
ser.char(fontdata)
ser.char(color.byte[1])
ser.char(color.byte[0])
ser.bin(data, digits)
ser.char(0)



pub hex(data, digits,r,c)''Simply displays a Hex number on to the screen, "Digits" is the number of digits in the sequence
''"r" and "c" are the starting column and row

ser.char(stringoftextformatted)
ser.char(r)
ser.char(c)
ser.char(fontdata)
ser.char(color.byte[1])
ser.char(color.byte[0])
ser.hex(data, digits)
ser.char(0)




pub erasechar(c, r)'' This command will erase a single character(located by c and r) by converting it back to it's background color. ONLY
''supports the 5x7 and 8x8 font size!! This command will reuse the first custom character ID, so it might be a slower command than fully erasing the screen


if fontdata == 0
 if c > 0
  c := c * 6
 if r > 0
  r := r * 8
 bmpchar(0, @data5)
 


if fontdata == 1
 if c > 0
  c := c * 8
 if r > 0
  r := r * 8
 bmpchar(0, @data8)

waitcnt(clkfreq/100 + cnt)
ser.char(displayuserchar)
ser.char(0)
ser.char(c)
ser.char(r)
ser.char(backcolor.byte[1])
ser.char(backcolor.byte[0]) 
 
pub choosecolor(colorpointer)'' This function will set a common variable(Color) to represent one of the pre-defined colors.
''You can also make your own using the "customcolor" method
''This function accepts a single ASCII character. Use the following chart to determine color
''B = Darkblue, b = Lightblue
''G = Darkgreen, g = Lightgreen
''R = Darkred, r = Lightred
''Y = Darkyellow, y = Lightyellow
''P = Darkpurple, p = Lightpurple
''O = Orange
''W = Brightwhite
''H = HotPink
''D = dark(black)

if colorpointer == "B"
 color := Darkblue2
if colorpointer == "b"
 color := Lightblue2
if colorpointer == "G"
 color := Darkgreen2
if colorpointer == "g"
 color := Lightgreen2
if colorpointer == "R"
 color := Darkred2
if colorpointer == "r"
 color := Lightred2
if colorpointer == "Y"
 color := Darkyellow2
if colorpointer == "y"
 color := Lightyellow2
if colorpointer == "P"
 color := Darkpurple2
if colorpointer == "p"
 color := Lightpurple2
if colorpointer == "O"
 color := Orange2
if colorpointer == "W"
 color := Brightwhite2
if colorpointer == "H"
 color := Hotpink2
if colorpointer == "D"
 color := dark2
 



dat
data8 byte  %11111111  
      byte  %11111111
      byte  %11111111
      byte  %11111111
      byte  %11111111
      byte  %11111111
      byte  %11111111
      byte  %11111111


data5 byte  %11111000
      byte  %11111000
      byte  %11111000
      byte  %11111000
      byte  %11111000
      byte  %11111000
      byte  %11111000
      byte  %11111000

{{

┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                 │                                                            
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation   │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,   │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the        │
│Software is furnished to do so, subject to the following conditions:                                                         │         
│                                                                                                                             │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the         │
│Software.                                                                                                                    │
│                                                                                                                             │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE         │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR        │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,  │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                        │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}          
 
 