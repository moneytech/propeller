''************************************
''*  Full-Duplex Serial Driver v3.0  *
''*  (C) 2006 Parallax, Inc.         *
''************************************

''*  Slightly modified Aug 24, 2006 by GP *
''*      ORIGINAL CODE AUTHORED BY PARALLAX
''*  ----------------------------------------------

''*  NOTE: Later versions of the 'official' serial object may have
''*        resolved some of the topics addressed below.

''*
''*    1)Stop-bit test added: rxdata discarded
''*      and rx_buffer index not advanced if test fails.
''*      Prior to a VB app's startup the PC may default its
''*      serial port transmit pin to a polarity equivalent
''*      to a 'start bit detected' state. Without a stop bit
''*      test, this causes the COG assembly receive code to
''*      continually feed 'null' characters to the rx_buffer.
''*  
''*    2)If a stop-bit goes undetected, rx_pin must first return
''*      to its 'MARKING' (default no signal) state before
''*      resuming its test for the next start-bit leading edge.
''*      This blocks further receive byte processing. The initial
''*      return to the 'MARKING' state at VB app startup during
''*      serial port opening will no longer be interpreted as the
''*      reception of a 'STOP' bit with the erroneous recording of
''*      a data byte to rx_buffer. The first discarded null character
''*      will trigger this 'wait for 'MARKING' state' protective mode.
''*
''*    3)Both Spin and assembly language code have been heavily
''*      commented. I hope that these detailed explanations
''*      will serve to accelerate other's understanding of
''*      Propeller code.
''*
''*    4)Rx_buffer & Tx_buffer sizes may now be specified using the
''*      BufferSize constant. Only specific values are permitted.
''*
'' RX:

' SPIN code (method: rx) is used to retrieve incoming data
' from the rx_tail index position of the rx_buffer() provided
' there is data to retrieve (rx_tail <> rx_head). If data
' is present in buffer, the rx_tail index is afterwards advanced
' toward the rx_head index value.

' ASSEM code running in a separate COG will always add newly
' received data bytes to the rx_head index position of rx_buffer().
' It is the programmer's responsibility to fetch newly received
' characters in a timely manner using SPIN code methods, rx or rxtime.
' The rx_head index value will be advanced following the addition of
' a new data byte, pointing to the next available buffer location. 

''
''   Byte-Out      Serial-In
''      ^             |
''      |             v
''    SPIN (rx)     ASSEM
''      ^             |
''      |             v
'' (  rx_tail+ --> rx_head+  )        :=  RX_BUFFER()
''[tail chases head in endless loop]
''

''TX:

' Tests have successfully transmitted upto 115200 baud.

' SPIN code (method: tx) is used to write a new data byte
' to the tx_head index position of the tx_buffer(). If this
' write would cause the NEXT tx_head index to equal the
' current tx_tail index value the write operation will be
' delayed until the data byte at the tx_tail position has
' been serially transmitted.

' It is possible at low baud rates to call the tx method from
' SPIN code at a rate faster than the ASSEM transmit code is
' transmitting its data bytes. The tx_buffer() will fill up
' and the SPIN method, tx, will be forced to wait for an available
' slot within the tx_buffer() to place its data byte cargo.
' Note that SPIN instructions following the .tx method call will not
' be executed during this wait. SPIN code execution could be slowed
' to a rate limited by the rate at which data is being serially transmitted.
' The programmer is advised to be aware of the time required to transmit
' a byte at the selected baud rate and to proportionately adjust the
' frequency at which characters are being feed to the tx method.
 
' ASSEM code running in a separate COG will transmit the
' data byte located at the tx_tail index position of the tx_buffer()
' provided tx_tail <> tx_head (there is actually data in buffer to send).

''
''    Serial-Out    Byte-In
''      ^             |
''      |             v
''    ASSEM          SPIN (tx)
''      ^             |
''      |             v
'' (  tx_tail+ --->  tx_head+ )       :=  TX_BUFFER()
''[tail chases head in endless loop]
''
                        
' Note: the open drain/source configuration may be of value
' when more than one device must share a common serial transmit
' line.   

CON

  BufferSize = 256   'Legal values:  16, 32, 64, 128, 256
  TermChar  = 13     'Carriage Return
 
  
