{{
┌──────────────────────────────────────────┐
│ LMM I2C Test Driver 1.1                  │
│ Author: Tim Moore                        │
│ Copyright (c) June 2010 Tim Moore        │
│ See end of file for terms of use.        │
└──────────────────────────────────────────┘

 Supports writing I2C device driver objects that use inline PASM

}}
CON
'  _clkmode = xtal1 + pll16x
'  _xinfreq = 5_000_000
  _clkmode        =             xtal1 + pll8x
  _xinfreq        =             10_000_000

#define LMM                     'enable lmm
#define QUICKATAN2              'enable faster atan2
#define I2CDEBUG                'display debug messages when i2c fails

OBJ
                                                        '1 Cog here
  uarts         : "pcFullDuplexSerial4FC"               '1 Cog for 4 serial ports

  i2cObject     : "basic_i2c_driver"                    '0 Cog

  i2cScan       : "i2cScan"                             '0 Cog

  lmm           : "SpinLMM"                             '0 Cog

  gyro          : "itg3200objectlmm"                    '0 Cog

  compass       : "HMC5843qObjectlmm"                   '0 Cog

  acc           : "adxl345objectlmm"                    '0 Cog

  pressure      : "BMP085Objectlmm"                     '0 Cog

  servo         : "pwm_32_sv2"                          '1 Cog - ESCs

  config        : "config"                              '0 Cog required

VAR
  long i2cSCL                                           'SCL pin number
  long gyroAddr, accAddr, comAddr, pressureAddr         'I2C device addresses
  long XG, YG, ZG, Temp
  long XA, YA, ZA, TempV, PressureV      'values from sensors
  long XC, YC, ZC
  long ttime, fttime
  long stime, etime
  long sptime, eptime
  long satime, eatime
  long sgtime, egtime
  long AverageP

  long test1[5]

