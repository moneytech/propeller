{{
********************************************************************************
Autodataloggeer V 1.0

By SRLM
********************************************************************************

Automatically logs data to a USB flash drive via a Parallax Datalogger

2009 SRLM

Questions? Comments? Bugs?
srlm@srlmproductions.com

Use this object in a project? Let us know!
srlm@srlmproductions.com

Program Overview:
This program will automatically log hub variables as fast as possible to the USB
  Datalogger from Parallax. It does this in the background, with no oversight
  once start is called. Logging will continue until a critical failure, loss of
  power, or the Spin function stop is called.

********************************************************************************

Hardware Setup


--------------------
Datalogger:
Connect the Datalogger to the Propeller as follows:
1. Datalogger pin 2 to Propeller CTS
2. Datalogger pin 4 to Propeller TX
3. Datalogger pin 5 to Propeller RX
4. Datalogger pin 6 to system ground

Each connection has a 2K resistor, although down to 100ohm will probably be fine.
Don't forget to connect the datalogger to a 5v supply.

--------------------
Propeller:
This object requires 80Mhz or more to operate correctly. It is possible to run
                slower, but in that case a new baud rate will need to be choosen
                for the fast speed. Should slower operation be required, the
                following changes should be made:
                1. In the init method, change the divisor in bit_ticksFast to
                  the slower baud rate.
                2. In the PASM set_speed, the first two bytes must be changed to
                  match the table in the Datalogger firmware specification.

This object requires three pins on the Propeller

********************************************************************************

Software Setup
Once launched, this program does not require or use any oversight.


--------------------
Object configuration:
1. Filename: A single filename can be used with this program.
2. File Close Frequency: The frequency with which a file can be "saved to disk"
                is configurable. A low value will close the file frequently,
                while a higher value will close the file only once in a great
                while. Note that until a file is closed, the data is not "saved"
                and could be lost in the event of a failure (brownout, disk
                removal, etc.). The tradeoff is that the more frequently a file
                is saved to disk, the slower the logging occurs. Additionally,
                as a file grows very large, a "save" has a much higher cost than
                a smaller file. See the benchmarks section below for more information.
3. Field/Watches: The heart of the program is the ability to watch 32bit,
                unsigned numbers. The number of variables to watch is completly
                configurable, from zero to about 125. Each variable to watch has
                two associated pieces of information: a column label (most
                likely the name) and the number of digits to log. The number of
                digits to log specifies how many decimal digits (starting from
                the right) to store. For example, the number 12345 is five
                digits long. If the digits value is too small for the number,
                the upper digits will be truncated. If the digits value is too
                large, the number will be padded with leading zeros. Note that
                signed numbers are not loggable at this time. There isn't a set
                limit on the quantity of variables to watch, but the total
                number of digits plus the number of variables cannot exceed 244:
                                digits + fields < 244


Object inconfiguration:
1. The object will always log the current system clock value.
2. The object will always log automatically, and cannot be interupted to log something else.


********************************************************************************

Benchmarks
All tests run for ten minutes.


--------------------
A = File close frequency
B = User supplied bytes logged per sample
        The sum of the passed digits
        Does not include commas
        Does not include the system clock field        
C = Samples per second at the start
D = Samples per second at the end
E = File Size


--------------------
Samples per second is calculated as follows:
1. Find the difference between the n and n-1 system clock log for the first 101 logs.
2. Average the difference
3. Divide 80_000_000 by the average

Note that if there is a 32 bit rollover, the negative number in the middle is ignored.


-------------------- 
HP 4GB USB Drive (with cheap black plastic wood grain cover)
+----------+------------+------------+------------+------------+
| FCF      | Bytes per S| SPS start  | SPS end    | Size KB    |
+----------+------------+------------+------------+------------+
|         1|         200|       39.69|       14.51|       2_809|
+----------+------------+------------+------------+------------+
|    10_000|         200|       41.51|       60.54|       7_634|
+----------+------------+------------+------------+------------+
|         1|          10|       53.05|       34.71|         602|
+----------+------------+------------+------------+------------+
|    10_000|          10|       95.87|       91.23|       1_299|
+----------+------------+------------+------------+------------+


Lexar 512MB Firefly USB Drive (with green cover and blinky blue light)
+----------+------------+------------+------------+------------+
| FCF      | Bytes per S| SPS start  | SPS end    | Size KB    |
+----------+------------+------------+------------+------------+
|         1|         200|       22.47|       10.78|       1_750|
+----------+------------+------------+------------+------------+
|    10_000|         200|       27.16|       26.47|       3_656|
+----------+------------+------------+------------+------------+
|         1|          10|       26.34|       16.00|         266|
+----------+------------+------------+------------+------------+
|    10_000|          10|       32.59|       32.83|         453|
+----------+------------+------------+------------+------------+


--------------------
Benchmark Conclusions:
1. The specific USB drive has a significant bearing on SPS
2. Large file close frequencies have a minimal effect on the overall SPS
3. Long term datalogging should not close the file frequently
4. High speed logging of a single variable is possible (~95 hz).

********************************************************************************

}}
VAR

  byte  CR, LF, ZERO

  long  cog                     'cog flag/id

  long  rx_pin                  'Do not change order of these variables!
  long  tx_pin
  long  cts_pin
  long  bit_ticksFast
  long  bit_ticksDefault
  long  filename_addr
  long  field_count
  long  stop_status              'Clear (0) indicates to log, set (1) indicates to stop and close file
  long  file_time
   