VAR

  long  cog                     'cog flag/id

  long  rx_head                 '9 contiguous longs
  long  rx_tail
  long  tx_head
  long  tx_tail

  long  rx_pin
  long  tx_pin
  long  rxtx_mode

  long  bit_ticks
  
  long  buffer_ptr0             'normally holds pointer to rx_buffer[] for cog use

 'note that variables in VAR block are sorted by object compiler by type !!
 'longs are placed first in memory, followed by words, then bytes.
 'if lists are being copied from hub to cog, and the cog expects variables
 'to be in a certain order, be careful that variable types are not mixed
 'within this list !!
  
  byte  rx_buffer[BufferSize]   'transmit and receive buffers
  byte  tx_buffer[BufferSize]  

  byte  stringsize              'added by GP
  

PUB start(rxpin, txpin, mode, baudrate) : okay

'' Start serial driver - starts a cog
'' returns false if no cog available
''
'' mode bit 0 = invert rx
'' mode bit 1 = invert tx
'' mode bit 2 = open-drain/source tx
'' mode bit 3 = ignore tx echo on rx

'NOTE:  The meaning of 'inverted' requires explanation. The 'non-inverted' mode
'       of operation (bit0 or bit1 cleared) actually requires the use of an external
'       polarity-inverting RS232 converter chip !

'       'Invert' best describes the polarity at the the Propeller pin of the data
'       bit's logic. If byte=01H were transmitted, for example, its non-inverted bit0
'       logic level would be HIGH (1). If mode bit1 (invert tx) = 0 (FALSE), then the
'       bit0 logic level at the propeller's tx_pin would also be HIGH (1). The external
'       RS232 converter chip performs a final polarity inversion, generating a
'       negative-voltage output during bit0's bit interval corresponding to an
'       RS232 'LOGIC 1' state.

  stop  'spin method call
   
  longfill(@rx_head, 0, 4)     'zero pointers to both rx & tx buffers heads & tails
                               'this assures rx_head = rx_tail, and tx_head = tx_tail
                               'a condition corresponding to buffers 'empty'
  
  longmove(@rx_pin, @rxpin, 3) 'copy 1st three start() parameters
  
  bit_ticks := clkfreq / baudrate   'calculate clock cycles per serial bit interval

  buffer_ptr0 := @rx_buffer   'save rx_buffer address to buffer_ptr0 for reference by cog.
 
  'Note: par = rx_head within assembly routine
  '      cog = ID# of cog started + 1
  '      okay = return value for start() routine,
  '      cognew return -1 if no cog available, so after +1, cog =0 (FALSE), okay = FALSE
  
  okay := cog := cognew(@entry, @rx_head) + 1

  
PUB stop

'' Stop serial driver - frees a cog

  if cog                    'TRUE = non-zero
    cogstop(cog~ - 1)       'stop cog with ID# 'cog-1', then post-clear cog to zero (FALSE)
    
  longfill(@rx_head, 0, 9)  'write 9 longs with zero value, starting at hub location rx_head.


PUB rxflush

'' Flush receive buffer

  repeat while rxcheck => 0
  

PUB tx_rxbuffer | temp

'' Flush receive buffer

   repeat temp from 0 to Constant(BufferSize-1)
     tx(rx_buffer[temp])
        
      
PUB rxcheck : rxbyte

'' Check if byte received (never waits)
'' returns -1 if no byte received, else $00..$FF if byte received

  rxbyte--                          'post decrement to -1 default "empty buffer" response
  if rx_tail <> rx_head             'if rx_buffer is not empty, then
    rxbyte := rx_buffer[rx_tail]    '  fetch byte from rx_tail index position of buffer
    rx_tail := (rx_tail + 1) & Constant(BufferSize-1) '$100-1=$FF
             '  advance rx_tail index value, rolling over if necessary


PUB rxtime(ms) : rxbyte | t

