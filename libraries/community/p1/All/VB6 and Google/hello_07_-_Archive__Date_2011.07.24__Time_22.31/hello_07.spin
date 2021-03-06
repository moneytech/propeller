{{  hello_07.spin

    Copyright (c) 2011 Greg Denson,
    See MIT License information at bottom of this document.
    

    CREATED BY:
    Greg Denson, 2011-07-06

    MODIFIED BY:
    Greg Denson, 2011-07-07, removed unnecessary lines of code in the receive section, and added more comments. 
    Greg Denson, 2011-07-22, making changes to ensure all the responses to VB go out as a single line of data
                             rather than being chopped into multiple pieces which don't look as neat in the
                             Google Docs form and spreadsheet.
    Greg Denson, 2011-07-23, created version 6 to make a few changes in various attempts to get the data from
                             the Propeller board to go to a Google Documents  online form and spreadsheet.                         
    Greg Denson, 2011-07-24, created version 7 by removing some extra messages in order to try and make the
                             data going to the Google Documents spreadsheet more consistent - stopping it from
                             breaking into two lines instead of just one (most of the time!).  This is similar
                             to the situation I had with VB in my 2011-07-22 comment, above.  I have not
                             completely solved this issue in respect to Google Documents, but using a high
                             baud rate has minimized it.  Will continue to work to figure out what the issue is.                       

    
    This is one of the more complicated things I've done with the Propeller.  The idea for this program is to
    do all of these things:
    1.  Send a message from Visual BASIC down to the Propeller Professional Development Board
    2.  Use two different ways, in the VB program, of sending the data out
    3.  Use the data in the message to turn an LED on and off
    4.  Send some data from the Propeller back to VB as a result of the above actions.
    5.  Store all the data that was passed back to VB in a Google Docs spreadsheet (using a form to collect the data.)

    So, this requires you to have this spin program, the VB Program, and a pre-designed Google Docs form; and then
    you have to set all of them so they talk to each other:
    1.  Correct baud rates, COM ports, etc. in both the spin and VB programs
    2.  Provide the Google form key to the VB program
    3.  Have your VB program correctly assemble the URL for your form and call the form up so that data goes to it.

    Rather than adding all the instructions on building the form, here are a couple of websites that you can use to
    duplicate my steps.  Yes, this first one says "arduino", but the form building steps, recording the keys, etc.,
    are what we're after, not the Arduino program.  We can use the resulting form and spreadsheet for our application.
    So, start here, and build a form, and capture the keys and URLS whenever instructed to do so:
         http://www.open-electronics.org/how-send-data-from-arduino-to-google-docs-spreadsheet/
    There is also form building help from Google at:
         http://docs.google.com/support/bin/answer.py?answer=87809
    
    
    And then, as I began to work with the programs, I found that if I wanted to be able to watch all this take place
    while testing the program, I needed a consistent process for starting the programs, and viewing the data. Here's
    what I do:
    1.  Compile and load the spin program to the EEPROM on the Propeller board.  This has to be done each time you
        modify the spin program, but after that, you can just the board on and off to start the program running.
    2.  So, after the EEPROM is loaded, I switch of the Propeller board.
    3.  Then I start the VB program, and leave it up and running.  During testing, I am just using the VB Debug window
        for this.  So, a few steps later, I will be bringing this debug window back to the foreground.
    4.  Now, I go and open the Google spreadsheet, not the form URL, but the spreadsheet that stores the data for the form.
        You will have the URL for this spreadsheet after you design and open the completed form once.  Or, you can just
        go into Google Docs and open it from there.
    5.  Now with the spreadsheet open in the background and expanded to the size I need, I click on the VB Debug window
        again to open it on top of the spreadsheet.  Then I move it around to a position where I can see the Debug window
        and my data columns in the spreadsheet at the same time.  If you have to click on the spreadsheet for something,
        then you will need to come back and do this step again.
    6.  At this point, I click on the Open Port button in VB, followed by the Read Data Button in VB.
    7.  Once the port is open, and the VB program is waiting on data, I switch on the Propeller board.  When it starts, it
        sends out a "Ready" message which will appear in the Serial Data In textbox in the VB window.  If you see that,
        you know you are communicating.
    8.  At this point, you can click on the LED check box to send a '1' to the Propeller board and turn on the LED,
        Unchecking the box will turn it off using a '0'.  You should also be able, now, to see the data in the VB
        textboxes as these transactions take place.
    9.  In addition to the checkbox, you can turn the LED on or off by sending odd or even numbers.  Type a number in the
        Serial Data Out box, and click the Send Data button.  As you will see farther down, below, I discovered that
        any data that is interpreted as a '1' or any other ODD number turns on the LED.  Any data that is equivalent to '0'
        or an EVEN number will turn the LED off.  For example sending the letter A (ASCII 65 decimal) turns the LED on,
        and sending B (ASCII 66 decimal) will turn it off.  Leaving the Send textbox blank and clicking the Send button
        will generate a NULL which will also turn off the LED.          
             
 
    A FEW NOTES ON A PROBLEM WITH THIS OBJECT'S RELATED VISUAL BASIC PROGRAM...
    As you can tell by reading the Modified By notes, above, there is some issue that I have dealt with in
    regard to getting data to go, first, to VB6, and the later to Google Documents in one chunk as it should when
    it leaves out of the PST (Parallax Serial Terminal) from my spin program.  I fixed the display of it as far as
    it goes with the VB6 part of the issue back in Version 5, a previous object uploaded to OBEX.  This mainly
    consisted of setting up the code so my text box would just collect the pieces in a way that makes it LOOK like
    the data all came in as one string from the PST.  However, when I started sending that same data out to a
    Google Documents form and spreadsheet, I have had to deal with it there, too.  It seems that if I use a very
    high baud rate like 115_200, the issue is minimized, but it is still not completely gone.  Occasionally, what
    should be one line of text is still chopped into two pieces that wind up on two different rows in the spreadsheet,
    and that's not good.  So, after doing all that I know to do, I decided that someone might at least get some
    benefit from this object, and it also might prompt someone smarter than me to figure out the issue and fix it.
    I have also noticed two other things that affect whether or not the data is chopped:
        1.  The longer I wait between the times I send data to the Propeller, the less chance there is of a chop. In
            this example object, most of my incoming data is triggered by my first sending something to the Propeller
            board.  So, the longer I wait, the fewer hiccups I have.
        2.  The shorter the string of data that I send from Propeller to Google, the less likelihood there is of a
            problem. During testing of this object, I would send back strings from the Propeller board to prove
            that it was the source of the incoming data.  Removing those comments from the transactions also
            improved the accuracy of the received data.

    IMPORTANT NOTE:  So, if you figure out the above problem, please share.  Post a new object of your own, or send
                     me a fix, and I will add it to a new version of this object, and post it for everyone.
    
    NOW TO GET ON WITH THE WORKINGS OF THIS OBJECT:
    This version of the 'hello' program was created to work with Visual BASIC 6.0 serial communications. It has
    since been altered to also work with some functionality in VB.Net 2010 Express, and I have posted objects for
    that software as well.  So, below where VB 6.0 is mentioned, it should also work with VB.Net if you have copies
    of the program for that software as well.  This latest version (7) will also send out the data that comes into
    Visual BASIC to a Google Documents form and it will be collected in a Google Docs spreadsheet from there.
    If you want to do this, you will have to do some extra work to set up the Google Docs form, and capture a few
    pieces of information about your form to add into the VB program.  That doesn't affect this spin object.
    
    This version of the program will send out a "Ready" message to VB to let the user know that it is ready to receive
    some from VB.  After that, you can send data to the Propeller using text boxes in the VB program, or click a
    checkbox to send data.  If you hook up the LED, then sending the data can turn the LED on and off as described
    below.

    The purpose of the program is to serve as a demonstration of serial communications between the Propeller
    chip and Visual Basic 6.0.  The hope is that the beginning user of Propeller who wants to try working with
    VB6 and the Propeller will find this a good starting place on which to build his/her own applications.

    As far is this spin program goes, it could also be easily modified to send and receive data from programs
    in other languages such as Python.  I used a Python-to-Propeller communication demo as a template when I
    started to create this program.  

    The VB6 program that was created to communicate with this spin program is 'read_propeller.vbp'.  
    
    NOTE:  2011-07-05, In order to get each line into VB6 as a separate line, I am sending the combination
           13, 10 (CR LF) with each line below.  Otherwise, the VB6 has some issues with how to organize the
           data it receives into lines of text that match what was sent.  I had also noticed that when I used
           my similar program for Python, that without the CR-LF pair, Python would wait and receive all the lines
           I sent, and then display them all as one big line.  So, it seems that whether I use VB6 or Python, I
           need to pay attention to how I format the lines going out so that they line up well when they are
           received.
    NOTE:  2011-07-06, The line formatting setup that I had for Python still doesn't want to work well with VB6.
           I was unable to get more than 14 characters per line when the data was received in VB6.  So, if you
           change the formatting setup I have below, as well as the setup in VB6, you may have to work out some
           issues with the formatting of text lines. I did finally get it to look the way I wanted, so that is
           the result that is in this spin program and my current VB6 program.  
    NOTE:  2011-07-06, I have now reached version 5( hello_05.spin) of this programl so that it works as described
           in the top paragraphs, above.  Additional work was done on the send routine in VB6 to ensure that this
           spin program did not send back multiple copies of the lines that confirm receipt of the data from VB6.
           This involved ensuring that the send textbox in VB6 is cleared after each send.  A "vbCrLf" carriage return
           and linefeed combination was added to every data item sent.  Before making these changes, I was having
           to manually hit return after entering a 1 or 0 in the send textbox, and was also having to manually
           delete all text in the send textbox each time I clicked the Send button.  So, if you make changes to
           This area of the VB6 program, you may get unexpected results coming back to VB from this spin program.
    NOTE:  2011-07-07 I also discovered today that sending odd numbers (bit zero is on) will turn on the LED.
           Sending any even number will turn the LED off.  I have tested this by sending NULL, which counts as
           an even number and turns off the LED if it is on.  I also tested it from 0 to 255.  Zero also counts
           as even and turns off the LED if is on.  255, being odd will turn it on, and 254, being even will
           turn it off.  I haven't yet tried this outside that range of numbers.              
}}

