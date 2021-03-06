{{
─────────────────────────────────────────────────
File: CMUCamera2.spin
Version: 2.0
Copyright (c) 2014 Joe Lucia
See end of file for terms of use.

Author: Joe Lucia                                      
─────────────────────────────────────────────────

CMU Camera Object v2.0.2014 for CMUCam2
based on my CMUCamera.spin for original CMUCam

http://irobotcreate.googlepages.com
2joester@gmail.com

Uses 2 cogs, one for Extended_FDSerial and one for This object to process the camera data.

Features:
  TrackWindow   - tracks mean color in the center of the camera view 
  TrackColor    - tracks a color of your choice
  FrameDifferencing - track changes between a loaded frame and the current view (motion detection)
  Statistics - access mean colors and deviations with tracking data 

5/8/2012 - made some updates for frame differencing and S packet handling
1/2014 - updates and fixes
}}


{
Example:

pub main ' press 1 to track Window, press 2 to track Color
  debug.start(debug_rxpin, debug_txpin, 0, 57600)
  cam.start(CAMERARXPIN, CAMERATXPIN, CAMERABAUD)

  repeat
    if (c := debug.rxcheck) => 0
      if c=="1"
        cam.TrackWindow
        debug.str(string("Tracking Window"))
      elseif c=="2"
        cam.TrackColor(220, 240, 220, 240, 220, 240)
        debug.str(string("Tracking White Color"))

    if (cam.mmxvalue <> lastmx) or (cam.mmyvalue <> lastmy) and (cam.mconfidencevalue>0)
      debug.tx(0)  ' goto 0,0
      debug.str(string("Middle X="))
      debug.dec(cam.mmxvalue)
      debug.str(string("  Y="))
      debug.dec(cam.mmyvalue)
      lastmx := cam.mmxvalue
      lastmy := cam.mmyvalue
      debug.str(string("  C="))
      debug.dec(cam.mconfidencevalue)
}


OBJ
  ser   : "FullDuplexSerial"

CON
  FRAMEBUF_SIZE  = 2000

VAR
  byte  RXPIN, TXPIN
  long  BAUDRATE

  long stk[100]

  byte cog
  long includePanTilt ' pan/tilt data included in T packet


  long FrameDumpBufStart
  long FrameDumpBufEnd
  long _isDataAvailable
  long _isTracking

  byte Mmx, Mmy, MConfidence    ' color tracking middle mass
  byte Mx1, My1, Mx2, My2       ' bounding box of color tracking
  byte  MPan, MTilt             ' servo positions after auto-tracking

  byte  LMType, LMMode
  byte LastCommand ' 0=none, 1=TrackColor, 2=GetMean, 3=GetDiff, 4=FrameDump, 5=GetHisto
  
  byte Rmean, Gmean, Bmean, Rdeviation, Gdeviation, Bdeviation

  long  gotPrompt
  
pub Start(_rxpin, _txpin, _baudrate)                    '' Start the cogs
  Stop

  RXPIN := _rxpin
  TXPIN := _txpin
  BAUDRATE := _baudrate
  
  return (cog := cognew(ProcessCamera, @stk)+1)
  
pub Stop                                                '' Stop the cogs
  if cog
    ser.Stop
    cogstop(cog~ - 1)

pri Delay(ms)                                           '' Delay for ms (milliseconds)
  waitcnt(clkfreq/1000*ms+cnt)

pri FrameDumpBuf_insert(b) | ptr                        '' Add a byte to the Frame Dump buffer
  FrameDumpBuf[FrameDumpBufEnd++]:=b
  if FrameDumpBufEnd=>FRAMEBUF_SIZE
    FrameDumpBufEnd:=0
  _isDataAvailable:=true

