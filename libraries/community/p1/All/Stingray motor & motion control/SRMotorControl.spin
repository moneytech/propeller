' File: SRMotorControl.spin  
''┌────────────────────────────────────┐
''│  Stingray motor/motion control     │
''│  Author: Nico Schoemaker           │
''│  Copyright(c) 2010 Nico Schoemaker │
''│  See end of file for terms of use. │
''└────────────────────────────────────┘
''
''A motor/motion control object to be used with the Stingray robot.
''The object is written in SPIN and PASM, and doesnt use other objects.
''To control the motors the object generates a 1Khz PWM signal.
''The PASM code doesnt make use of counters to generate the PWM signal.
''Counters are reserved for future versions to support wheel/motor encoders.
''
''Requires a clock setting of 80Mhz:
''  _xinfreq = 5_000_000
''  _clkmode = xtal1 + pll16x
'' 
''┌────────────────────────────────────┐
''│Revision History:                   │ 
''│03/04/10 - Initial release V1.0     │
''└────────────────────────────────────┘ 


CON
  _xinfreq = 5_000_000
  _clkmode = xtal1 + pll16x


VAR
  long  vCog
  long  vPeriodTicks
  long  vCommand                'Command is made up of four bytes, byte 0 = bit 1 to update the cog. byte 1 = LeftSpeed, byte 2 = RightSpeed, byte 3 = ramping delay

PUB Start: ok

''Starts the 1Khz PWM control in a seperate cog.

  Stop
  vPeriodTicks := clkfreq / 1000                        
  ok := (vCog := cognew(@init, @vPeriodTicks) +1 )

PUB Stop

''Removes the 1Khz PWM control from the cog.

  if vCog
    cogstop(vCog~ -1)

  vCommand := 0    


PUB SetRamp(Delay)

''Sets the ramping delay, default no ramping is used.
''Allowed delay values: 0..10
''When setting a speed from 0 to 100 it takes aprox 1 sec. to reach the full speed(100) with a ramping delay of 10
''When moving from forward with a speed of 100 to backward with a speed of 100 will take aprox 2 sec. with a ramping delay of 10
''Increase the ramping delay for a more smooth movement, decrease for a more snappy movement.
''Ramping is turned of with a delay of 0

  repeat until vCommand.byte[0] == 0                   'Wait until current getCommand is processed by the cog

  Delay <#= 10                                          'Limit Ramp to 0..10
  Delay #>= 0

  vCommand.byte[3] := Delay                            'Set ramp delay, dont update cog  
  
PUB MoveForward(Speed)

''Moves the Stingray forward with the given speed, using ramping if set.(See the SetRamp(Delay) method)
''Allowed speed values: 0..100
''A value of 0 will stop the stingray using ramping if set.For a emergency stop use the Break() method

  repeat until vCommand.byte[0] == 0                   'Wait until current getCommand is processed by the cog 

  Speed <#= 100                                        'Limit Speed to 0..100
  Speed #>= 0
   
  vCommand.byte[1] := Speed                            'Set leftspeed to Speed
  vCommand.byte[2] := vCommand.byte[1]                 'Set rightspeed to leftspeed
  vCommand.byte[0] := 1                                'Update flag

PUB MoveBackward(Speed)

''Moves the Stingray backward with the given speed, using ramping if set.(See the SetRamp(Delay) method)
''Allowed speed values: 0..100
''A value of 0 will stop the stingray using ramping if set.For a emergency stop use the Break() method

   repeat until vCommand.byte[0] == 0                   'Wait until current getCommand is processed by the cog

   Speed <#= 100                                        'Limit Speed to 0..100
   Speed #>= 0

   vCommand.byte[1] := -Speed                           'Set leftspeed to neg. Speed 
   vCommand.byte[2] := vCommand.byte[1]                 'Set rightspeed to leftspeed
   vCommand.byte[0] := 1                                'Update flag

PUB Break | oldRamp

''Stops the Stingray immediately without ramping

  repeat until vCommand.byte[0] == 0                   'Wait until current getCommand is processed by the cog

  oldRamp := vCommand.byte[3]
  SetRamp(0)
  MoveForward(0)
  SetRamp(oldRamp)
  
PUB TurnCCW(Speed)

''Turns the Stingray counterclockwise with the given speed, using ramping if set.(See the SetRamp(Delay) method)
''Allowed speed values: 0..100
''The left wheel of the stingray will be stopped.
''The right wheel will rotate forward with the given speed.
''A value of 0 will stop the stingray using ramping if set.For a emergency stop use the Break() method

  repeat until vCommand.byte[0] == 0                   'Wait until current getCommand is processed by the cog

  Speed <#= 100                                        'Limit Speed to 0..100
  Speed #>= 0
   
  vCommand.byte[1] := 0                                'Set leftspeed to 0 
  vCommand.byte[2] := Speed                            'Set rightspeed to Speed
  vCommand.byte[0] := 1                                'Update flag