OBJ
  serial :      "FullDuplexSerialUART"                  'Required for initial setup


PUB start : okay

  closefile
  waitcnt(clkfreq/2 + cnt)
  serial.stop
  okay := cog := cognew(@setup, @rx_pin) + 1
  
PUB init(rxpin, txpin, ctspin, filenameaddr, filecount) 
  {{
    Prepares the datalogger, allows subsequent calls to add a field.

    rxpin - input receives signals from peripheral's TX pin
    txpin - output sends signals to peripheral's RX pin
    ctspin - connects to the cts pin (Datalogger's or Propeller's? I don't know...)
    filenameaddr - the C style zero terminated string of the filename (including .extension)
                                filename may not be modified once start is called for the life of the program
                                filename (including extension) may not be longer than 16 chars.
    filecount - the number of writes to keep a file open
                                0 or 1 indicates to close after every write
                                ?      indicates to close after ? writes. 32 bit signed limit (~2_000_000_000)

    Don't run slower than 80MHz!

    Requires one cog from this point forward

    Note: only call init once!
  }}

  'dbg.start(31,30,@setup)                 '<---- Add for Debugger

  
  longfill(@rx_pin, 0, 9)
  longmove(@rx_pin, @rxpin, 3)
  bit_ticksDefault := clkfreq / 9600   'The default clock rate of FTDI is 9600 bps
  bit_ticksFast    := clkfreq / 460_800  'For now, the fast rate is unchangable
  filename_addr := filenameaddr
  field_count := 0
  stop_status := 0
  file_time := filecount #> 1

  serial.start(rx_pin, tx_pin, 0, 9600, ctspin)

  waitcnt(clkfreq + cnt)

  syncdatalogger
  openfile
  
  txstring(string("System Clock"), 1)
  valuedigits[0] := 10
  field_count++
  


PUB stop

  '' Stops driver - frees a cog
  if cog
    stop_status := 1
    repeat until stop_status <> 1
    cogstop(cog~ - 1)
  
PUB addfield(address, digits, labeladdr)
{{
This function adds a long sized, numeric variable to watch.
        address - The hub address of the variable
        digits  - The number of digits (1 to 10) to log. Zero padded.
        labeladdr - The address of the ASCII label to apply to the watch
}}
  
  valuedigits[field_count] := 10 <# digits #> 1 ' Make sure digits is >= 1 and <= 10
  valueaddr[field_count] := address
  txstring(labeladdr, 1)
  field_count++

PRI syncdatalogger

  
  repeat until serial.rxtime(50) == "E"
    serial.tx("E")
    serial.tx($0D)
  
  repeat until serial.rxtime(50) == "e"
    serial.tx("e")
    serial.tx($0D)

PRI openfile

  serial.str(string("OPW "))
  serial.str(filename_addr)
  serial.tx($0D)

PRI closefile | temp

  CR := $0D
  LF := $0A
  ZERO := 0
  txstring(@CR, 0)

  serial.str(string("CLF "))
  serial.str(filename_addr)
  serial.tx($0D)
  
  
PRI txstring(address, commabool) | length
{Will transmit a string to be written to the file
commabool determines whether or not to add a tail comma}

  serial.str(string("WRF "))
  serial.tx(0)
  serial.tx(0)
  serial.tx(0)
  length := strsize(address)
  if commabool
    length++
  serial.tx(length)
  serial.tx($0D)
  serial.str(address)
  if commabool
    serial.tx(",")
  serial.tx($0D)

  repeat until serial.rx == $0D



DAT

'***************************************
'* Assembly language datalogger driver *
'***************************************

                        org
setup
                        mov     t1,par                  'get structure address
                        

                        rdlong  t2,t1                   'get rx_pin
                        mov     rxmask,#1
                        shl     rxmask,t2

                        add     t1,#4                   'get tx_pin
                        rdlong  t2,t1
                        mov     txmask,#1
                        shl     txmask,t2

                        add     t1, #4                  'get cts_pin
                        rdlong  t2, t1
                        mov     ctsmask, #1
                        shl     ctsmask, t2
                        
                        mov     rxtxmode, #0

                        add     t1, #4                  'get the fast speed value
                        rdlong  bitticksfast, t1

                        add     t1,#4                   'get bit_ticks
                        rdlong  bitticks,t1

                        add     t1, #4                  'get filename address
                        rdlong  t3, t1

                        add     t1, #4                  'get number of fields
                        rdlong  fieldcount, t1

                        add     t1, #4                  'Get the address of stop_status
                        mov     stopstatus, t1

                        add     t1, #4                  'Get the write count to keep the file open
                        rdlong  filetime, t1            

                        
                        test    rxtxmode,#%100  wz      'init tx pin according to mode
                        test    rxtxmode,#%010  wc
        if_z_ne_c       or      outa,txmask
        if_z            or      dira,txmask

                        call    #get_filename
                        call    #get_total_digits        
                        call    #datalogger_setup
                        
                       
                        
main                    call    #open_file_write     
                        mov     currentfiletime, filetime

:loop                   call    #get_value
                        call    #write_value
                        rdlong  t1, stopstatus  wz
              if_z      djnz    currentfiletime, #:loop 'If stop status is not to stop and more time, keep looping
                        
                        call    #close_file_write

                        cmp     currentfiletime, #0     wz 'Keep logging or has stop status stopped us?
              if_z      jmp     #main


                        mov     t1, #2
                        wrlong  t1, stopstatus
                        
:wait                   rdlong  t1, stopstatus  wz
              if_nz     jmp     #:wait

                        jmp     #main
                                     
'-----------------------------------------------------
'Initialization
'-----------------------------------------------------
datalogger_setup        nop
:sync_BigE              mov     txdata, #"E"             'Transmit 'E' (sync char)  
                        call    #transmit
                        mov     txdata, #$0D             'Transmit CR
                        call    #transmit
                        call    #receive
                        cmp     rxdata, #"E"    wz                              'Compare to 'E'
              if_nz     movs    :sync_BigE_a, #:sync_BigE                       'if it isn't 'E'
              if_z      movs    :sync_BigE_a, #:sync_Littlee                    'if it is 'E'

                        call    #receive                                        'Get rid of the CR
:sync_BigE_a            jmp     #:sync_BigE

:sync_Littlee           mov     txdata, #"e"            'Transmit 'e' (sync char)
                        call    #transmit
                        mov     txdata, #$0D
                        call    #transmit
                        call    #receive
                        cmp     rxdata, #"e"    wz
              if_nz     movs    :sync_Littlee_a, #:sync_Littlee
              if_z      movs    :sync_Littlee_a, #:check_online
              
                        call    #receive
:sync_Littlee_a         jmp     #:sync_littlee



:check_online           mov     txdata, #$0D             'Transmit CR (a promt to return disk status)
                        call    #transmit
                        call    #reply                  
                     
:set_speed              mov     txdata, #"S"
                        call    #transmit

                        mov     txdata, #"B"
                        call    #transmit

                        mov     txdata, #"D"
                        call    #transmit
                        
                        mov     txdata, #" "
                        call    #transmit
                        
                        mov     txdata, #$06            'Set speed according to table in datalogger datasheet, must match the start method bit ticks fast
                        call    #transmit
                        
                        mov     txdata, #$40
                        call    #transmit
                        
                        mov     txdata, #$00
                        call    #transmit
                        
                        mov     txdata, #$0D
                        call    #transmit

                        
                        call    #reply

                        mov     t1, baudsetdelay        'Mandatory wait, not documented in datasheet
                        add     t1, cnt
                        waitcnt t1, #0

                        mov     bitticks, bitticksfast  'increase serial speed      

datalogger_setup_ret    ret          

'-----------------------------------------------------
'Datalogger Functions
'-----------------------------------------------------

'NOTE!!!

'The get filename function may be brittle! It relies on a set number of variables prior to filename address



get_filename            mov     t1, par                 'Get filename from hub
                        add     t1, #20                 'Filename addr is 5 longs later
                        rdlong  t2, t1
                        movd    :g_f_loop, #filename
                        nop

:g_f_loop               rdbyte  0-0, t2         wz
                        add     t2, #1
                        add     :g_f_loop, destination_mask
              if_nz     jmp     #:g_f_loop

get_filename_ret        ret

get_value               mov     t1, fieldcount
                        movs    :loop, #valueaddr
                        movd    :loop, #value
                        add     :loop, destination_source_mask                  'Need to add one to both D and S to get past counter value
                        sub     t1, #1                                          'Field for count isn't included

:loop                   rdlong  0-0, 0-0                   
                        add     :loop, destination_source_mask
                        djnz    t1, #:loop


get_value_ret           ret

open_file_write         mov     txdata, #"O"             
                        call    #transmit
                        mov     txdata, #"P"             
                        call    #transmit
                        mov     txdata, #"W"             
                        call    #transmit
                        
                        call    #gen_file
open_file_write_ret     ret

close_file_write        mov     txdata, #"C"
                        call    #transmit
                        mov     txdata, #"L"
                        call    #transmit
                        mov     txdata, #"F"
                        call    #transmit
                        
                        call    #gen_file
close_file_write_ret    ret
  

gen_file                mov     txdata, #" "              'Generic file process, will transmit a space, filename, and CR
                        call    #transmit
                        movs    :g_f_loop, #filename
                        nop
                        
:g_f_loop               mov     txdata, 0-0        wz   'Transmit filename
              if_z      jmp     #:g_f_cr
                        add     :g_f_loop, #1
                        call    #transmit
                        jmp     #:g_f_loop

:g_f_cr                 mov     txdata, #$0D
                        call    #transmit

                        call    #reply

gen_file_ret            ret          
                        
                          

get_total_digits        mov     t1, fieldcount          'Calculate the total number of digits to transmit
                        mov     totaldigits, #0
                       
:loop                   add     totaldigits, valuedigits
                        nop
                        add     :loop, #1
                        djnz    t1, #:loop

                        movs    :loop, #valuedigits     'reset for another time

get_total_digits_ret    ret

write_value             mov     txdata, #"W"            'Writes data to the open file
                        call    #transmit

                        mov     txdata, #"R"
                        call    #transmit

                        mov     txdata, #"F"
                        call    #transmit

                        mov     txdata, #" "
                        call    #transmit

                        mov     txdata, #$00
                        call    #transmit

                        mov     txdata, #$00
                        call    #transmit

                        mov     txdata, #$00
                        call    #transmit

                        mov     txdata, totaldigits     'number of numbers to write
                        add     txdata, fieldcount      'number of commas to write
                        add     txdata, #2              'number of CRs to write
                        
                        call    #transmit

                        mov     txdata, #$0D
                        call    #transmit          

                        mov     value, cnt              'first field is always cnt

                        mov     t7, fieldcount
                        movs    :loop, #value
                        movs    :loop_a, #valuedigits
                        
:loop                   mov     t4, 0-0
:loop_a                 mov     t5, 0-0
                        mov     t6, t5                  'copy number of digits of the number
                        call    #dec_to_ASCII
                        add     :loop, #1
                        add     :loop_a, #1
                        movs    :loop_transmit, #ASCII_num
                        nop
                         
:loop_transmit          mov     txdata, 0-0             'transmit each digit of the number
                        call    #transmit
                        add     :loop_transmit, #1
                        djnz    t6, #:loop_transmit
                         
                        mov     txdata, #","             'Transmit comma
                        call    #transmit
                        
                        djnz    t7, #:loop

                        mov     txdata, #$0D            'Datalogger requires CR + LF for a new line
                        call    #transmit

                        mov     txdata, #$0A
                        call    #transmit
                        
                        mov     txdata, #$0D
                        call    #transmit

                        call    #reply

write_value_ret         ret


reply                                                   'reply analyzes the reply, checks for bad command, command failed, no disk or success.
                                                        'works with either short or extended command set
                        call    #receive
                        cmp     rxdata, #"B"    wz      'Compare to bad command
              if_z      call    #critical_error
                        cmp     rxdata, #"C"    wz      'Compare to command failed
              if_z      call    #critical_error
                        cmp     rxdata, #"N"            'Compare to no disk
              if_z      jmp     #no_disk
                        cmp     rxdata, #"D"    wz      'Compare to prompt (both extended and short)
              if_nz     cmp     rxdata, #">"    wz
              
              
:loop                   call    #receive
                        cmp     rxdata, #$0D    wz      'Compare to CR
              if_nz     jmp     #:loop
reply_ret               ret


critical_error          nop                             'Stops cog
                        cogid   t1              
                        cogstop t1
critical_error_ret      ret                             'Allows tracing for debugging purposes
                        
                          

no_disk                 call    #receive                'For now, just throws away the reply and tries again
                        cmp     rxdata, #$0D    wz
              if_nz     jmp     #no_disk
                        jmp     #datalogger_setup



dec_to_ASCII            'Converts an unsigned number in a register to an ASCII value
                        't1 - The decimal number
                        't2 - The current count of the digits (ie, how many 100's are in 843)
                        't3 - The current number of digit (1000(4), 10(2), 1(1))
                        't4 - (parameter) the number to convert
                        't5 - (parameter) the number of digits in the number (modified)
                        '       ---too few will result in tuncation of upper digits
                        'ASCII_num - (result) will contain the number, optional negative (-, counts as digit)

                        movs    :main_loop, #decimal
                        movd    :write, #ASCII_num
                        mov     t3, #10
                        
                        
