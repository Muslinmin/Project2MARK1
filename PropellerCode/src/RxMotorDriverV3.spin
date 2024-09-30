{{

  File: Motor Driver

  Developer: Kenichi Kato
  Copyright (c) 2021, Singapore Institute of Technology
  Platform: Parallax USB Project Board (P1)
  Date:
  03 Nov 2021:
    V2: Uses simple serial communication with the RoboClaw motor driver
        Only the S1 pin for each motor driver will be used as Rx to P1 Board
        0   => Shuts Down Channel 1 & 2
        1   => Channel 1 - Full Reverse
        64  => Channel 1 - Stop
        127 => Channel 1 - Full Forward
        128 => Channel 2 - Full Reverse
        192 => Channel 2 - Stop
        255 => Channel 2 - Full Forward
  10 Jan 2022:
    V3: Added Mecanum Movement

}}

CON

  '' For testing use only
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000
  _ConClkFreq = ((_clkmode - xtal1) >> 6) * _xinfreq
  '_Ms_001   = _ConClkFreq / 1_000
  '' ------------------------

  ' Config
  mot_Shutdown1n2 = 0
  mot_1Stop = 64
  mot_2Stop = 192

  motCmdStopAll   = 0
  motCmdForward   = 1
  motCmdReverse   = 2
  motCmdLeft      = 3
  motCmdRight     = 4
  motCmdSetMot    = 5 ' Setting Individual Motors
  motCmdMcTL      = 6 ' Top/Left
  motCmdMcTR      = 7 ' Top/Right
  motCmdMcBL      = 8 ' Bottom/Left
  motCmdMcBR      = 9 ' Bottom/Right
  motCmdMcCW      = 10  ' Turning Clockwise
  motCmdMcCCW     = 11  ' Turning Counter-Clockwise
  motCmdMcSLeft   = 12  ' Move Side Left
  motCmdMcSRight  = 13  ' Move Side Right



OBJ

  'SSComm[2]  : "FullDuplexSerial.spin"                  '<-- Replace with UART4
  SSComm    : "FDS4FC.spin"
  Def       : "RxBoardDef.spin"

'  DBG       : "FullDuplexSerialExt.spin"
   pst           : "Parallax Serial Terminal"

VAR

  long  mainHubMS
  'long  motorPins[4], motorOffset[4], motorStop[4]

  long  cog, cogStack[64]

