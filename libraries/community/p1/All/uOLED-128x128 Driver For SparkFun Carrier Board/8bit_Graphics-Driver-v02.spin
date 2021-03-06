''**************************************
''
''  8-Bit graphics driver
''
''  Mark Swann
''  from code originally authored by
''  Timothy D. Swieter, E.I.
''  www.brilldea.com
''
''Description:
''      This program is an 8-bit graphics driver. 
''
''
'**************************************
CON               'Constants to be located here
'***************************************
  
  BYTES_PER_PIXEL = 1
  
  cmdClear      = 1
  cmdPlotPixel  = 2
  cmdPlotLine   = 3
  cmdPlotCircle = 4
  cmdFillCircle = 5
  cmdPlotChar   = 6
  cmdSetFont    = 7
  cmdSetColor   = 8
  cmdSetFillColor = 9
  cmdPlotHorizLine = 10
  cmdPlotVertLine = 11
  cmdPlotText   = 12
  cmdPlotSprite = 13
  cmdSelFrontBfr= 14
  cmdSelBackBfr = 15
  cmdendFrame   = 16
  cmdLast       = 17

'**************************************
VAR               'Variables to be located here
'**************************************

  'Processor
  long  GRAPHICS_cog            'Cog flag/ID

  'Graphics routine
  long  command, parm1, parm2, parm3, parm4

OBJ               'Object declaration to be located here
'**************************************

' none
  
'**************************************
PRI start(_FramePtrA, _FramePtrB, _width, _height, _currFrameOut) : okay
'**************************************
'' Start the ASM display driver for the graphics display
'' returns cog ID (1-8) if good or 0 if no good

  Parm1Addr := @parm1
  Parm2Addr := @parm2
  Parm3Addr := @parm3
  Parm4Addr := @parm4

  CurrFrameOutAddr := _currFrameOut
  BitmapLongs := (BYTES_PER_PIXEL*_width*_height)/4

  BmpBaseAddrA    := _FramePtrA
  BmpBaseAddrB    := _FramePtrB

  BmpBaseAddr     := BmpBaseAddrA
  BmpBaseTopAddr  := (BYTES_PER_PIXEL*_width*_height)

  Font8x8Addr := @font_8x8
  Font8x12Addr := @font_8x12
  Font5x7Addr := @font_5x7
  ScrWidth := BYTES_PER_PIXEL*_width ' physical width in bytes
  ScrHeight := _height
  MaxX := _width - 1
  PhysMaxX := BYTES_PER_PIXEL*(_width-1)
  MaxY := _height - 1

  command := 1

  'Start a cog with assembly routine
  okay:= GRAPHICS_cog:= cognew(@entry, @command) + 1    'Returns 0-8 depending on success/failure

  repeat while command

'**************************************
PUB stop
'**************************************
'' Stops ASM graphics driver - frees a cog

  if GRAPHICS_cog                                       'Is cog non-zero?  
    cogstop(GRAPHICS_cog~ - 1)                          'Stop the cog and then make value of flag zero


'**************************************
PUB setup(_FramePtrA, _FramePtrB, _width, _height, _currFrameOut)
'**************************************
'' Setup the bitmap parameters for the graphics driver, must be run
''
''  _baseptr   - base address of bitmap

  stop

  start(_FramePtrA, _FramePtrB, _width, _height, _currFrameOut)


'**************************************
PUB selectFrontSurface
'**************************************

  repeat while command

  command := cmdSelFrontBfr

'**************************************
PUB selectBackSurface
'**************************************

  repeat while command

  command := cmdSelBackBfr

'**************************************
PUB endFrame
'**************************************

  repeat while command

  command := cmdEndFrame

'**************************************
'PUB fill(_color)
'**************************************
'' Clear bitmap (write zeros to all pixels)

'  _color |= _color << 8
'  _color |= _color << 16

'  repeat while command

'  longfill(CurrFrame, _color, BitmapLongs)                  'Fill the bitmap with zeros

  
'**************************************
PUB busyWait
'**************************************

  repeat while command

'**************************************
PUB frameWait
'**************************************

  repeat while long[CurrFrameOutAddr]

'**************************************
PUB clear
'**************************************
'' Plot at pixel at x, y, with the appropriate 8-bit color
''
''  _x         - coordinate of the pixel
''  _y         - coordinate of the pixel

  repeat while command

  command := cmdClear

'**************************************
PUB plotPixel(_x0, _y0)
'**************************************
'' Plot at pixel at x, y, with the appropriate 8-bit color
''
''  _x         - coordinate of the pixel
''  _y         - coordinate of the pixel

  repeat while command

  parm1 := _x0
  parm2 := _y0

  command := cmdPlotPixel

'**************************************
PUB plotPixelC(_x0, _y0, _color)
'**************************************
'' Plot at pixel at x, y, with the appropriate 8-bit color
''
''  _x         - coordinate of the pixel
''  _y         - coordinate of the pixel
''  _color     - 8-bit color value (RRRGGGBB)

  SetColor(_color)

  repeat while command

  parm1 := _x0
  parm2 := _y0

  command := cmdPlotPixel

'**************************************
PUB plotLine(_x0, _y0, _x1, _y1)
'**************************************
'' Plot a line from _x0,_y0 to _x1,_y1 with the appropriate 8-bit color
''
''  _x0, _y0   - coordinate of the start pixel
''  _x1, _y1   - coordinate of the end pixel
''

  repeat while command

  parm1 := _x0
  parm2 := _y0
  parm3 := _x1
  parm4 := _y1

  command := cmdPlotLine

'**************************************
PUB plotHorizLine(_x0, _x1, _y0)
'**************************************
'' Plot a line from _x0,_y0 to _x1,_y1 with the appropriate 8-bit color
''
''  _x0, _y0   - coordinate of the start pixel
''  _x1, _y0   - coordinate of the end pixel
''

  repeat while command

  parm1 := _x0
  parm2 := _y0
  parm3 := _x1

  command := cmdPlotHorizLine

'**************************************
PUB plotVertLine(_x0, _y0, _y1)
'**************************************
'' Plot a line from _x0,_y0 to _x1,_y1 with the appropriate 8-bit color
''
''  _x0, _y0   - coordinate of the start pixel
''  _x0, _y1   - coordinate of the end pixel
''

  repeat while command

  parm1 := _x0
  parm2 := _y0
  parm4 := _y1

  command := cmdplotVertLine

'**************************************
PUB plotLineC(_x0, _y0, _x1, _y1, _color)
'**************************************
'' Plot a line from _x0,_y0 to _x1,_y1 with the appropriate 8-bit color
''
''  _x0, _y0   - coordinate of the start pixel
''  _x1, _y1   - coordinate of the end pixel
''  _color     - 8-bit color value (RRRGGGBB)
''

  SetColor(_color)

  repeat while command

  parm1 := _x0
  parm2 := _y0
  parm3 := _x1
  parm4 := _y1

  command := cmdPlotLine

'**************************************
PUB SetColor(_color)
'**************************************
      
  repeat while command

  parm1 := _color

  command := cmdSetColor

'**************************************
PUB SetFillColor(_color)
'**************************************
      
  repeat while command

  parm1 := _color

  command := cmdSetFillColor

'**************************************
PUB SetFont(_font)
'**************************************
      
  repeat while command

  parm1 := _font

  command := cmdSetFont

'**************************************
PUB MoveTo(_x, _y)
'**************************************
      
  repeat while command

  parm1 := _x
  parm2 := _y

'**************************************
PUB LineTo(_x, _y)
'**************************************
'' Plot a line from curent location _x,_y with the appropriate 8-bit color
''
''  _x, _y   - coordinate of the end pixel
''

  repeat while command

  parm3 := _x
  parm4 := _y

  command := cmdPlotLine