'' Wait ms milliseconds for a byte to be received
'' returns -1 if no byte received, $00..$FF if byte

 'CNT is SIGNED. The (CNT - t) result (see instruction below) is almost always positive.
 'CNT always advances from NEGX(-2,127,483,649) to POSX (+2,127,483,647) rolling
 'over at POSX back to NEGX (&H7FFFFFFF(POSX) + 1  -> &H80000000(NEGX)).

 'Consider the case in which POSX is incremented by 1 to NEGX,
 'Let's determine the difference:  NEGX - POSX  = ?

 ' NEGX :  &80 00 00 00
 '-POSX : -&7F FF FF FF
 '======================
 '  ?

 'Subtraction would require taking the 2's complement of POSX and adding it
 'to NEGX. The 2s complement is formed by first inverting each bit of a
 '32-bit value then adding one.

 'So,  2sComp(POSX)  = &80 00 00 01

 'Adding to NEGX yields:  &1 00 00 00 01. Discard bit-32 (overflow bit) and
 'you have a positive 1 as our result, the difference of NEGX-POSX at CNT rollover.
 'SO, for small differences between CNT values, the result is always positive.

 'So what happens if we wait so long that CNT is allowed to return to a positive
 'value before the expression (CNT - t) is first evaluated ? What will be the
 'sign of this difference ?

 ' '1' :  &00 00 00 01    'example value of CNT approximately 26.6 seconds after t:=cnt statement.
 '-POSX: -&7F FF FF FF    'value of CNT written to variable 't' when CNT = POSX 
 '=====================
 '  ?  :  &80 00 00 02    'equivalent to NEGX+2 : -2,127,483,647
 
 'This shows that the expression (CNT-t), if evaluated more infrequently than every
 '26.6 seconds, may return a negative difference result. It is important to be aware
 'of this 'loophole' and code appropriately.
  
 '------------------------------
  
 'capture start time in 't'
 'wait until TRUE:  char received OR time 'ms' (in milliseconds) has elapsed
 ' 
  t := cnt
  repeat until (rxbyte := rxcheck) => 0 or (cnt - t) / (clkfreq / 1000) > ms
    
PUB rx : rxbyte

'' Receive byte (will wait indefinitely for a received byte !)
'' returns $00..$FF

'return only after a character has been received
  repeat while (rxbyte := rxcheck) < 0


PUB tx(txbyte)

''Send byte (may wait for room in buffer)
 
 'Wait until the tx_head index (when advanced) will not equal the current tx_tail index value.
 'That will prevent data that has not yet been transmitted by the COG from being overwritten
 'by new data.

 'The COG continually grabs a data byte at the tx_buffer's tx_tail index location,
 'serially transmits this byte, then increments the tx_tail pointer value, PROVIDED the
 ' tx_tail index <> tx_head index value, i.e., provided there is something to transmit.
 
 'Bitwise And (&) has higher precedence than "Not Equal" operation
 'So if tx_head = 255, tx_head+1 = 256 ($100), after AND with &FF rolls over to $00
 '--------------------------------------------------------------------------------
 'The 'repeat' code below prevents the writing of a new byte of data to the
 'tx_head position if, following the write, the incremented tx_head pointer
 'would point to the yet-to-be-transmitted data at the current tx_tail position.
 'In effect, if the tx_head pointer has "caught up with" the tx_tail pointer,
 'we must wait for the tx_tail pointer to be advanced ahead of us by the cog as it
 'transmits more serial data, opening up room for us within the buffer to write
 'the new data to be transmitted (and to further advance the tx_head pointer).
 '-------------------------------------------------------------------------------- 
  repeat until (tx_tail <> (tx_head + 1) & Constant(BufferSize-1))  '$100-1 = $FF
  
  tx_buffer[tx_head] := txbyte    'NEW DATA TO TRANSMIT WRITTEN TO TX_HEAD POSITION
  
  tx_head := (tx_head + 1) & Constant(BufferSize-1)  '$100-1 = $FF

 'Waits at most 40 mS (if echo mode enabled) for a received char reply (echo).
 'At 300 baud, allowing 11 bits per byte, about 36.7 mS of transmission time
 'is required per character.  
  if rxtx_mode & %1000
     rxtime(1)


PUB str(stringptr)

'' Send string                    
   
  repeat strsize(stringptr)   'NOTE: strsize() counts bytes to the 1st null character.
    tx(byte[stringptr++])    

PUB dec(value) | i

'' Print a decimal number

  if value < 0
    -value
    tx("-")

  i := 1_000_000_000

  repeat 10
    if value => i
      tx(value / i + "0")
      value //= i
      result~~
    elseif result or i == 1
      tx("0")
    i /= 10


