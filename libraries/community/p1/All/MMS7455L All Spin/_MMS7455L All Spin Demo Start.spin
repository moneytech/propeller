{{      
          Written by Michael Lord     www.electronicdesignservice.com      650-219-6467 
          Consulting and design services available
         
          2013-06-01
          All Rights Reserved



}}

CON

         _CLKMODE      = XTAL1 + PLL16X                        
         _XINFREQ      = 5_000_000




             

'Pin Assignments
       TvPin        = 24





          

Obj
       TV         :   "Mirror_TV_Text"
       Acel       : "MMA7455L_SPI_All_SPIN"
       
       

Var




'acelerometer
      long   XYZData[3]     ' X Y Z  from accelerometer as read                    
      long   DecAcl[3]      ' X Y Z  as averaged over N counts
       

'===================================================================================================================================
Pub _Start   | Index  , LastCnt , Looptime  , Meastime , DispTime
'===================================================================================================================================

       Initialize
       tv.out($00)


         Acel.Acel_Start( @XYZData, @DecAcl   )   'starts Acelerometer


         LastCnt := cnt 
       
       repeat

              Tv.out( $0A  )  'set X position (X follows) 
              Tv.out( $00  ) 
              Tv.out( $0B )   ' set Y position (Y follows) 
              Tv.out( $10  )


           
               Looptime :=  (cnt - LastCnt  )/ (clkfreq / 1000)
               LastCnt := cnt  
               Meastime := MeasTime +  Looptime   'measure time in ms
               DispTime := Disptime + LoopTime
               

             if DispTime > 1000   'Display tank info every 1 seconds
                 Display2 
                 DispTime := 0
                 
         waitcnt(clkfreq / 50 + cnt)   








                   

'===================================================================================================================================
PUB Display2
'===================================================================================================================================
             
              Tv.out( $00  )  'clear
              Tv.out( $01  )  'home



            
              Tv.out( $0A  )  'set X position (X follows) 
              Tv.out( $00  ) 
              Tv.out( $0B )   ' set Y position (Y follows) 
              Tv.out( $00  )

              Tv.out( $0D  ) 
             
              Tv.str(string( "X ="))
              Tv.dec( XYZData[0] )
              Tv.out( $0D  ) 
             
              Tv.str(string( "Y ="))
              Tv.dec( XYZData[1] )
              Tv.out( $0D  ) 

              Tv.str(string( "Z ="))
              Tv.dec( XYZData[2] )
              Tv.str(string( " Hex Z ="))  
              Tv.hex( XYZData[2] , 2 )
              Tv.str(string( " Bin Z ="))  
              Tv.bin( XYZData[2] , 8 )
              
              Tv.out( $0D  ) 
 

         
      
'===================================================================================================================================
Pub Initialize  | index     
'===================================================================================================================================


       
'start tv
        tv.start( TvPin)
               repeat index from 0 to 10      'this wakes up the tv from sleep mode     
                    tv.str(string("Tv Started ="))
                    tv.dec( index )
                     Tv.out($0D)







          

  