PRI ProcessCamera | b                                   '' MAIN Camera Data Processing routine

  ser.Start(rxpin, txpin, 0, baudrate)
  'clock.Start

  repeat
    if (b := ser.rx) => 0
      if (_isDumpingFrame<>True) and (b==1)                                         ' START of FRAME DUMP
        FrameDumpBufStart:=FrameDumpBufEnd:=0
        _isTracking:=false
        _isDumpingFrame:=true
        
      if _isDumpingFrame==true
        ' send to calling objects frame dump buffer
        FrameDumpBuf_insert(b)
        if b==3                                         ' END of FRAME DUMP
          _isDumpingFrame:=false
      elseif b==255                                         ' start of packet
        b := ser.rxTime(50)
        if b=="T"                                   '' Middle + Color + Frame Differencing packet
          _isTracking:=true
          '(raw data: FE XX XX XX XX XX XX FD) M 45 56 34 10 15 8 (GM+LineMode Active)
          ' M mx my x1 y1 x2 y2 pixels confidence Pan Tilt\r 
          Mmx := ser.rxTime(50)
          Mmy := ser.rxTime(50)
          Mx1 := ser.rxTime(50)
          My1 := ser.rxTime(50)
          Mx2 := ser.rxTime(50)
          My2 := ser.rxTime(50)
          Mpixels := ser.rxTime(50)
          Mconfidence := ser.rxTime(50)
          ' servo pan position
          if (includePanTilt==true)
            MPan := ser.rxTime(50)
            MTilt := ser.rxTime(50)
        elseif b=="S"                                   '' Statistics
          'S Rmean Gmean Bmean Rdeviation Gdeviation Bdeviation\r
          Rmean := ser.rxTime(50)
          Gmean := ser.rxTime(50)
          Bmean := ser.rxTime(50)
          Rdeviation := ser.rxTime(50)
          Gdeviation := ser.rxTime(50)
          Bdeviation:= ser.rxTime(50) 
        elseif b=="H"                                  '' Histogram
          'H bin0 bin2 bin2 bin3 ... bin26 bin27\r
        elseif b==$AA
          ' LMType=0,LMMode=1 -- binary bitmap terminates with $AA$AA
          ' LMType=2,LMMode=1 -- Frame Differencing binary bitmap
        elseif b==$FE
          ' LMType=0,LMMode=2 -- per-row statistics, terminates with $FD
          ' LMType=1,LMMode=1 -- per-row mean value, ""
          ' LMType=1,LMMode=2 -- per-row mean value and deviation
        elseif b==$FC
          ' LMType=2,LMMode=2 -- Delta Frame Differencing 
          ' LMType=2,LMMode=3 -- bitmap of Stored Image that FrameDifferencing is working with 
                  
      '' TODO: Check LMType and LMMode to see if we have those types of packets available
          
        

CON '' Camera Commands
  fps50 = 0 'default
  fps26 = 1
  fps17 = 2
  fps13 = 3
  fps11 = 4
  fps9  = 5
  fps8  = 6
  fps7  = 7
  fps6  = 8
  fps5  = 10

pub SetIdle
  ' wait for : prompt
  gotPrompt:=false
  repeat 3
    ser.tx(13)
    waitcnt(clkfreq/1000*200+cnt)
      
  ser.rxflush
  
  _isTracking := false
  _isDumpingFrame := false
  FrameDumpBufStart:=FrameDumpBufEnd:=0
  
pub SetBufferMode(isActive)                             '' Set Buffer Mode to 0 for Continuous Frame Reading
  ' Buffer Mode 1 requires ReadFrame to be called to get a fram into memory
  if isActive
    ser.str(string("BM 1",13))
  else
    ser.str(string("BM 0",13))
  delay(500)

pub SetRegister(reg, val)                               '' Set a camera register value
{ Camera Registers:
Common Settings:  
 Register                                               Values     Effect 
  5   Contrast                                          0-255 
  6   Brightness                                        0-255  
  18 Color Mode           
                                                        36     YCrCb*  Auto White Balance On  
                                                        32     YCrCb* Auto White Balance Off
YCrCb Mode maps RGB to CrYCb where Y is illumination of Red and Blue
RGB -> CrYCb
Y=0.59G + 0.31R + 0.11B
Cr=0.713x (R-Y)
Cb=0.564x (B-Y)

                                                        44     RGB  Auto White Balance On                                      
                                                        40     RGB  Auto White Balance Off   (default)  
  17 Clock Speed                 
                                                        0         50 fps   (default)
                                                        1         26 fps
                                                        2         17 fps 
                                                        3         13 fps    
                                                        4         11 fps   
                                                        5         9  fps  
                                                        6         8  fps  
                                                        7         7  fps  
                                                        8         6  fps  
                                                        10        5  fps  
                                                          
  19 Auto Exposure          
                                                        32       Auto Gain Off  
                                                        33       Auto Gain On  (default)
}
  ser.str(string("CR "))
  ser.dec(reg)
  ser.tx(" ")
  ser.dec(val)
  ser.tx(13)
  Delay(500)

