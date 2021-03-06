{{*********** Public Notes ********************

  ddwd_PS2ControllerV10

  Modified from Juan Carlos Orozco's PS2_Controller.
  by Duane Degn, April 23, 2012
  (see date code in name for latest update date.
  two digit year, two digit month, two digit day
  followed by version letter (for that day))
  

  The modified version of this driver allows the
  controller to be changed between analog and
  digital modes by software.  The modes may be
  locked.

  The ability to read the analog pressures
  of the buttons was also added.
  
  The data is written directly to variables in the
  parent object.

  A pointer to a group of seven longs is passed to
  the Start method.  A pointer to a group of 34
  bytes is also passed.

  These pointers are used by the object to fill
  the variables with processed data from the
  PlayStation 2 controller.

  The separation of the various data elements occurs
  within the PASM section of the code.  This allows
  for very frequent updating of joysticks and button
  states.

  The bits representing the button states are ordered
  differently than the bytes measuring the pressure of
  the analog buttons.  The program uses the same button
  order for both the digital buttons and the analog
  readings from those buttons.

  This reordering of the pressure data should make it
  easier to use with the digital button data.

  The button states are reported three different ways.

  The state of all 16 buttons are written to a long with
  each button being represented by one bit.  A low value
  it the button's bit position indicates a button press.

  The second set of button data is an array of 16 bytes.
  The normal state of these bytes is zero.  A button
  press with cause a one to be written to the corresponding
  byte.

  The third set of button data is held in a 12 byte array.
  The bytes in this array contain the pressure reading
  for each button.  These reading vary from zero (for
  no pressure) to 255 (full pressure).

  The four analog joystick values are written from the
  PASM portion of the program so these values are
  updated automatically.

  There is also a byte to hold the mode the controller
  is in and a final byte to hold the number of 16-bit
  words (after the header) returned by the controller.

  The raw data is also written to the hub.  This data
  can make transmitting the all the contoller information
  easier. 

  I used different connections than Juan Carlos suggests.
  I power the controller with 3.3V.  I have a 10K pull-up
  resistor on the DAT line but not any on the others.
  I also don't any series resistors on any of the lines.

  I still hope to add a "lock" feature to lock the
  controller in analog or digital mode.

  I also want to add support for the Dual Shock
  motors.  I don't have the motor wired for power
  on my controller yet.


}}
{{
  Play Station 2 Controller driver v1.0

  Author: Juan Carlos Orozco
  Copyright (c) 2007 Juan Carlos Orozco ACELAB LLC
  http://www.acelab.com
  Industrial Automation

  License: See end of file for terms of use.
  
  Use the Sony Playstation Controller Cable (adapter) from LynxMotion
  http://www.lynxmotion.com/Product.aspx?productID=73&CategoryID=

  Connect DAT, CMD, SEL, CLK signals to four consecutive pins of the propeller
  DAT should be the lowest pin. Use this pin when calling Start(first_pin)
  DAT (Brown), CMD (Orange), SEL (Blue) and CLK (Black or White)
  Use a 1K resistor from Propeller output to each controller pin.
  Use a 10K pullup to 5V for DAT pin. 

  Conect Power 5V (Yellow) and Gnd (Red covered with black)

  Digital buttons:

  get_Data1 $FFFFFFFF

  From Left To Right Byte
  Byte 0: $41 Digital, $73 Analog
  Byte 1: $5A Wired MadCatz (Maybe type of controller)
  Byte 2: <, v, >, ^, Start, R3, L3, Select (Note that this cursors are also activated by the left joystick if in digital mode)  
  Byte 4: Square, Cross, Circle, Triangle, R1, L1, R2, L2
  All bytes from bit 7 to bit 0. Digital data is inverted (1 button not pressed, 0 pressed)
  
  See PS2_Controller_Serial_demo for a use example of this object.
}}

CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000
  PULSE_HIGH_US = 5
  PULSE_LOW_US = 5
  DELAY_US = 20 'Delay between communication bytes

  _NumberOfControllerButtons = 16
  _NumberOfAnalogButtons = 12
  
  ' command enumeration
  #0, _StreamData, _ConfigAnalog, _ConfigDigital, _AnalogButtons

  ' debug message enumeration
  #0, _StayDigital, _ToDigital, _StayAnalog, _ToAnalog, _OnAnalogButtons, _OffAnalogButtons

    ' PlayStation 2 button enumeration (not used by program, here to show order data is stored in RAM)
  #0, _SquarePs2, _CrossPs2, _CirclePs2, _TrianglePs2, { 0 - 3
    } _R1Ps2, _L1Ps2, _R2Ps2, _L2Ps2, { 4 - 7
    } _LeftArrowPs2, _DownArrowPs2, _RightArrowPs2, _UpArrowPs2, { 8 - 11
    } _StartPs2, _RightJoystickPs2, _LeftJoystickPs2, _SelectPs2' 12 - 15

  
