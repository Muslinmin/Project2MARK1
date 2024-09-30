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



  long  cog, cogStack[64]
  long area, x_coord, y_coord
  long secretCode[4]
OBJ
  pst           : "Parallax Serial Terminal"
  Def           : "RxBoardDef.spin"
  SSComm        : "FullDuplexSerialExt.spin"



PUB Start
  Stop
  cog := cognew(commCore, @cogStack) + 1
  return cog

PUB Stop
  if(cog)
    cogstop(~cog - 1)
  return


PUB commCore | j, checksum, count
  pst.start(9600)
  Pause(500)
  SSComm.Start(Def#STM_Rx, Def#STM_Tx, 0, Def#STM_Baud)
  Pause(1000)
  count := 0
  repeat
    'Pause(200)
    j:= SSComm.rxcheck
    if j == -1 OR j == $00
      next
    else
      secretCode[count] := j
      count++
      if count == 4
        'START BYTE, X_COORD, Y_COORD =  CHECKSUM
          checksum:= secretCode[0] + secretCode[1] + secretCode[2]
          pst.Str(String("X_COORD"))
          pst.Chars(pst#NL, 2)
          pst.Dec(secretCode[1])
          pst.Chars(pst#NL, 2)

          pst.Str(String("Y_COORD"))
          pst.Chars(pst#NL, 2)
          pst.Dec(secretCode[2])
          pst.Chars(pst#NL, 2)
          count:=0


PUB sendStatus(status) | checksum
    checksum := $01 + status
    SSComm.Tx($01)
    SSComm.Tx(status)
    SSComm.Tx(checksum)
    Pause(3000)
  'status Packet: START BYTE | STATUS FLAG | CHECKSUM


PRI Pause(ms) | t
  t := cnt - 1088                                               ' sync with system counter
  repeat (ms #> 0)                                              ' delay must be > 0
    'waitcnt(t += MainHubMS)
    waitcnt(t +=  _Ms_001)
  return