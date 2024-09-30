{{

  File: Mk1_CommControl

  Muslinmin
  Platform: Parallax USB Project Board (P1)
  Date: 15 Feb 2023
  Objective:
    - Receives 4 byte set from the STM32 MCU
    - Relay instructions from 2nd byte and 3rd byte into the other cogs
    - Details of what the bytes are is in the commCore function


}}
CON

  _clkmode = xtal1 + pll16x                                               'Standard clock mode * crystal frequency = 80 MHz
  _xinfreq = 5_000_000
  _ConClkFreq = ((_clkmode - xtal1) >> 6) * _xinfreq
  _Ms_001 = _ConClkFreq / 1_000
  {
  firstByte = $01
  success_flag = $0A
  obstacle_flag = $69
  do_nothing_flag = $18
  }

VAR
  {List of Comm commands possible. Ranging from $01-$0C}


  long MainHubMS
  long  cog, cogStack[64], cogTxStack[64], cogTX
  long copyCmd
  long copySpeed
  long flagstatus
  long secretCode[4], str
OBJ
  pst           : "Parallax Serial Terminal"
  Def           : "RxBoardDef.spin"
  SSComm        : "FullDuplexSerialExt.spin"


   {

  First byte: $01 ' first byte check

  Second byte :   ' speed available : 25% $02 50% $05 70% $07... Duty cycle

  Third byte :   ' direction available : 25% $02 50% $05 70% $07... Duty cycle
  'What is the inverse bytes of these?

  Fourth byte :   Checksum byte
  'What is the inverse bytes of these?

  }
PUB Start(MS)
  Stop
  cog := cognew(commCore, @cogStack) + 1
  return cog

PUB Stop
  if(cog)
    cogstop(~cog - 1)
  return

DAT


{============================================}
{
  commCore

  * Retrieves data packet from the BRONCHIO i.e. STM32
  * Count == 4 indicates a full data packet received and its time to process the packet
  * Two data packets to be expected to receive,
  * Usual direction and speed packet assuming target is still in range
  * Special data packet that indicates that the target is out of sight or its time to stop
  * as the robot is just nice in front of the target

}

{============================================}
PUB commCore | j, checksum, count
  'pst.start(9600)
  SSComm.Start(Def#STM_Rx, Def#STM_Tx, 0, Def#STM_Baud)
  Pause(30)
  count := 0
  repeat
    j:= SSComm.rxcheck
    'pst.Dec(j)
    if j == -1 OR j == $00
      next
    else
      {0x02 0x01 0x01 0x04} ' Special data packet to indicate that target is not in - sight
      secretCode[count] := j
      'pst.Dec(j)
      'pst.Chars(pst#NL, 2)
      count++
      if count == 4
        checksum:= secretCode[0] + secretCode[1] + secretCode[2]
        if(checksum == secretCode[3] AND secretCode[0] == $01)
          long[@copyCmd]:= long[@secretCode][1]

          long[@copySpeed] := long[@secretCode][2]
          'pst.Dec(secretCode[1])
          'pst.Chars(pst#NL, 2)
          'SSComm.rxflush
        elseif(checksum == secretCode[3] AND secretCode[0] == $02)
          long[@copyCmd] := $00
          long[@copySpeed] := $00
          'pst.Str(String("TARGET NOT IN SIGHT OR ROBOT MUST STOP"))
          'pst.Chars(pst#NL, 2)
          'SSComm.rxflush
        elseif(checksum == secretCode[3] AND secretCode[0] == $03)
          long[@copyCmd]:= long[@secretCode][1]  ' $05
          long[@copySpeed] := long[@secretCode][2]   ' $04
        count:=0
DAT


{============================================}
{
  retrieveCmd

  * Returns a copy of the cmd

}

{============================================}
PUB retrieveCmd
  return copyCmd
DAT


{============================================}
{
  retrieveCmd

  * Returns a copy of the speedcmd

}

{============================================}
PUB retrieveSpeed
  return copySpeed
DAT


{============================================}
{
  Send status to BRONCHIO AKA STM32 if necessary

  * Status is a three byte sized data packet
  * first byte is by default 0x01
  * second byte is the status byte
  STATUS:
  $AA - Obstacle INBOUND
  $CC - Proximity is CLEARED
  * third byte is checksum

}

{============================================}
PUB sendStatus(status) | checksum
    checksum := $01 + status
    SSComm.Tx($01)
    SSComm.Tx(status)
    SSComm.Tx(checksum)
  'status Packet: START BYTE | STATUS FLAG | CHECKSUM


PRI Pause(ms) | t
  t := cnt - 1088                                               ' sync with system counter
  repeat (ms #> 0)                                              ' delay must be > 0
    'waitcnt(t += MainHubMS)
    waitcnt(t +=  _Ms_001)
  return