VAR
  'Communication between object and new cog. Each variable is ofseted 4 bytes from the address passed as PAR
  long first_pin
  long Pulse_High_Ticks
  long Pulse_Low_Ticks
  long Delay_Ticks
  long Delay_Requests_Ticks
  
  'Normal variables
  long Cog
  long Command, subCommand

PUB Start(firstpin, delay_requests_us, longPtr, bytePtr) : ok
'' Start cog to read the PS2 Controller in repeatedly.
'' first_pin: is first pin (DAT) for the 4 consecutive pins of the controller
'' DAT, CMD, SEL, CLK
'' delay_requests_us: Delay between requests poll controller every Ex. 1000 -> 1ms.

  first_pin := firstpin
  
  'Convert time delays to equivalent procesor clock ticks
  Pulse_High_Ticks := PULSE_HIGH_US * (clkfreq / 1000000)
  Pulse_Low_Ticks := PULSE_LOW_US * (clkfreq / 1000000)
  Delay_Ticks := DELAY_US * (clkfreq / 1000000)
  Delay_Requests_Ticks := delay_requests_us * (clkfreq / 1000000)

' below added by dwd
' addresses poked into memory prior to
' launching cog.  Not the "proper" way
' to do this, but it's easier than
' doing it all in PASM.
  ps2Data0Address := longPtr
  longPtr += 4
  ps2Data1Address := longPtr
  longPtr += 4
  ps2Data2Address := longPtr
  longPtr += 4
  ps2Data3Address := longPtr
  longPtr += 4
  ps2Data4Address := longPtr
  longPtr += 4
  allButtonsAddress := longPtr
  longPtr += 4
  debugLongAddress := longPtr
  
  joystickAddress := bytePtr
  bytePtr += 4
  dButtonsAddress := bytePtr    ' digital buttons array
  bytePtr += _NumberOfControllerButtons
  aButtonsAddress := bytePtr    ' analog buttons array
  bytePtr += _NumberOfAnalogButtons
  modeAddress := bytePtr
  bytePtr += 1
  dataSizeAddress := bytePtr          
  
  
  commandPtr := @command
  'subCommandPtr := @subCommand  ' to be used to add "lock" feature
' End of code added by dwd
  
  'If cog already executing stop it first.
  Stop
  'Call cog
  'TODO If Cog stop cog, add Stop function
  Cog := cognew(@Wave, @first_pin)+1
  ok := Cog

PUB Stop
  ''Stop cog
' This method by Juan Carlos
  'TODO reset dira for output pins. (Free pins)
' dwd pins should return to inputs automatically when cog is stopped
  if cog
    cogstop(cog~ - 1)

PUB Analog
'' Puts the controller in to analog mode.
'' The buttons will be in digital mode still.
'' Two longs are read from controller the
'' second long contains analog joystic information.
' Added by dwd

  command := _ConfigAnalog
  repeat while command
  
PUB Digital
'' Puts the controller in to digital mode.
'' Turns off analog buttons.
'' Two longs are read from controller but only
'' one of the longs contain useful data.
'' The joystick buttons don't register in
'' digital mode.
' Added by dwd

  command := _ConfigDigital
  repeat while command
  
PUB AnalogButtons
'' Causes the controller to start outputting
'' the button pressure information
'' The button pressure information is only available
'' in analog mode.  This method will make sure
'' the controller is in analog mode prior to
'' turning on the analog button feature.
'' A total of five longs are read from controller.
'' The three additional long contains analog button
'' information.  The analog information is written
'' to hub RAM in the same order as the digital
'' button information.
' Added by dwd

  Analog  ' Make sure controller is in analog mode.

' Some delay is required after contoller is in analog mode
' prior to turning on the analog buttons.
' I don't know how long this delay needs to be.
  waitcnt(clkfreq / 100 + cnt)
   
  command := _AnalogButtons
  repeat while command
  
DAT
                        org     0
