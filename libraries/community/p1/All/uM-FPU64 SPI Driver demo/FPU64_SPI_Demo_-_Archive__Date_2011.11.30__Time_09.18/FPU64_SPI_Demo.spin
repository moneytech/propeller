{{
┌───────────────────────────┬───────────────────┬────────────────────────┐
│  FPU64_SPI_Demo.spin v1.1 │ Author: I.Kövesdi │  Release: 30 Nov 2011  │
├───────────────────────────┴───────────────────┴────────────────────────┤
│                    Copyright (c) 2011 CompElit Inc.                    │               
│                   See end of file for terms of use.                    │               
├────────────────────────────────────────────────────────────────────────┤
│  This is a PST application to demonstrate a core driver object for the │
│ uM-FPU64 with 2-wire SPI connection.                                   │
│                                                                        │ 
├────────────────────────────────────────────────────────────────────────┤
│ Background and Detail:                                                 │
│  The uM-FPU64 floating point coprocessor supports 64-bit IEEE 754      │
│ compatible floating point and integer operations, as well as 32-bit    │
│ IEEE 754 compatible floating point and integer operations.             │
│  Advanced instructions are provided for fast data transfer, matrix     │
│ operations, FFT calculations, serial input/output, NMEA sentence       │
│ parsing, string handling, digital input/output, analog input, and      │
│ control of local devices.                                              │
│  Local device support includes: RAM, 1-Wire, I2C, SPI, UART, counter,  │
│ servo controller, and LCD devices. A built-in real-time clock and      │
│ foreground/background processing is also provided. The uM-FPU64 can    │
│ act as a complete subsystem controller for sensor networks, robotic    │
│ subsystems, IMUs, and other applications.                              │
│  The chip is available in 28-PIN DIP package, too.                     │
│                                                                        │    
├────────────────────────────────────────────────────────────────────────┤
│ Note:                                                                  │
│  The 'core' SPI driver is the common part of specialized drivers for   │
│ the uM-FPU64 with 2-wire SPI connection. Up till now with only clean   │
│ SPIN/PASM code are:                                                    │
│                                                                        │
│  FPU64_ARITH   (Basic arithmetic operations)                           │
│  FPU64_MATRIX  (Basic and advanced matrix operations)                  │
│  FPU64_FFT     (FFT with advanced options, e.g. as ZOOM FFT)     (soon)│
│                                                                        │
│  The procedures and functions of these drivers can be cherry picked and│
│ used together to build application specific uM-FPU64 drivers.          │
│  Other specialized drivers, as GPS, MEMS, IMU, MAGN, NAVIG, ADC, DSP,  │
│ ANN, STR are in preparation with similar cross-compatibility features  │
│ around the instruction set and with the user defined function ability  │
│ of the uM-FPU64.                                                       │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
}}


CON

_CLKMODE = XTAL1 + PLL16X
_XINFREQ = 5_000_000

{
Schematics
                                                3V3 
                                               (REG)                                                           
                                                 │                   
P   │                                     10K    │
  A0├1────────────────────────────┳───────────┫
R   │                              │             │
  A1├2────────────────────┐       │             │
O   │                      │       │             │
  A2├3────┳──────┐                          │
P   │       │      17     16       1             │
            │    ┌──┴──────┴───────┴──┐          │                             
          1K    │ SIN   SCLK   /MCLR │          │                
            │    │                    │          │  LED   (On while busy)
            └──18┤SOUT            AVDD├28──┳─────╋────┐
                 │                 VDD├13──┼─────┫      │
                 │      uM-FPU64      │     0u1       │
                 │    (28 PIN DIP)    │    │     │      │
                 │                    │               │
            ┌──15┤/SS                 │   GND   GND     │ 
            ┣───9┤SEL                 │                 │
            ┣──14┤SERIN          /BUSY├10─────────────┘
            ┣──27┤AVSS                │        200 
            ┣───8┤VSS     VCAP        │         
            │    └──────────┬─────────┘
            │              20               
            │               │                             
            │                6u2 tantalum   
            │               │               
                                     6u2: 6.2 microF       
           GND             GND         0u1: 100 nF, close to the VDD pins

The SEL pin(9) of the FPU64 is tied to LOW to select SPI mode at Reset and
must remain LOW during operation. In this Demo the 2-wire SPI connection
was used, where the SOUT pin(18) and SIN pin(17) were connected through a
1K resistor and the A2 DIO pin(3) of the Propeller was connected to the SIN
pin(17) of the FPU. Since in this demo only one uM-FPU64 chip is used, the
SPI Slave Select pin(15) of the FPU64 is tied to ground.
}

'                            Interface lines
'            On Propeller                           On FPU64
'-----------------------------------  ------------------------------------
'Sym.   A#/IO       Function            Sym.  P#/IO        Function
'-------------------------------------------------------------------------
_FCLR = 0 'Out  FPU Master Clear   -->  MCLR  1  In   Master Clear
_FCLK = 1 'Out  FPU SPI Clock      -->  SCLK 16  In   SPI Clock Input     
_FDIO = 2 ' Bi  FPU SPI In/Out     -->  SIN  17  In   SPI Data In 
'       └───────────────via 1K     <--  SOUT 18 Out   SPI Data Out


