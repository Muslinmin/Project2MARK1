{{

  File: Sensors

  Developer: Kenichi Kato
  Copyright (c) 2021, Singapore Institute of Technology
  Platform: Parallax USB Project Board (P1)
  Date: 09 Sep 2021
  V2:
    19 Jan 2022

}}
CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000
  _ConClkFreq = ((_clkmode - xtal1) >> 6) * _xinfreq
  _Ms_001   = _ConClkFreq / 1_000


CON

  _maxI2CDevice = 5   ' 0 to 7

  ACK = 0                                                   'signals ready for more
  NAK = 1                                                   'signals not ready for more

OBJ
  ' Definition / Header files
  Def   : "RxBoardDef.spin"

  '' TCA9548A - I2C connection to ToF & Ultrasonic
  TCA : "TCA9548Av2"   'I2C 1-to-8 Switch
  'pst   : "Parallax Serial Terminal.spin"
  ' Debugging
  'DBG   : "FullDuplexSerialExt.spin"

VAR
  long  cog, cogStack[128]
  long mainHubMS

PUB Start(MS, tofMainMem, ultraMainMem)
{{ Launch sensors units into new core }}
  mainHubMS := MS
  Stop
  cog := cognew(runnAllSensors(tofMainMem, ultraMainMem), @cogStack) + 1
  return cog

PUB Stop

  if(cog)
    cogstop(~cog - 1 )
  return

PUB runnAllSensors(tofMainMem, ultraMainMem) | i
{{ Main code running sensors retrieving & updating main memory }}
  '' Init TCA9548A
  TCA.PInit2
  Pause(100)

  ' Init ToF
  TCA.PSelect(0, 0)
  tofInit(0)
  Pause(500)
  TCA.PSelect(1, 0)
  tofInit(1)
  Pause(500)

  repeat

    ' ToF 1 - Front
    TCA.PSelect(0, 0)
    long[tofMainMem][0] := TCA.GetSingleRange(Def#ToFAdd)
    Pause(1)

    ' ToF 2 - Back
    TCA.PSelect(1, 0)
    long[tofMainMem][1] := TCA.GetSingleRange(Def#ToFAdd)
    Pause(1)

    ' Ultrasonic 1 - Front
    TCA.PSelect(2, 0)
    TCA.PWriteByte(2, Def#UltraAdd, $01)  '<-- Trigger Sensor
    Pause(30)
    long[ultraMainMem][0] := TCA.readHCSR04(2, Def#UltraAdd)*100/254
    Pause(1)
    TCA.resetHCSR04(2, Def#UltraAdd)


    ' Ultrasonic 2 - Back
    TCA.PSelect(3, 0)
    TCA.PWriteByte(3, Def#UltraAdd, $01)  '<-- Trigger Sensor
    Pause(30)
    long[ultraMainMem][1] := TCA.readHCSR04(3, Def#UltraAdd)*100/254
    Pause(1)
    TCA.resetHCSR04(3, Def#UltraAdd)

    ' Ultrasonic 3 - Left
    TCA.PSelect(4, 0)
    TCA.PWriteByte(4, Def#UltraAdd, $01)  '<-- Trigger Sensor
    Pause(30)
    long[ultraMainMem][2] := TCA.readHCSR04(4, Def#UltraAdd)*100/254
    Pause(1)
    TCA.resetHCSR04(4, Def#UltraAdd)

    ' Ultrasonic 4 - Right
    TCA.PSelect(5, 0)
    TCA.PWriteByte(5, Def#UltraAdd, $01)  '<-- Trigger Sensor
    Pause(30)
    long[ultraMainMem][3] := TCA.readHCSR04(5, Def#UltraAdd)*100/254
    Pause(1)
    TCA.resetHCSR04(5, Def#UltraAdd)






PRI tofInit(channel) | i
{{ Init ToF Sensors via TCP9548A }}

  case channel
    0:
      TCA.initVL6180X(Def#ToF1RST)
      TCA.ChipReset(1, Def#ToF1RST)
      'Pause(1000)
      Pause(500)
      TCA.FreshReset(Def#ToFAdd)
      TCA.MandatoryLoad(Def#ToFAdd)
      TCA.RecommendedLoad(Def#ToFAdd)
      TCA.FreshReset(Def#ToFAdd)

    1:
      TCA.initVL6180X(Def#ToF2RST)
      TCA.ChipReset(1, Def#ToF2RST)
      'Pause(1000)
      Pause(500)
      TCA.FreshReset(Def#ToFAdd)
      TCA.MandatoryLoad(Def#ToFAdd)
      TCA.RecommendedLoad(Def#ToFAdd)
      TCA.FreshReset(Def#ToFAdd)
  return

PUB readUltra(channel) | ackBit, clearBus
{{ Get a reading from Ultrasonic sensor }}
  TCA.PWriteByte(channel, Def#UltraAdd, $01)
  waitcnt(cnt + clkfreq/10)
  result := TCA.PReadLong(channel, Def#UltraAdd, $01)
  return result

PRI Pause(ms) | t
  t := cnt - 1088                                               ' sync with system counter
  repeat (ms #> 0)                                              ' delay must be > 0
    waitcnt(t += mainHubMS)
  return