:main_loop              mov     t1, 0-0                 'Copy the decimal number (1, 1000, 10000, etc) into the variable
                        mov     t2, #0                  'Clear the counter
        
:multiply               cmp     t4, t1          wc      'Is the number less than the decimal number?
              if_nc     sub     t4, t1                  'The decimal number is <= than the value
              if_nc     add     t2, #1                  'increment the digit count
              if_nc     jmp     #:multiply

                        add     t2, #48                 'Increase to ASCII 0

:write                  mov     0-0, t2
                        
                        cmp     t5, t3          wc      'Should I write move on to the next digit?
              if_nc     add     :write, destination_mask'Move on to the next digit in ASCII_num
                        add     :main_loop, #1          'Move on to the next digit in decimal
                        djnz    t3, #:main_loop
                         

dec_to_ASCII_ret        ret

'-----------------------------------------------------
'Serial Routines
'-----------------------------------------------------
receive                 test    rxtxmode,#%001  wz    'wait for start bit on rx pin
                        test    rxmask,ina      wc
        if_z_eq_c       jmp     #receive

                        mov     rxbits,#9             'ready to receive byte
                        mov     rxcnt,bitticks
                        shr     rxcnt,#1
                        add     rxcnt,cnt                          

:bit                    add     rxcnt,bitticks        'ready next bit period