'**************************************
PUB plotCircle(_x0, _y0, _radius)
'**************************************
'' Plot a circle with center _x0,_y0 and radius _radius with the appropriate 8-bit color
''
''  _x0, _y0   - coordinate of the center of the circle
''  _radius    - radius, in pixels, of the circle
''
''  Based on routines from Paul Sr. on Parallax Forum

  repeat while command

  parm1 := _x0
  parm2 := _y0
  parm3 := _radius

  command := cmdPlotCircle
    
'**************************************
PUB fillCircle(_x0, _y0, _radius)
'**************************************
'' Plot a circle with center _x0,_y0 and radius _radius with the appropriate 8-bit color
''
''  _x0, _y0   - coordinate of the center of the circle
''  _radius    - radius, in pixels, of the circle
''
''  Based on routines from Paul Sr. on Parallax Forum

  repeat while command

  parm1 := _x0
  parm2 := _y0
  parm3 := _radius

  command := cmdFillCircle
    
'**************************************
PUB plotCircleC(_x0, _y0, _radius, _color)
'**************************************
'' Plot a circle with center _x0,_y0 and radius _radius with the appropriate 8-bit color
''
''  _x0, _y0   - coordinate of the center of the circle
''  _radius    - radius, in pixels, of the circle
''  _color     - 8-bit color value (RRRGGGBB)
''
''  Based on routines from Paul Sr. on Parallax Forum

  SetColor(_color)

  repeat while command

  parm1 := _x0
  parm2 := _y0
  parm3 := _radius

  command := cmdPlotCircle
    
'**************************************
PUB plotSprite(_x0, _y0, _spritePTR)
'**************************************
'' Plot a pixel sprite into the video memory.
''
''  _x0, _y0   - coordinate of the center of the sprite
''  _spritePTR - pointer to pixel sprite memory location
''    
''  long
''  byte xpixels, ypixels, xorigin, yorigin
''  long %RRRGGGBB, %RRRGGGBB, %RRRGGGBB, %RRRGGGBB
''  long %RRRGGGBB, %RRRGGGBB, %RRRGGGBB, %RRRGGGBB
''  long %RRRGGGBB, %RRRGGGBB, %RRRGGGBB, %RRRGGGBB
''  long %RRRGGGBB, %RRRGGGBB, %RRRGGGBB, %RRRGGGBB
''  .... 

  repeat while command

  parm1 := _x0
  parm2 := _y0
  parm3 := _spritePTR

  command := cmdPlotSprite

'**************************************
PUB plotChar(_char, _xC, _yC) | row, col
'**************************************
'' Plot a single character into the video memory.
''
''  _char      - The character
''  _xC        - Text column (0-11 for 8x8 font, 0-15 for 5x7 font)
''  _yC        - Text row (0-7 for 8x8 and 5x7 font)
''
''  Based on routines from 4D System uOLED driver    

  repeat while command
               
  parm1 := _xC
  parm2 := _yC
  parm3 := _char

  command := cmdPlotChar

'**************************************
PUB plotCharC(_char, _xC, _yC, _color) | row, col
'**************************************
'' Plot a single character into the video memory.
''
''  _char      - The character
''  _xC        - Text column (0-11 for 8x8 font, 0-15 for 5x7 font)
''  _yC        - Text row (0-7 for 8x8 and 5x7 font)
''  _color     - 8-bit color value (RRRGGGBB)
''
''  Based on routines from 4D System uOLED driver    

  SetColor(_color)

  repeat while command
               
  parm1 := _xC
  parm2 := _yC
  parm3 := _char

  command := cmdPlotChar


PUB plotText(_xC, _yC, _font, _color, _str) | t, x, y
'' Plot a string of characters into the video memory.
''
''  _xC        - Text column (0-11 for 8x8 font, 0-15 for 5x7 font)
''  _yC        - Text row (0-7 for 8x8 and 5x7 font)
''  _font      - The font, if 1 then 8x8, else 5x7
''  _color     - 8-bit color value (RRRGGGBB)
''  _str       - String of characters
''
''  Based on routines from 4D System uOLED driver

  SetFont(_font)
  SetColor(_color)

  repeat while command

  parm1 := _xC
  parm2 := _yC
  parm3 := _str
               
  command := cmdPlotText

'**************************************
DAT
'**************************************

