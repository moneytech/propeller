{      

VC0706 (radio shack camera beard; ladyada serial camera; and others) driver
very basic
push button, receive jpg (there are a few bytes in the back of the buffer, remember that
a jpg file starts with FFD8 and ends with FFD9. you will get a few bytes past the FFD9, can be cleaned up but it's faster to send them than to write a cleanup, honestly)

contains stub for also sending a text frame because this is for environmental monitoring and robotics

see my other work at www.f3.to

mit license, i guess

mkb@robots-everywhere.com
}


CON
        _clkmode = xtal1 + pll16x                                               'Standard clock mode * crystal frequency = 80 MHz
        _xinfreq = 5_000_000

VAR
  long  symbol
   
OBJ
  com1      : "FullDuplexSerial"
  com2      : "FullDuplexSerial"
  

var
byte buflenb[4] 'i'm lazy with the endianness
long buflenl

byte txtbuffer[256] ' accompanying ascii data such as gps and sensors
byte imgbuffer[BUFSIZE] ' image

pub start

com1.start(31,30,%0000,115200)
com2.start(27,26,%0000,115200)
rxflush

if (reset)
   com1.tx("R")
else
   com1.tx("r")

waitcnt(cnt+clkfreq)
rxflush

if (getversion)
   com1.tx("V")
else
   com1.tx("v")
rxflush

if (setresolution(RES_QQVGA))
   com1.tx("Q")
else
   com1.tx("q")
rxflush

if (setcompression($FF))' this stops the frame
   com1.tx("C")
else
   com1.tx("c")
rxflush

if (resumephoto)
  com1.tx("F")
else
  com1.tx("f")
rxflush

repeat

 com1.rx ' push button, receive jpg

 com1.str(string("<t>"))
 com1.str(@txtbuffer)
 com1.tx(",")

 if (resumephoto)
   com1.tx("F")
 else
   com1.tx("f")
 rxflush

 if (takephoto)
   com1.tx("T")
 else
   com1.tx("t")
 rxflush

 if (getbuflen)
   com1.tx("B")
 else
   com1.tx("b")
 rxflush

  com1.tx(",")
 com1.dec(buflenl)
 com1.str(string("<i>")) ' frame separator

 readbuffer ' also outputs, while we're at it. this is not interruptable.

 if (resumephoto)
    com1.str(string("<d>")) ' frame separator
 else
    com1.str(string("<d>")) ' frame separator

 rxflush


{
repeat
  result:=com1.rxcheck
  if (result>-1)
     com2.tx(result)
  result:=com2.rxtimecheck
  if (result>-1)
     com1.tx(result)
}


con
BUFSIZE = 4096
BAUD = 115200
SERIALNUM = 0 ' start with 0
COMMANDSEND = $56
COMMANDREPLY = $76
COMMANDEND = $00
CMD_GETVERSION = $11
CMD_RESET = $26
CMD_TAKEPHOTO = $36
CMD_READBUFF = $32
CMD_GETBUFFLEN = $34
FBUF_CURRENTFRAME = $00
FBUF_NEXTFRAME = $01
FBUF_RESUMEFRAME = $02
FBUF_STOPCURRENTFRAME = $00
CMD_JPEG=$31
RES_VGA=$00
RES_QVGA=$11
RES_QQVGA=$22

TIMEOUT=5 ' in milliseconds, not a hex value.
LONGTIMEOUT=200
'6. Set photo compression ratio command:56 00 31 05 01 01 12 04 XX Return：76 00 31 00 00
'7. Set photo size command: 
'56 00 31 05 04 01 00 19 22 （160*120）Return：76 00 31 00 00
'56 00 31 05 04 01 00 19 11 （320*240）Return：76 00 31 00 00
'56 00 31 05 04 01 00 19 00 （640*480）Return：76 00 31 00 00 

pri sendcmd(a,b,c,d,e)
com2.tx(a)
com2.tx(b)
com2.tx(c)
com2.tx(d)
if (e<>-1)  ' actually d is "how many bytes after this"
  com2.tx(e)
  
pri checkreply(checkme)
if com2.rxtime(LONGTIMEOUT)<>$76
   return false
if com2.rxtime(LONGTIMEOUT)<>SERIALNUM
   return false
if com2.rxtime(LONGTIMEOUT)<>checkme
   return false
if com2.rxtime(LONGTIMEOUT)<>$00
   return false
return true

pri rxflush
repeat
  result:=com2.rxtime(TIMEOUT)
  if result==-1
     quit
 ' com1.tx(result)

pri setcompression(c)
sendcmd(COMMANDSEND,SERIALNUM,CMD_JPEG,$05,$01)
sendcmd($01,$12,$04,c,-1)
result:=checkreply(CMD_JPEG)
rxflush

pri setresolution(rr)
sendcmd(COMMANDSEND,SERIALNUM,CMD_JPEG,$05,$04)
sendcmd($01,$00,$19,rr,-1)
result:=checkreply(CMD_JPEG)
rxflush

pri getversion
sendcmd(COMMANDSEND,SERIALNUM,CMD_GETVERSION,COMMANDEND,COMMANDEND)
result:=checkreply(CMD_GETVERSION)
rxflush

pri reset
sendcmd(COMMANDSEND,SERIALNUM,CMD_RESET,COMMANDEND,COMMANDEND)
result:=checkreply(CMD_RESET)
rxflush

pri takephoto
sendcmd(COMMANDSEND,SERIALNUM,CMD_TAKEPHOTO,$01,FBUF_STOPCURRENTFRAME)
result:=checkreply(CMD_TAKEPHOTO)
result:=result and (com2.rxtime(LONGTIMEOUT)==$00)  
rxflush

pri resumephoto
sendcmd(COMMANDSEND,SERIALNUM,CMD_TAKEPHOTO,$01,FBUF_RESUMEFRAME)
result:=checkreply(CMD_TAKEPHOTO)
result:=result and (com2.rxtime(LONGTIMEOUT)==$00)  
rxflush

pri getbuflen
sendcmd(COMMANDSEND,SERIALNUM,CMD_GETBUFFLEN,$01,FBUF_CURRENTFRAME)
result:=checkreply(CMD_GETBUFFLEN)
result:=result and (com2.rxtime(LONGTIMEOUT)==$04)
if (result)
  buflenb[0]:=com2.rxtime(LONGTIMEOUT)
  buflenb[1]:=com2.rxtime(LONGTIMEOUT)
  buflenb[2]:=com2.rxtime(LONGTIMEOUT)
  buflenb[3]:=com2.rxtime(LONGTIMEOUT)
  buflenl:=(buflenb[0]*16777216)+(buflenb[1]*65536)+(buflenb[2]*256)+(buflenb[3]*1)
else
  buflenl:=0

con packetsize = 48'32 ' seems to be max
pri readbuffer | addr
if buflenl==0 or buflenl > BUFSIZE
   return false

addr:=0
'while(addr < (buflenl))


repeat

  if (addr>(buflenl))''+packetsize))
     rxflush
     quit ' worked
     

  sendcmd(COMMANDSEND,SERIALNUM,CMD_READBUFF,$0c,FBUF_CURRENTFRAME)