:wait                   mov     t1,rxcnt              'check if bit receive period done
                        sub     t1,cnt
                        cmps    t1,#0           wc
        if_nc           jmp     #:wait

                        test    rxmask,ina      wc    'receive bit on rx pin
                        rcr     rxdata,#1
                        djnz    rxbits,#:bit

                        shr     rxdata,#32-9          'justify and trim received byte
                        and     rxdata,#$FF
                        test    rxtxmode,#%001  wz    'if rx inverted, invert byte
        if_nz           xor     rxdata,#$FF

                        
receive_ret             ret              'byte done, receive next byte
'
'
' Transmit
'
transmit                mov     t1, ctsmask             'Is the datalogger ready to receive yet?
                        and     t1, ina         wz
              if_nz     jmp     #transmit

                        or      txdata,#$100          'ready byte to transmit
                        shl     txdata,#2
                        or      txdata,#1
                        mov     txbits,#11
                        mov     txcnt,cnt

:bit                    test    rxtxmode,#%100  wz    'output bit on tx pin 
                        test    rxtxmode,#%010  wc    'according to mode
        if_z_and_c      xor     txdata,#1
                        shr     txdata,#1       wc
        if_z            muxc    outa,txmask        
        if_nz           muxnc   dira,txmask
                        add     txcnt,bitticks        'ready next cnt