PUB hex(value, digits)

'' Print a hexadecimal number

' &HFFEEDDCC  - a 32-bit value composed of four bytes: FF, EE, DD, CC
' It is represented by no more than 8 alphanumeric characters.

' Example:   .hex(32,2)  would transmit a two-character hexidecimal equivalent of number 32.

' If this example we first shift bits left, zero filling LSBs, by (8-2)<<2 or 6<<2, or 24 bits.
' The "<<2" operator effectively multiplies the number of bits to shift by 4, as there are
' four bits per nibble (or hexidecimal character).

' The bits originally in positions 7 thru 0, now occupy positions 31 thru 24.

  value <<= (8 - digits) << 2

' Next, for each  hex digit (2 in our example), we rotate left 4 bits (effectively placing
' bits in positions 31 thru 28 in positions 3 thru 0. All bits are then zeroed, except
' for the bits which lie at positions 3 thru 0 ( zeroed with '& $F' code). The resulting value
' which must lie in the range 0 thru 15 which is used as an index into a lookup table
' to determine the exact ascii character to be transmitted. This procedure is repeated
' for subsequent digits.

  repeat digits
    tx(lookupz((value <-= 4) & $F : "0".."9", "A".."F"))


PUB bin(value, digits)

'' Print a binary number

  value <<= 32 - digits
  repeat digits
    tx((value <-= 1) & 1 + "0")
 
   
DAT 'Cog Entry

'***********************************
'* Assembly language serial driver *
'***********************************

                        org
' Entry
'
' Note: PAR holds the address of rx_head, a variable in hub memory.
'       It was assigned by the COGNEW spin instruction within the Start method
'       The entry portion of this assembly language program accesses
'       a string of consecutive long variables, beginning at the hub location, rx_head.
 
'       par             = rx_head
'       par + 1         = rx_tail
'       par + 2         = tx_head
'       par + 3         = tx_tail

'       par + 4         = rx_pin
'       par + 5         = tx_pin
'       par + 6         = rxtx_mode

'       par + 7         = bit_ticks

'       par + 8         = buffer_ptr0
'   

' The  "<<2" portion multiplies "#4" by 4 (the number of bytes per long-type variable).

entry                   mov     t1,par         'get address of 1st long variable ...
                        add     t1,#4 << 2     'skip past heads and tails variable addresses ...
                                               '(ADVANCE 4 LONGS)
                                                      
                        rdlong  t2,t1          'get rx_pin data value (HUB INSTRUCTION: 7 to 22 cycles)
                        mov     rxmask,#1
                        shl     rxmask,t2      'rxmask: only set bit corresponds to rx_pin# position 

                        add     t1,#4          'get tx_pin address (ADVANCE 1 LONG)
                        rdlong  t2,t1          'get tx_pin data value (HUB INSTRUCTION)
                        mov     txmask,#1      
                        shl     txmask,t2      'txmask: only set bit corresponds to tx_pin# position 

                        add     t1,#4          'get rxtx_mode address (ADVANCE 1 LONG)
                        rdlong  rxtxmode,t1    'get rxtx_mode data value

                        add     t1,#4          'get bit_ticks address  (ADVANCE 1 LONG)
                        rdlong  bitticks,t1    'get bit_ticks data value

                        add     t1,#4          'get address of HUB rx_buffer() from HUB buffer_ptr0 variable
                        rdlong  rxbuff,t1      'save address data to COG ram variable, rxbuff
                        
                        mov     txbuff,rxbuff
                        add     txbuff,#BufferSize   'Add 32 bytes to rxbuff addr -> to get tx_buffer start addr.
                                                     'NOTE: these are BYTE arrays.
              
  'SERIAL MODE CONTROL                                             
' mode bit 0 = invert rx
' mode bit 1 = invert tx
' mode bit 2 = open-drain/source tx
' mode bit 3 = ignore tx echo on rx

                        test    rxtxmode,#%100  wz    'Z=1, for zero result of AND operation
                        test    rxtxmode,#%010  wc    'C=1, for odd# of high(1) bits in AND result.

' Z = NOT-OPEN
' z=1 (zero result of AND operation), if bit2(open-drain enabled)= 0 (FALSE).