pub SetFrameRate(val)                                   '' Set the sample Frame Rate
  '' Set Frame Rate
  SetRegister(17, val)

pub CameraPower(isOn)                                    '' Turn Camer Power On/Off
  setIdle
  if isOn==1
    ser.str(string("CP 1",13))
  else
    ser.str(string("CP 0",13))

pub SetDelayMode(dVal)                                 '' Set Delay Between Characters on Serial Port 0..255
  ser.str(string("DM "))
  ser.dec(dVal)
  ser.tx(13)
  delay(500)

pub SetDownSampleFactors(x_factor,y_factor)             '' Set Down Sampling Factors
  ser.str(string("DS "))
  ser.dec(x_factor)
  ser.tx(" ")
  ser.dec(y_factor)
  ser.tx(13)
  delay(500)

pub SetFrameStreaming(isEnabled)                       '' Set Frame Streaming Mode
  if isEnabled
    ser.str(string("FS 1",13))
  else
    ser.str(string("FS 0",13))
  delay(500)                         

pub GetButtonPress                                     '' Gets button-press value from camera
  ser.str(string("GB",13))
  delay(500)                         

pub GetHistogram(channel)                               '' Gets a Histogram for a channel
  ser.str(string("GH "))
  ser.dec(channel)
  ser.tx(13)
  Delay(500)

pub GetInputs                                          '' Get Input Values from Cameras Inputs
  ser.str(string("GI",13))
  delay(500)                         

pub GetMean                                             '' Gets the Mean Color for the selected window
  ser.str(string("GM",13))
  Delay(500)

pub GetServoPos(servo)                                 '' Get last position of a servo
  setIdle
  ser.str(string("GS "))
  ser.dec(servo)
  ser.tx(13)
  Delay(500)

pub GetTrackedColors                                   '' Gets currently tracked color values
  ser.str(string("GT",13))
  delay(500)

pub GetVersion                                          '' Gets the Software Version of the firmware
  ser.str(string("GV"))
  ser.tx(13)
  ' but we are currently ignoring the response
  Delay(500)


pub GetWindowSise                                       '' Gets the current Virtual Window Values
  ser.str(string("GW",13))
  delay(500)

CON
  hc28Bins = 0
  hc14Bins = 1
  hc7Bins  = 2

pub SetHistogramBins(bins,scale)                        '' Set Histogram # of Bins and Scale
  setIdle
  ser.str(string("HC "))
  ser.dec(bins)
  ser.tx(" ")
  ser.dec(scale)
  ser.tx(13)
  Delay(500)

pub setHiResMode(isHiRes)                               '' Set Hi or Low Res Mode
  setIdle
  if isHiRes
    ser.str(string("HR 1",13))
  else
    ser.str(string("HR 0",13))
    
pub SetHistogramTracking(isEnabled)                    '' Set Histogram Tracking
  setIdle
  if isEnabled
    ser.str(string("HT 1",13))
  else
    ser.str(string("HT 0",13))

pub SetLED0Mode(mode)                                  '' Set LED 0=Off,1=On,2=Auto(LED1)
  setIdle
  ser.str(string("L0 "))
  ser.dec(mode)
  ser.tx(13)
  Delay(500)

pub SetLED1Mode(mode)
  setIdle
  ser.str(string("L1 "))
  ser.dec(mode)
  ser.tx(13)
  Delay(500)
    
'' Frame Differencing
pub SetFrameDifferencingChannel(chRGB)                  '' Set Frame Differencing Channel (0=Red, 1=Green, 2=Blue)
  setIdle
  ser.str(string("DC "))
  ser.dec(chRGB)
  ser.tx(13)
  delay(500)

pub SetHiResFrameDifferencing(isEnabled)                '' Set hiRes Frame Differencing
  setIdle
  if isEnabled
    ser.str(string("HD 1",13))
  else
    ser.str(string("HD 0",13))

pub LoadFrameForDifferencing                      '' Load a new frame for Frame Differencing to compare to
  setIdle
  ser.str(string("LF",13))
  delay(200)
  ser.rxflush

pub GetMaskedFrameDifference(threshold)                '' Get Masked Frame Differenceing (T packet)
  SetRawMode(3)
  ser.str(string("MD "))
  ser.dec(threshold)
  ser.tx(13)
  delay(100)
  ser.rxflush
  _isTracking:=true