OBJ

PST     : "Parallax Serial Terminal"   'From Parallax Inc.
                                       'v1.0
                                       
FPU     : "FPU64_SPI_Driver"           'v1.1

  
VAR

LONG  okay, fpu64, char
LONG  ptr, strPtr
LONG  cog_ID
LONG  cntr, time, dTime
LONG  dlongVal[2]
LONG  longArray[10]
LONG  floatArray[10]


DAT '------------------------Start of SPIN code---------------------------

  
PUB Start_Application | addrCOG_ID_                                                     
'-------------------------------------------------------------------------
'--------------------------┌───────────────────┐--------------------------
'--------------------------│ Start_Application │--------------------------
'--------------------------└───────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: -Starts driver objects
''             -Makes a MASTER CLEAR of the FPU and
''             -Calls demo procedures
'' Parameters: None
''     Result: None
''+Reads/Uses: /fpu64, Hardware constants from CON section
''    +Writes: fpu64,
''      Calls: FullDuplexSerialPlus->PST.Start
''             FPU_SPI_Driver ------>FPU.StartCOG
''                                   FPU.StopCOG 
''             FPU_Demo, FPU_Demo_Lite 
'-------------------------------------------------------------------------
'Start FullDuplexSerialPlus PST terminal
PST.Start(57600)
  
WAITCNT(4 * CLKFREQ + CNT)