' C = INVERTED
' c=1 if bit1 (invert tx) = TRUE, the AND result: 010 would have an odd # of high bits.

' if_Z_ne_C is TRUE, either:  (z=0,c=1) OR  (z=1,c=0) is TRUE,
' and the default output level of the 'tx_pin' pin is HIGH (regardless of whether the pin
' is initially defined to be an input or output type ).

' The conditional "if_Z_ne_C" effects the outa OR operation, which determines
' the High/Low default state of the tx_pin WHEN IT'S USED AS AN OUTPUT. For the
' non-open-drain/source case (z=1), the tx_pin is always in the output state.
' For the open-drain/source case (z=0), the tx_pin is only placed in the output state
' when a polarity opposite to that achieved by the pin's pullup/pulldown resistor
' is required.

' (z=1,c=0): non-open, non-inverted --> tx_pin off (or mark) state HIGH (data logic '1')
' (z=1,c=1): non-open, inverted     --> tx_pin off (or mark) state is LOW

' (z=0,c=1): open-source, inverted  --> data LOW polarity is HIGH 
'              --> when data LOW:       -> output state: actively driven HIGH  
'              --> when data HIGH:      -> input state : pulldown R to LOW 
' (z-0,c=0): open-drain, non-inverted --> data LOW polarity is LOW )
'              --> when data LOW:       -> output state: actively driven LOW             
'              --> when data HIGH:      -> input state : pullup R to HIGH
  
' At startup the outa register = all-zero, so by default all output signal levels are LOW.
' For open-source/drain case, the 'data LOW' state is achieved by setting the pin to be an output.
' Whatever level (HIGH or LOW) that was written to the OUTA register during startup will
' be made available at the tx_pin when its becomes an output. This is determined by whether
' the tx_pin was defined as 'inverted' or 'non-inverted.' If 'inverted', a 'data LOW' state
' will cause an output HIGH level at the tx_pin. An external pullup or pulldown resistor
' determines the polarity of the tx_pin signal when the 'data HIGH' state is specified as
' the tx_pin is configured as an input (Hi-Z) at this time.

' Note an RS232 chip is assumed to invert the 'non-inverted' HIGH logic level to a negative
' voltage (the mark state polarity for RS232 signalling)

        if_z_ne_c       or      outa,txmask  'if not-open & not-inverted, set tx_pin default HIGH.
                                             'if open & inverted, set 'data LOW' output default HIGH. 
        if_z            or      dira,txmask  'if NOT open-drain, make tx_pin an output
 
                        mov     txcode,#transmit 'initialize ping-pong multitasking

                        jmp     #receive_low
'
'----------------------------------------------------
DAT 'Receive
'----------------------------------------------------
                                                           
'------------------------------------------------------------------
'NEW: TEST FOR MARK (NO-SIGNAL) STATE IF STOP-BIT WAS NOT DETECTED

receive_high            jmpret  rxcode,txcode         'run a chunk of transmit code, then return
                                                      'txcode is the 'GOTO' address
                                                      'rxcode is loaded with PC+1, return address.     

                        test    rxtxmode,#%001  wz    'wait for start bit on rx pin
                                                      'bit 0 = rx invert, if set -> z=0,
                                                      'if cleared (not inverted) -> z=1
                                                      
                        test    rxmask,ina      wc    'c=1 if odd# of high(1) bits in result.
                                                      'rxmask has a single bit set, if ina's
                                                      'corresponding bit is also set (rx_pin),
                                                      'the AND result will yield a value with
                                                      'a single bit set. That's an odd # of bits so,
                                                      'c=1 if rx_pin=1
                                                      
        if_z_ne_c      jmp     #receive_high         'If not inverted (z=1), mark state = HIGH
                                                      'If z=1 (non-inverted mode) and c=0 (rx_pin=LOW(non-mark)),
                                                      '   then retest rx_pin until mark state (after tx code detour).
                                                      'If z=0 (inverted mode) and c=1 (rx_pin=HIGH(non-mark)),
                                                      '   then retest rx_pin until mark state (after tx code detour)  
                                                      'ELSE execute some transmit code before
                                                      '     retesting for start bit's leading edge

'-------------------------------------------------------------------
'TEST FOR LEADING EDGE OF START-BIT AT RECEIVE PIN
'AFTER EACH FAILURE TO DETECT START-BIT SWITCH TO TX CODE