Wave
                        mov     t1, par                 ' Set all pin masks
                        rdlong  t2, t1
                        mov     dat_mask, #1
                        shl     dat_mask, t2

                        mov     cmd_mask, dat_mask
                        shl     cmd_mask, #1

                        mov     sel_mask, dat_mask
                        shl     sel_mask, #2

                        mov     clk_mask, dat_mask
                        shl     clk_mask, #3

                        mov     t1, par
                        add     t1, #4
                        rdlong  high_t, t1 'Pulse_High_Ticks

                        mov     t1, par
                        add     t1, #8   'Pulse_Low_Ticks
                        rdlong  low_t, t1

                        mov     t1, par
                        add     t1, #12   'Delay_Ticks
                        rdlong  delay_t, t1

                        mov     t1, par
                        add     t1, #16  'Delay_Requests_Ticks
                        rdlong  delay_rq_t, t1

                        mov     pentaReadFlag, #0       ' start with short reads dwd
                        
                        mov     dira, cmd_mask
                        or      dira, sel_mask
                        or      dira, clk_mask

                        'Set clock to high
                        or      outa, clk_mask
                        or      outa, sel_mask
preloop                 wrlong  zero, commandPtr      ' Start of major change in PASM by dwd                  
mainLoop
                        'Delay between each controller POLL.
                        ' Wait Long delay (Maybe 1 milisecond)
                        mov     Time, cnt
                        add     Time, delay_rq_t
                        waitcnt Time, high_t
                        rdlong  cogCommand, commandPtr
                        add     cogCommand, #jumpTable
                        jmp     cogCommand

jumpTable               jmp     #normalRead
                        jmp     #configAnalog
                        jmp     #configDigital
                        jmp     #configAnalogButtons

'-------------------------------------------------------------------------------
                        
normalRead              tjnz    pentaReadFlag, #pentaRead

smallRead               mov     tx_data0, readController
                        mov     tx_data1, zero
                        call    #doubleTxRx                        
                        wrlong  data0, ps2Data0Address
                        wrlong  data1, ps2Data1Address

                        mov     t1, data0
                        and     t1, #$F          ' just keept he last four bits
                        wrbyte  t1, dataSizeAddress
                        mov     t1, data0
                        shr     t1, #4                                            
                        and     t1, #$F          ' just keept he last four bits
                        wrbyte  t1, modeAddress

                        mov     t1, data0
                        shr     t1, #16                                            
                        wrlong  t1, allButtonsAddress

                        mov     addressTemp, dButtonsAddress                         
                        call    #bitsToBytes
                        
                        mov     addressTemp, joystickAddress
                        mov     t1, data1
                        call    #longToBytes    ' joystick data     
                        
                        jmp     #mainLoop

'-------------------------------------------------------------------------------
                        
pentaRead               mov     tx_data0, readController
                        mov     tx_data1, zero
                        call    #pentaTxRx                        
                        wrlong  data0, ps2Data0Address
                        wrlong  data1, ps2Data1Address
                        wrlong  data2, ps2Data2Address
                        wrlong  data3, ps2Data3Address 
                        wrlong  data4, ps2Data4Address 

                        mov     t1, data0
                        and     t1, #$F          ' just keept he last four bits
                        wrbyte  t1, dataSizeAddress
                        mov     t1, data0
                        shr     t1, #4                                            
                        and     t1, #$F          ' just keept he last four bits
                        wrbyte  t1, modeAddress
                        
                        mov     t1, data0
                        shr     t1, #16                                            
                        wrlong  t1, allButtonsAddress
                        
                        mov     addressTemp, dButtonsAddress                         
                        call    #bitsToBytes
                        
                        mov     addressTemp, joystickAddress
                        mov     t1, data1
                        call    #longToBytes    ' joystick data
                                               
                        mov     addressTemp, aButtonsAddress
                        
                        mov     t1, data3
                        call    #longToBytesRev
                        mov     t1, data4
                        call    #longToBytesLR
                        mov     t1, data2
                        call    #longToBytesArrows
                        
                        jmp     #mainLoop

'-------------------------------------------------------------------------------

bitsToBytes             mov     t2, #_NumberOfControllerButtons
                        shl     t1, #16
:Bit                    shl     t1, #1 wc   ' shift off the bit to write
                        mov     t3, #0
                        muxc    t3, #1              ' make t3 either one or zero
                        xor     t3, #1          ' make zeros ones and visaversa
                        wrbyte  t3, addressTemp
                        add     addressTemp, #1
                        djnz    t2, #:Bit
bitsToBytes_ret         ret

'-------------------------------------------------------------------------------

longToBytes             mov     t2, #4
                        
:Byte                   wrbyte  t1, addressTemp
                        shr     t1, #8
                        add     addressTemp, #1
                        djnz    t2, #:Byte