PUB RotateCCW(Speed)

''Rotates the Stingray counterclockwise with the given speed, using ramping if set.(See the SetRamp(Delay) method)
''Allowed speed values: 0..100
''The left wheel will rotate backward with the given speed.
''The right wheel will rotate forward with the given speed.
''A value of 0 will stop the stingray using ramping if set.For a emergency stop use the Break() method

  if Speed == 0
    MoveForward(0)

  repeat until vCommand.byte[0] == 0                   'Wait until current getCommand is processed by the cog

  Speed <#= 100                                        'Limit Speed to 0..100
  Speed #>= 0
   
  vCommand.byte[1] := -Speed                           'Set leftspeed to neg. Speed 
  vCommand.byte[2] := Speed                            'Set rightspeed to pos. Speed
  vCommand.byte[0] := 1                                'Update flag

PUB TurnCW(Speed)

''Turns the Stingray clockwise with the given speed, using ramping if set.(See the SetRamp(Delay) method)
''Allowed speed values: 0..100
''The left wheel will rotate forward with the given speed.
''The right wheel of the stingray will be stopped.
''A value of 0 will stop the stingray using ramping if set.For a emergency stop use the Break() method


  repeat until vCommand.byte[0] == 0                   'Wait until current getCommand is processed by the cog

  Speed <#= 100                                        'Limit Speed to 0..100
  Speed #>= 0
   
  vCommand.byte[1] := Speed                            'Set leftspeed to Speed 
  vCommand.byte[2] := 0                                'Set rightspeed to 0
  vCommand.byte[0] := 1                                'Update flag

PUB RotateCW(Speed)

''Rotates the Stingray clockwise with the given speed, using ramping if set.(See the SetRamp(Delay) method)
''Allowed speed values: 0..100
''The left wheel will rotate forward with the given speed.
''The right wheel will rotate backward with the given speed.
''A value of 0 will stop the stingray using ramping if set.For a emergency stop use the Break() method

  if Speed == 0
    MoveForward(0)

  repeat until vCommand.byte[0] == 0                   'Wait until current getCommand is processed by the cog

  Speed <#= 100                                        'Limit Speed to 0..100
  Speed #>= 0
   
  vCommand.byte[1] := Speed                            'Set leftspeed to pos. Speed 
  vCommand.byte[2] := -Speed                           'Set rightspeed to neg. Speed
  vCommand.byte[0] := 1                                'Update flag

DAT
              org   0

init
              movi      dira, #%11110                   'Set bit 24..27 of dira to output 
              movi       outa,#%00000                   'Set output pin 24..27 to 0
               
              rdlong    _sliceDuration, par             'Read the clockticks of one period
              mov       _r1, #100                       'Set _r1 to divider of 100
              shl       _r1, #15
              mov       _r2, #16
:divide                                                 'Divide the clockticks of one period by 100 and store result into _sliceDuration
              cmpsub    _sliceDuration, _r1     wc              
              rcl       _sliceDuration, #1
              djnz      _r2, #:divide         
               
              mov       _r1, par
              add       _r1, #4                         'Read the Command parameter address
              mov       _commandAddr, _r1               'Save Command address in _commandAddr

              mov       _speedL, #0                     'Set all speeds to 0
              mov       _speedR, #0   
              mov       _curSpeedL, #0
              mov       _curSpeedR, #0
              mov       _command, #0
              mov       _prevCommand, #0                'Set previous command to 0 = no speed, no ramp and no update                   

              mov       _sliceCount, #100               'Preset the slicecount of one period to 100

              mov       _delay, _sliceDuration          'Initialze the _delay to the end of the first period slice
              add       _delay, cnt
              
startPeriod                  
              call      #getOutputMask                  'Get the outputmask to control output pin 24..27 
              movi      outa, _outputMask               'Set output pin 24..27
              waitcnt   _delay, _sliceDuration          'Wait until slice of period is ended   
              djnz      _sliceCount, #startPeriod       '100 of period slice's are done ?
:endPeriod
              mov       _sliceCount, #100               'Set _sliceCount to 100 for new period
              call      #getCommand                     'Get/Check for new command and load speeds and ramp
              cmp       _rampDelay, #0          wz      'Command contains ramp delay ?
 if_z         jmp       #startPeriod                    'No ramp delay, start new period
       