font_8x8      byte %00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000
              byte %00001100,%00001100,%00001100,%00001100,%00001100,%00000000,%00001100,%00000000
              byte %00110110,%00110110,%00110110,%00000000,%00000000,%00000000,%00000000,%00000000
              byte %00110110,%00110110,%01111111,%00110110,%01111111,%00110110,%00110110,%00000000
              byte %00001100,%00111110,%00000011,%00011110,%00110000,%00011111,%00001100,%00000000
              byte %00000000,%01100011,%00110011,%00011000,%00001100,%01100110,%01100011,%00000000
              byte %00011100,%00110110,%00011100,%01101110,%00111011,%00110011,%01101110,%00000000
              byte %00000110,%00000110,%00000011,%00000000,%00000000,%00000000,%00000000,%00000000
              byte %00011000,%00001100,%00000110,%00000110,%00000110,%00001100,%00011000,%00000000
              byte %00000110,%00001100,%00011000,%00011000,%00011000,%00001100,%00000110,%00000000
              byte %00000000,%01100110,%00111100,%11111111,%00111100,%01100110,%00000000,%00000000
              byte %00000000,%00001100,%00001100,%00111111,%00001100,%00001100,%00000000,%00000000
              byte %00000000,%00000000,%00000000,%00000000,%00000000,%00001100,%00001100,%00000110
              byte %00000000,%00000000,%00000000,%00111111,%00000000,%00000000,%00000000,%00000000
              byte %00000000,%00000000,%00000000,%00000000,%00000000,%00001100,%00001100,%00000000
              byte %00100000,%00110000,%00011000,%00001100,%00000110,%00000011,%00000001,%00000000
              byte %00111110,%01100011,%01110011,%01111011,%01101111,%01100111,%00111110,%00000000
              byte %00001100,%00001110,%00001100,%00001100,%00001100,%00001100,%00111111,%00000000
              byte %00011110,%00110011,%00110000,%00011100,%00000110,%00110011,%00111111,%00000000
              byte %00011110,%00110011,%00110000,%00011100,%00110000,%00110011,%00011110,%00000000
              byte %00111000,%00111100,%00110110,%00110011,%01111111,%00110000,%01111000,%00000000
              byte %00111111,%00000011,%00011111,%00110000,%00110000,%00110011,%00011110,%00000000
              byte %00011100,%00000110,%00000011,%00011111,%00110011,%00110011,%00011110,%00000000
              byte %00111111,%00110011,%00110000,%00011000,%00001100,%00001100,%00001100,%00000000
              byte %00011110,%00110011,%00110011,%00011110,%00110011,%00110011,%00011110,%00000000
              byte %00011110,%00110011,%00110011,%00111110,%00110000,%00011000,%00001110,%00000000
              byte %00000000,%00001100,%00001100,%00000000,%00000000,%00001100,%00001100,%00000000
              byte %00000000,%00001100,%00001100,%00000000,%00000000,%00001100,%00001100,%00000110
              byte %00011000,%00001100,%00000110,%00000011,%00000110,%00001100,%00011000,%00000000
              byte %00000000,%00000000,%00111111,%00000000,%00000000,%00111111,%00000000,%00000000
              byte %00000110,%00001100,%00011000,%00110000,%00011000,%00001100,%00000110,%00000000
              byte %00011110,%00110011,%00110000,%00011000,%00001100,%00000000,%00001100,%00000000
              byte %00111110,%01100011,%01111011,%01111011,%01111011,%00000011,%00011110,%00000000
              byte %00001100,%00011110,%00110011,%00110011,%00111111,%00110011,%00110011,%00000000
              byte %00111111,%01100110,%01100110,%00111110,%01100110,%01100110,%00111111,%00000000
              byte %00111100,%01100110,%00000011,%00000011,%00000011,%01100110,%00111100,%00000000
              byte %00011111,%00110110,%01100110,%01100110,%01100110,%00110110,%00011111,%00000000
              byte %01111110,%00000110,%00000110,%00011110,%00000110,%00000110,%01111110,%00000000
              byte %01111110,%00000110,%00000110,%00011110,%00000110,%00000110,%00000110,%00000000
              byte %00111100,%01100110,%00000011,%00000011,%01110011,%01100110,%01111100,%00000000
              byte %00110011,%00110011,%00110011,%00111111,%00110011,%00110011,%00110011,%00000000
              byte %00011110,%00001100,%00001100,%00001100,%00001100,%00001100,%00011110,%00000000
              byte %01111000,%00110000,%00110000,%00110000,%00110011,%00110011,%00011110,%00000000
              byte %01100111,%01100110,%00110110,%00011110,%00110110,%01100110,%01100111,%00000000
              byte %00000110,%00000110,%00000110,%00000110,%00000110,%00000110,%01111110,%00000000
              byte %01100011,%01110111,%01111111,%01111111,%01101011,%01100011,%01100011,%00000000
              byte %01100011,%01100111,%01101111,%01111011,%01110011,%01100011,%01100011,%00000000
              byte %00011100,%00110110,%01100011,%01100011,%01100011,%00110110,%00011100,%00000000
              byte %00111111,%01100110,%01100110,%00111110,%00000110,%00000110,%00001111,%00000000
              byte %00011110,%00110011,%00110011,%00110011,%00111011,%00011110,%00111000,%00000000
              byte %00111111,%01100110,%01100110,%00111110,%00110110,%01100110,%01100111,%00000000
              byte %00011110,%00110011,%00000111,%00011110,%00111000,%00110011,%00011110,%00000000
              byte %00111111,%00001100,%00001100,%00001100,%00001100,%00001100,%00001100,%00000000
              byte %00110011,%00110011,%00110011,%00110011,%00110011,%00110011,%00111111,%00000000
              byte %00110011,%00110011,%00110011,%00110011,%00110011,%00011110,%00001100,%00000000
              byte %01100011,%01100011,%01100011,%01101011,%01111111,%01110111,%01100011,%00000000
              byte %01100011,%01100011,%00110110,%00011100,%00011100,%00110110,%01100011,%00000000
              byte %00110011,%00110011,%00110011,%00011110,%00001100,%00001100,%00011110,%00000000
              byte %01111111,%01100000,%00110000,%00011000,%00001100,%00000110,%01111111,%00000000
              byte %00011110,%00000110,%00000110,%00000110,%00000110,%00000110,%00011110,%00000000
              byte %00000011,%00000110,%00001100,%00011000,%00110000,%01100000,%01000000,%00000000
              byte %00011110,%00011000,%00011000,%00011000,%00011000,%00011000,%00011110,%00000000
              byte %00001000,%00011100,%00110110,%01100011,%00000000,%00000000,%00000000,%00000000
              byte %00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%11111111
              byte %00001100,%00001100,%00011000,%00000000,%00000000,%00000000,%00000000,%00000000
              byte %00000000,%00000000,%00011110,%00110000,%00111110,%00110011,%01101110,%00000000
              byte %00000111,%00000110,%00000110,%00111110,%01100110,%01100110,%00111011,%00000000
              byte %00000000,%00000000,%00011110,%00110011,%00000011,%00110011,%00011110,%00000000
              byte %00111000,%00110000,%00110000,%00111110,%00110011,%00110011,%01101110,%00000000
              byte %00000000,%00000000,%00011110,%00110011,%00111111,%00000011,%00011110,%00000000
              byte %00011100,%00110110,%00000110,%00001111,%00000110,%00000110,%00001111,%00000000
              byte %00000000,%00000000,%01101110,%00110011,%00110011,%00111110,%00110000,%00011111
              byte %00000111,%00000110,%00110110,%01101110,%01100110,%01100110,%01100111,%00000000
              byte %00001100,%00000000,%00001110,%00001100,%00001100,%00001100,%00011110,%00000000
              byte %00110000,%00000000,%00110000,%00110000,%00110000,%00110011,%00110011,%00011110
              byte %00000111,%00000110,%01100110,%00110110,%00011110,%00110110,%01100111,%00000000
              byte %00001110,%00001100,%00001100,%00001100,%00001100,%00001100,%00011110,%00000000
              byte %00000000,%00000000,%00110011,%01111111,%01111111,%01101011,%01100011,%00000000
              byte %00000000,%00000000,%00011111,%00110011,%00110011,%00110011,%00110011,%00000000
              byte %00000000,%00000000,%00011110,%00110011,%00110011,%00110011,%00011110,%00000000
              byte %00000000,%00000000,%00111011,%01100110,%01100110,%00111110,%00000110,%00001111
              byte %00000000,%00000000,%01101110,%00110011,%00110011,%00111110,%00110000,%01111000
              byte %00000000,%00000000,%00111011,%01101110,%01100110,%00000110,%00001111,%00000000
              byte %00000000,%00000000,%00111110,%00000011,%00011110,%00110000,%00011111,%00000000
              byte %00001000,%00001100,%00111110,%00001100,%00001100,%00101100,%00011000,%00000000
              byte %00000000,%00000000,%00110011,%00110011,%00110011,%00110011,%01101110,%00000000
              byte %00000000,%00000000,%00110011,%00110011,%00110011,%00011110,%00001100,%00000000
              byte %00000000,%00000000,%01100011,%01101011,%01111111,%01111111,%00110110,%00000000
              byte %00000000,%00000000,%01100011,%00110110,%00011100,%00110110,%01100011,%00000000
              byte %00000000,%00000000,%00110011,%00110011,%00110011,%00111110,%00110000,%00011111
              byte %00000000,%00000000,%00111111,%00011001,%00001100,%00100110,%00111111,%00000000
              byte %00111000,%00001100,%00001100,%00000111,%00001100,%00001100,%00111000,%00000000
              byte %00011000,%00011000,%00011000,%00000000,%00011000,%00011000,%00011000,%00000000
              byte %00000111,%00001100,%00001100,%00111000,%00001100,%00001100,%00000111,%00000000
              byte %01101110,%00111011,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000
              byte %00000000,%01100110,%01100110,%01100110,%01100110,%01100110,%00111010,%00000001