longToBytes_ret         ret

'-------------------------------------------------------------------------------
' only one long has all the analog buttons in the same order as
' the digital buttons.  So the three other longs need to be reordered
' so the analog buttons will be in the same order as the digital buttons.

longToBytesRev          mov     t2, #4
                        rol     t1, #8          ' make last byte first
:Byte                   wrbyte  t1, addressTemp
                        rol     t1, #8
                        add     addressTemp, #1
                        djnz    t2, #:Byte
longToBytesRev_ret      ret

'-------------------------------------------------------------------------------

longToBytesLR           ror     t1, #8          ' make second byte first
                        wrbyte  t1, addressTemp
                        add     addressTemp, #1
                        rol     t1, #8          
                        wrbyte  t1, addressTemp
                        add     addressTemp, #1
                        rol     t1, #8          
                        wrbyte  t1, addressTemp
                        add     addressTemp, #1
                        rol     t1, #8          
                        wrbyte  t1, addressTemp
                        add     addressTemp, #1
                        
longToBytesLR_ret       ret

'-------------------------------------------------------------------------------

longToBytesArrows       ror     t1, #8          ' make second byte first
                        wrbyte  t1, addressTemp
                        add     addressTemp, #1
                        rol     t1, #16          
                        wrbyte  t1, addressTemp
                        add     addressTemp, #1
                        ror     t1, #8          
                        wrbyte  t1, addressTemp
                        add     addressTemp, #1
                        rol     t1, #16          
                        wrbyte  t1, addressTemp
                        add     addressTemp, #1
                        
longToBytesArrows_ret   ret

'-------------------------------------------------------------------------------
                        
doubleTxRx              andn    outa, sel_mask  ' This section is similar to Juan Calos' original

                        ' Wait 20 us delay
                        mov     Time, cnt
                        add     Time, delay_t
                        waitcnt Time, low_t
      
                        
                        mov     tx_data, #$01
                        call    #txrx
                        
                        mov     tx_data, tx_data0
                        call    #txrx
                        call    #txrx
                        call    #txrx
                        call    #txrx      
                        mov     data0, rx_data
                                                
                        mov     tx_data, tx_data1
                        call    #txrx
                        call    #txrx
                        call    #txrx
                        call    #txrx  
                        mov     data1, rx_data
                      
                        or      outa, sel_mask                        
doubleTxRx_ret          ret

'-------------------------------------------------------------------------------
' This section was added by dwd.  The beginning of this section is similar
' to Juan Calos' original

pentaTxRx               andn    outa, sel_mask

                        ' Wait 20 us delay
                        mov     Time, cnt
                        add     Time, delay_t
                        waitcnt Time, low_t
      
                        
                        mov     tx_data, #$01
                        call    #txrx
                        
                        mov     tx_data, tx_data0
                        call    #txrx
                        call    #txrx
                        call    #txrx
                        call    #txrx      
                        mov     data0, rx_data
                                                
                        mov     tx_data, tx_data1 ' all the remain tx data is the same (zero)
                        call    #txrx
                        call    #txrx
                        call    #txrx
                        call    #txrx  
                        mov     data1, rx_data

                        call    #txrx
                        call    #txrx
                        call    #txrx
                        call    #txrx  
                        mov     data2, rx_data

                        call    #txrx
                        call    #txrx
                        call    #txrx
                        call    #txrx  
                        mov     data3, rx_data
                      
                        call    #txrx
                        call    #txrx
                        call    #txrx
                        call    #txrx  
                        mov     data4, rx_data

                        or      outa, sel_mask                        
pentaTxRx_ret           ret

'-------------------------------------------------------------------------------
' Added by dwd

configAnalog            call    #configAnalogSub
                        jmp     #preLoop
                        
configAnalogSub         mov     t1, data0
                        and     t1, deviceModeNibble    
                        xor     t1, analogMode          ' check to see if it's in analog mode already
                                       
                        mov     t2, #_StayAnalog
                        wrlong  t2, debugLongAddress
                        
                        tjz     t1, #configAnalogSub_ret ' all ready in analog mode
                        
                        mov     tx_data0, enterConfig
                        mov     tx_data1, zero
                        call    #doubleTxRx

                        mov     Time, cnt
                        add     Time, delay_t
                        waitcnt Time, low_t

                        mov     tx_data0, changeToAnalog
                        mov     tx_data1, zero
                        call    #doubleTxRx

                        mov     Time, cnt
                        add     Time, delay_t
                        waitcnt Time, low_t

                        mov     tx_data0, exitConfig
                        mov     tx_data1, zero
                        call    #doubleTxRx

                        mov     t2, #_ToAnalog
                        wrlong  t2, debugLongAddress
