{{
┌───────────────────────────────────────────────────┐
│ Stepper.spin version 1.0.0                        │
├───────────────────────────────────────────────────┤
│                                                   │               
│ Author: Mark M. Owen                              │
│                                                   │                 
│ Copyright (C)2016 Mark M. Owen                    │               
│ MIT License - see end of file for terms of use.   │                
└───────────────────────────────────────────────────┘

Description:

  Basic driver for a unipolar stepper motor with two limit switches using
  a FIFO command queue and separate cogs for the motor driver and switch
  monitor.
  
  Nothing fancy, no acceleration / deceleration code is provided.  Such
  code can be accomplished by the client process.  For example to
  accelerate from minimum speed to maximum one may simply enqueue single
  step motor commands inside a dimishing time duration loop.

Driver Board:

  +V  ─────────────────┬─┐    Note: NMOS Devices with Vgs < Vcc, low
             ┌──┳──────┫   │          Rdson, and other parameters as
  M1on────  └────┼───┫          appropriate to the motor voltage
          ┌──┘      A    │   │          and current requirements.
  Gnd ──┫              │   │
          │  ┌──┳──────┫   │          Schottky blocking diodes used to
  M2on──┼─  └────┼───┫          mitigate inductive voltage spikes
          ┣──┘      B    │   │          during phase switching.
          │              │   │
          │  ┌──┳──────┫   │          Inductors represent motor phases.
  M3on──┼─  └────┼───┫
          ┣──┘      /A   │   │
          │              │   │
          │  ┌──┳──────┘   │
  M4on──┼─  └────────┘
          └──┘      /B

Limit Switches (Normally Open, Active Low):

  Vcc─────┳────┐
    10kΩ     │  ─┴─
  LSW─────┻────┼──┘ └────┐
         10kΩ   ─┴─    │
  RSW──────────┻──┘ └────┫
                           │
  Vss────────────────────┘ 
     
Revision History:

  09Feb2016     Initial release version 1.0.0

}}

CON
  '
  ' Motor Command Arguments
  '
  '               Positive logic
  '                 _ _  _ _  _ _  _ _  _ _  _ _  _ _  _ _ 
  '                AABB AABB AABB AABB AABB AABB AABB AABB
  WAVESTEP_CW   = %1000_0010_0100_0001_1000_0010_0100_0001 
  WAVESTEP_CCW  = %0001_0100_0010_1000_0001_0100_0010_1000 
  FULLSTEP_CW   = %1010_0110_0101_1001_1010_0110_0101_1001
  FULLSTEP_CCW  = %1001_0101_0110_1010_1001_0101_0110_1010
  HALFSTEP_CW   = %1000_1010_0010_0110_0100_0101_0001_1001
  HALFSTEP_CCW  = %1001_0001_0101_0100_0110_0010_1010_1000

  '
  ' Motor Commands
  '
  #0
  SET_PULSE_DURATION     ' arg: ticks for NSTEPS_AND_HOLD and RUN_UNTIL_INTERRUPT
  SET_STEP_AND_DIRECTION ' arg: WAVESTEP, HALFSTEP or FULLSTEP and CW or CCW above
  SINGLE_STEP_AND_HOLD   ' arg: 
  RUN_UNTIL_INTERRUPT    ' arg: 
  FREEWHEEL              ' arg: 
  BRAKE                  ' arg:
  NSTEPS_AND_HOLD        ' arg: number of steps
  REVERSE                ' arg:
  CEASE                  ' arg:
  '
  ' NOTE:
  '     commands with HOLD apply a partial brake using the phase state to hold the motor position;
  '     FREEWHEEL turns all phases off effectively releasing the BRAKE;
  '     RUN_UNTIL_INTERRUPT cycles the motor phases until interrupted then FREEWHEELs it.

  QSIZE         = 128    ' use powers of two for ease in masking
  QSIZEMODULUS  = QSIZE-1           

  QUEUE_EMPTY   = -1
 
VAR
  long  stack[25]        ' Cog stack space (measured at 17)
  byte  cog              ' Cog ID
  
  byte  interrupt

  long  nextin           ' nextin (put) index for queue
  long  nextout          ' nextout (get) index for queue
  long  queue[QSIZE]     ' buffer