font_5x7      byte $00,$00,$00,$00,$00,$00,$00,$00  ' space
              byte $02,$02,$02,$02,$02,$00,$02,$00  '  "!"
              byte $36,$12,$24,$00,$00,$00,$00,$00  '  """
              byte $00,$14,$3E,$14,$3E,$14,$00,$00  '  "#"
              byte $08,$3C,$0A,$1C,$28,$1E,$08,$00  '  "$"
              byte $22,$22,$10,$08,$04,$22,$22,$00  '  "%"
              byte $04,$0A,$0A,$04,$2A,$12,$2C,$00  '  "&"
              byte $18,$10,$08,$00,$00,$00,$00,$00  '  "'"
              byte $20,$10,$08,$08,$08,$10,$20,$00  '  "("
              byte $02,$04,$08,$08,$08,$04,$02,$00  '  ")"
              byte $00,$08,$2A,$1C,$1C,$2A,$08,$00  '  "*"
              byte $00,$08,$08,$3E,$08,$08,$00,$00  '  "+"
              byte $00,$00,$00,$00,$00,$06,$04,$02  '  ","
              byte $00,$00,$00,$3E,$00,$00,$00,$00  '  "-"
              byte $00,$00,$00,$00,$00,$06,$06,$00  '  "."
              byte $20,$20,$10,$08,$04,$02,$02,$00  '  "/"
              byte $1C,$22,$32,$2A,$26,$22,$1C,$00  '  "0"
              byte $08,$0C,$08,$08,$08,$08,$1C,$00  '  "1"
              byte $1C,$22,$20,$10,$0C,$02,$3E,$00  '  "2"
              byte $1C,$22,$20,$1C,$20,$22,$1C,$00  '  "3"
              byte $10,$18,$14,$12,$3E,$10,$10,$00  '  "4"
              byte $3E,$02,$1E,$20,$20,$22,$1C,$00  '  "5"
              byte $18,$04,$02,$1E,$22,$22,$1C,$00  '  "6"
              byte $3E,$20,$10,$08,$04,$04,$04,$00  '  "7"
              byte $1C,$22,$22,$1C,$22,$22,$1C,$00  '  "8"
              byte $1C,$22,$22,$3C,$20,$10,$0C,$00  '  "9"
              byte $00,$06,$06,$00,$06,$06,$00,$00  '  ":"
              byte $00,$06,$06,$00,$06,$06,$04,$02  '  ";"
              byte $20,$10,$08,$04,$08,$10,$20,$00  '  "<"
              byte $00,$00,$3E,$00,$3E,$00,$00,$00  '  "="
              byte $02,$04,$08,$10,$08,$04,$02,$00  '  ">"
              byte $1C,$22,$20,$10,$08,$00,$08,$00  '  "?"
              byte $1C,$22,$2A,$2A,$1A,$02,$3C,$00  '  "@"
              byte $08,$14,$22,$22,$3E,$22,$22,$00  '  "A"
              byte $1E,$22,$22,$1E,$22,$22,$1E,$00  '  "B"
              byte $18,$24,$02,$02,$02,$24,$18,$00  '  "C"
              byte $0E,$12,$22,$22,$22,$12,$0E,$00  '  "D"
              byte $3E,$02,$02,$1E,$02,$02,$3E,$00  '  "E"
              byte $3E,$02,$02,$1E,$02,$02,$02,$00  '  "F"
              byte $1C,$22,$02,$02,$32,$22,$1C,$00  '  "G"
              byte $22,$22,$22,$3E,$22,$22,$22,$00  '  "H"
              byte $3E,$08,$08,$08,$08,$08,$3E,$00  '  "I"
              byte $20,$20,$20,$20,$20,$22,$1C,$00  '  "J"
              byte $22,$12,$0A,$06,$0A,$12,$22,$00  '  "K"
              byte $02,$02,$02,$02,$02,$02,$3E,$00  '  "L"
              byte $22,$36,$2A,$2A,$22,$22,$22,$00  '  "M"
              byte $22,$22,$26,$2A,$32,$22,$22,$00  '  "N"
              byte $1C,$22,$22,$22,$22,$22,$1C,$00  '  "O"
              byte $1E,$22,$22,$1E,$02,$02,$02,$00  '  "P"
              byte $1C,$22,$22,$22,$2A,$12,$2C,$00  '  "Q"
              byte $1E,$22,$22,$1E,$0A,$12,$22,$00  '  "R"
              byte $1C,$22,$02,$1C,$20,$22,$1C,$00  '  "S"
              byte $3E,$08,$08,$08,$08,$08,$08,$00  '  "T"
              byte $22,$22,$22,$22,$22,$22,$1C,$00  '  "U"
              byte $22,$22,$22,$14,$14,$08,$08,$00  '  "V"
              byte $22,$22,$22,$2A,$2A,$2A,$14,$00  '  "W"
              byte $22,$22,$14,$08,$14,$22,$22,$00  '  "X"
              byte $22,$22,$14,$08,$08,$08,$08,$00  '  "Y"
              byte $3E,$20,$10,$08,$04,$02,$3E,$00  '  "Z"
              byte $3E,$06,$06,$06,$06,$06,$3E,$00  '  "["
              byte $02,$02,$04,$08,$10,$20,$20,$00  '  "\"
              byte $3E,$30,$30,$30,$30,$30,$3E,$00  '  "]"
              byte $00,$00,$08,$14,$22,$00,$00,$00  '  "^"
              byte $00,$00,$00,$00,$00,$00,$00,$7F  '  "_"
              byte $10,$08,$18,$00,$00,$00,$00,$00  '  "`"
              byte $00,$00,$1C,$20,$3C,$22,$3C,$00  '  "a"
              byte $02,$02,$1E,$22,$22,$22,$1E,$00  '  "b"
              byte $00,$00,$3C,$02,$02,$02,$3C,$00  '  "c"
              byte $20,$20,$3C,$22,$22,$22,$3C,$00  '  "d"
              byte $00,$00,$1C,$22,$3E,$02,$3C,$00  '  "e"
              byte $18,$24,$04,$1E,$04,$04,$04,$00  '  "f"
              byte $00,$00,$1C,$22,$22,$3C,$20,$1C  '  "g"
              byte $02,$02,$1E,$22,$22,$22,$22,$00  '  "h"
              byte $08,$00,$0C,$08,$08,$08,$1C,$00  '  "i"
              byte $10,$00,$18,$10,$10,$10,$12,$0C  '  "j"
              byte $02,$02,$22,$12,$0C,$12,$22,$00  '  "k"
              byte $0C,$08,$08,$08,$08,$08,$1C,$00  '  "l"
              byte $00,$00,$36,$2A,$2A,$2A,$22,$00  '  "m"
              byte $00,$00,$1E,$22,$22,$22,$22,$00  '  "n"
              byte $00,$00,$1C,$22,$22,$22,$1C,$00  '  "o"
              byte $00,$00,$1E,$22,$22,$1E,$02,$02  '  "p"
              byte $00,$00,$3C,$22,$22,$3C,$20,$20  '  "q"
              byte $00,$00,$3A,$06,$02,$02,$02,$00  '  "r"
              byte $00,$00,$3C,$02,$1C,$20,$1E,$00  '  "s"
              byte $04,$04,$1E,$04,$04,$24,$18,$00  '  "t"
              byte $00,$00,$22,$22,$22,$32,$2C,$00  '  "u"
              byte $00,$00,$22,$22,$22,$14,$08,$00  '  "v"
              byte $00,$00,$22,$22,$2A,$2A,$36,$00  '  "w"
              byte $00,$00,$22,$14,$08,$14,$22,$00  '  "x"
              byte $00,$00,$22,$22,$22,$3C,$20,$1C  '  "y"
              byte $00,$00,$3E,$10,$08,$04,$3E,$00  '  "z"
              byte $38,$0C,$0C,$06,$0C,$0C,$38,$00  '  "{"
              byte $08,$08,$08,$08,$08,$08,$08,$08  '  "|"
              byte $0E,$18,$18,$30,$18,$18,$0E,$00  '  "}"
              byte $00,$2C,$1A,$00,$00,$00,$00,$00  '  "~"
              byte $7F,$7F,$7F,$7F,$7F,$7F,$7F,$7F   '  --