receive_low             jmpret  rxcode,txcode  'run a chunk of transmit code, then return here
                                               'txcode is the 'GOTO' address
                                               'rxcode is auto-loaded with PC+1, the ret addr.     

         
                        test    rxtxmode,#%001  wz    'wait for start bit on rx pin
                                                      'bit 0 = rx-invert, if set -> z=0,
                                                      'if cleared (not inverted) -> z=1
                                                      
                        test    rxmask,ina      wc    'c=1 if odd# of high(1) bits in result.
                                                      'rxmask has a single bit set, if ina's
                                                      'corresponding bit is also set (rx_pin),
                                                      'the AND result will yield a value with
                                                      'a single bit set. That's an odd# so,
                                                      'c=1 if rx_pin=1
                                                      
        if_z_eq_c       jmp     #receive_low  'If not inverted mode (z=1), mark state = HIGH
                                              'If z=1 (non-inverted mode) and c=1 (rx_pin = HIGH(mark)),
                                              '   then retest rx_pin again until start-state detected
                                              '   (after tx code detour)
                                              'If z=0 (inverted mode) and c=0 (rx_pin = LOW(mark)),
                                              '   then retest rx_pin again until start-state detected
                                              '   (after tx code detour).  
                                              'ELSE rx_pin = 'START' polarity so prepare to
                                              '   handle incoming stream of data bits .....


'-----------------------------------------------------------------------------                                                      
'********  THE LEADING EDGE OF THE START BIT HAS BEEN DETECTED !!! ***********

           mov     rxcnt,cnt             'Capture sys counter value
          
           mov     bitticks_half,bitticks
           shr     bitticks_half,#1      'divide by two for half-a-bit duration                          

           add     rxcnt,bitticks_half   'Add an initial offset in time equal
                                         'to half-a-bit: from start-bit leading edge
                                         'to center-of-start-bit.              

           sub     rxcnt, #200           'correct for late data bit sampling time
                                         'at highest baud rate (115.2k)
           
           mov     rxbits,#9             'ready to receive byte

           '---------- ORIGINAL CODE ----------                             
           'mov     rxbits,#9             'ready to receive byte
           'mov     rxcnt,bitticks
           'shr     rxcnt,#1              'divide by two for half-a-bit duration                          
           'add     rxcnt,cnt             'Add an initial offset in time equal
                                         'to half-a-bit: from start-bit leading edge
                                         'to center-of-start-bit.              
'-----------------------------
' CALC NEXT CENTER-OF-BIT TIME

:bit                    add     rxcnt,bitticks  'Advance time-target to a full bit period
                                                'NOTE: a half-bit interval was initially
                                                'added from the leading edge of start-bit
                                                'so the first rx_pin data sampling will occur
                                                'halfway thru bit-0 (1.5 bits from leading
                                                'edge of start bit).
                                                      
'----------------------------------------------------------------
'TEST FOR CENTER-OF-BIT TIME

:wait                   jmpret  rxcode,txcode  'run a chuck of transmit code, then return
                                               'txcode holds 'GOTO' address
                                               'rxcode auto-loaded with PC+1, the ret addr
         
                        mov     t1,rxcnt       'check if bit receive period done
                        sub     t1,cnt
                        cmps    t1,#0    wc    'C=1, if t1 <= #0  (t1 = rxcnt - cnt)
                                               'So, cnt >= rxcnt causes t1 <=0, and C=1
        if_nc           jmp     #:wait

'----------------------------------------------------------------
'READ RX_PIN INPUT

                        
                        test    rxmask,ina      wc    'Receive bit on rx pin
                                                      'C=1, if AND result has odd # of bits
                                                      'Since rxmask has only 1 bit set, if
                                                      'corresponding bit of INA is set, AND
                                                      'result will have 1 bit set (odd) and C=1
                                                      'In summary: C = rx_pin input
                                                      
                        rcr     rxdata,#1             'C-> rxdata
                                                      'By stuffing the received bits into the
                                                      'highest bit of rxdata, the correct bit
                                                      'order is restored. This is because bit 0
                                                      'is received first in a serial packet                                                       'to 
                                                     
                        djnz    rxbits,#:bit          '9 BITS SAMPLED YET ?