PUB Start(Apin,Bpin)
{{
  Initialize motor driver in freewheel state running in a dedicated cog.
  
  A block of four IO pins is passed to this function and are expected to be
  connected to NMOS gates used to switch the grounds of the motor phases in
  the order A B /A and /B.

  Apin is the gate for phase A, Apin+1 is the gate for phase B, APin+2 is the
  gate for phase /A and finally Bpin is the gate for phase /B and should be
  equal to Apin+3.

  Parameters:
      Apin      first IO pin of the four pin phase gate block.  
      Bpin      fourth IO pin of the four pin phase gate block.

  Returns:
      cogID of the allocated cog or zero if no cog could be started
}}
  nextin~
  nextout~
  interrupt~
  result := (cog := cognew(driver(APin, Bpin), @stack) + 1)

PUB Stop
{{
  Terminates the motor driver by purging the command queue and stopping
  the driver cog if one is running.
}}
  EnqueueCmd(CEASE)
  repeat while not QueueEmpty
    waitcnt(clkfreq/1000+cnt)
  nextin~
  nextout~
  if cog
    cogstop(cog~ - 1)

PUB EnqueueCmd(cmd)
{{
  Adds a motor command to the end of the command queue.  Waits until space 
  is available in the queue if necessary.

  Parameters:
      cmd       a motor command (see enumeration "Motor Commands" in CON section)
}}
  repeat while not Enqueue(cmd)
    waitcnt(clkfreq/10_000+cnt)

PUB EnqueueCmdArg(cmd,arg)
{{
  Adds a motor command with an argument to the end of the command queue.  Waits
  until space is available in the queue if necessary.

  Parameters:
      cmd       a motor command (see enumeration "Motor Commands" in CON section)
      arg       a motor command argument(see "Motor Command Arguments" in CON section) 
}}
  repeat while not Enqueue(cmd)
    waitcnt(clkfreq/10_000+cnt)
  repeat while not Enqueue(arg)
    waitcnt(clkfreq/10_000+cnt)

PUB SetInterrupt(bool)
{{
  Places the motor driver cog in a tight loop thereby interrupting its operation until
  the interrupt is cleared.

  Parameters:
      bool      TRUE - driver will loop until SetInterrupt is called again with a FALSE
                parameter value at which time it will resume processing where it left off.
}}
  interrupt := bool

PUB GetInterrupt
{{
  Returns the current interrupt state value'
}}
  return interrupt

PUB QueueEmpty
{{
  Returns TRUE if the command queue is empty, FALSE otherwise.
}}
  return nextin == nextout

PUB PurgeQueue
{{
  Interrupts the motor driver, purges the command queue then clears the interrupt.
}}
  interrupt := %010
  repeat while interrupt == %010 'gets set to %110 by driver in response
    waitcnt(clkfreq/1_000+cnt) ' 1000µS  : 1mS
  nextin~
  nextout~
  interrupt~
  
PRI Enqueue(d)
{ Adds a 32bit value to the end of the command queue.

  Parameters:
      d         32bit value to place at the end of the command queue.
      
  Returns:
      TRUE if successfull
      FALSE if the queue was full (the value was not added to the queue).
}
  if nextin < nextout
    return false
  queue[nextin++] := d
  nextin &= QSIZEMODULUS  ' keeps it in range 
  return true
 
PRI Dequeue
{
  Returns the next entry in the command queue or QUEUE_EMPTY if appropriate.
} 
  if nextin == nextout
    return QUEUE_EMPTY
  result := queue[nextout++]
  nextout &= QSIZEMODULUS ' keeps it in range 

PRI driver(Apin,_Bpin) | cmd, t, seq, n, rvs 
  outa[Apin.._Bpin] := %0000
  dira[Apin.._Bpin]~~

'  outa[0]~
'  dira[0]~~  ' scope timing pin
  
  interrupt~
  rvs~
  seq := FULLSTEP_CW ' HALFSTEP_CW' FULLSTEP_CW' WAVESTEP_CW  
  t := clkfreq/1_000 * 3  ' default pulse width 3mS for RUN_UNTIL_INTERRUPT and NSTEPS_AND_HOLD
  
  repeat
  
    waitcnt(clkfreq/4_000+cnt) ' 250µS
    
    if interrupt & %110       ' queue purge in progress
      interrupt := %110       ' indicate driver is idle pending completion of the purge
      next
      
    case Dequeue
      QUEUE_EMPTY            :' nothing
        next
      REVERSE                :' arg: state boolean
        rvs := Dequeue
      SET_STEP_AND_DIRECTION :' arg: seq
        seq := Dequeue
      SET_PULSE_DURATION     :' arg: ticks
        t := Dequeue
        
      SINGLE_STEP_AND_HOLD   :' arg: n/a
        if rvs
          outa[Apin.._Bpin] := (seq->= 4) & $FFFF ' rotate right by 4 bits (seq contains 8 steps)
        else
          outa[Apin.._Bpin] := (seq<-= 4) & $FFFF ' rotate left by 4 bits (seq contains 8 steps)