font_8x12     byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ' CHAR
              byte $00,$18,$3C,$3C,$3C,$18,$18,$00,$18,$18,$00,$00 ' CHAR !
              byte $00,$CC,$CC,$CC,$48,$00,$00,$00,$00,$00,$00,$00 ' CHAR "
              byte $00,$6C,$6C,$FE,$6C,$6C,$6C,$FE,$6C,$6C,$00,$00 ' CHAR #
              byte $18,$18,$7C,$06,$06,$3C,$60,$60,$3E,$18,$18,$00 ' CHAR $00
              byte $00,$00,$00,$46,$66,$30,$18,$0C,$66,$62,$00,$00 ' CHAR %
              byte $00,$1C,$36,$36,$1C,$BE,$F6,$66,$76,$DC,$00,$00 ' CHAR &
              byte $00,$18,$18,$18,$0C,$00,$00,$00,$00,$00,$00,$00 ' CHAR '
              byte $00,$60,$30,$18,$0C,$0C,$0C,$18,$30,$60,$00,$00 ' CHAR (
              byte $00,$0C,$18,$30,$60,$60,$60,$30,$18,$0C,$00,$00 ' CHAR )
              byte $00,$00,$00,$CC,$78,$FE,$78,$CC,$00,$00,$00,$00 ' CHAR *
              byte $00,$00,$00,$30,$30,$FC,$30,$30,$00,$00,$00,$00 ' CHAR +
              byte $00,$00,$00,$00,$00,$00,$00,$00,$38,$38,$0C,$00 ' CHAR ,
              byte $00,$00,$00,$00,$00,$FE,$00,$00,$00,$00,$00,$00 ' CHAR -
              byte $00,$00,$00,$00,$00,$00,$00,$00,$38,$38,$00,$00 ' CHAR .
              byte $00,$00,$80,$C0,$60,$30,$18,$0C,$06,$02,$00,$00 ' CHAR /
              byte $00,$7C,$C6,$E6,$F6,$D6,$DE,$CE,$C6,$7C,$00,$00 ' CHAR 0
              byte $00,$10,$18,$1E,$18,$18,$18,$18,$18,$7E,$00,$00 ' CHAR 1
              byte $00,$3C,$66,$66,$60,$30,$18,$0C,$66,$7E,$00,$00 ' CHAR 2
              byte $00,$3C,$66,$60,$60,$38,$60,$60,$66,$3C,$00,$00 ' CHAR 3
              byte $00,$60,$70,$78,$6C,$66,$FE,$60,$60,$F0,$00,$00 ' CHAR 4
              byte $00,$7E,$06,$06,$06,$3E,$60,$60,$66,$3C,$00,$00 ' CHAR 5
              byte $00,$38,$0C,$06,$06,$3E,$66,$66,$66,$3C,$00,$00 ' CHAR 6
              byte $00,$FE,$C6,$C6,$C0,$60,$30,$18,$18,$18,$00,$00 ' CHAR 7
              byte $00,$3C,$66,$66,$6E,$3C,$76,$66,$66,$3C,$00,$00 ' CHAR 8
              byte $00,$3C,$66,$66,$66,$7C,$30,$30,$18,$1C,$00,$00 ' CHAR 9
              byte $00,$00,$00,$38,$38,$00,$00,$38,$38,$00,$00,$00 ' CHAR :
              byte $00,$00,$00,$38,$38,$00,$00,$38,$38,$30,$18,$00 ' CHAR ' 
              byte $00,$60,$30,$18,$0C,$06,$0C,$18,$30,$60,$00,$00 ' CHAR <
              byte $00,$00,$00,$00,$FC,$00,$FC,$00,$00,$00,$00,$00 ' CHAR =
              byte $00,$0C,$18,$30,$60,$C0,$60,$30,$18,$0C,$00,$00 ' CHAR >
              byte $00,$3C,$66,$60,$30,$18,$18,$00,$18,$18,$00,$00 ' CHAR ?
              byte $00,$7C,$C6,$C6,$F6,$F6,$F6,$06,$06,$7C,$00,$00 ' CHAR @
              byte $00,$18,$3C,$66,$66,$66,$7E,$66,$66,$66,$00,$00 ' CHAR A
              byte $00,$7E,$CC,$CC,$CC,$7C,$CC,$CC,$CC,$7E,$00,$00 ' CHAR B
              byte $00,$78,$CC,$C6,$06,$06,$06,$C6,$CC,$78,$00,$00 ' CHAR C
              byte $00,$3E,$6C,$CC,$CC,$CC,$CC,$CC,$6C,$3E,$00,$00 ' CHAR D
              byte $00,$FE,$8C,$0C,$4C,$7C,$4C,$0C,$8C,$FE,$00,$00 ' CHAR E
              byte $00,$FE,$CC,$8C,$4C,$7C,$4C,$0C,$0C,$1E,$00,$00 ' CHAR F
              byte $00,$78,$CC,$C6,$06,$06,$E6,$C6,$CC,$F8,$00,$00 ' CHAR G
              byte $00,$66,$66,$66,$66,$7E,$66,$66,$66,$66,$00,$00 ' CHAR H
              byte $00,$3C,$18,$18,$18,$18,$18,$18,$18,$3C,$00,$00 ' CHAR I
              byte $00,$F0,$60,$60,$60,$60,$66,$66,$66,$3C,$00,$00 ' CHAR J
              byte $00,$CE,$CC,$6C,$6C,$3C,$6C,$6C,$CC,$CE,$00,$00 ' CHAR K
              byte $00,$1E,$0C,$0C,$0C,$0C,$8C,$CC,$CC,$FE,$00,$00 ' CHAR L
              byte $00,$C6,$EE,$FE,$FE,$D6,$C6,$C6,$C6,$C6,$00,$00 ' CHAR M
              byte $00,$C6,$C6,$CE,$DE,$FE,$F6,$E6,$C6,$C6,$00,$00 ' CHAR N
              byte $00,$38,$6C,$C6,$C6,$C6,$C6,$C6,$6C,$38,$00,$00 ' CHAR O
              byte $00,$7E,$CC,$CC,$CC,$7C,$0C,$0C,$0C,$1E,$00,$00 ' CHAR P
              byte $00,$38,$6C,$C6,$C6,$C6,$E6,$F6,$7C,$60,$F0,$00 ' CHAR Q
              byte $00,$7E,$CC,$CC,$CC,$7C,$6C,$CC,$CC,$CE,$00,$00 ' CHAR R
              byte $00,$3C,$66,$66,$06,$1C,$30,$66,$66,$3C,$00,$00 ' CHAR S
              byte $00,$7E,$5A,$18,$18,$18,$18,$18,$18,$3C,$00,$00 ' CHAR T
              byte $00,$66,$66,$66,$66,$66,$66,$66,$66,$3C,$00,$00 ' CHAR U
              byte $00,$66,$66,$66,$66,$66,$66,$66,$3C,$18,$00,$00 ' CHAR V
              byte $00,$C6,$C6,$C6,$C6,$D6,$D6,$6C,$6C,$6C,$00,$00 ' CHAR W
              byte $00,$66,$66,$66,$3C,$18,$3C,$66,$66,$66,$00,$00 ' CHAR X
              byte $00,$66,$66,$66,$66,$3C,$18,$18,$18,$3C,$00,$00 ' CHAR Y
              byte $00,$FE,$E6,$32,$30,$18,$0C,$8C,$C6,$FE,$00,$00 ' CHAR Z
              byte $00,$78,$18,$18,$18,$18,$18,$18,$18,$78,$00,$00 ' CHAR [
              byte $00,$00,$02,$06,$0C,$18,$30,$60,$C0,$80,$00,$00 ' CHAR \
              byte $00,$78,$60,$60,$60,$60,$60,$60,$60,$78,$00,$00 ' CHAR ]
              byte $10,$38,$6C,$C6,$00,$00,$00,$00,$00,$00,$00,$00 ' CHAR ^
              byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FE,$00 ' CHAR _
              byte $18,$18,$30,$00,$00,$00,$00,$00,$00,$00,$00,$00 ' CHAR `
              byte $00,$00,$00,$00,$3C,$60,$7C,$66,$66,$DC,$00,$00 ' CHAR a
              byte $00,$0E,$0C,$0C,$7C,$CC,$CC,$CC,$CC,$76,$00,$00 ' CHAR b
              byte $00,$00,$00,$00,$3C,$66,$06,$06,$66,$3C,$00,$00 ' CHAR c
              byte $00,$70,$60,$60,$7C,$66,$66,$66,$66,$DC,$00,$00 ' CHAR d
              byte $00,$00,$00,$00,$3C,$66,$7E,$06,$66,$3C,$00,$00 ' CHAR e
              byte $00,$38,$6C,$0C,$0C,$3E,$0C,$0C,$0C,$1E,$00,$00 ' CHAR f
              byte $00,$00,$00,$00,$DC,$66,$66,$66,$7C,$60,$66,$3C ' CHAR g
              byte $00,$0E,$0C,$0C,$6C,$DC,$CC,$CC,$CC,$CE,$00,$00 ' CHAR h
              byte $00,$30,$30,$00,$3C,$30,$30,$30,$30,$FC,$00,$00 ' CHAR i
              byte $00,$60,$60,$00,$78,$60,$60,$60,$60,$66,$66,$3C ' CHAR j
              byte $00,$0E,$0C,$0C,$CC,$6C,$3C,$6C,$CC,$CE,$00,$00 ' CHAR k
              byte $00,$3C,$30,$30,$30,$30,$30,$30,$30,$FC,$00,$00 ' CHAR l
              byte $00,$00,$00,$00,$7E,$D6,$D6,$D6,$D6,$C6,$00,$00 ' CHAR m
              byte $00,$00,$00,$00,$3E,$66,$66,$66,$66,$66,$00,$00 ' CHAR n
              byte $00,$00,$00,$00,$3C,$66,$66,$66,$66,$3C,$00,$00 ' CHAR o
              byte $00,$00,$00,$00,$76,$CC,$CC,$CC,$CC,$7C,$0C,$1E ' CHAR p
              byte $00,$00,$00,$00,$DC,$66,$66,$66,$66,$7C,$60,$F0 ' CHAR q
              byte $00,$00,$00,$00,$6E,$EC,$DC,$0C,$0C,$1E,$00,$00 ' CHAR r
              byte $00,$00,$00,$00,$3C,$66,$0C,$30,$66,$3C,$00,$00 ' CHAR s
              byte $00,$00,$08,$0C,$7E,$0C,$0C,$0C,$6C,$38,$00,$00 ' CHAR t
              byte $00,$00,$00,$00,$66,$66,$66,$66,$66,$DC,$00,$00 ' CHAR u
              byte $00,$00,$00,$00,$66,$66,$66,$66,$3C,$18,$00,$00 ' CHAR v
              byte $00,$00,$00,$00,$C6,$C6,$D6,$D6,$6C,$6C,$00,$00 ' CHAR w
              byte $00,$00,$00,$00,$C6,$6C,$38,$38,$6C,$C6,$00,$00 ' CHAR x
              byte $00,$00,$00,$00,$CC,$CC,$CC,$CC,$78,$60,$30,$1E ' CHAR y
              byte $00,$00,$00,$00,$7E,$62,$30,$0C,$46,$7E,$00,$00 ' CHAR z
              byte $00,$70,$18,$18,$0C,$06,$0C,$18,$18,$70,$00,$00 ' CHAR {
              byte $00,$30,$30,$30,$30,$00,$30,$30,$30,$30,$00,$00 ' CHAR |
              byte $00,$0E,$18,$18,$30,$60,$30,$18,$18,$0E,$00,$00 ' CHAR }
              byte $00,$9C,$B6,$E6,$00,$00,$00,$00,$00,$00,$00,$00 ' CHAR ~