'----------------------------------------------------------------
'PROCESS RECEIVED BYTE

                        shr     rxdata,#32-9  'justify and trim received byte
                                              'shift right remaining bits until bit 0
                                              'of rxdata holds bit 0 of received byte
                                                                              
                        and     rxdata,#$1FF          'zero all but lower 9-bits
                                      
                        test    rxtxmode,#%001  wz    'if rx inverted, invert byte
                                                      'Z=1 if bit0=0 (data not inverted)
        if_nz           xor     rxdata,#$1FF          'if Z=0(data inverted),
                                                      '  INVERT DATA BITS & STOP BIT

'--------------------------------------------------------------------------------
'NEW: TEST FOR CORRECT STOP-BIT POLARITY 

'   If stop-bit (bit 8 of rxdata) polarity is not high,
'   then don't write rxdata to the rx_buffer() !!  It is likely corrupt.
'   Note, if inverted mode was selected, rxdata was just bitwise inverted,
'   so the "bit-8 equals HIGH" polarity test would also be valid for this mode.

                        test   rxdata, #$100  wz      'z=1 if bit8=0 (stop-bit not high)
        if_z            jmp    #receive_high          'skip buffer write if stop-bit not high
                                                      'NOTE: Since STOP-BIT is not HIGH we will
                                                      'branch to 'receive_high' and loop until
                                                      'rx_pin=HIGH(mark state) BEFORE testing for
                                                      'next start-bit leading edge (rx_pin=LOW)

'--------------------------------------------------------------------------------
'WRITE BYTE TO CURRENT RX_HEAD INDEX WITHIN RX_BUFFER() & ADVANCE RX_HEAD INDEX
        
                        rdlong  t2,par                'After: t2 holds current rx_head value (rx_buffer INDEX)
                                                      'par = address of rx_head HUB variable
                                                      
                        add     t2,rxbuff             't2 = rxbuff + t2, t2 now holds address to current head
                                                      'position within circular buffer rx_buffer().
                                                      'rxbuff previously loaded with rx_buffer(0) address.
                                                      
                        wrbyte  rxdata,t2             'HUB WRITE INSTR:  rxdata -> head pos within rx_buffer()
                        sub     t2,rxbuff             'Afterwards: t2 = rx_buffer INDEX value (again)

                        add     t2,#1                 'Increment Head INDEX 
                        and     t2,#BufferSize-1      'Rollover to zero if > 31 (only 32 byte buffer)
                        wrlong  t2,par                'HUB WRITE INSTR: par = address of rx_head,
                                                      'write new INDEX value (t2) to rx_head HUB address (par)

                        jmp     #receive_low          'byte done, wait to receive next byte ....
                                                      'branch to 'receive_low' and test for START-BIT
                                                      'leading edge as a valid stop-bit was detected.
'
'-------------------------------------------------------------------
DAT 'Transmit
'-------------------------------------------------------------------
'TEST FOR PRESENCE OF DATA TO BE SENT WITHIN TX_BUFFER()

transmit                jmpret  txcode,rxcode 'run a chunk of receive code, then return
                                              'rxcode holds the 'GOTO' address
                                              'txcode is aut0-loaded with PC+1, the ret addr

                        mov     t1,par                'check for head <> tail

                        add     t1,#2 << 2            'advance two longs to tx_head
                        rdlong  t2,t1                 'read into t2 the contents of HUB var tx_head

                        add     t1,#1 << 2            'advance one long to tx_tail
                        rdlong  t3,t1                 'read into t3 the contents of HUB var tx_tail

                        cmp     t2,t3           wz    'if t2=t3 (tx_head = tx_tail), z=1 (buffer empty)
        if_nz           call    #Transmit_TxBuf       'if tx_buffer() not empty (z=0), transmit byte.

                        jmp     #transmit   'loop

      
'@@@@@@@@@@@@@@@@@@@@@@@@@@@  SINGLE-BYTE TRANSMIT @@@@@@@@@@@@@@@@@@@@@@@@@@@@
DAT 'Transmit_TxBuf Routine

'---------------------------------------------------------------------------        
'GET BYTE FROM TX_TAIL POSITION WITHIN TX_BUFFER() AND ADVANCE TX_TAIL INDEX