PST.Char(PST#CS)
PST.Str(STRING("Demo of uM-FPU64 with 2-wire SPI connection started..."))
PST.Char(PST#NL)

WAITCNT(CLKFREQ + CNT)

addrCOG_ID_ := @cog_ID

fpu64 := FALSE

'FPU Master Clear...
PST.Str(STRING(10, "FPU64 Master Clear..."))
OUTA[_FCLR]~~ 
DIRA[_FCLR]~~
OUTA[_FCLR]~
WAITCNT(CLKFREQ + CNT)
OUTA[_FCLR]~~
DIRA[_FCLR]~

fpu64 := FPU.StartDriver(_FDIO, _FCLK, addrCOG_ID_)

PST.Chars(PST#NL, 2)  

IF fpu64

  PST.Str(STRING("FPU64 2-wire SPI connection driver started in COG "))
  PST.Dec(cog_ID)
  PST.Chars(PST#NL, 2)
  WAITCNT(CLKFREQ + CNT)

  FPU64_SPI_Demo

  PST.Char(PST#NL)
  PST.Str(STRING("FPU64 2-wire SPI connection demo terminated normally."))

  FPU.StopDriver
   
ELSE

  PST.Char(PST#NL)
  PST.Str(STRING("FPU64 2-wire SPI connection driver start failed!"))
  PST.Chars(PST#NL, 2)
  PST.Str(STRING("Device not detected! Check hardware and try again..."))

WAITCNT(CLKFREQ + CNT)
  
PST.Stop  
'--------------------------End of Start_Application-----------------------    


PRI FPU64_SPI_Demo | i, r, c
'-------------------------------------------------------------------------
'----------------------------┌────────────────┐---------------------------
'----------------------------│ FPU64_SPI_Demo │---------------------------
'----------------------------└────────────────┘---------------------------
'-------------------------------------------------------------------------
'     Action: Demonstrates some uM-FPU64 features by calling 
'             FPU64_SPI_Driver procedures
' Parameters: None
'     Result: None
'+Reads/Uses: /okay, char, Some constants from the FPU object
'    +Writes: okay, char
'      Calls: FullDuplexSerialPlus->PST.Str
'                                   PST.Dec
'                                   PST.Hex
'                                   PST.Bin   
'             FPU64_SPI_Driver ---->FPU. Most of the procedures
'       Note: Emphasize is on 64-bit features 
'-------------------------------------------------------------------------
PST.Char(PST#CS) 
PST.Str(STRING("----uM-FPU64 with 2-wire SPI connection v1.1----"))
PST.Char(PST#NL)

WAITCNT(CLKFREQ + CNT)

okay := FALSE
okay := Fpu.Reset
PST.Char(PST#NL)   
IF okay
  PST.Str(STRING("FPU Software Reset done..."))
  PST.Char(PST#NL)
ELSE
  PST.Str(STRING("FPU Software Reset failed..."))
  PST.Char(PST#NL)
  PST.Str(STRING("Please check hardware and restart..."))
  PST.Char(PST#NL)
  REPEAT

WAITCNT(CLKFREQ + CNT)

char := FPU.ReadSyncChar
PST.Char(PST#NL)
PST.Str(STRING("Response to _SYNC: $"))
PST.Hex(char, 2)
IF (char == FPU#_SYNC_CHAR)
  PST.Str(STRING("    (OK)"))
  PST.Char(PST#NL)  
ELSE
  PST.Str(STRING("   Not OK!"))   
  PST.Char(PST#NL)
  PST.Str(STRING("Please check hardware and restart..."))
  PST.Char(PST#NL)
  REPEAT

PST.Char(PST#NL)
PST.Str(STRING("   Version String: "))
FPU.WriteCmd(FPU#_VERSION)
FPU.Wait
PST.Str(FPU.ReadStr) 

PST.Char(PST#NL)
PST.Str(STRING("     Version Code: $"))
FPU.WriteCmd(FPU#_LREAD0)
PST.Hex(FPU.ReadReg, 8) 
  
PST.Char(PST#NL)
PST.Str(STRING(" Clock Ticks / ms: "))
PST.Dec(FPU.ReadInterVar(FPU#_TICKS))
PST.Char(PST#NL) 

QueryReboot

PST.Char(PST#CS)    
PST.Str(STRING("Math constants in IEEE 754 floating point variables:"))
PST.Chars(PST#NL, 2)

'64-bit operations
FPU.WriteCmdByte(FPU#_SELECTA, 128)
    
PST.Str(STRING("As 64-bit DFLOAT:"))
PST.Chars(PST#NL, 2)

PST.Str(STRING("         Pi = "))
FPU.WriteCmd(FPU#_LOADPI)
FPU.WriteCmdByte(FPU#_FTOA, 0)
WAITCNT(FPU#_FTOAD + CNT)
FPU.Wait
PST.Str(FPU.ReadStr)
PST.Char(PST#NL)
 
PST.Str(STRING("          e = "))
FPU.WriteCmd(FPU#_LOADE)
FPU.WriteCmdByte(FPU#_FTOA, 0)
WAITCNT(FPU#_FTOAD + CNT)
FPU.Wait
PST.Str(FPU.ReadStr)
PST.Chars(PST#NL, 2)

'32-bit operations
FPU.WriteCmdByte(FPU#_SELECTA, 0)    
  
PST.Str(STRING(" As 32-bit FLOAT:"))
PST.Chars(PST#NL, 2)

PST.Str(STRING("         Pi = "))
FPU.WriteCmd(FPU#_LOADPI)
FPU.WriteCmdByte(FPU#_FTOA, 0)
WAITCNT(FPU#_FTOAD + CNT)
FPU.Wait
PST.Str(FPU.ReadStr)
PST.Char(PST#NL)
 
PST.Str(STRING("          e = "))
FPU.WriteCmd(FPU#_LOADE)
FPU.WriteCmdByte(FPU#_FTOA, 0)
WAITCNT(FPU#_FTOAD + CNT)
FPU.Wait
PST.Str(FPU.ReadStr)
PST.Char(PST#NL)

QueryReboot

PST.Char(PST#CS)
PST.Str(STRING("Convert ASCII string to floating point variables"))
PST.Chars(PST#NL, 2)

'64-bit operations
FPU.WriteCmdByte(FPU#_SELECTA, 128)

strPtr := STRING("1.12345678901234")

'Convert string to float
FPU.WriteCmdStr(FPU#_ATOF, strPtr)
'Display the FLOAT value in Reg[A] as a string   
PST.Str(STRING("'1.12345678901234' as 64-bit DFLOAT:"))
PST.Chars(PST#NL, 2)
PST.Str(FPU.ReadRaFloatAsStr(0))
PST.Chars(PST#NL, 2)

'32-bit operations
FPU.WriteCmdByte(FPU#_SELECTA, 0)    

'Convert string to float
FPU.WriteCmdStr(FPU#_ATOF, strPtr)
'Display the FLOAT value in Reg[A] as a string   
PST.Str(STRING("'1.12345678901234' as  32-bit FLOAT:"))
PST.Chars(PST#NL, 2)
PST.Str(FPU.ReadRaFloatAsStr(0))
PST.Char(PST#NL)

QueryReboot

PST.Char(PST#CS)
PST.Str(STRING("Convert ASCII string to 64-bit DLONG"))
PST.Chars(PST#NL, 2)

'64-bit operations
FPU.WriteCmdByte(FPU#_SELECTA, 128)

strPtr := STRING("1234567890123456789")    

'Convert string to DLONG
FPU.WriteCmdStr(FPU#_ATOL, strPtr)
'Display the 64-bit INTEGER value in Reg[A] as a string   
PST.Str(STRING("'1234567890123456789' as 64-bit DLONG: "))
PST.Chars(PST#NL, 2)
PST.Str(FPU.ReadRaLongAsStr(0))
PST.Char(PST#NL)

QueryReboot

PST.Char(PST#CS)
PST.Str(STRING("Write 64-bit DLONG from HUB into FPU"))
PST.Chars(PST#NL, 2)

PST.Str(STRING("DLONG is represented as two 32-bit LONGs in HUB:"))
PST.Char(PST#NL)
PST.Str(STRING("   Most Significant LONG = 20122012"))
PST.Char(PST#NL)
PST.Str(STRING("  Least Significant LONG = 20112011"))
PST.Chars(PST#NL, 2)

dlongVal[0] := 20122012
dlongVal[1] := 20112011

'64-bit operations
FPU.WriteCmdByte(FPU#_SELECTA, 128)
FPU.WriteCmdRnDLong(FPU#_DWRITE, 128, dlongVal[0], dlongVal[1])

PST.Str(STRING("64-bit DLONG read back from FPU64 as"))
PST.Chars(PST#NL, 2)
PST.Str(FPU.ReadRaLongAsStr(0))
PST.Str(STRING(" ((2^32)*20122012 + 20112011)"))
PST.Char(PST#NL)

'Read back 64-bit DLONG data directly
'FPU.WriteCmdByte(FPU#_SELECTA, 128)
'FPU.WriteCmdByte(FPU#_DREAD, 128)
'dlongVal[0] := FPU.ReadReg
'dlongVal[1] := FPU.ReadReg

QueryReboot

PST.Char(PST#CS)
PST.Str(STRING("64-bit DFLOAT addition"))
PST.Str(STRING(PST#NL, PST#NL))

'64-bit operations
FPU.WriteCmdByte(FPU#_SELECTA, 128)
strPtr := STRING("1234.56789012345")
FPU.WriteCmdStr(FPU#_ATOF, strPtr)
PST.Str(FPU.ReadRaFloatAsStr(0))
PST.Char(PST#NL)
PST.Str(STRING("+"))
PST.Char(PST#NL)
FPU.WriteCmdByte(FPU#_SELECTA, 129)
FPU.WriteCmdByte(FPU#_FSET, 128)
FPU.WriteCmdByte(FPU#_SELECTA, 128)
strPtr := STRING("2345.67890123456")
FPU.WriteCmdStr(FPU#_ATOF, strPtr)
PST.Str(FPU.ReadRaFloatAsStr(0))
PST.Char(PST#NL)
PST.Str(STRING("="))
PST.Char(PST#NL)
FPU.WriteCmdByte(FPU#_FADD, 129)
PST.Str(FPU.ReadRaFloatAsStr(0))
PST.Char(PST#NL)

QueryReboot

PST.Char(PST#CS)
PST.Str(STRING("64-bit DFLOAT subtraction"))
PST.Str(STRING(PST#NL, PST#NL))

'64-bit operations
FPU.WriteCmdByte(FPU#_SELECTA, 128)
strPtr := STRING("5678.90123456789")
FPU.WriteCmdStr(FPU#_ATOF, strPtr)
PST.Str(FPU.ReadRaFloatAsStr(0))
PST.Char(PST#NL)
PST.Str(STRING("-"))
PST.Char(PST#NL)
FPU.WriteCmdByte(FPU#_SELECTA, 129)
FPU.WriteCmdByte(FPU#_FSET, 128)
FPU.WriteCmdByte(FPU#_SELECTA, 128)
strPtr := STRING("2345.67890123456")
FPU.WriteCmdStr(FPU#_ATOF, strPtr)
PST.Str(FPU.ReadRaFloatAsStr(0))
PST.Char(PST#NL)
PST.Str(STRING("="))
PST.Char(PST#NL)
FPU.WriteCmdByte(FPU#_SELECTA, 129)
FPU.WriteCmdByte(FPU#_FSUB, 128)
PST.Str(FPU.ReadRaFloatAsStr(0))
PST.Char(PST#NL)

QueryReboot

PST.Char(PST#CS)
PST.Str(STRING("64-bit DFLOAT multiplication"))
PST.Str(STRING(PST#NL, PST#NL))

'64-bit operations
FPU.WriteCmdByte(FPU#_SELECTA, 128)
strPtr := STRING("1234.567891234567")
FPU.WriteCmdStr(FPU#_ATOF, strPtr)
PST.Str(FPU.ReadRaFloatAsStr(0))
PST.Char(PST#NL)
PST.Str(STRING("*"))
PST.Char(PST#NL)
FPU.WriteCmdByte(FPU#_SELECTA, 129)
FPU.WriteCmdByte(FPU#_FSET, 128)
FPU.WriteCmdByte(FPU#_SELECTA, 128)
strPtr := STRING("2345.678912345678")
FPU.WriteCmdStr(FPU#_ATOF, strPtr)
PST.Str(FPU.ReadRaFloatAsStr(0))
PST.Char(PST#NL)
PST.Str(STRING("="))
PST.Char(PST#NL)
FPU.WriteCmdByte(FPU#_FMUL, 129)
PST.Str(FPU.ReadRaFloatAsStr(0))
PST.Char(PST#NL)

QueryReboot

PST.Char(PST#CS)
PST.Str(STRING("64-bit DFLOAT divison"))
PST.Str(STRING(PST#NL, PST#NL))

'64-bit operations
FPU.WriteCmdByte(FPU#_SELECTA, 128)
strPtr := STRING("112233.4455667788")
FPU.WriteCmdStr(FPU#_ATOF, strPtr)
PST.Str(FPU.ReadRaFloatAsStr(0))
PST.Char(PST#NL)
PST.Str(STRING("/"))
PST.Char(PST#NL)
FPU.WriteCmdByte(FPU#_SELECTA, 129)
FPU.WriteCmdByte(FPU#_FSET, 128)
FPU.WriteCmdByte(FPU#_SELECTA, 128)
strPtr := STRING("123.4567890123456")
FPU.WriteCmdStr(FPU#_ATOF, strPtr)
PST.Str(FPU.ReadRaFloatAsStr(0))
PST.Char(PST#NL)
PST.Str(STRING("="))
PST.Char(PST#NL)
FPU.WriteCmdByte(FPU#_SELECTA, 129)
FPU.WriteCmdByte(FPU#_FDIV, 128)
PST.Str(FPU.ReadRaFloatAsStr(0))
PST.Char(PST#NL)

QueryReboot

PST.Char(PST#CS)
PST.Str(STRING("64-bit DLONG addition"))
PST.Str(STRING(PST#NL, PST#NL))

'64-bit operations
FPU.WriteCmdByte(FPU#_SELECTA, 128)
strPtr := STRING("1234567890123456789")
FPU.WriteCmdStr(FPU#_ATOL, strPtr)
PST.Str(FPU.ReadRaLongAsStr(0))
PST.Char(PST#NL)
PST.Str(STRING("+"))
PST.Char(PST#NL)
FPU.WriteCmdByte(FPU#_SELECTA, 129)
FPU.WriteCmdByte(FPU#_LSET, 128)
FPU.WriteCmdByte(FPU#_SELECTA, 128)
strPtr := STRING("987654321098765432")
FPU.WriteCmdStr(FPU#_ATOL, strPtr)
PST.Str(FPU.ReadRaLongAsStr(0))
PST.Char(PST#NL)
PST.Str(STRING("="))
PST.Char(PST#NL)
FPU.WriteCmdByte(FPU#_LADD, 129)
PST.Str(FPU.ReadRaLongAsStr(0))
PST.Char(PST#NL)

QueryReboot

PST.Char(PST#CS)
PST.Str(STRING("64-bit DLONG subtraction"))
PST.Str(STRING(PST#NL, PST#NL))

'64-bit operations
FPU.WriteCmdByte(FPU#_SELECTA, 128)
strPtr := STRING("987654321098765432")
FPU.WriteCmdStr(FPU#_ATOL, strPtr)
PST.Str(FPU.ReadRaLongAsStr(0))
PST.Char(PST#NL)
PST.Str(STRING("-"))
PST.Char(PST#NL)
FPU.WriteCmdByte(FPU#_SELECTA, 129)
FPU.WriteCmdByte(FPU#_LSET, 128)
FPU.WriteCmdByte(FPU#_SELECTA, 128)
strPtr := STRING("123456789012345678")
FPU.WriteCmdStr(FPU#_ATOL, strPtr)
PST.Str(FPU.ReadRaLongAsStr(0))
PST.Char(PST#NL)
PST.Str(STRING("="))
PST.Char(PST#NL)
FPU.WriteCmdByte(FPU#_SELECTA, 129)
FPU.WriteCmdByte(FPU#_LSUB, 128)
PST.Str(FPU.ReadRaLongAsStr(0))
PST.Char(PST#NL)

QueryReboot

PST.Char(PST#CS)
PST.Str(STRING("64-bit DLONG multiplication"))
PST.Str(STRING(PST#NL, PST#NL))

'64-bit operations
FPU.WriteCmdByte(FPU#_SELECTA, 128)
strPtr := STRING("1234567890")
FPU.WriteCmdStr(FPU#_ATOL, strPtr)
PST.Str(FPU.ReadRaLongAsStr(0))
PST.Char(PST#NL)
PST.Str(STRING("*"))
PST.Char(PST#NL)
FPU.WriteCmdByte(FPU#_SELECTA, 129)
FPU.WriteCmdByte(FPU#_LSET, 128)
FPU.WriteCmdByte(FPU#_SELECTA, 128)
strPtr := STRING("2345678901")
FPU.WriteCmdStr(FPU#_ATOL, strPtr)
PST.Str(FPU.ReadRaLongAsStr(0))
PST.Char(PST#NL)
PST.Str(STRING("="))
PST.Char(PST#NL)
FPU.WriteCmdByte(FPU#_LMUL, 129)
PST.Str(FPU.ReadRaLongAsStr(0))
PST.Char(PST#NL)

QueryReboot

PST.Char(PST#CS)
PST.Str(STRING("64-bit DLONG division"))
PST.Str(STRING(PST#NL, PST#NL))

'64-bit operations
FPU.WriteCmdByte(FPU#_SELECTA, 128)
strPtr := STRING("987654321098765432")
FPU.WriteCmdStr(FPU#_ATOL, strPtr)
PST.Str(FPU.ReadRaLongAsStr(0))
PST.Char(PST#NL)
PST.Str(STRING("/"))
PST.Char(PST#NL)
FPU.WriteCmdByte(FPU#_SELECTA, 129)
FPU.WriteCmdByte(FPU#_LSET, 128)
FPU.WriteCmdByte(FPU#_SELECTA, 128)
strPtr := STRING("201220122012")
FPU.WriteCmdStr(FPU#_ATOL, strPtr)
PST.Str(FPU.ReadRaLongAsStr(0))
PST.Char(PST#NL)
PST.Str(STRING("="))
PST.Char(PST#NL)
FPU.WriteCmdByte(FPU#_SELECTA, 129)
FPU.WriteCmdByte(FPU#_LDIV, 128)
PST.Str(FPU.ReadRaLongAsStr(0))
PST.Char(PST#NL)

QueryReboot

PST.Char(PST#CS)    
PST.Str(STRING("Write array of LONGs into a block of FPU64 registers..."))
PST.Chars(PST#NL, 2)

longArray[0] := 2010
longArray[1] := 2011
longArray[2] := 2012
longArray[3] := 2013
longArray[4] := 2014
longArray[5] := 2015
longArray[6] := 2016
longArray[7] := 2017
longArray[8] := 2018
longArray[9] := 2019

'Address of data array = @longArray
'Number of data        = 10ű
'Start Reg No.         = 20
FPU.WriteRegs(@longArray, 10, 20)

PST.Str(STRING("Data check in block of FPU registers:"))
PST.Chars(PST#NL, 2)

'Read back LONG data from FPU registers
REPEAT i FROM 20 TO 29
  PST.Str(STRING("FPU64 Reg("))
  PST.Dec(i)
  PST.Str(STRING(")="))
  FPU.WriteCmdByte(FPU#_SELECTA, i)
  FPU.WriteCmdByte(FPU#_LTOA, 0)
  WAITCNT(FPU#_FTOAD + CNT)
  FPU.Wait
  PST.Str(FPU.ReadStr)
  PST.Char(PST#NL)

QueryReboot

PST.Char(PST#CS)    
PST.Str(STRING("Write array of FLOATs into a block of FPU64 of registers:"))
PST.Chars(PST#NL, 2)

floatArray[0] := 2010.2010
floatArray[1] := 2011.2011
floatArray[2] := 2012.2012
floatArray[3] := 2013.2013 
floatArray[4] := 2014.2014
floatArray[5] := 2015.2015
floatArray[6] := 2016.2016
floatArray[7] := 2017.2017 
floatArray[8] := 2018.2018
floatArray[9] := 2019.2019

'Address of data array = @floatArray
'Number of data        = 10ű
'Start Reg No.         = 30
FPU.WriteRegs(@floatArray, 10, 30)

PST.Str(STRING("Data check in block of FPU registers:"))
PST.Chars(PST#NL, 2)

'Read back data from FPU registers
REPEAT i FROM 30 TO 39
  PST.Str(STRING("FPU64 Reg("))
  PST.Dec(i)
  PST.Str(STRING(")="))
  FPU.WriteCmdByte(FPU#_SELECTA, i)
  FPU.WriteCmdByte(FPU#_FTOA, 0)
  WAITCNT(FPU#_FTOAD + CNT)
  FPU.Wait
  PST.Str(FPU.ReadStr)
  PST.Char(PST#NL)

QueryReboot

PST.Char(PST#CS)    
PST.Str(STRING("Read block of FPU registers with 32-bit LONGs into HUB:"))
PST.Chars(PST#NL, 2)

'Start Reg No.         = 20           'Previously stored LONG array in FPU
'Number of data        = 10           'will overwrite floatArray in HUB
'Address of data array = @floatArray  
FPU.ReadRegs(20, 10, @floatArray)

PST.Str(STRING("This overwrites previous array of FLOATs in HUB"))
PST.Chars(PST#NL, 2)

'Check data read from FPU registers
REPEAT i FROM 0 TO 9
  PST.Str(STRING("HUB/VAR/LONG floatArray["))
  PST.Dec(i)
  PST.Str(STRING("]="))
  PST.Dec(floatArray[i])
  PST.Char(PST#NL)

QueryReboot

PST.Char(PST#CS)
PST.Str(STRING("Some matrix operations with 32-bit FLOATs"))
PST.Str(STRING(PST#NL, PST#NL))
PST.Str(STRING("            1  2  3  ", PST#NL))
PST.Str(STRING("       MA = 4  5  6  ", PST#NL))
PST.Str(STRING("            7  8  8  ", PST#NL))
PST.Char(PST#NL)
'Fill up a matrix
'                          ┌       ┐
'                          │ 1 2 3 │
'                      A = │ 4 5 6 │
'                          │ 7 8 8 │
'                          └       ┘
'Setup MA then read back it's parameters
FPU.WriteCmdByte(FPU#_SELECTA, 0)
FPU.WriteCmd3Bytes(FPU#_SELECTMA, 12, 3, 3)
PST.Str(STRING("MA matrix strored from 32-bit reg #12"))
PST.Chars(PST#NL, 2)
PST.Str(STRING("Read back parameters of MA:"))
PST.Chars(PST#NL, 2)
PST.Str(STRING("      MA register= "))
PST.Dec(FPU.ReadInterVar(FPU#_MA_REG))
PST.Char(PST#NL)
PST.Str(STRING("       X register= "))
PST.Dec(FPU.ReadInterVar(FPU#_X_REG))
PST.Char(PST#NL)
PST.Str(STRING("          MA rows= "))
PST.Dec(FPU.ReadInterVar(FPU#_MA_ROWS))
PST.Char(PST#NL)
PST.Str(STRING("       MA columns= "))
PST.Dec(FPU.ReadInterVar(FPU#_MA_COLS))
PST.Char(PST#NL)

QueryReboot

'Allocate MB and MC 3x3 matrices, too
FPU.WriteCmd3Bytes(FPU#_SELECTMB, 24, 3, 3)
FPU.WriteCmd3Bytes(FPU#_SELECTMC, 36, 3, 3)
  
'Fill MA by directly addressing it's cells
FPU.WriteCmdByte(FPU#_SELECTA, 0)    'Reg[A]=Reg[0]!    
FPU.WriteCmdByte(FPU#_FSETI, 1)
FPU.WriteCmd2Bytes(FPU#_SAVEMA, 0, 0) 
FPU.WriteCmdByte(FPU#_FSETI, 2)
FPU.WriteCmd2Bytes(FPU#_SAVEMA, 0, 1)
FPU.WriteCmdByte(FPU#_FSETI, 3)
FPU.WriteCmd2Bytes(FPU#_SAVEMA, 0, 2)
FPU.WriteCmdByte(FPU#_FSETI, 4)
FPU.WriteCmd2Bytes(FPU#_SAVEMA, 1, 0)
FPU.WriteCmdByte(FPU#_FSETI, 5)
FPU.WriteCmd2Bytes(FPU#_SAVEMA, 1, 1)
FPU.WriteCmdByte(FPU#_FSETI, 6)
FPU.WriteCmd2Bytes(FPU#_SAVEMA, 1, 2)
FPU.WriteCmdByte(FPU#_FSETI, 7)
FPU.WriteCmd2Bytes(FPU#_SAVEMA, 2, 0)
FPU.WriteCmdByte(FPU#_FSETI, 8)
FPU.WriteCmd2Bytes(FPU#_SAVEMA, 2, 1)
FPU.WriteCmd2Bytes(FPU#_SAVEMA, 2, 2)

'Copy MA to MB and to MC
FPU.WriteCmdByte(FPU#_MOP, FPU#_MX_COPYAB)
FPU.WriteCmdByte(FPU#_MOP, FPU#_MX_COPYAC)
   
'Now read back MA's elements
PST.Char(PST#CS)
PST.Str(STRING("Read back elements of MA:"))
PST.Chars(PST#NL, 2)
REPEAT r FROM 0 TO 2
  REPEAT c FROM 0 TO 2
    PST.Str(STRING("          MA["))
    PST.Dec(r+1)
    PST.Str(STRING(","))
    PST.Dec(c+1)
    PST.Str(STRING("]= "))
    FPU.WriteCmd2Bytes(FPU#_LOADMA, r, c)
    FPU.WriteCmdByte(FPU#_SELECTA, 0)   
    PST.Str(FPU.ReadRaFloatAsStr(0))
    PST.Char(PST#NL)

QueryReboot    

PST.Char(PST#CS)
PST.Str(STRING("Calculate Determinant and Inverse of MA:"))
PST.Char(PST#NL)

' Det(MA) = 3
'
'                    ┌                ┐
'                    │ -8/3   8/3  -1 │
' Inv(MA) = {1/MA} = │ 10/3 -13/3   2 │ 
'                    │   -1    2   -1 │
'                    └                ┘
  
'Calculate determinant of MA
FPU.WriteCmdByte(FPU#_MOP, FPU#_MX_DETERM)

PST.Char(PST#NL)
PST.Str(STRING("          Det(MA)= "))
'Since Reg[A]=Reg[0]
PST.Str(FPU.ReadRaFloatAsStr(0))
PST.Char(PST#NL)
  
'Calculat inverse of MB where MB=original MA
'Inverse will be written to MA
FPU.WriteCmdByte(FPU#_MOP, FPU#_MX_INVERSE)

PST.Char(PST#NL)
PST.Str(STRING("Inverse of (MA):"))
'Now read back elements of MA again.
PST.Chars(PST#NL, 2)
REPEAT r FROM 0 TO 2
  REPEAT c FROM 0 TO 2
    PST.Str(STRING("      {1/MA}["))
    PST.Dec(r+1)
    PST.Str(STRING(","))
    PST.Dec(c+1)
    PST.Str(STRING("]= "))
    FPU.WriteCmd2Bytes(FPU#_LOADMA, r, c) 
    PST.Str(FPU.ReadRaFloatAsStr(0))
    PST.Char(PST#NL) 

QueryReboot

'Now MA contains {1/MA}, MC contains the original MA
'Copy MA to MB
FPU.WriteCmdByte(FPU#_MOP, FPU#_MX_COPYAB)
'Matrix multiply MA= MB*MC i.e. Result = InvMA * MA : should be I matrix
FPU.WriteCmdByte(FPU#_MOP, FPU#_MX_MULTIPLY)
'Now read back elements of MA again
PST.Char(PST#CS)
PST.Str(STRING("Check  MA * {1/MA} matrix product:"))
PST.Chars(PST#NL, 2)
REPEAT r FROM 0 TO 2
  REPEAT c FROM 0 TO 2
    PST.Str(STRING("   MA*{1/MA}["))
    PST.Dec(r+1)
    PST.Str(STRING(","))
    PST.Dec(c+1)
    PST.Str(STRING("]= "))
    FPU.WriteCmd2Bytes(FPU#_LOADMA, r, c) 
    PST.Str(FPU.ReadRaFloatAsStr(0))
    PST.Char(PST#NL)  
  
QueryReboot
  
'Check FFT operation with 32-bit FLOATs
PST.Char(PST#CS)
PST.Str(STRING("16 complex points of FLOATs, in-place FFT"))
PST.Chars(PST#NL, 2)

'Calculate the frequency domain of a pulse at t=1 (Re[1]=1, Im[1]=0)
'ReX(t), ImX(t) data points (16x2=32) can fit in a matrix
'somewhere in the FPU's register memory
FPU.WriteCmd3Bytes(FPU#_SELECTMA, 88, 16, 2) 'For example from Reg[88]
  
'Clear MA, Reg[X] now points to the beginning of MA, so
REPEAT 32
  FPU.WriteCmd(FPU#_CLRX)
'Set ReX[1] = 1 everthing else is zero
FPU.WriteCmdByte(FPU#_SELECTA, 0)    
FPU.WriteCmdByte(FPU#_FSETI, 1)
FPU.WriteCmd2Bytes(FPU#_SAVEMA, 1, 0)

PST.Str(STRING("Real part of input data:"))
PST.Chars(PST#NL, 2)
cntr := 0
REPEAT 16
  FPU.WriteCmd2Bytes(FPU#_LOADMA, cntr++, 0)
  PST.Str(FPU.ReadRaFloatAsStr(0))
  PST.Char(PST#NL)
PST.Char(PST#NL)
PST.Str(STRING("Imaginary part is all zero."))
PST.Char(PST#NL)
  
'Do one-shot in-place FFT with bit-reverse sort pre-processing
FPU.WriteCmdByte(FPU#_FFT, FPU#_BIT_REVERSE)

QueryReboot 
  
'Real part of frequency domain (should be cosine shape at f=0)
PST.Char(PST#CS)
PST.Str(STRING("Real part of DFT result (COSINE shape):"))
PST.Chars(PST#NL, 2)
cntr := 0
REPEAT 16
  FPU.WriteCmd2Bytes(FPU#_LOADMA, cntr++, 0)
  PST.Str(FPU.ReadRaFloatAsStr(0))
  PST.Char(PST#NL)

QueryReboot

'Imaginary part of frequency domain (should be -sine shape at f=0)
PST.Char(PST#CS) 
PST.Str(STRING("Imaginary part of DFT result (-SINE shape):"))
PST.Chars(PST#NL, 2)
cntr := 0
REPEAT 16
  FPU.WriteCmd2Bytes(FPU#_LOADMA, cntr++, 1)
  PST.Str(FPU.ReadRaFloatAsStr(0))
  PST.Char(PST#NL)

QueryReboot    
'---------------------------End of FPU64_SPI_Demo-------------------------


PRI QueryReboot | done, r
'-------------------------------------------------------------------------
'------------------------------┌─────────────┐----------------------------
'------------------------------│ QueryReboot │----------------------------
'------------------------------└─────────────┘----------------------------
'-------------------------------------------------------------------------
'     Action: Queries to reboot or to finish
' Parameters: None                                
'     Result: None                
'+Reads/Uses: PST#NL, PST#PX                     (OBJ/CON)
'    +Writes: None                                    
'      Calls: "Parallax Serial Terminal"--------->PST.Str
'                                                 PST.Char 
'                                                 PST.RxFlush
'                                                 PST.CharIn
'------------------------------------------------------------------------
PST.Char(PST#NL)
PST.Str(STRING("[R]eboot or press any other key to continue..."))
PST.Char(PST#NL)
done := FALSE
REPEAT UNTIL done
  PST.RxFlush
  r := PST.CharIn
  IF ((r == "R") OR (r == "r"))
    PST.Char(PST#PX)
    PST.Char(0)
    PST.Char(32)
    PST.Char(PST#NL) 
    PST.Str(STRING("Rebooting..."))
    WAITCNT((CLKFREQ / 10) + CNT) 
    REBOOT
  ELSE
    done := TRUE
'----------------------------End of QueryReboot---------------------------


DAT '---------------------------MIT License------------------------------- 


{{
┌────────────────────────────────────────────────────────────────────────┐
│                        TERMS OF USE: MIT License                       │                                                            
├────────────────────────────────────────────────────────────────────────┤
│  Permission is hereby granted, free of charge, to any person obtaining │
│ a copy of this software and associated documentation files (the        │ 
│ "Software"), to deal in the Software without restriction, including    │
│ without limitation the rights to use, copy, modify, merge, publish,    │
│ distribute, sublicense, and/or sell copies of the Software, and to     │
│ permit persons to whom the Software is furnished to do so, subject to  │
│ the following conditions:                                              │
│                                                                        │
│  The above copyright notice and this permission notice shall be        │
│ included in all copies or substantial portions of the Software.        │  
│                                                                        │
│  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND        │
│ EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF     │
│ MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. │
│ IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY   │
│ CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,   │
│ TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE      │
│ SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                 │
└────────────────────────────────────────────────────────────────────────┘
}}