'  sendcmd($0a,(addr/16777216)&$FF,(addr/65536)&$FF,(addr/256)&$FF,addr&$FF)
  sendcmd($0a,(addr>>24)&$FF,(addr>>16)&$FF,(addr>>8)&$FF,addr&$FF)
  sendcmd(00,00,(packetsize/256)&$FF,packetsize&$FF,-1)
  com2.tx($00) ' delay 1
  com2.tx($40) ' delay 2


  if checkreply(CMD_READBUFF)== false
       com1.tx("!")
       

  com2.rxtime(LONGTIMEOUT) ' there's an extra zero
  

  repeat packetsize ' this guy here is very time critical, we're flooding a serial buffer!
     imgbuffer[addr]:=com2.rx
     com1.tx(imgbuffer[addr++])
     'addr++

  if checkreply(CMD_READBUFF)== false
       com1.tx("?")


  com2.rxtime(LONGTIMEOUT) ' there's an extra zero

var
long jpgstart
long jpgend
pri playbuffer | addr, ffd8, ffd9
com1.str(string("<it>")) ' frame separator
com1.str(@txtbuffer) ' if any; skip txtbuffer if first byte is zero

{
pri playbuffer | addr, ffd8, ffd9

addr~~
ffd8~
ffd9~              

repeat buflenl
  if imgbuffer[++addr]==$FF
     if imgbuffer[addr+1]==$D8
         ffd8:=addr
     if imgbuffer[addr+1]==$D9
         ffd9:=addr

com1.str(string("<fr>")) ' frame start (ffd8 and ffd9 can be used as frame separators, i guess...)
addr:=ffd8
repeat (ffd9-ffd8)+2
  com1.tx(imgbuffer[addr++])        
com1.str(string("<it>")) ' frame separator
com1.str(@txtbuffer) ' if any; skip txtbuffer if first byte is zero
com1.str(string("</fr>"))' frame end
}  