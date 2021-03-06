{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                   NTSC 8x8 Character Driver (C) 2009-06-29 Doug Dingus                                       │                                                            
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                    TERMS OF USE: Parallax Object Exchange License                                            │                                                            
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

''Auto Hardware Detect by Graham Coley  (Demoboard, HYBRID, and HYDRA)
''Based off of the very nice template contributed by Eric Ball

''Use this file to start the driver.

''TODO:  Mouse Pointer -- Sometime later, this is text only release, there are two screen colors avaliable
''       For a mouse pointer, as the core graphics are 4 color, two used for text.

''This file also contains a number of handy text routines

''Warning on color space.  The very lowest intensity color text, and the highest intensity color text, as
''defined in this driver are out of NTSC spec.  Most all displays will render these just fine.  I have
''Found on newer HDTV displays, these may cause screen tearing.  Running a non-interlaced display can
''help with this, as can only using color text with intensity 2-5.





CON
  _CLKMODE = RCSlow     ' Start prop in RCSlow mode internal crystal

VAR           
        long screen[(80*25)/4]                          'Display Screen Buffer needs long alignment
        word color[80*25]                               'Color Cell Buffer, needs word alignment

        long PIXEL_RAM[80]                              'Pixel RAM Read by TV COG
        long COLOR_RAM[80]                              'Color RAM Read by TV COG --every scan line.
                                                        'Keep these two sequential!

        'If you know you are running at lower character densities, you can cut these buffers
        'back some  

VAR     'Used by simple library functions
        word          count                             'general purpose counter
        word          index                             'general purpose index        
        byte          screen_width
        byte          background
        byte          foreground
        word          cursor                            'next character marker
        
           


OBJ
 TV             : "Potato_Text_TV_01.spin"                                  'TV Video Cog   
 TX             : "Potato_Text_GR_01.spin"                            'Text Generator Cog
 FONT           : "Font_ATARI_DEMO.spin"                             '8x8 Text Font Non-Inverted
' POINTER        : "Font_mouse.spin"                            'Mouse Pointer Shapes
 
PUB start(sc)


  HWDetect                                              'Automagical board detect by Coley
  Init                                                  'One time driver setup tasks
  CharsPerLine(sc)                                      'Make sure driver starts with useful values
  TV.start(@tv_cog_init)                                'Launch the video signal cog
  TX.start(@tx_cog_init)                                'Launch the text cog



Pri  HWDetect | HWPins

  clkset(%01101000,  12_000_000)                        ' Set internal oscillator to RCFast and set PLL to start
  waitcnt(cnt+120_000)                                  ' wait approx 10ms at 12mhz for PLL to 'warm up'

' Automatic hardware detection based on the use of pins 12 & 13 which results
' in different input states 
' Demoboard = Video Out
' Hydra = Keyboard Data In & Data Out
' Hybrid = Keyboard Data I/O & Clock I/O  
  
  HWPins := INA[12..13]                                 ' Check state of Pins 12-13

  CASE HWPins
    %00 : clkset( %01101111, 80_000_000 )                          ' Demo Board   80MHz (5MHz PLLx16)  
          ivcfg := %0_11_1_0_1_000_00000000000_001_0_01110000      ' demoboard 4 color mode
          ifrqa := $16E8_BA2F                                      ' (7,159,090.9Hz/80MHz)<<32 NTSC demoboard & Hydra 
          idira := $0000_7000                                      ' demoboard
               
    %01 : clkset( %01110110, 80_000_000 )                          ' Hydra        80MHz (10MHz PLLx8)
          ivcfg := %0_11_1_0_1_000_00000000000_001_0_01110000      ' %0_10_1_0_1_000_00000000000_011_0_00000111      ' Hydra & Hybrid
          ifrqa := $16E8_BA2F                                      ' (7,159,090.9Hz/80MHz)<<32 NTSC demoboard & Hydra 
          idira := $0700_0000                                      ' Hydra & Hybrid
          
    %11 : clkset( %01101111, 96_000_000 )                          ' Hybrid       96MHz (6MHz PLLx16)
          ivcfg := %0_10_1_0_1_000_00000000000_011_0_00000111      ' Hydra & Hybrid
          ifrqa := $1317_45D1                                      ' (7,159,090.9Hz/96MHz)<<32 NTSC Hybrid
          idira := $0700_0000                                      ' Hydra & Hybrid

Pub   Init |  i, j, k, l

    lnram := @PIXEL_RAM                                   'Video Cog Pixel Buffer HUB Address
    clram := @COLOR_RAM                                   'Video Cog Color Buffer HUB Address

    fonttab := font.GetPtrToFontTable                     'Get HUB address of font table 
    tx_screen := @screen                                  'Get HUB address for start of text screen
    tx_color :=  @color                                   'Get HUB address for start of color cells

    cursor := 0                                         'x * y
    


    
PUB   Scroll(ssl, ssh) |  i, j, k, l

'This one scrolls the screen with a start line and end line.  Start line is overwritten, end line is blanked
'Zeros = Entire screen
'TEXT.Scroll([lower limit], [upper limit])  or TEXT.Scroll(0,0)

      if (ssl == 0) & (ssh == 0)
        bytemove(tx_screen, (tx_screen+screen_width), (screen_width*24+1))
        bytemove(tx_color, tx_color+(screen_width*2), (screen_width*24*2))
        repeat i from 0 to screen_width
          SetTextAt(i, 24, $20)
          SetColorCell(i, 24, background, foreground)

      bytemove((tx_screen + (ssl * screen_width)), (tx_screen+screen_width+(ssl*screen_width)), (screen_width*ssh))
      bytemove(tx_color + (ssl * 2 * screen_width), (tx_color+screen_width*2+(ssl*screen_width*2)), (screen_width*ssh*2))
      repeat i from 0 to screen_width
        SetTextAt(i, ssh, $20)
        SetColorCell(i, ssh, background, foreground)
        

pub   CharsPerLine(chars)  |  i, j, k, l

'this one sets characters per line
'Called like this:  chars_per_line( [16, 32, 40, 64, 80]) eg:  chars_per_line(64) = 64 character x 25 row display
'
        vsclactv := (2560 / (chars*8))<<12 + (2560 / (chars*8) * 8)
        numwtvd := chars
        screen_width := chars



Pub   ColorMode(colormodep)

      '0 = Color Cells Enabled
      'non zero = color values; color 00 = background; 01 = character color
      '                         color 10 = mouse 1; color 11 = mouse 2


      two_colors := colormodep                               


Pub   SetColors (scb, scf)
'Sets default background and foreground colors)
'TEXT.SetColors( [background color], [foreground color])

    background := scb 'byte[@CLUT][scb]
    foreground := scf 'byte[@CLUT][scf]      

    background //= 136
    foreground //= 136
    

Pub   Interlace(im)

'      0   = Vertically Interlaced Display
'      1+  = Non Vertically Interlaced Display

    no_interlace := im

Pub   ClearText (ct)

'ClearText( [character value] )

'Sets the text buffer to characer specified

    Repeat index from 0 to (screen_width * 25)
      byte[tx_screen] [index] := ct 


Pub   ClearColors (cb, cc) | i

'Sets all the color cells to the color specified
'If one value is zero, that color will not be set

'TEXT.ClearColors ([background], [foreground])

    Repeat i from 0 to (screen_width*25*2) step 2
      if (cb > 0)
        byte[tx_color] [i] := byte[@CLUT] [cb]
      if (cc > 0)
        byte[tx_color] [i+1] := byte[@CLUT][cc]


Pub   SetColorCell(ccx, ccy, cb, cc)

'TEXT.SetColorCell( [screen x], [screen y], [background], [foreground])

      word[tx_color] [ccx + (ccy*screen_width)] := byte[@CLUT][cb] + (byte[@CLUT][cc] << 8)

      'index := (ccx + (ccy*screen_width)) << 1
      'byte[tx_color][index] := byte[@CLUT][cb]
      'byte[tx_color][index + 1] := byte[@CLUT][cc]
      

Pub   SetTextAt(stx, sty, stch)

'Sets the text character value at a given screen coordinate

'TEXT.SetTextAt( [screen x], [screen y], [character value])

      byte[tx_screen] [stx + (sty * screen_width)] := stch
       
      
Pub   Redefine (rchar, r1, r2, r3, r4, r5, r6, r7, r8)

'For OBC, C64 Style Character Redefine)

'TEXT.Redefine ([char], [binary row 0], [binary row 1], [binary row 2] ...[binary row7])


      byte[fonttab] [(rchar * 8)] := r1
      byte[fonttab] [(rchar * 8) + 1] := r2
      byte[fonttab] [(rchar * 8) + 2] := r3
      byte[fonttab] [(rchar * 8) + 3] := r4
      byte[fonttab] [(rchar * 8) + 4] := r5
      byte[fonttab] [(rchar * 8) + 5] := r6
      byte[fonttab] [(rchar * 8) + 6] := r7
      byte[fonttab] [(rchar * 8) + 7] := r8


Pub   RedefineDat (rdchar, rddat)
'Redefine a character based on some data in a DAT block

'TEXT.RedefineDat ([char], [address of binary data])

      bytemove(fonttab + (rdchar * 8), rddat, 8)


Pub   PrintStringAt(psx, psy, str) | i, j
      'write string to screen at x, y, string address

      j := 1
      i := 0
      repeat until j == 0
        j := byte[str] [i]
        if j <> 0
          byte [tx_screen + (psy * screen_width)+ psx][i] := j
                   
          word [tx_color + (psy * screen_width*2) + (psx*2)][i] := byte[@CLUT][background] + (byte[@CLUT][foreground] << 8) 
        i++

  
           
Pub   PrintChar(char)
      'write a character to the screen with current color attributes in play
      byte[tx_screen][cursor] := char&$ff
      word[tx_color][cursor] := byte[@CLUT][background] + (byte[@CLUT][foreground] << 8)
      cursor ++
      if cursor > (24*screen_width)
        cursor := cursor - screen_width
        scroll(0,24)
      

Pub   PrintString(str) | i, j
      'Write a string to the current display position
      '...and current color attributes in play
      j := 1
      i := 0
      repeat until j == 0
        j := byte[str] [i]
        if j <> 0
          PrintChar(j)
       i++    
          


PUB PrintDec(value) | i

'' Print a decimal number, ported from TV_Text.spin

  if value < 0
    -value
    PrintChar("-")

  i := 1_000_000_000

  repeat 10
    if value => i
      PrintChar(value / i + "0")
      value //= i
      result~~
    elseif result or i == 1
      PrintChar("0")
    i /= 10



DAT

'LineRAM, video pins and other goodies live here

tv_cog_init            'Mode parameters required for proper init of the TV cog.
ivcfg                   long  0                    'video config
ifrqa                   long  0                    'PLLA frequency
idira                   long  0                     'Pin direction mask

                       'Mode parameters for video signal pixel size and framing / number of waitvids 
vsclbp                  LONG    1<<12+312                                       ' NTSC back porch + overscan (213)
vsclactv                LONG    8<<12+128                                       ' NTSC 25 PLLA per pixel, 4 pixels per frame
vsclfp                  LONG    1<<12+320                                       ' NTSC overscan (214) + front porch

'front porch timing 315 & 312 is stable just rocks.  It's C64 mode, for sure.  Have to do some math to nail it.

tx_cog_init           'mode parameters for text cog
numwtvd                 LONG    20                                               '

lnram                   long  0                                                 'capture start of PIXEL_RAM

'TV Cog Reads this every scan line (live)
clram                   long  0                                                 'capture start of COLOR_RAM

                      'TV cog display signals for text and maybe sprite cog
tv_vblank               LONG    0                                               'Set to 0 during active, 1 during VBLANK
tv_actv                 LONG    0                                               'Set to 1 when pixels are drawing to TV   (10)

'additional text cog parameters here
tx_screen               LONG    0                                               'screen buffer address
tx_color                LONG    0                                               'color cell buffer address
fonttab                 LONG    0                                               'HUB Font table pointer
ctable                  LONG    0                                               'color table pointer (maybe) NOT USED

'live TV COG signal parameters

two_colors              LONG    $07_04_0A_07                                    'non zero = two color mode and color values
no_burst                LONG    0                                               'non zero = no color burst reference 
no_interlace            LONG    0                                               'non zero = non vertically interlaced screen
border                  LONG    0                                               'blank the border flag






{NOTES:

3192 PLLA / Active Video Line, including porches

2560 PLLA / Visible Video Line is working value right now



VSCL = [PLLA / PIXEL] << 12 + PLLA / WAITVID]

WAITVIDS = 2560 / [PLLA / WAITVID]

640 pixels = 2560 / 640 = 4 PLLA * 16 = 64 / FRAME
640 / 16 = 40 waitvids

}

