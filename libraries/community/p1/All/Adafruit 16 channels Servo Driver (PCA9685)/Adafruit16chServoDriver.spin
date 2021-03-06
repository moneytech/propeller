{{
=================================================================================================
  File....... ADAFRUIT 16 Channels servodriver based on PCA9685 (16-Channel I2C Servo/PWM Driver)
  Author..... JeromeLab             
  E-mail..... Jerome@lab-au.com
  Started.... 16 May 2018
  Updated....
        v0.1   initial release 
=================================================================================================
 refer to https://learn.adafruit.com/16-channel-pwm-servo-driver/overview
 for addressing and other information.

 This is a minimum object to get you started, it uses excellent I2C drivers by Chris Gadd, available in the OBEX
 You can uncomment/comment some lines below to use I2C PASM driver(faster) instead of the default I2C SPIN driver
 It can be used as a bare PCA9685 driver (rather than with the Adafruit 16 channels pwm/servo driver board)          
 
                                    Prop (other pins than EEPROM SCL/SDA)
                                     ΔΔ
                 ┌------------┐      ||
       ┌-------A0|1         28|Vdd   | 10k(optional)
       |-------A1|2         27|SDA---┘ 10k(optional)            
      Gnd      A2|3         26|SCL----┘    gnd          
               A3|4         25|EXTCLK ------┘
               A4|5         24|A5    
             LED0|6         23|OE
             LED1|7         22|LED15
             LED2|8         21|LED14
             LED3|9         20|LED13
             LED4|10        19|LED12
             LED5|11        18|LED11
             LED6|12        17|LED10
             LED7|13        16|LED9
              Vss|14        15|LED8 
                 └────────────┘

}}

CON
  
  PCA9685_SUBADR1 = $02
  PCA9685_SUBADR2 = $03
  PCA9685_SUBADR3 = $04
   
  PCA9685_MODE1 = $00
  PCA9685_PRESCALE = $FE
   
  LED0_ON_L = $06
  LED0_ON_H = $07
  LED0_OFF_L = $08
  LED0_OFF_H = $09
   
  ALLLED_ON_L = $FA
  ALLLED_ON_H = $FB
  ALLLED_OFF_L = $FC
  ALLLED_OFF_H = $FD

  
OBJ

  I2C        : "I2C Spin driver v1.4od"  'use SPIN I2C driver 'comment for using the pasm driver
  'I2C        : "I2C PASM driver v1.8od"  'use PASM I2C driver(use 1 cog) 'uncomment for using the paasm driver

VAR

  byte setPWMData[4]
  byte pca9685address
  byte i2cscl
  byte i2csda

PUB init(i2caddress,scl,sda)

  pca9685address:=i2caddress
  i2cscl:=scl
  i2csda:=sda

  'I2C.start(SCL, SDA, 150000) 'max 400Kbits (400_000) use slower for longuer I2C lines  uncomment for using PASM I2C driver    

  I2C.init(i2cscl, i2csda) 'using I2C spin driver comment for using PASM I2C driver
  
PUB reset

  I2C.writeByte(pca9685address,PCA9685_MODE1,$80)
  PauseMSec(10)
  
PUB getmode 
  return I2C.readByte(pca9685address,PCA9685_MODE1)

PUB getprescale
  return I2C.readByte(pca9685address,PCA9685_PRESCALE)
    
PUB setPWMFreq(freq) | prescaleval,newmode


  freq:=freq* 90  ' Correct for overshoot in the frequency setting
  freq:=freq/100
  
  prescaleval := 25000000  'internal clock frequency
  prescaleval := prescaleval/4096 'divided by 12bit
  prescaleval := prescaleval/freq
  prescaleval := prescaleval-1

  newmode := %00010001 'Sleep ON, respond to all call ON
  
  I2C.writeByte(pca9685address,PCA9685_MODE1, newmode)'go to sleep
  I2C.writeByte(pca9685address,PCA9685_PRESCALE, prescaleval)' set the prescaler
  newmode := SetBit(newmode,4,0) 'Sleep OFF
  newmode := SetBit(newmode,5,1) 'Auto increment ON
  I2C.writeByte(pca9685address,PCA9685_MODE1, newmode)
  PauseMSec(5)

PUB setPWM(num, on, off)

  setPWMData[0] := on
  setPWMData[1] := on >> 8
  setPWMData[2] := off
  setPWMData[3] := off >> 8

  I2C.writeBytes(pca9685address,LED0_ON_L+4*num,@setPWMData,4)
  
PRI SetBit (In,Bit,OnOff) : Out
   Out := (In & !(1<<bit)) | (OnOff << Bit)
   
PRI PauseMSec(Duration)
  waitcnt(((clkfreq / 1_000 * Duration - 3932) #> 381) + cnt)
DAT                     
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