:wait                   mov     t1,txcnt              'check if bit transmit period done
                        sub     t1,cnt
                        cmps    t1,#0           wc
        if_nc           jmp     #:wait

                        djnz    txbits,#:bit          'another bit to transmit?

transmit_ret            ret             'byte done, transmit next byte


'---------------------------------------------------------
'Data
'---------------------------------------------------------
destination_mask        long    $200                    'When added, adds 1 to destination
destination_source_mask long    $201                    'When added, adds 1 to both destination and source
demo_data               long    $48, $65, $6C, $6C, $6F, $20, $57, $6F, $72, $6C, $64, $21, $0D, $00 'Hello World![CR]
fieldcount              long    32              'for now, preload it with 32
totaldigits             long    0               'The sum of valuedigits

'The first entry in the value table is reserved for logging the system clock.
valuedigits             long    10,03,03,03,03,03,03,03,03,03,03,03,03,03,03,03,03,03,03,03,03,03,03,03,03,03,03,03,03,03,03,03 'The number of digits to store.
valueaddr               long    00,01,02,03,04,05,06,07,08,09,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31 'The hub addresses of the values       
value                   long    00,01,02,03,04,05,06,07,08,09,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31 'The values as fetched from the hub

baudsetdelay            long    5_000_000      'changing the baud requires a delay afterwards, found by experimentation