'Easy color index table 

CLUT
byte byte    $02, $03, $04, $05, $06, $07, $07, $07            'Six intensities
byte byte    $09, $0a, $0b, $0c, $0d, $0e, $88, $9f
byte byte    $19, $1a, $1b, $1c, $1d, $1e, $98, $af            '16 Hues
byte byte    $29, $2a, $2b, $2c, $2d, $2e, $a8, $bf
byte byte    $39, $3a, $3b, $3c, $3d, $3e, $b8, $cf
byte byte    $49, $4a, $4b, $4c, $4d, $4e, $c8, $df
byte byte    $59, $5a, $5b, $5c, $5d, $5e, $d8, $ef            'High saturation colors, placed
byte byte    $69, $6a, $6b, $6c, $6d, $6e, $e8, $ff            'in table by closest hue match.
byte byte    $79, $7a, $7b, $7c, $7d, $7e, $f8, $0f
byte byte    $89, $8a, $8b, $8c, $8d, $8e, $08, $1f            'Hues are presented in this table
byte byte    $99, $9a, $9b, $9c, $9d, $9e, $18, $2f            'vertically, in sequence as shown
byte byte    $a9, $aa, $ab, $ac, $ad, $ae, $28, $3f            'in screenie below.
byte byte    $b9, $ba, $bb, $bc, $bd, $be, $38, $4f
byte byte    $c9, $ca, $cb, $cc, $cd, $ce, $48, $5f            'Start with intensity on left, and
byte byte    $d9, $da, $db, $dc, $dd, $de, $58, $6f            'work to the right, starting at
byte byte    $e9, $ea, $eb, $ec, $ed, $ee, $68, $7f            'top of table.
byte byte    $f9, $fa, $fb, $fc, $fd, $fe, $78, $8f

              