'        not outa[0] ' scope timing 
               
      NSTEPS_AND_HOLD        :' arg: N steps
        n := Dequeue
        repeat n
          waitcnt(t+cnt)
          if rvs
            outa[Apin.._Bpin] := (seq->= 4) & $FFFF ' rotate right by 4 bits (seq contains 8 steps)        
          else
            outa[Apin.._Bpin] := (seq<-= 4) & $FFFF ' rotate left by 4 bits (seq contains 8 steps)
                 
      RUN_UNTIL_INTERRUPT    :' arg: n/a
        interrupt~
        repeat until interrupt
          waitcnt(t+cnt) 
          if rvs
            outa[Apin.._Bpin] := (seq->= 4) & $FFFF ' rotate right by 4 bits (seq contains 8 steps)        
          else
            outa[Apin.._Bpin] := (seq<-= 4) & $FFFF ' rotate left by 4 bits (seq contains 8 steps)        
        outa[Apin.._Bpin] := %0000 ' freewheel
        
      FREEWHEEL              :' arg: n/a
        outa[Apin.._Bpin] := %0000
      BRAKE                  :' arg: n/a
        outa[Apin.._Bpin] := seq & $FFFF
      CEASE:
        outa[Apin.._Bpin] := %0000
        dira[Apin.._Bpin]~
        quit
        
  waitcnt(clkfreq/10+cnt)

'  
VAR
  long  lswStack[25]    ' says 12
  byte  lswCogID                                                                                                     
  byte  lLSwStates

PUB StartWatchLSws(Apin,Bpin)
{{
  Allocates a cog to monitor the states of two IO pins connected to active low
  switches. 

  Parameters:
    Apin      first limit switch IO pin number.
    Bpin      second limit switch IO pin number.

  Returns:
      cogID of the allocated cog or zero if no cog could be started
}}
  lLSwStates~ 
  lswCogID := cognew(WatchLSws(Apin,Bpin,@lLSwStates), @lswStack) + 1
  return lswCogID
                                              
PUB StopWatchLSws
{{
  Terminates the cog allocated by StartWatchLSws, if appropriate.
}}
  if lswCogID
    cogstop(lswCogID~ - 1)

PUB LSwStates
{{
  Returns the current state of the limit switches as a 32 bit value.
  The two bits of interest are in the low order positions (%0000_00XX)
  and are mutually exclusive.
}}
  return lLSwStates

PUB LSwLon
{{
  Returns TRUE if the first limit switch has been closed, FALSE otherwise.
}}
  return lLSwStates == 2

PUB LSwRon
{{
  Returns TRUE if the second limit switch has been closed, FALSE otherwise.
}}
  return lLSwStates == 1

PUB ResetLSwStates
{{
  Resets the observed state bits for the switchs to zero.
}}
  lLSwStates~
       
PRI WatchLSws(Apin,Bpin,pBits) | state, mask
{
  Waits for a change in state of a pair of active low switches.  When a state
  change occurs the current state is updated to indicate that a switch has
  closed then the process waits until the client process calls ResetLSwStates
  at which point this process resumes waiting for a state change.

  Parameters:
    Apin      first limit switch IO pin number.
    Bpin      second limit switch IO pin number.
    pBits     address of byte used to store the current state of the switches. 
    
}
  dira[Apin]~ ' input
  dira[Bpin]~ ' input
  byte[pBits]~
'  outa[8..9]~
'  dira[8..9]~~
  mask := (|<Apin) | (|<Bpin)
  state := mask
  repeat
    waitpne(state,mask,0) ' (pins are pulled up with switches open, pulled down by switch closure)
    byte[pBits] := (!ina[Apin..Bpin]) & %11 ' convert to positive logic
'    outa[8] := (byte[pBits]& 2)<> 0 ' set LED
'    outa[9] := (byte[pBits]& 1)<> 0 ' set LED 
    repeat while byte[pBits]<>0 ' wait until client resets the output area
      waitcnt(clkfreq>>12+cnt)
'    outa[8..9]~ ' clear LEDs

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