configAnalogSub_ret     ret                        

                        

'-------------------------------------------------------------------------------
                        
configDigital           mov     t1, data1
                        and     t1, deviceModeNibble    
                        xor     t1, digitalMode          ' check to see if it's in digital mode already

                        mov     t2, #_StayDigital
                        wrlong  t2, debugLongAddress
                                           
                        tjz     t1, #preLoop
                        
                        mov     tx_data0, enterConfig
                        mov     tx_data1, zero
                        call    #doubleTxRx

                        mov     Time, cnt
                        add     Time, delay_t
                        waitcnt Time, low_t

                        mov     tx_data0, changeToDigital
                        mov     tx_data1, zero
                        call    #doubleTxRx

                        mov     Time, cnt
                        add     Time, delay_t
                        waitcnt Time, low_t

                        mov     tx_data0, exitConfig
                        mov     tx_data1, zero
                        call    #doubleTxRx

                        mov     t2, #_ToDigital
                        wrlong  t2, debugLongAddress
                        
                        mov     pentaReadFlag, #0  ' analog buttons are now off
                                                   ' use smallRead
                        jmp     #preLoop

'-------------------------------------------------------------------------------

configAnalogButtons     mov     tx_data0, enterConfig
                        mov     tx_data1, zero
                        call    #doubleTxRx
                 
                        mov     Time, cnt
                        add     Time, delay_t
                        waitcnt Time, low_t

                        mov     tx_data0, analogButtons0
                        mov     tx_data1, analogButtons1
                        call    #doubleTxRx
                      
                        mov     Time, cnt
                        add     Time, delay_t
                        waitcnt Time, low_t

                        mov     tx_data0, exitConfig
                        mov     tx_data1, zero
                        call    #doubleTxRx

                        mov     pentaReadFlag, #1       ' use long reads now (pentaRead)             
                        
                        mov     t2, #_OnAnalogButtons
                        wrlong  t2, debugLongAddress
                        

                        jmp     #preLoop
                        
'-------------------------------------------------------------------------------
' Most of this section is by Juan Carlos
                     
txrx                    
                        mov     t1, #8 

                        ' Wait 20 us delay
                        mov     Time, cnt
                        add     Time, delay_t
                        waitcnt Time, low_t
                        
:bit
                        test    tx_data, #1 wc
                        muxc    outa, cmd_mask          ' Write tx_data[0]
                        ror     tx_data, #1             ' Shift out tx_data[0]
                        
                        andn    outa, clk_mask          ' dwd
                        waitcnt Time, high_t
                        or      outa, clk_mask
                        test    dat_mask, ina wc        ' Read CMD bit                        
                        rcr     rx_data, #1             ' Shift into rx_data[31]
                        waitcnt Time, low_t
                        djnz    t1, #:bit               ' Next bit...
txrx_ret                ret

'-------------------------------------------------------------------------------

zero                    long    0
ps2Data0Address         long    0
ps2Data1Address         long    0
ps2Data2Address         long    0
ps2Data3Address         long    0
ps2Data4Address         long    0
allButtonsAddress       long    0
debugLongAddress        long    0
joystickAddress         long    0
dButtonsAddress         long    0
aButtonsAddress         long    0
modeAddress             long    0
dataSizeAddress         long    0
commandPtr              long    0
'subCommandPtr           long    0    ' not used yet
deviceModeNibble        long    $F0
analogMode              long    $70
digitalMode             long    $40
readController          long    $42 
enterConfig             long    $010043
exitConfig              long    $43
changeToAnalog          long    $010044
lockToAnalog            long    $03010044
changeToDigital         long    $44
lockToDigital           long    $03000044
analogButtons0          long    $FFFF004F
analogButtons1          long    $03

addressTemp             res     1
pentaReadFlag           res     1
tx_data0                res     1
tx_data1                res     1
cogCommand              res     1                     
dat_mask                res     1
cmd_mask                res     1
sel_mask                res     1
clk_mask                res     1

Time                    res     1
t1                      res     1     'Temp variable
t2                      res     1     'Temp variable
t3                      res     1
low_t                   res     1
high_t                  res     1
delay_t                 res     1
delay_rq_t              res     1
tx_data                 res     1
rx_data                 res     1
data0                   res     1
data1                   res     1
data2                   res     1
data3                   res     1
data4                   res     1

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