:ramp              
              djnz      _curRampDelay, #startPeriod     'Is ramp delay done ?  
              mov       _curRampDelay, _rampDelay       'Set new rampdelay

              cmps      _curSpeedL, _speedL     wc,wz   'Compare currentspeed with commandspeed of left motor  
 if_c         adds      _curSpeedL, #1                  'Currentspeed < commandspeed, add 1 to currentspeed of left motor
 if_nc_and_nz subs      _curSpeedL, #1                  'Currentspeed > commandspeed, sub 1 from currentspeed of left motor
              cmps      _curSpeedR, _speedR     wc,wz   'Compare currentspeed with commandspeed of right motor  
 if_c         adds      _curSpeedR, #1                  'Currentspeed < commandspeed, add 1 to currentspeed of right motor
 if_nc_and_nz subs      _curSpeedR, #1                  'Currentspeed > commandspeed, sub 1 from currentspeed of right motor

              jmp       #startPeriod                    'Start new period

getOutputMask

              abs       _r1, _curSpeedL         wc,wz   'Get the absolute value of the leftspeed, C flag indicates backward, Z flag indicates stop
 if_z         mov       _outputMask, #%11000            'Stop left motor
 if_c         mov       _outputMask, #%11010            'Set left motor to backward, bit 24 = 1
 if_nc_and_nz mov       _outputMask, #%11100            'Set left motor to forward, bit 25 = 1
              cmp       _sliceCount, _r1        wc,wz   'Compare leftspeed with current slice of period
 if_nc_and_nz mov       _outputMask, #%11000            '_sliceCount > leftspeed, stop left motor 

              abs       _r1, _curSpeedR         wc,wz   'Get the absolute value of the rightspeed, C flag indicates backward, Z flag indicates stop
 if_z         and       _outputMask, #%00110            'Stop left motor
 if_c         and       _outputMask, #%10110            'Set right motor to backward, bit 27 = 1
 if_nc_and_nz and       _outputMask, #%01110            'Set right motor to forward, bit 26 = 1
              cmp       _sliceCount, _r1        wc,wz   'Compare leftspeed with current slice of period
 if_nc_and_nz and       _outputMask, #%00110            '_sliceCount > rightspeed, stop right motor 

getOutputMask_ret
              ret
             
getCommand
              rdlong    _command, _commandAddr          'Read command from startPeriod memory                                                           
              test      _command, #1            wz      'Command is updated ? bit 0 must be 1
 if_z         jmp       #getCommand_ret                 'No new command present, return to caller
              cmp       _command, _prevCommand  wz      'Is new and previous command the same ?
 if_z         jmp       #:endcommand                    'Command not changed, return to caller              

:setSpeed     
              mov       _r1, _command                   'Copy command in _r1
              shr       _r1, #8                         'Shift leftspeed into byte 0
              mov       _speedL, _r1                    'Save leftspeed
              and       _speedL, #$FF                   'Clear byte 1..3 of leftspeed
              cmp       _speedL, #101           wc      'Is leftspeed negative( > 100) ?
 if_nc        muxnc     _speedL, _negMask               'Create long negative
              shr       _r1, #8                         'Shift rightspeed into byte 0    
              mov       _speedR, _r1                    'Save rightspeed
              and       _speedR, #$FF                   'Clear byte 1..3 of rightspeed
              cmp       _speedR, #101           wc      'Is rightspeed negative( > 100) ?
 if_nc        muxnc     _speedR, _negMask               'Create long negative
              shr       _r1, #8                         'Shift ramp delay into byte 0
              mov       _rampDelay, _r1                 'Save rampdelay
              mov       _curRampDelay, _rampDelay       'Set current ramp
              cmp       _rampDelay, #0          wz      'Ramp delay present ?
 if_nz        jmp       #:endcommand                    'Ramp <> 0 jump to endcommand
              mov       _curSpeedL, _speedL
              mov       _curSpeedR, _speedR 
   
:endcommand                                             'Reset command in startPeriod memory
              mov        _prevCommand, _command         'Save the command as previous getCommand         
              mov       _r1, _command           wz      'Copy new command into _r1, set the Z flag to 0 for muxz instruction
              muxz      _r1, #1                         'Reset bit 0 of the command                    
              wrlong    _r1, _commandAddr               'Signal to object in startPeriod memory that command processing is finished
getCommand_ret
              ret
                   
_negMask                long    $FF_FF_FF_00         
_sliceDuration          res     1
_sliceCount             res     1        
_delay                  res     1         
_commandAddr            res     1
_command                res     1
_prevCommand            res     1
_r1                     res     1              
_r2                     res     1        
_speedL                 res     1
_speedR                 res     1
_curSpeedL              res     1
_curSpeedR              res     1
_outputMask             res     1
_rampDelay              res     1
_curRampDelay           res     1        

              fit   496

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