pub GetFrameDifference(threshold)                       '' Get a Frame Difference "T packet"
  SetRawMode(3)
  ser.str(string("FD "))
  ser.dec(threshold)
  ser.tx(13)
  delay(100)
  ser.rxflush
  _isTracking:=true

'' End Frame Differencing

pub SetLineMode(type,mode)                        '' Set Line Mode
  ser.str(string("LM "))
  ser.dec(type)
  ser.tx(" ")
  ser.dec(mode)
  ser.tx(13)
  LMType:=type
  LMMode:=mode
  delay(500)

pub SetNoiseFilter(threshold)                           '' Set Noise Filter threshold
  ser.str(string("NF "))
  ser.dec(threshold)
  ser.tx(13)
  Delay(500)

pub SetOutputMask(packet,mask)                          '' Set Output Mask for packets
  ser.str(string("OM "))                                
  ser.dec(packet)                                        
  ser.tx(" ")
  ser.dec(mask)
  ser.tx(13)
  delay(500)
  
{
# Tracking Type Packet
0 Track Color T
1 Get Mean S
2 Frame Difference T
3 Non-tracked packets* T
4 Additional Count Information** T, H
5 Track Color Line Mode 2 T
6 Get Mean Line Modes 1 and 2 S
}

pub EnableStatisticsPackets
  SetOutputMask(1, 255)

pub SetPixelDifferenceMode(isOn)                           '' Set Noise Filter threshold
  ser.str(string("PD "))
  ser.dec(isOn)
  ser.tx(13)
  Delay(500)

pub SetPacketFilteringMode(isOn)                           '' Set Noise Filter threshold
  ser.str(string("PF "))
  ser.dec(isOn)
  ser.tx(13)
  Delay(500)

pub SetPollMode(mode)                                 '' Activates/Disabled Poll Mode
  setIdle
  ser.str(string("PM "))
  ser.dec(mode)
  ser.tx(13)
  Delay(500)

pub SetPacketSkipping(number)                          '' Set Packet Skipping
  ser.str(string("PS "))
  ser.dec(number)
  ser.tx(13)
  delay(500)

pub ReadFrame                                           '' Read New Frame into Buffer
  ser.str(string("RF",13))
  delay(500)

pub SetRawMode(mode)                                    '' Set RawMode for received data
{
bit_flags =  B2 B1 B0 
 
  Bits    
B0    Output from the camera is in raw bytes 
B1    “ACK\r” and “NCK\r” confirmations are suppressed  
B2    Input to the camera is in raw bytes
}
  
  'GetVersion
  setIdle
  ser.rxflush
  ser.str(string("RM "))
  ser.dec(mode)
  ser.tx(13)
  Delay(200)
  ser.rxflush

pub ResetCamera                                          '' Reset Vision Board
  setIdle
  ser.str(string("RS",13))
  LMType:=0
  LMMode:=0
  _isDumpingFrame:=false
  _isTracking := false
  delay(500)

pub DeepSleep                                          '' Puts camera into Deep Sleep Mode
  setIdle
  ser.str(string("SD",13))
  delay(500)

pub DumpFrame(channel)                                 '' Send a Frame to the Serial Port (DumpFrame)
  FrameDumpBufStart:=FrameDumpBufEnd:=0
  _isTracking:=false
  _isDumpingFrame:=true
  ser.rxflush
  ser.str(string("SF "))
  ser.dec(channel)
  ser.tx(13)
  delay(500)

pub Sleep(isActive)                                              '' Put camera to Sleep
  setIdle
  ser.str(string("SL "))
  ser.dec(isActive)
  ser.tx(13)
  delay(500)

pub SetServoMask(flags)                            '' Sets Servo Masks
{bit_flags = B3 B2 B1 B0
B0 Pan Control Enable
B1 Tilt Control Enable
B2 Pan Report Enable
B3 Tilt Report Enable
}
  setIdle
  ser.rxflush

  if (flags>3)
    includePanTilt:=true
  else
    includePanTilt:=false
    
  ser.str(string("SM "))
  ser.dec(flags)
  ser.tx(13)
  Delay(2000)

pub SetServoLevel(servo,level)                         '' Set a Servo voltage level 1=high,0=low
  setIdle
  ser.str(string("SO "))
  ser.dec(servo)
  ser.tx(" ")
  ser.dec(level)
  ser.tx(13)
  delay(500)