PUB main | count, value, time1[3], time2[3], instr[20]

  config.Init(@pininfo, @i2cinfo)                       'init config tables

  servo.start
  servo.ServoFast(config.GetPin(CONFIG#SERVO1), 1000, 5000) 'must set escs to min setting or esc will not enable
  servo.ServoFast(config.GetPin(CONFIG#SERVO2), 1000, 5000)
  servo.ServoFast(config.GetPin(CONFIG#SERVO3), 1000, 5000)
  servo.ServoFast(config.GetPin(CONFIG#SERVO4), 1000, 5000)

'  i2cSCL := config.GetPin(CONFIG#I2C_SCL1)             'uncomment this if using pin 28 for SCL
  i2cSCL := config.GetPin(CONFIG#I2C_SCL2)             'uncomment this if using pin 28 for SCL

  uarts.Init                                            'Init serial ports

  if ina[config.GetPin(CONFIG#DEBUG_RX)] == 1           'dont start debug port if not connected
    uarts.AddPort(0, config.GetPin(CONFIG#DEBUG_RX), config.GetPin(CONFIG#DEBUG_TX), {
}     UARTS#PINNOTUSED, UARTS#PINNOTUSED, UARTS#DEFAULTTHRESHOLD, {
}     UARTS#NOMODE, UARTS#BAUD115200)                   'Add debug port

  uarts.Start                                           'Start the ports

  i2cObject.Initialize(i2cSCL)                          'init I2C bus

  waitcnt(clkfreq*3 + cnt)                              'start-up delay

  uarts.str(0, string("LMM HMC5843/ITG-3200 test", 13))

  ' Run time tests before adding LMM PASM interpreter
  TimeTest(@time1)

  ' Start the LMM interpreter
  lmm.start

  ' Run time tests after adding LMM PASM interpreter
  TimeTest(@time2)

  uarts.dbprintf2(0, string("sqrt cycles = %d, %d\n"), time1[0], time2[0])
  uarts.dbprintf2(0, string("strsize cycles = %d, %d\n"), time1[1], time2[1])
  uarts.dbprintf2(0, string("strcomp cycles = %d, %d\n"), time1[2], time2[2])

  i2cScan.i2cScan(i2cSCL)                               'display I2C devices

  comAddr := config.GetI2C(CONFIG#HMC5843)              'compass I2C address
  gyroAddr := config.GetI2C(CONFIG#ITG3200)             'gyro I2C address
  accAddr := config.GetI2C(CONFIG#ADXL345)              'acc I2C address
  pressureAddr := config.GetI2C(CONFIG#BMP085)

  uarts.str(0, string("ITG-3200 init: "))
  if gyro.Init(i2cSCL, gyroAddr)                        'init gyro
    uarts.str(0, string("ok", 13))
  else
    uarts.str(0, string("failed", 13))
  uarts.str(0, string("HMC5843 init: "))
  if compass.Init(i2cSCL, comAddr, true)                'init compass
    uarts.str(0, string("ok", 13))
  else
    uarts.str(0, string("failed", 13))

  uarts.str(0, string("ADXL345 init: "))
  if acc.Init(i2cSCL, accAddr)                          'init acc, default to ±16G
    uarts.str(0, string("ok", 13))
  else
    uarts.str(0, string("failed", 13))

  uarts.str(0, string("BMP085 init: "))
  if pressure.Init(i2cSCL, pressureAddr)                'init presssure sensor
    uarts.str(0, string("ok", 13))
  else
    uarts.str(0, string("failed", 13))

  gyro.SetZero(i2cSCL, gyroAddr)                        'get an average of gyro values, to subtract from later values
  count := 1
  repeat
    waitcnt(clkfreq/50 + cnt)
    sgtime := cnt
    gyro.GetGyro(i2cSCL, gyroAddr, @XG, @YG, @ZG, @Temp)
    egtime := cnt

    stime := cnt
    compass.GetData(i2cSCL, comAddr, @XC, @YC, @ZC)
    etime := cnt

    satime := cnt
    acc.GetAcceleration(i2cSCL, accAddr, @XA, @YA, @ZA)
    eatime := cnt
    sptime := cnt
    if pressure.GetPressureTempA(i2cSCL, pressureAddr, 3, @TempV, @PressureV)
      eptime := cnt
      if AverageP == 0
        AverageP := PressureV                           '1st time
      else
        AverageP := (15*AverageP + PressureV)>>4        'Filter
    else
      eptime := cnt
    ttime := (ttime*7 + (eptime-sptime)) ~> 3

    if count++ == 0

      uarts.str(0, string("Gyro (x,y,z,t), Compass (x,y,z): "))

      uarts.dec(0, XG)                                   'ITG3200 gyro output
      uarts.tx(0, " ")
      uarts.dec(0, YG)
      uarts.tx(0, " ")
      uarts.dec(0, ZG)
      uarts.tx(0, " ")
      uarts.dec(0, Temp/280)                            'temp is °C * 280
      uarts.tx(0, ".")
      uarts.dec(0, ((Temp*10)/28)//100)
      uarts.str(0, string("°C, "))
      uarts.dec(0, (egtime-sgtime)/(clkfreq/1000000))
      uarts.str(0, string("us "))

      uarts.dec(0, XC)                                  'HMC5843 compass output
      uarts.tx(0, " ")
      uarts.dec(0, YC)
      uarts.tx(0, " ")
      uarts.dec(0, ZC)
      uarts.tx(0, " ")

      uarts.dec(0, (etime-stime)/(clkfreq/1000000))
      uarts.strln(0, string("us "))

      uarts.str(0, string("Acc (x,y,z), Pressure (T,P): "))

      uarts.dec(0, XA)                                  'ADXL345 acc output
      uarts.tx(0, " ")
      uarts.dec(0, YA)
      uarts.tx(0, " ")
      uarts.dec(0, ZA)
      uarts.tx(0, " ")
      uarts.dec(0, (eatime-satime)/(clkfreq/1000000))
      uarts.str(0, string("us "))

      uarts.dec(0, TempV/10)                            'BMP085 output
      uarts.tx(0, ".")                                  'temp is °C * 10
      uarts.dec(0, TempV//10)
      uarts.str(0, string("°C "))
      uarts.dec(0, PressureV)
      uarts.str(0, string("kPa, "))
      uarts.dec(0, ttime/(clkfreq/1000000))
      uarts.strln(0, string("us"))

    count //= 20

' This routine runs timing tests on sqrt, strsize and strcomp
PUB TimeTest(pTimes) | cycles, ptr

  ptr :=  string("1234567890123456789012345")

  cycles := cnt
  result := ^^ 169
  cycles := cnt - cycles
  long[pTimes][0] := cycles

  cycles := cnt
  result := strsize(ptr)
  cycles := cnt - cycles
  long[pTimes][1] := cycles

  cycles := cnt
  result := strcomp(ptr, ptr)
  cycles := cnt - cycles
  long[pTimes][2] := cycles

DAT
pininfo       word CONFIG#NOT_USED              'pin 0
              word CONFIG#NOT_USED              'pin 1
              word CONFIG#SERVO1                'pin 2 ESC1 - front motor ccw
              word CONFIG#SERVO2                'pin 3 ESC2 - back motor ccw
              word CONFIG#SERVO3                'pin 4 ESC3 - left motor cw
              word CONFIG#SERVO4                'pin 5 ESC4 - right motor cw
              word CONFIG#I2C_SCL2              'pin 6 I2C SCL
              word CONFIG#I2C_SDA2              'pin 7 I2C SDA
              word CONFIG#NOT_USED              'pin 8
              word CONFIG#NOT_USED              'pin 9
              word CONFIG#NOT_USED              'pin 10
              word CONFIG#NOT_USED              'pin 11
              word CONFIG#NOT_USED              'pin 12
              word CONFIG#NOT_USED              'pin 13
              word CONFIG#NOT_USED              'pin 14
              word CONFIG#NOT_USED              'pin 15
              word CONFIG#NOT_USED              'pin 16
              word CONFIG#NOT_USED              'pin 17
              word CONFIG#NOT_USED              'pin 18
              word CONFIG#NOT_USED              'pin 19
              word CONFIG#NOT_USED              'pin 20
              word CONFIG#NOT_USED              'pin 21
              word CONFIG#NOT_USED              'pin 22
              word CONFIG#NOT_USED              'pin 23
              word CONFIG#NOT_USED              'pin 24
              word CONFIG#NOT_USED              'pin 25
              word CONFIG#NOT_USED              'pin 26
              word CONFIG#NOT_USED              'pin 27
              word CONFIG#I2C_SCL1              'pin 28
              word CONFIG#I2C_SDA1              'pin 29
              word CONFIG#DEBUG_TX              'pin 30
              word CONFIG#DEBUG_RX              'pin 31

{┌────────────────────┬──────────────────────────────────────────────────────────────────────────────────────}
'│I2C device addresses│
'└────────────────────┘
'Table of I2C devices and their I2C addresses
i2cinfo
              byte CONFIG#ITG3200
              byte %1101_0010                   'gyro I2C address
              byte CONFIG#ADXL345
              byte %1010_0110                   'acc I2C address
              byte CONFIG#HMC5843
              byte %0011_1100                   'compass I2C address
              byte CONFIG#BMP085
              byte %1110_1110                   'pressure sensor I2C address
              byte CONFIG#NOT_USED
              byte CONFIG#NOT_USED