VAR
  long SERIAL_IN[20]   'Variable to hold the data that comes in from VB6. This could be smaller than 20 if all you
                       'want to do is send in a 1 or 0 to turn the LED on/off. I was allowing for sending text, too.
                       'The value that comes in from VB6, even a 1 or 0, is in text format, so this holds a string.
  long led_on_off      'Holds the status of the LED for the (as sent from VB6).  Read by the Set_LED routine below.
                       'This is now in decimal format, having been converted by the str_to_dec routine, below.
                      
CON
  _CLKMODE = XTAL1 + PLL16X   'Setting up the clock mode
  _XINFREQ = 5_000_000        'Setting up the frequency

  output_pin = 0              'Using this constant to set the Propeller pin used to turn on/off the LED in this demo.

{{  Setting up the hardware:

    My connections for the Propeller Demo board are shown below. Same pins can be used for other Propeller setups.                                                      

    Parallax 
    Propeller
    Demo Board
             ───┐    LED   
          P0    │───────┐     Be sure the cathode of the LED is connected to ground (GND).  The cathode is the 
                │         │     shorter lead of the LED, and often has a flat spot on the rim of the LED, too.
          GND   │───────┘
             ───┘    470 Ohm    The correct value of this resistor can be determined by some calculations.  However,
                                the value, depending on your LED, and other factors usually falls somewhere between
                                220 and 470 Ohms.  If you have a huge LED that sucks up a lot of power, then you
                                might want to search the Internet for a formula to help you calculate the correct value
                                for a current limiting resistor in a circuit.  For most of the common LEDs we use on our
                                experiment boards, 470 Ohms is usually more than enough.     


}}
OBJ
    pst  : "Parallax Serial Terminal"     'This object is used to support the serial communications.
                                          'It should already be in your working directory.  If not, download it
                                          'from www.parallax.com, in the Object Exchange section.