pub SetServoParameters(panRangeFar,panRangeNear,panStep,tiltRangeFar,tiltRangeNear,tiltStep)  '' Set Servo Params
  setIdle
  ser.str(string("SP "))
  ser.dec(panRangeFar)
  ser.tx(" ")
  ser.dec(panRangeNear)
  ser.tx(" ")
  ser.dec(panStep)
  ser.tx(" ")
  ser.dec(tiltRangeFar)
  ser.tx(" ")
  ser.dec(tiltRangeNear)
  ser.tx(" ")
  ser.dec(tiltStep)
  ser.tx(" ")
  ser.tx(13)
  delay(500)

pub SetTrackingColors(rmin, rmax, gmin, gmax, bmin, bmax)      '' Set Colors for Track MiddleMass of specific color
  setIdle
  ser.str(string("ST "))
  ser.dec(rmin)
  ser.tx(" ")
  ser.dec(rmax)
  ser.tx(" ")
  ser.dec(gmin)
  ser.tx(" ")
  ser.dec(gmax)
  ser.tx(" ")
  ser.dec(bmin)
  ser.tx(" ")
  ser.dec(bmax)
  ser.tx(" ")
  ser.tx(13)
  Delay(300)

 
pub SetServoPosition(servo,position)                         '' Set a Servo Position
  setIdle
  ser.str(string("SV "))
  ser.dec(servo)
  ser.tx(" ")
  ser.dec(position)
  ser.tx(13)
  delay(500)

pub TrackColor(rmin, rmax, gmin, gmax, bmin, bmax)      '' Track MiddleMass of specific color
  setIdle
  SetRawMode(3)
  ser.rxflush
  ser.str(string("TC "))
  ser.dec(rmin)
  ser.tx(" ")
  ser.dec(rmax)
  ser.tx(" ")
  ser.dec(gmin)
  ser.tx(" ")
  ser.dec(gmax)
  ser.tx(" ")
  ser.dec(bmin)
  ser.tx(" ")
  ser.dec(bmax)
  ser.tx(" ")
  ser.tx(13)
  Delay(300)
  ser.rxflush

  _isTracking:=true

pub SetTrackInverted(isOn)                        '' Set Track Inverted Mode (0 or 1)
  setIdle
  ser.str(string("TI "))
  ser.dec(isOn)
  ser.tx(13)
  delay(500)
  
pub TrackWindow                                         '' Track MiddleMass of camera views mean center color
  setIdle
  SetRawMode(3)
  ser.rxflush
  ser.str(string("TW"))
  ser.tx(13)
  Delay(300)
  ser.rxflush

  _isTracking:=true
  
pub SetWindow(x1, y1, x2, y2)                           '' Set the window for dump or middle mass
  setIdle
  _isTracking := false

  ser.str(string("VW "))
  ser.dec(x1)
  ser.tx(" ")
  ser.dec(y1)
  ser.tx(" ")
  ser.dec(x2)
  ser.tx(" ")
  ser.dec(y2)
  ser.tx(13)
  Delay(500)


CON '' Public Camera Data
  
PUB FrameDumpBuf_get                                    '' Get the next buffered byte and update pointer
  if FrameDumpBufStart==FrameDumpBufEnd
    return 3 ' force end-of-frame marker
  result := FrameDumpBuf[FrameDumpBufStart++]
  if FrameDumpBufStart=>FRAMEBUF_SIZE
    FrameDumpBufStart:=0
  _isDataAvailable := (FrameDumpBufStart<>FrameDumpBufEnd)

pub PanValue
  return MPan
  
pub TiltValue
  return MTilt

pub MmxValue                                            '' return X coordinate of Middle of tracked color
  return Mmx

pub MmyValue                                            '' return Y coordinate of Middle of tracked color
  return Mmy

pub MconfidenceValue                                    '' return Confidence of tracked color
  return Mconfidence

pub isTracking                                          '' indicates we are currently tracking a color
  return _isTracking

pub isDataAvailable
  return _isDataAvailable

pub GetMmBox(bytearray_ptr)
  byte[bytearray_ptr] := mx1
  byte[bytearray_ptr][1] := my1
  byte[bytearray_ptr][2] := mx2
  byte[bytearray_ptr][3] := my2  

DAT

_isDumpingFrame         long    false

FrameDumpBuf            byte    0 [FRAMEBUF_SIZE]

Mpixels       byte

'' Update 12/2011 for serverbot LIFT
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
