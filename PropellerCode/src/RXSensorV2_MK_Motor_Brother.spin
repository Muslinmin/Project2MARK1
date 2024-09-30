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

PUB Start(MS, ultraMainMem)
{{ Launch sensors units into new core }}
  mainHubMS := MS
  Stop
  cog := cognew(runnAllSensors(ultraMainMem), @cogStack) + 1
  return cog

PUB Stop

  if(cog)
    cogstop(~cog - 1 )
  return
DAT

     {============================================}
{
        Utilizes the I2C bus to send a trigger signal
        and retrieves the values from the ultrasonic sensors

        Through the selection of port i.e. which sensors to write trigger signal and retrive from
        and then followed by writing a 0x01 to the sensor through the PWRITE BYTE

        and a pause
        foolowed by retrieving the values from that sensor

        iterates through three ports i.e. 0 to 2

        and repeats indefinitely to monitor the robot's proximity

        Three ultrasonic sensors in total
        Ranging from PORT 0 to PORT 2

}

{============================================}
PUB runnAllSensors(ultraMainMem) | i
{{ Main code running sensors retrieving & updating main memory }}
  '' Init TCA9548A
  TCA.PInit2
  Pause(500)

  repeat
    ' Ultrasonic 1 - Left
    TCA.PSelect(0, 0)
    TCA.PWriteByte(0, Def#UltraAdd, $01)  '<-- Trigger Sensor
    Pause(30)
    long[ultraMainMem][0] := TCA.readHCSR04(0, Def#UltraAdd)*100/254
    Pause(1)
    TCA.resetHCSR04(2, Def#UltraAdd)


    ' Ultrasonic 2 - Right
    TCA.PSelect(1, 0)
    TCA.PWriteByte(1, Def#UltraAdd, $01)  '<-- Trigger Sensor
    Pause(30)
    long[ultraMainMem][1] := TCA.readHCSR04(1, Def#UltraAdd)*100/254
    Pause(1)
    TCA.resetHCSR04(3, Def#UltraAdd)

    ' Ultrasonic 3 - Back
    TCA.PSelect(2, 0)
    TCA.PWriteByte(2, Def#UltraAdd, $01)  '<-- Trigger Sensor
    Pause(30)
    long[ultraMainMem][2] := TCA.readHCSR04(2, Def#UltraAdd)*100/254
    Pause(1)
    TCA.resetHCSR04(4, Def#UltraAdd)



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