DAT
'PUB Init(mainMS)
{
PUB Main | i, j, k
{{ For Testing Only }}
  ' Main memory/registers
  'mainHubMS := mainMS
  mainHubMS := _Ms_001

  ' Init & Assigning Motor drivers
  SSComm[0].Start(Def#R1S2, Def#R1S1, 0, Def#SSBaud)
  SSComm[1].Start(Def#R2S2, Def#R2S1, 0, Def#SSBaud)
  Pause(500)
}

PUB Start(mainMS, Cmd, AllDutyCycle, motOrient, motDCycle)
  mainHubMS := mainMS

  Stop
  cog := cognew(motorCore(Cmd, AllDutyCycle, motOrient, motDCycle), @cogStack) + 1
  return cog


PUB Stop
{{ Stop & Release Core }}
  if cog
    cogstop(cog~ - 1)
  return

PUB motorCore(Cmd, AllDutyCycle, motOrient, motDCycle) | i, k, j, prevCmd, prevDC
{{ Load core for motor }}
{
  ' Testing Use Only
  DBG.Start(31, 30, 0, 115200)
  Pause(500)
  dbg.Tx(0)
  dbg.Str(String(13, "Cog Loaded",13))
}
  ' Init & Assigning Motor drivers
  'SSComm[0].Start(Def#R1S2, Def#R1S1, 0, Def#SSBaud)
  'SSComm[1].Start(Def#R2S2, Def#R2S1, 0, Def#SSBaud)
  SSComm.AddPort(0, Def#R1S2, Def#R1S1, SSComm#PINNOTUSED, SSComm#PINNOTUSED, SSComm#DEFAULTTHRESHOLD, %000000, Def#SSBaud)
  SSComm.AddPort(1, Def#R2S2, Def#R2S1, SSComm#PINNOTUSED, SSComm#PINNOTUSED, SSComm#DEFAULTTHRESHOLD, %000000, Def#SSBaud)
  SSComm.Start
  prevCmd:= 0
  prevDC := $32
  Pause(500)

repeat
  if long[Cmd] <> prevCmd OR long[AllDutyCycle] <> prevDC
    prevCmd:=long[Cmd]
    prevDC:= long[AllDutyCycle]
    case long[Cmd]
      motCmdStopAll:  ' Stop All Motors
        AllMotorStop

      motCmdForward:  ' Forward
        Forward(long[AllDutyCycle])

      motCmdReverse:  ' Reverse
        Reverse(long[AllDutyCycle])
      motCmdLeft:     ' Left Turn
        Left(long[AllDutyCycle])

      motCmdRight:    ' Right Turn
        Right(long[AllDutyCycle])

      motCmdSetMot:   ' Setting individual motors
        repeat i from 0 to 3
          k := long[motOrient] & ($FF << (i*8))
          j := long[motDCycle] & ($FF << (i*8))
          SetMotor(i+1, k >> (i*8), j >> (i*8))

      motCmdMcTR:
        long[motOrient] := 1 << 24 | 1 << 16 | 1 << 8 | 1
        i := 1
        k := long[motOrient] & ($FF << (i*8))
        j := long[motDCycle] & ($FF << (i*8))
        SetMotor(i+1, k >> (i*8), j >> (i*8))
        i := 2
        k := long[motOrient] & ($FF << (i*8))
        j := long[motDCycle] & ($FF << (i*8))
        SetMotor(i+1, k >> (i*8), j >> (i*8))

      motCmdMcTL:
        long[motOrient] := 1 << 24 | 1 << 16 | 1 << 8 | 1
        i := 0
        k := long[motOrient] & ($FF << (i*8))
        j := long[motDCycle] & ($FF << (i*8))
        SetMotor(i+1, k >> (i*8), j >> (i*8))
        i := 3
        k := long[motOrient] & ($FF << (i*8))
        j := long[motDCycle] & ($FF << (i*8))
        SetMotor(i+1, k >> (i*8), j >> (i*8))

      motCmdMcBR:
        long[motOrient] := 0 << 24 | 0 << 16 | 0 << 8 | 0
        i := 1
        k := long[motOrient] & ($FF << (i*8))
        j := long[motDCycle] & ($FF << (i*8))
        SetMotor(i+1, k >> (i*8), j >> (i*8))
        i := 2
        k := long[motOrient] & ($FF << (i*8))
        j := long[motDCycle] & ($FF << (i*8))
        SetMotor(i+1, k >> (i*8), j >> (i*8))

      motCmdMcBL:
        long[motOrient] := 0 << 24 | 0 << 16 | 0 << 8 | 0
        i := 0
        k := long[motOrient] & ($FF << (i*8))
        j := long[motDCycle] & ($FF << (i*8))
        SetMotor(i+1, k >> (i*8), j >> (i*8))
        i := 3
        k := long[motOrient] & ($FF << (i*8))
        j := long[motDCycle] & ($FF << (i*8))
        SetMotor(i+1, k >> (i*8), j >> (i*8))

      motCmdMcCW:
        long[motOrient] := 1 << 24 | 0 << 16 | 1 << 8 | 0
        repeat i from 0 to 3
          k := long[motOrient] & ($FF << (i*8))
          j := long[motDCycle] & ($FF << (i*8))
          SetMotor(i+1, k >> (i*8), j >> (i*8))

      motCmdMcCCW:
        long[motOrient] := 0 << 24 | 1 << 16 | 0 << 8 | 1
        repeat i from 0 to 3
          k := long[motOrient] & ($FF << (i*8))
          j := long[motDCycle] & ($FF << (i*8))
          SetMotor(i+1, k >> (i*8), j >> (i*8))

      motCmdMcSLeft:
        long[motOrient] := 1 << 24 | 0 << 16 | 0 << 8 | 1
        long[motDCycle] := long[AllDutyCycle] << 24 | long[AllDutyCycle] << 16 | long[AllDutyCycle] << 8 | long[AllDutyCycle]
        repeat i from 0 to 3
          k := long[motOrient] & ($FF << (i*8))
          j := long[motDCycle] & ($FF << (i*8))
          SetMotor(i+1, k >> (i*8), j >> (i*8))

      motCmdMcSRight:
        long[motOrient] := 0 << 24 | 1 << 16 | 1 << 8 | 0
        long[motDCycle] := long[AllDutyCycle] << 24 | long[AllDutyCycle] << 16 | long[AllDutyCycle] << 8 | long[AllDutyCycle]
        repeat i from 0 to 3
          k := long[motOrient] & ($FF << (i*8))
          j := long[motDCycle] & ($FF << (i*8))
          SetMotor(i+1, k >> (i*8), j >> (i*8))




PUB SetMotor(MotNum, Orientation, DutyCycle) | i, compValue
{{
  MotNum = 1 ~ 4
  Orientation = 0 or 1 (0 => Reverse, 1 => Forward)
  DutyCycle = 1 to 100
}}

  DutyCycle := DutyCycle <#= 100
  DutyCycle := DutyCycle #>= 1
  compValue := (DutyCycle * 63)/100

  case MotNum
    1..2:
      case Orientation
        0:    ' Reverse
          case MotNum
            1:
              'SSComm[0].Tx( 64 - compValue )
              SSComm.Tx(0, 64 - compValue )
            2:
              'SSComm[0].Tx( 192 - compValue )
              SSComm.Tx(0, 192 - compValue )
        1:    ' Forward
          case MotNum
            1:
              'SSComm[0].Tx( 64 + compValue )
              SSComm.Tx(0, 64 + compValue )
            2:
              'SSComm[0].Tx( 192 + compValue )
              SSComm.Tx(0, 192 + compValue )

    3..4:
      case Orientation
        0:    ' Reverse
          case MotNum
            3:
              'SSComm[1].Tx( 64 - compValue )
              SSComm.Tx(1, 64 - compValue )
            4:
              'SSComm[1].Tx( 193 - compValue )
              SSComm.Tx(1, 193 - compValue )

        1:    ' Forward
          case MotNum
            3:
              'SSComm[1].Tx( 64 + compValue )
              SSComm.Tx(1, 64 + compValue )
            4:
              'SSComm[1].Tx( 192 + compValue )
              SSComm.Tx(1, 192 + compValue )
  return


PUB Forward(DutyCycle) | i, compValue
{{ value: 1 to 100 percent }}
  DutyCycle := DutyCycle <#= 100
  DutyCycle := DutyCycle #>= 1
  compValue := (DutyCycle * 63)/100
{
  SSComm[0].Tx( 64 + compValue )
  SSComm[0].Tx( 192 + compValue )
  SSComm[1].Tx( 64 + compValue )
  SSComm[1].Tx( 192 + compValue )
}
  SSComm.Tx(0, 64 + compValue )
  SSComm.Tx(0, 192 + compValue )
  SSComm.Tx(1, 64 + compValue )
  SSComm.Tx(1, 192 + compValue )

  return

PUB Reverse(DutyCycle) | i, compValue
{{ value: 1 to 100 percent }}
  DutyCycle := DutyCycle <#= 100
  DutyCycle := DutyCycle #>= 1
  compValue := (DutyCycle * 63)/100
{
  SSComm[0].Tx( 64 - compValue )
  SSComm[0].Tx( 192 - compValue )
  SSComm[1].Tx( 64 - compValue )
  SSComm[1].Tx( 192 - compValue )
}
  SSComm.Tx(0, 64 - compValue )
  SSComm.Tx(0, 192 - compValue )
  SSComm.Tx(1, 64 - compValue )
  SSComm.Tx(1, 192 - compValue )

  return

PUB Left(DutyCycle) | i, compValue
{{ value: 1 to 100 percent }}
  DutyCycle := DutyCycle <#= 100
  DutyCycle := DutyCycle #>= 1
  compValue := (DutyCycle * 63)/100
{
  SSComm[0].Tx( 64 + compValue )
  SSComm[0].Tx( 192 - compValue )
  SSComm[1].Tx( 64 + compValue )
  SSComm[1].Tx( 192 - compValue )
}
  SSComm.Tx(0, 64 + compValue )
  SSComm.Tx(0, 192 - compValue )
  SSComm.Tx(1, 64 + compValue )
  SSComm.Tx(1, 192 - compValue )

  return

PUB Right(DutyCycle) | i, compValue
{{ value: 1 to 100 percent }}
  DutyCycle := DutyCycle <#= 100
  DutyCycle := DutyCycle #>= 1
  compValue := (DutyCycle * 63)/100
{
  SSComm[0].Tx( 64 - compValue )
  SSComm[0].Tx( 192 + compValue )
  SSComm[1].Tx( 64 - compValue )
  SSComm[1].Tx( 192 + compValue )
}
  SSComm.Tx(0, 64 - compValue )
  SSComm.Tx(0, 192 + compValue )
  SSComm.Tx(1, 64 - compValue )
  SSComm.Tx(1, 192 + compValue )

  return

PUB AllMotorStop | i
  repeat i from 0 to 1
    'SSComm[i].Tx(0)
    SSComm.Tx(i, 0)
  return


PUB testMotors | i

  Pause(1000)
  repeat
    repeat i from mot_1Stop to 1 step 1
      'SSComm[0].Tx(i)
      SSComm.Tx(0, i)
      Pause(100)
    repeat i from 1 to mot_1Stop step 1
      'SSComm[0].Tx(i)
      SSComm.Tx(0, i)
      Pause(100)

PRI Pause(ms) | t
  t := cnt - 1088                                               ' sync with system counter
  repeat (ms #> 0)                                              ' delay must be > 0
    waitcnt(t += mainHubMS)
  return

PRI PauseMin(arg)
  repeat arg
    Pause(60000)
  return

PUB TestSetMotor | i, j
  ' Forward
  repeat j from 1 to 100
    repeat i from 1 to 4
      SetMotor(i, 1, j)
    Pause(50)
  repeat j from 100 to 1
    repeat i from 1 to 4
      SetMotor(i, 1, j)
    Pause(50)

  AllMotorStop

  ' Reverse
  repeat j from 1 to 100
    repeat i from 1 to 4
      SetMotor(i, 0, j)
    Pause(50)
  repeat j from 100 to 1
    repeat i from 1 to 4
      SetMotor(i, 0, j)
    Pause(50)

  AllMotorStop
  return

PUB FullMotionTest | i

  ' Testing right motion
  repeat i from 0 to 100 step 10
    Right(i)
    Pause(300)
  repeat i from 100 to 0 step 10
    Right(i)
    Pause(300)
  AllMotorStop

  ' Testing left motion
  repeat i from 0 to 100 step 10
    Left(i)
    Pause(300)
  repeat i from 100 to 0 step 10
    Left(i)
    Pause(300)
  AllMotorStop

  ' Testing forward motion
  repeat i from 0 to 100 step 10
    Forward(i)
    Pause(300)
  repeat i from 100 to 0 step 10
    Forward(i)
    Pause(300)
  AllMotorStop

  ' Testing reverse motion
  repeat i from 0 to 100 step 10
    Reverse(i)
    Pause(300)
  repeat i from 100 to 0 step 10
    Reverse(i)
    Pause(300)
  AllMotorStop
  return

DAT 'Unused Codes
{
  DBG.Start(31, 30, 0, 115200)
  Pause(500)

  'PWM.Init
  'PWM.AddFastPin(S1)
  'PWM.AddFastPin(S2)
  PWM.Start

  PWM.Set(S1, MotorZero+S1Offset)
  PWM.Set(S2, MotorZero+S2Offset)
  Pause(1000)

  repeat i from 1500 to 1800 step 10
    PWM.Set(S1, i+S1Offset)
    PWM.Set(S2, i+S2Offset)
    Pause(200)
  Pause(1000)

  repeat i from 1800 to 1500 step 10
    PWM.Set(S1, i+S1Offset)
    PWM.Set(S2, i+S2Offset)
    Pause(200)
  'Pause(2000)

  PWM.Set(S1, MotorZero+S1Offset)
  PWM.Set(S2, MotorZero+S2Offset)
  'Pause(5000)

  'StopS1S2Motor
  repeat



PRI StopS1S2Motor
  PWM.Set(S1, MotorZero+S1Offset)
  PWM.Set(S2, MotorZero+S2Offset)
  return
}
{
  repeat 2
    repeat i from mot_1Stop to 1 step 5
      SSComm[0].Tx(i)
      SSComm[0].Tx(i + 127)
      SSComm[1].Tx(i)
      SSComm[1].Tx(i + 127)
      Pause(100)
    repeat i from 1 to mot_1Stop step 5
      SSComm[0].Tx(i)
      SSComm[0].Tx(i + 127)
      SSComm[1].Tx(i)
      SSComm[1].Tx(i + 127)
      Pause(100)

  ' Stopping all
  repeat i from 0 to 1
    SSComm[i].Tx(0)
}