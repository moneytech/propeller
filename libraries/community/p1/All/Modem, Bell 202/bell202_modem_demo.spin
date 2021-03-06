CON

  XMT           = false '─────── Set true for transmit demo, false for receive demo.
  USING_BP      = true  '─────── Set true for Propeller Backpack, false for simple setup.

  RCVPIN        = 0 '┐
  XMTPIN        = 1 '┼────────── Change, as needed, for non-Backpack use.
  PTTPIN        = 2 '┘

  _clkmode      = (xtal1 + pll8x) & USING_BP | (xtal1 + pll16x) & !USING_BP
  _xinfreq      = 10_000_000 & USING_BP | 5_000_000 & !USING_BP


OBJ

  mdm   : "bell202_modem"
  num   : "simple_numbers"
  ser   : "FullDuplexSerial"

VAR

  byte  strbuf[64]

PUB main

  if (USING_BP)
    mdm.start_bp(0)
  else
    mdm.start_simple(RCVPIN, XMTPIN, PTTPIN, 0)
  if (XMT)
    do_transmit
  else
    do_receive

PUB do_transmit | i

  i~  
  repeat
    mdm.transmit
    mdm.outstr(string("!Testing "))
    mdm.outstr(num.decf(i++, 4))
    mdm.outstr(string(" de YOUR CALLSIGN", 13)) '─────── callsign here if using radio transmission.
    mdm.standby
    waitcnt(cnt + clkfreq * 2)

PUB do_receive | timeout

  ser.start(31, 30, 0, 9600)
  ser.str(string("Beginning reception...", 13))
  repeat
    timeout~~
    if (mdm.waitstr(string("!Testing "), 4000))
      if (mdm.inpstr(@strbuf, 13, 16, 4000))
        ser.str(@strbuf)
        timeout~
    if(timeout)
      ser.str(string("Nothing received.", 13))
      