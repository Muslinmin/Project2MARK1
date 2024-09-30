{Object_Title_and_Purpose}


CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000
  _ConClkFreq = ((_clkmode - xtal1) >> 6) * _xinfreq
  _Ms_001   = _ConClkFreq / 1_000

  {
  ===========================Motor Driver Related========================
  MotNum = 1 ~ 4
  Orientation = 0 or 1 (0 => Reverse, 1 => Forward)
  DutyCycle = 1 to 100


  ============================Command Bytes==============================
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


  =======================================================================
  }





OBJ
  Def   : "RxBoardDef.spin"
  pst   : "Parallax Serial Terminal.spin"
  MK_Motor: "Mk_Motor_Brother.spin"
  MK_Sensor: "RXSensorV2_MK_Motor_Brother.spin"
  MK_Comms: "Mk1_CommControl.spin"

VAR
  long cmd
  long singleMotorDutyCycle, AllDutyCycle
  long motorOrientation
  long ultraArrayMem[3]
  long speed, direction ' Speed Available := 0x01 to 0x64 (1% to 100%) ' Direction := Motor Cmds

  long duration
DAT


{============================================}
{
  Main function of the MARK 1

  * Relays instructions to the Motor COG i.e. MK_MOTOR_BROTHER IF THERE IS A CHANGE in direction
  * Calls the proximity function and decide whether the MARK 1 has to stop and send
  * an emergency signal to BRONCHIO AKA STM32

}

{============================================}
PUB Main | proximity, t, prevcmd, copyCmd, obstacle_flag, dc
  'Debug Sensor Values. Initialize PST for that
  {Initialize to default values}
  AllDutyCycle:= $25
  singleMotorDutyCycle:= $25
  motorOrientation:= 0 ' Forward default

  cmd:= $0
  prevCmd:= $0
  copyCmd:= $0
  proximity := 0
  obstacle_flag := 0
  dira[21]~~
  {=====================================}
     pst.start(9600)
     MK_Motor.Start(_MS_001, @cmd, @AllDutyCycle, @motorOrientation, @singleMotorDutyCycle)
     Pause(1)
     Mk_Comms.Start(_MS_001) ' The comms shall update the command and the speed instructions from stm32
     Pause(1)
     'MK_Sensor.Start(_MS_001, @ultraArrayMem)

  {=====================================}
  'Mk_Comms.sendStatus($AA)

  {=====================================}
    repeat
      copyCmd := Mk_Comms.retrieveCmd
      'dc := Mk_Comms.retrieveSpeed
      {if (copyCmd == $05 AND dc == $04)'specific sequence
        cmd:= $00
        'Set up the LED light
        pst.Str(String("TARGET IN SIGHT"))
        outa[21]~~
        Pause(5000)
        next}

      'Pause(2000)
      'pst.Dec(cmd)
      if(prevCmd <> copyCmd)
          pst.Dec(cmd)
          pst.Chars(pst#NL, 2)
          prevCmd:= copyCmd
          cmd:= copyCmd
          Pause(200)






DAT


{============================================}
{
  printSensor

  *Prints the value of the three ultrasonic sensors

}

{============================================}
PRI printSensor
    {Prints all the Ultrasonic sensor values here}
    pst.Str(String("Ultrasonic Sensors:"))
    pst.Chars(pst#NL, 2)
    pst.Dec(ultraArrayMem[0])
    pst.Chars(pst#NL, 2)
    pst.Dec(ultraArrayMem[1])
    pst.Chars(pst#NL, 2)
    pst.Dec(ultraArrayMem[2])
    pst.Chars(pst#NL, 2)
DAT


{============================================}
{
  proximityCheck

  * Determines if any of the three sensors detect any obstacle
  * Returns 1 i.e. TRUE if obstacle inbound
  * Else returns 0 i.e. Proximity is CLEAR

}

{============================================}
PUB proximityCheck(AlertDistance) : alert | i
  alert:= 0 ' by default, no obstacles within proximity, returns 0 (FALSE)
  repeat i from 0 to 2
    if ultraArrayMem[i] <> 0  ' if ultrasound is able to pick up its signal.
      if ultraArrayMem[i] <= AlertDistance ' if the distance is too close to the robot
        alert := 1  ' RETURNS TRUE
        QUIT

  return alert
PRI Pause(ms) | t
  t := cnt - 1088                                               ' sync with system counter
  repeat (ms #> 0)                                              ' delay must be > 0
    waitcnt(t += _MS_001)
  return