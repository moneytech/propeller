CON                      _CLKMODE        = XTAL1 + PLL16X                         _XINFREQ        = 5_000_000    _Stack          = 20  SignFlag      = $1  ZeroFlag      = $2  NaNFlag       = $8  BUFFER_LENGTH = 301 ' change to '2' to remove the ring buffer.VAR        long    cogPUB Start (AddPassThrough)' Enter with address of variable that contains the base address of pass through variables (3 longs in SPIN memory).'  Long[Long[AddPassThrough]+0] = address of Pass-through variable between interpolation COGs & this buffer'  Long[Long[AddPassThrough]+4] = address of Pass-through variable between this buffer and output driver.'  Long[Long[AddPassThrough]+8] = number of used longs in ring buffer (set by this cog and optionally read by the main SPIN program)    stop                                                                              cog := cognew(@OutBuffer,AddPassThrough) + 1            ' Start the output driver COG    waitcnt(clkfreq/10+cnt)                                 ' Allow time for COG to load'    return cogPUB Stop  if cog    cogstop(cog~ - 1)dat{This is the common output buffer.The interpolation COGS offer moves to this buffer when available.The buffer receives the LONGS that describe the output pin valuesand the length of delay in clock pulses.The moves are stored in a ring buffer and released to the output driver as the output driver can receive them.This routine is split off from the output driver for two reasons:    1. Make room for a large ring buffer    2. Make sure there is no latency in accepting and releasing moves to the output buffer. Circular moves take some time to calculate        the starting point so the buffer should prevent the stutter between moves.}                        org     0OutBuffer'                        mov     TableAt, par               ' +0 Variable Table Address                                  rdlong  IntBufferAt, par            ' Address of pass-through variable between Interpolation COGs and Output Buffer                            rdlong  OutBufferAt, par            ' Address of pass-through variable between Output Buffer COG and Output Driver                             add     OutBufferAt, #4                        rdlong  BufferUsedAt, par           ' Address of pass-through variable of used buffer slots                             add     BufferUsedAt, #8                        wrlong  NegOne,IntBufferAt          ' Flag that we can accept a new step from an interpolation cog                        wrlong  zero,BufferUsedAt           ' Clear the number of buffer slots used to 0Debug1At mov Debug1At, par ' Debugging Variables, can be removedDebug2At mov Debug2At, par ' Debugging Variables, can be removedDebug3At mov Debug3At, par ' Debugging Variables, can be removedDebug4At mov Debug4At, par ' Debugging Variables, can be removedDebug5At mov Debug5At, par ' Debugging Variables, can be removedDebug6At mov Debug6At, par ' Debugging Variables, can be removedDebugcnt add Debug1At, #64 ' Debugging Variables, can be removed         add Debug2At, #68 ' Debugging Variables, can be removed         add Debug3At, #72 ' Debugging Variables, can be removed         add Debug4At, #76 ' Debugging Variables, can be removed         add Debug5At, #80 ' Debugging Variables, can be removed         add Debug6At, #84 ' Debugging Variables, can be removed         mov DebugCnt, #0  ' Debugging Variables, can be removed                                                                                                {This routine communicates through three variables.Var 1:  long[AddPassThrough+0]: A value set by either interpolation cog to be read by this buffer cog.   -1       Means that this routine is ready to accept another step from an interpolation cog.    0       Means that this routine is busy and the buffer can't accept any more moves.            Either it is processing or the buffer is full.Other value Means a new step value from the interpolation cog is waiting to be buffered.     ie. (High 6 bits are the output bit pattern, Low 26 bits are the delay time)Sequence:  ┌────────┐  │          │        0 = Not ready (set by this cog)  │          │       -1 = Ready for long from interpolation cog (set by this cog)  │          │        value to be stored in buffer (set by interpolation cog)  │        │  └────────┘Var 2:  long[AddPassThrough+4]: A value set by the output cog, to be read by the this buffer cog.    0   instructs this cog that the output driver cog can accept a new value.        When a 0 is seen, this buffer cog places the next value in this variable to be executed by the output driver.         (High 6 bits are the output bit pattern, Low 26 bits are the delay time)    -1  Tells the output driver that we have a G92 to perform    Sequence:  ┌────────┐  │            │        0 = Output driver cog is ready for a long from this buffer cog  │           │        value is placed in this memory location to be to be digested by the output cog  │        │  └────────┘Var 3:  long[AddPassThrough+8]: A value set by this buffer cog, to be read by the this buffer cog.    a long value indicating the number of buffered slots being used. 0=empty}LoopStart                        mov     tmp1,Head                        sub     tmp1,Tail wc, wz            ' C set if underflow (Head-Tail < 0), Z=set if Head=Tail        if_c            add     tmp1,#BUFFER_LENGTH                                                wrlong  tmp1,BufferUsedAt'                        cmp     Head,Tail wz                ' check for head <> tail            if_nz       jmp     #Not92                      ' Buffer not empty when head <> tail                        ' Buffer is empty, are we sitting idle?                        rdlong  tmp1, par wz            ' Get current operating state (0=stopped, 1=running)            if_z        jmp     #LoopStart'                       cmp     tmp1, OTCode wz             ' Is -100 if overtravel occured'           if_z        jmp     #LoopStart                        cmp     tmp1, #92 wz            if_nz       jmp     #Not92                      ' Not a G92 = 1,-2,2 = interpolated move' ===================== G92 = Preset position registers with X, Y & Z values =======================================                              wrlong  NegOne,OutBufferAt          ' -1 tells Output Driver we have a G92G92NotDone              rdlong  tmp1,OutBufferAt wz         ' Wait for Output Driver to complete G92            if_nz       jmp     #G92NotDone                                    wrlong  Zero, par                   ' Signal we have finished the G92                        wrlong  NegOne,IntBufferAt          ' Flag that we can accept a new step from an interpolation cog                        jmp     #LoopStartNot92'==================================================================================================='=========== Check to see if a new value is available from an interpolation cog ===================='=========== if so, put new value in Ring buffer                                ===================='=========== Check to see if the output driver can accept a new value           ===================='=========== If so, give it the oldest value from the ring buffer.              ==================== '==================================================================================================='wrlong tmp1, Debug1At                        ' Check to see if something is available from an interpolation cog                        ' States can be:                        ' 0 or -1 = nothing ready to receive                        ' Other = value to save in ring buffer                                                rdlong  tmp1, IntBufferAt wz        ' Current state:            if_z        jmp     #GetFromBuffer              ' Nothing ready to receive yet, see if we can send something to the output buffer                        cmp     tmp1,NegOne wz            if_z        jmp     #GetFromBuffer              ' Nothing ready to receive yet, see if we can send something to the output buffer                'add DebugCnt,#1'wrlong DebugCnt, Debug4At'wrlong tmp1, Debug3At                        ' Data is ready, store it in the ring buffer                        mov     tmp2, #RingBuffer                        add     tmp2,Head                        movd    :ToRing,tmp2                ' Point to self-modifying code target address. Force address of array into destination address                        add     Head,#1                     ' increment head and Required for processor instruction pipeline 'wrlong tmp2, Debug2At:ToRing                 mov     tmp2,tmp1                   ' Save new value in ring buffer                        cmpsub  head,#Buffer_Length                        mov     tmp1,Head                   ' must leave 1 slot open to distinguise between full & empty                        add     tmp1,#1                                     cmpsub  tmp1,#Buffer_Length                        cmp     Tail,tmp1 wz                ' is buffer full (leaving 1 slot open)?            if_z        wrlong  zero, IntBufferAt           ' signal that buffer is full                                    if_nz       wrlong  NegOne, IntBufferAt         ' Signal that we can accept new move values into the ring bufferGetFromBuffer'wrlong head, Debug4At'wrlong tail, Debug5At'a'rdlong tmp1,Debug6At wz'if_nz jmp #a'                       Check an see if output driver can accept the next move                        rdlong  tmp1,OutBufferAt wz         ' Zero = ready for next move, non-zero = busy moving        if_nz           jmp     #LoopStart                                                    cmp     Head,Tail wz                'check for head <> tail'       if_z            wrlong  Zero,BufferUsedAt        if_z            jmp     #LoopStart                  ' Buffer empty  when head = tail'                       Get oldest value from ring buffer and process it                        mov     tmp1,#RingBuffer                        add     tmp1,Tail                   'get oldest move and inc tail                        movs    :FromRing,tmp1              ' Point to self-modifying code target address. Force address of array into SOURCE address                        nop'wrlong tmp1, Debug3At:FromRing               mov     tmp1,tmp1                        wrlong  tmp1,OutBufferAt                        wrlong  NegOne, IntBufferAt         ' Signal that we can accept more into the buffer                        add     Tail,#1                        cmpsub  tail,#Buffer_Length'                       cmp     Head,Tail wz                'check for head <> tail'       if_z            wrlong  Zero,BufferUsedAt'b'rdlong tmp1,Debug6At wz'if_nz jmp #b                        jmp     #LoopStart'------------------------------------------------------------------------------'Integer ConstantsZero            long    $0000_0000NegOne          long    $FFFF_FFFF' Addresses of Shared VariablesIntBufferAt     long    0   ' Address of pass-through variable between Interpolation COGs and Output Driver                            ' long[IntBufferAt]==0 when ready to receive a step from an interpolation cog                            ' long[IntBufferAt]==-1 when ready to receive a step from an interpolation cog                            ' long[IntBufferAt]:= other value = step pins & delay time for a stepOutBufferAt     long    0   ' Address of pass-through variable between Output Buffer COG and Output Driver COGBufferUsedAt    long    0   ' Current number of used buffer slotsHead            long    0Tail            long    0'Calculated Variablestmp1            long    0   ' Temporary Variabletmp2            long    0   ' Temporary VariableRingBuffer      res     BUFFER_LENGTH                fit     496