'---------------------------
' Assembly language routines
'---------------------------
                        org     0

entry
temp1 ' re-use the initializatin space
                        mov     currFontAddr, Font5x7Addr

commandComplete         wrlong  Zero, par

getCommand              rdlong  temp1, par       wz      ' wait for command
          if_z          jmp     #getCommand

                        cmp     temp1, #cmdLast wc  ' check for valid command
          if_nc         jmp     #commandComplete

                        add     temp1, #cmdTable-1
                        jmp     temp1

cmdTable                jmp     #asmClear
                        jmp     #asmPlotPixel
                        jmp     #asmPlotLine
                        jmp     #asmPlotCircle
                        jmp     #asmFillCircle
                        jmp     #asmPlotChar
                        jmp     #asmSetFont
                        jmp     #asmSetColor
                        jmp     #asmSetFillColor
                        jmp     #asmPlotHorizLine
                        jmp     #asmPlotVertLine
                        jmp     #asmPlotText
                        jmp     #asmPlotSprite
                        jmp     #asmSelFrontBfr
                        jmp     #asmSelBackBfr
_endFrame               jmp     #asmEndFrontFrame


asmClear
                        mov     temp1, BitmapLongs
                        mov     temp2, BmpBaseAddr
:loop                   wrlong  Zero, temp2
                        add     temp2, #4
                        djnz    temp1, #:loop

                        jmp     #commandComplete


'-------------------------------------------------------------------------------
' PlotPixel
'
asmPlotPixel
                        rdlong  currXOffset, Parm1Addr
                        rdlong  currYOffset, Parm2Addr

                        mov     pixelColor, color

                        call    #asmPlotPixelSub
                        jmp     #commandComplete

_plotRelativePixel      mov     currXOffset, fromX
                        add     currXOffset, dx
                        mov     currYOffset, fromY
                        add     currYOffset, dy

asmPlotPixelSub
                        mov     currXOffset, currXOffset wc
          if_nc         cmp     MaxX, currXOffset wc
          if_nc         mov     targAddr, currYOffset wc
          if_nc         shl     targAddr, #7
          if_nc         add     targAddr, currXOffset

          if_nc         mov     targAddr, targAddr wc
          if_nc         cmp     BmpBaseTopAddr, targAddr wc
          if_nc         add     targAddr, BmpBaseAddr

          if_nc         wrbyte  pixelColor, targAddr

_plotRelativePixel_ret
asmPlotPixelSub_ret     ret

'-------------------------------------------------------------------------------
' PlotLine
'
asmPlotLine             rdlong  fromX, Parm1Addr
                        rdlong  fromY, Parm2Addr
                        rdlong  toX,   Parm3Addr
                        rdlong  toY,   Parm4Addr

                        mov     lineColor, color

                        call    #asmPlotLineSub

                        jmp     #commandComplete

'-------------------------------------------------------------------------------
' PlotLine subroutine
'
asmPlotLineSub_ret      ret
asmPlotLineSub          mov     dx, toX
                        sub     dx, fromX wc
                        abs     dx, dx
                        negc    stepX, #BYTES_PER_PIXEL

                        mov     dy, toY
                        sub     dy, fromY wc
                        abs     dy, dy
                        negc    stepY, ScrWidth

                        shl     dx, #1
                        shl     dy, #1

                        mov     currXOffset, fromX

                        ' Multiply the start Y offset by 128
                        mov     currYOffset, fromY
                        shl     currYOffset, #7

                        ' Multiply the target Y offset by 128
                        mov     targYOffset, toY
                        shl     targYOffset, #7

                        mov     targAddr, BmpBaseAddr
                        add     targAddr, currXOffset
                        add     targAddr, currYOffset

                        wrbyte  lineColor, targAddr

                        cmp     dx, dy wc
          if_c          jmp     #_move_along_y_axis

_move_along_x_axis      mov     temp1, dx wz
          if_z          jmp     asmPlotLineSub_ret
                        shr     temp1, #1
                        mov     fraction, dy
                        sub     fraction, temp1

:loop                   mov     fraction, fraction wc
          if_nc         add     currYOffset, stepy
          if_nc         add     targAddr, stepy
          if_nc         sub     fraction, dx

                        add     targAddr, stepx
                        add     fraction, dy

                        wrbyte  lineColor, targAddr

                        djnz    temp1, #:loop

                        jmp     asmPlotLineSub_ret

_move_along_y_axis      mov     temp1, dy wz
          if_z          jmp     asmPlotLineSub_ret
                        shr     temp1, #1
                        mov     fraction, dx
                        sub     fraction, temp1

:loop
                        mov     fraction, fraction wc
          if_nc         add     currXOffset, stepx
          if_nc         add     targAddr, stepx
          if_nc         sub     fraction, dy

                        add     targAddr, stepy
                        add     fraction, dx

                        wrbyte  lineColor, targAddr

                        djnz    temp1, #:loop

                        jmp     asmPlotLineSub_ret

'-------------------------------------------------------------------------------
' PlotCircle
'
asmFillCircle

                        mov     _circleHelper, #_circleHelper_2
                        jmp     #_plotCircle

asmPlotCircle

                        mov     _circleHelper, #_circleHelper_1
                        mov     pixelColor, color

_plotCircle
                        rdlong  xC, Parm1Addr
                        rdlong  yC, Parm2Addr
                        mov     circleSum, #5
                        rdlong  radius,Parm3Addr

                        mov     radius, radius wz, wc
          if_z_or_c     jmp     #commandComplete

                        mov     tx, #0
                        mov     ty, radius

                        shl     radius, #2
                        sub     circleSum, radius
                        abs     circleSum, circleSum wc
                        shr     circleSum, #2
          if_c          neg     circleSum, circleSum

                        mov     dxC, #0
                        mov     dyC, ty
                        jmpret  _circleHelper_ret, _circleHelper

                        mov     dxC, ty
                        mov     dyC, #0
                        jmpret  _circleHelper_ret, _circleHelper