PUB Setup
   pst.start(115_200)                      'This line starts the Parallax Serial Terminal, and sets the baud rate
                                           'for the serial communications terminal.  You can change this to the
                                           'desired rate if you want to run faster.
                                             
  'Here we begin the section of the program that sends out data from spin to VB6 (or VB.Net if you prefer it)
   pst.str(string("Ready",13, 10))                                'Send a message that the terminal is running, use CR/LF.
                                                                  
   repeat                                                         'This time, we will continue to loop so that the terminal
                                                                  'will continue to watch for our incoming data.
      pst.strIn(@SERIAL_IN)                                       'This is the line that receives the string data from VB6
                                                                  'and stores it in SERIAL_IN.
      pst.str(@SERIAL_IN)                                         'For the demo, we now send that same data back out to VB6.
      led_on_off := str_to_dec(@SERIAL_IN)                        'Here's where the text '1' or '0' is sent off to the
                                                                  'str_to_dec routine for conversion to a decimal number.
                                                                  'The number is then stored in 'led_on_off'
      Set_LED(output_pin)                                         'Now the Set_LED method is called to actually turn on/off the LED.

      
PUB Set_LED(Pin)                           'This is the routine to turn the LED on or off.  Send the pin number to this routine.
  dira [output_pin]~~                      'Sets the pin to output using ~~
  outa[output_pin] := led_on_off           'Uses the value in led_on_off to send either a 1 or 0 out to pin 0 to turn LED on or off.
     
PUB str_to_dec(str) | index                       'This routine takes in a string representation of a number and converts it to decimal
  result := 0                                     'Initialize the result variable with zero.
  repeat index from 0 to (strsize(str) - 1)       'We are only using one digit, but this routine can convert larger numbers, so it
                                                  'looks at each text character that might need conversion to decimal.
    if byte[str][index] == "."                    'It quits if it finds a decimal point - we're only going to work with integers here.
      quit
    result *= 10                                  'This routine is basically starting from the left side of your string 'number' and 
    result += byte[str][index] - "0"              'converting each character to a number, and then each time it finds an additional
                                                  'character to convert as it moves from right to left, it multiplies the previous
                                                  'result by 10, and adds the new digit to that result. I'm accustomed to seeing shift left
                                                  'commands in Assembly Language dealing with binary numbers, so this routine is
                                                  'pretty much like shifting left in decimal (after the character to number conversion,
                                                  'of course.)

{{ MIT License:
Copyright (c) 2011 Greg Denson 

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following
conditions: 

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. 

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                                                 

}}      