debugclkfreq            long    80_000_000
debugdelay              long    80_000_000
debugtemp               long    1_000_000

decimal                 long    1_000_000_000                       'Constants for the ASCII_to_dec routine
                        long    100_000_000
                        long    10_000_000
                        long    1_000_000
                        long    100_000
                        long    10_000
                        long    1_000
                        long    100
                        long    10
                        long    1
ASCII_num               res     11                        

t1                      res     1
t2                      res     1
t3                      res     1
t4                      res     1              
t5                      res     1              
t6                      res     1              
t7                      res     1              

debugcount              res     1
debugcnt                res     1
debugdifference         res     1
debugloop               res     1
debugnumber             res     1

stopstatus              res     1


rxtxmode                res     1
bitticks                res     1

rxmask                  res     1
rxdata                  res     1
rxbits                  res     1
rxcnt                   res     1
rxcode                  res     1

txmask                  res     1
txdata                  res     1
txbits                  res     1
txcnt                   res     1
txcode                  res     1

ctsmask                 res     1

fileaction              res     1

filetime                res     1               'The number of writes to keep the file open.
currentfiletime         res     1

bitticksfast            res     1               'The faster version (since default is 9600)

filename                res     16
                        FIT     490

{{

┌──────────────────────────────────────────────────────────────────────────────────────┐
│                           TERMS OF USE: MIT License                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this  │
│software and associated documentation files (the "Software"), to deal in the Software │ 
│without restriction, including without limitation the rights to use, copy, modify,    │
│merge, publish, distribute, sublicense, and/or sell copies of the Software, and to    │
│permit persons to whom the Software is furnished to do so, subject to the following   │
│conditions:                                                                           │                                            
│                                                                                      │                                               
│The above copyright notice and this permission notice shall be included in all copies │
│or substantial portions of the Software.                                              │
│                                                                                      │                                                
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,   │
│INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A         │
│PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT    │
│HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION     │
│OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE        │
│SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                                │
└──────────────────────────────────────────────────────────────────────────────────────┘
}}