:loop                   cmp     tx, ty wc
          if_nc         jmp     #:finish

                        add     tx, #1

                        mov     temp1, tx
                        mov     circleSum, circleSum wc
          if_c          jmp     #:sum_skip

                        sub     ty, #1
                        sub     temp1, ty

:sum_skip               add     circleSum, temp1
                        add     circleSum, temp1
                        add     circleSum, #1

                        mov     dxC, tx
                        mov     dyC, ty
                        jmpret  _circleHelper_ret, _circleHelper
 
                        mov     dxC, ty
                        mov     dyC, tx
                        jmpret  _circleHelper_ret, _circleHelper

                        jmp     #:loop

:finish
                        mov     dxC, tx
                        mov     dyC, ty
                        jmpret  _circleHelper_ret, _circleHelper

                        jmp     #commandComplete

_circleHelper           long    _circleHelper_2

' Draw Circle (no fill)

_circleHelper_1         ' Draw bottom half of circle

                        mov     currXOffset, xC
                        add     currXOffset, dxC
                        mov     currYOffset, yC
                        add     currYOffset, dyC
                        call    #asmPlotPixelSub ' Draw lower right

                        neg     dxC, dxC wz
          if_nz         mov     currXOffset, xC
          if_nz         add     currXOffset, dxC
          if_nz         call    #asmPlotPixelSub ' Draw lower left

                        ' Draw top half of circle

                        neg     dyC, dyC wz
          if_nz         mov     currYOffset, yC
          if_nz         add     currYOffset, dyC
          if_nz         call    #asmPlotPixelSub ' Draw upper left

                        neg     dxC, dxC wz
          if_nz         mov     currXOffset, xC
          if_nz         add     currXOffset, dxC
          if_nz         call    #asmPlotPixelSub ' Draw upper right

                        jmp     _circleHelper_ret

' Fill Circle

_circleHelper_2         ' Draw bottom half of circle

                        mov     currYOffset, yC
                        add     currYOffset, dyC

                        mov     toX, xC
                        add     toX, dxC ' lower right

                        neg     dxC, dxC wz
          if_z          jmp     _circleHelper_ret

                        mov     fromX, xC
                        add     fromX, dxC ' lower left
                        call    #_circleFill

                        ' Draw top half of circle

                        sub     currYOffset, dyC
                        sub     currYOffset, dyC

                        call    #_circleFill

_circleHelper_ret       ret

_circleFill
                        mov     temp2, toX
                        sub     temp2, fromX
                        mov     temp2, temp2 wz, wc
          if_z_or_c     jmp     _circleFill_ret

                        mov     fromY, currYOffset
                        mov     lineColor, fillColor

                        call    #_plotHorizLine

_circleFill_ret         ret

'-------------------------------------------------------------------------------
' PlotChar
'
asmPlotChar             rdlong  fromY, Parm2Addr
                        shl     fromY, #3
                        rdbyte  temp3, Parm3Addr
                        min     temp3, #$20
                        sub     temp3, #$20
                        rdlong  fromX, Parm1Addr
'                       shl     temp3, #3

                        jmpret  _plotCharFontSwitch_ret, _plotCharFontSwitch1
                        jmpret  plotCharSub_ret, _plotCharSubSwitch

                        jmp     #commandComplete

_plotCharFontSwitch1    jmp     #_5x7_1

_8x8_1                  shl     fromX, #3 ' multiply by 8

                        jmp     _plotCharFontSwitch_ret

_5x7_1                  shl     fromX, #1 ' multiply by 6
                        mov     temp1, fromX
                        shl     fromX, #1
                        add     fromX, temp1

_plotCharFontSwitch_ret ret

_plotCharSubSwitch      jmp     #plotCharSub_x8

plotCharSub_x8          shl     temp3, #3 ' multiply by 8

                        add     temp3, currFontAddr
                        mov     dy, #0

                        rdlong  temp4, temp3
                        add     temp3, #4
                        mov     pixelColor, color
                        rdlong  temp5, temp3

                        call    #_plotChar
                        mov     temp4, temp5
                        call    #_plotChar
 
                        add     fromX, charWidth

plotCharSub_ret         ret

plotCharSub_x12         shl     temp3, #2 ' multiply by 12
                        mov     temp4, temp3
                        shl     temp3, #1
                        add     temp3, temp4
                        add     temp3, currFontAddr

                        rdlong  temp4, temp3
                        mov     dy, #0
                        add     temp3, #4
                        rdlong  temp5, temp3
                        mov     pixelColor, color
                        add     temp3, #4
                        rdlong  temp3, temp3

                        call    #_plotChar
                        mov     temp4, temp5
                        call    #_plotChar
                        mov     temp4, temp3
                        call    #_plotChar
 
                        add     fromX, charWidth

                        jmp     plotCharSub_ret

_plotChar               mov     l1, #4

:outerLoop              mov     temp2, temp4
                        shr     temp4, #8

                        mov     l2, #8
                        mov     dx, fontCharOffset
:innerLoop              shr     temp2, #1 wc
'         if_c          mov     pixelColor, color
'         if_nc         mov     pixelColor, fillColor
          if_c          call    #_plotRelativePixel

                        add     dx, #1
                        djnz    l2, #:innerLoop

                        add     dy, #1
                        djnz    l1, #:outerLoop

_plotChar_ret           ret

'-------------------------------------------------------------------------------
' PlotText
'
asmPlotText             rdlong  fromY, Parm2Addr
                        shl     fromY, #3
                        mov     pixelColor, color
                        rdlong  fromX, Parm1Addr

                        rdlong  xC, Parm3Addr

                        jmpret  _plotCharFontSwitch_ret, _plotCharFontSwitch1

:loop
                        rdbyte  temp3, xC wz
          if_nz         add     xC, #1

          if_nz         min     temp3, #$20
          if_nz         sub     temp3, #$20
'         if_nz         shl     temp3, #3

          if_nz         jmpret  plotCharSub_ret, _plotCharSubSwitch

          if_nz         jmp     #:loop

                        jmp     #commandComplete

'-------------------------------------------------------------------------------
' SetFont
'
asmSetFont              rdlong  font, Parm1Addr

                        mov     temp1, font wz

          if_z          jmp     #:_5x5
                        sub     temp1, #1 wz
          if_z          jmp     #:_8x8
                        sub     temp1, #1 wz
          if_z          jmp     #:_8x12

                        mov     font, #0
:_5x5
                        movs    _plotCharFontSwitch1, #_5x7_1
                        movs    _plotCharSubSwitch, #plotCharSub_x8
                        mov     charWidth, #6
                        mov     fontCharOffset, #1
                        mov     currFontAddr, Font5x7Addr
                        jmp     #commandComplete

:_8x8
                        movs    _plotCharFontSwitch1, #_8X8_1
                        movs    _plotCharSubSwitch, #plotCharSub_x8
                        mov     charWidth, #8
                        mov     fontCharOffset, #0
                        mov     currFontAddr, Font8x8Addr
                        jmp     #commandComplete

:_8x12
                        movs    _plotCharFontSwitch1, #_8X8_1
                        movs    _plotCharSubSwitch, #plotCharSub_x12
                        mov     charWidth, #8
                        mov     fontCharOffset, #0
                        mov     currFontAddr, Font8x12Addr
                        jmp     #commandComplete

'-------------------------------------------------------------------------------
' SetColor
'
asmSetColor             rdlong  color, Parm1Addr

                        mov     temp1, color
                        shl     temp1, #8
                        or      temp1, color
                        mov     color, temp1
                        shl     temp1, #16
                        or      color, temp1

                        jmp     #commandComplete