't3 must have been preloaded with tx_tail value prior to calling this routine

Transmit_TxBuf          add     t3,txbuff             't3 == next hub_addr to transmit (tx_buffer + tx_tail_index)
                        rdbyte  txdata,t3             'txdata == value @ tx_tail_index within tx_buffer()
                        sub     t3,txbuff             't3 == tx_tail_index (tx_tail_index + tx_buffer - tx_buffer)

                        add     t3,#1                 'incr t3 (tx_tail_index)
                        and     t3,#BufferSize-1      'rollover index if necessary: limit 0 to BufferSize-1 
                        wrlong  t3,t1                 'write new tx_tail_index to HUB address t1 (tx_tail)

                        call    #Transmit_Byte
Transmit_TxBuf_RET      ret
 

DAT  'Transmit Byte Routine

'------------------------
' TRANSMIT_BYTE ROUTINE                          
'------------------------

     '-----------------------------
     'PREPARE TO SEND DATA BITS ...

Transmit_Byte           'or      outa, TestMask6       'TEST ONLY - SET HIGH AT TX BYTE
               
                        or      txdata,#$100          'get ready to transmit byte: STOP BIT is bit8 = 1
                        shl     txdata,#2             'bits 1-0 are both zero ( START BIT + SPACE-BIT)
                        or      txdata,#1             'set SPACE-BIT to 1 (same polarity as stop bit)
                        mov     txbits,#11            'START + 8-BITS + STOP + 1-SPACE
                       
                        mov     txcnt,cnt             'preload current system count value

     '----------------------
     'TRANSMIT NEXT DATA BIT

:bit                    test    rxtxmode,#%100  wz    'z=1 if bit2=0 (NOT open drain)
                        test    rxtxmode,#%010  wc    'c=1 if bit1=1 ( tx inverted )
        if_z_and_c      xor     txdata,#1             'if inverted & not open-drain, INVERT BITS
        
                        shr     txdata,#1       wc    'C = shift out next data bit ...LSB first !
                                                              
        if_z            muxc    outa,txmask           'if z=1 (NOT open drain), then tx_pin = C
        if_nz           muxnc   dira,txmask           'if z=0 (open drain/source), then
                                                      '    if C=0 (DATA BIT LOW) then
                                                      '       tx_pin = output type
                                                      '       NOTE: inverted mode sets out level HIGH
                                                      '             non-inverted mode sets out level LOW        
                                                      '    else (DATA BIT HIGH)
                                                      '       tx_pin = input type
                                                      '         Pulled to V+ or GND by
                                                      '         external pullup or pulldown resistor.
                       
                        add     txcnt,bitticks        'ready next cnt

     '-------------------------
     'TEST FOR END-OF-BIT TIME

:wait                   jmpret  txcode,rxcode         'run a chunk of receive code, then return
                                                      'rxcode holds 'GOTO' address
                                                      'txcode auto-loaded with PC+1, the ret addr

                        'andn    outa, TestMask5   'SET LOW WHILE TX CODE
                                   
                        mov     t1,txcnt              'check if bit transmit period done
                        sub     t1,cnt
                        cmps    t1,#0           wc    'C=1 if t1 <= #0, t1 = txcnt - cnt
                                                      'if cnt >= txcnt, then t1 <= #0, and C = 1
        if_nc           jmp     #:wait                'do receive code then return and retest

                        djnz    txbits,#:bit          'another bit to transmit?

                        'andn    outa, TestMask6       'TEST ONLY - SET LOW AT TX BYTE
                        
Transmit_Byte_RET       ret                           'byte transmission complete ...


'---------------------------------------------------------------------------------
DAT 'Uninitialized data 
'
t1                      res     1
t2                      res     1
t3                      res     1

rxtxmode                res     1
bitticks                res     1

rxmask                  res     1
rxbuff                  res     1
rxdata                  res     1
rxbits                  res     1
rxcnt                   res     1
rxcode                  res     1

txmask                  res     1
txbuff                  res     1
txdata                  res     1
txbits                  res     1
txcnt                   res     1
txcode                  res     1

syncmask                res     1

bufptr                  res     1
bufcnt                  res     1
bufptr_temp             res     1
long_temp               res     1

WriteLong               res     1
bitticks_half           res     1

    
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