'-------------------------------------------------------------------------------
' SetFillColor
'
asmSetFillColor         rdlong  fillColor, Parm1Addr

                        mov     temp1, fillColor
                        shl     temp1, #8
                        or      temp1, fillColor
                        mov     fillColor, temp1
                        shl     temp1, #16
                        or      fillColor, temp1

                        jmp     #commandComplete

'-------------------------------------------------------------------------------
' PlotHorizLine
'
asmPlotHorizLine
                        rdlong  fromX, Parm1Addr
                        rdlong  fromY, Parm2Addr
                        mov     lineColor, color
                        rdlong  toX,   Parm3Addr

                        call    #_plotHorizLine

                        jmp     #commandComplete

_plotHorizLine          call    #_CalcEfficientLine

                        ' Multiply the start Y offset by 128
                        mov     temp1, fromY
                        shl     temp1, #7

                        mov     targAddr, BmpBaseAddr
                        add     targAddr, temp1
                        add     targAddr, fromX

                        call    #_plotEfficientHorizLine

_plotHorizLine_ret      ret

'-------------------------------------------------------------------------------
' PlotHorizLine subroutine
'

_plotEfficientHorizLine
                        mov     temp1, __startLength wz
          if_z          jmp     #:doMiddle

:doBeginningLoop
                        wrbyte  lineColor, targAddr
                        add     targAddr, #1
                        djnz    temp1, #:doBeginningLoop

:doMiddle
                        mov     temp1, __middleLength wz
          if_z          jmp     #:doEnding

:doMiddleLoop
                        wrlong  lineColor, targAddr
                        add     targAddr, #4
                        djnz    temp1, #:doMiddleLoop

:doEnding
                        mov     temp1, __endLength wz
          if_z          jmp     _plotEfficientHorizLine_ret

:doEndingLoop
                        wrbyte  lineColor, targAddr
                        add     targAddr, #1
                        djnz    temp1, #:doEndingLoop

_plotEfficientHorizLine_ret ret

_CalcEfficientLine
                        mins   fromX, #0
                        maxs   fromX, MaxX

                        mins   toX, #0
                        maxs   toX, MaxX

                        cmp     toX, fromX wz, wc
          if_c          xor     toX, fromX
          if_c          xor     fromX, toX
          if_c          xor     toX, fromX

                        mov     __startLength, fromX
                        add     __startLength, #3
                        andn    __startLength, #3
                        mov     __middleLength, toX
                        add     __middleLength, #1
                        sub     __middleLength, __startLength
                        sub     __startLength, fromx
                        mov     __endLength, __middleLength
                        and     __endLength, #3
                        shr     __middleLength, #2

_CalcEfficientLine_ret  ret

__startLength           long    0
__middleLength          long    0
__endLength             long    0

'-------------------------------------------------------------------------------
' PlotVertLine
'
asmPlotVertLine
                        rdlong  fromX, Parm1Addr
                        rdlong  fromY, Parm2Addr
                        rdlong  toY,   Parm4Addr

                        mins    fromX, #0
                        maxs    fromX, MaxX

                        mins    fromY, #0
                        maxs    fromY, MaxX

                        mins    toY, #0
                        maxs    toY, MaxX

                        cmp     toY, fromY wc
          if_c          xor     toY, fromY
          if_c          xor     fromY, toY
          if_c          xor     toY, fromY

                        mov     temp2, toY
                        sub     temp2, fromY
                        add     temp2, #1

                        ' Multiply the start Y offset by 128
                        mov     targAddr, fromY
                        shl     targAddr, #7

                        add     targAddr, BmpBaseAddr
                        add     targAddr, fromX

                        mov     lineColor, color
:loop
                        wrbyte  lineColor, targAddr
                        add     targAddr, ScrWidth
                        djnz    temp2, #:loop

                        jmp     #commandComplete


'-------------------------------------------------------------------------------
' PlotSprite
'
asmPlotSprite
                        rdlong  fromY, Parm2Addr ' read the Y position
                        shl     fromY, #7
                        rdlong  fromX, Parm1Addr ' read the X position
                        rdlong  temp5, Parm3Addr ' read the sprite address

                        rdbyte  xC, temp5
                        add     temp5, #1
                        rdbyte  yC, temp5
                        add     temp5, #3
                        rdlong  spriteMaskColor, temp5
                        add     temp5, #4

                        mov     l1, yC

:outerLoop              mov     l2, xC
                        mov     currXOffset, fromX

:innerLoop              mov     targAddr, currXOffset wc
          if_nc         cmp     PhysMaxX, currXOffset wc
          if_nc         add     targAddr, fromY

          if_nc         mov     targAddr, targAddr wc
          if_nc         cmp     BmpBaseTopAddr, targAddr wc
          if_nc         add     targAddr, BmpBaseAddr

          if_nc         rdbyte  temp2, temp5
          if_nc         cmp     temp2, spriteMaskColor wz

                        add     temp5, #BYTES_PER_PIXEL
                        add     currXOffset, #BYTES_PER_PIXEL

          if_nc_and_nz  wrbyte  temp2, targAddr

                        djnz    l2, #:innerLoop

                        add     fromY, ScrWidth

                        djnz    l1, #:outerLoop

                        jmp     #commandComplete

'-------------------------------------------------------------------------------
' EndFrame
'
asmEndBackFrame         rdlong  temp1, CurrFrameOutAddr wz

          if_z          mov     BmpBaseAddr, BmpBaseAddrA
          if_z          mov     BmpBaseAddrA, BmpBaseAddrB

          if_z          wrlong  BmpBaseAddrB, CurrFrameOutAddr

          if_z          mov     BmpBaseAddrB, BmpBaseAddr

                        jmp     #commandComplete

asmEndFrontFrame        wrlong  BmpBaseAddr, CurrFrameOutAddr

                        jmp     #commandComplete

'-------------------------------------------------------------------------------
' SelBackBfr
'
asmSelBackBfr           movs    _endFrame, #asmEndBackFrame
                        mov     BmpBaseAddr, BmpBaseAddrB

                        jmp     #commandComplete

'-------------------------------------------------------------------------------
' SelFrontBfr
'
asmSelFrontBfr          movs    _endFrame, #asmEndFrontFrame
                        mov     BmpBaseAddr, BmpBaseAddrA

                        jmp     #commandComplete

'-------------------------------------------------------------------------------
' Hub addresses setup before cog load

Parm1Addr               long    0
Parm2Addr               long    0
Parm3Addr               long    0
Parm4Addr               long    0
CurrFrameOutAddr        long    0
BmpBaseAddr             long    0
BmpBaseTopAddr          long    0
BmpBaseAddrA            long    0
BmpBaseAddrB            long    0
Font5x7Addr             long    0
Font8x8Addr             long    0
Font8x12Addr            long    0

'-------------------------------------------------------------------------------
' Screen settings

ScrWidth                long    BYTES_PER_PIXEL*128
ScrHeight               long    128
BitmapLongs             long    0  'Number of longs in the bitmap video memory

'-------------------------------------------------------------------------------
' Window Settings

PhysMaxX                long    BYTES_PER_PIXEL*127
MaxX                    long    127
MaxY                    long    127

'-------------------------------------------------------------------------------
' Constants

Zero                    long    0

'-------------------------------------------------------------------------------
' Workspace

color                   long    $FFFFFFFF
fillColor               long    0
font                    long    0
charWidth               long    6
currFontAddr            long    0
fontCharOffset          long    1
spriteMaskColor         long    -1
lineColor               res     1
pixelColor              res     1

fromX                   res     1
fromY                   res     1
toX                     res     1
toY                     res     1
radius                  res     1
xC                      res     1
yC                      res     1
tx                      res     1
ty                      res     1
circleSum               res     1

dx                      res     1
dy                      res     1
dxC                     res     1
dyC                     res     1
stepx                   res     1
stepy                   res     1
currXOffset             res     1
currYOffset             res     1
targXOffset             res     1
targYOffset             res     1
fraction                res     1
targAddr                res     1
temp2                   res     1
temp3                   res     1
temp4                   res     1
temp5                   res     1
l1                      res     1
l2                      res     1

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