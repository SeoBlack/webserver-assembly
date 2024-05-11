.intel_syntax noprefix
.globl _start

.section .text

_start:
    mov rax, 41     #socket
    mov rdi, 2      #AF_INET
    mov rsi, 1      #SOCK_STREAM
    mov rdx, 0      #IPPROTO_IP
    syscall

    mov rdi, rax
    xor rax,rax     #clear rax for setting sin_family
    mov eax, 0     #localhost
    push rax
    mov ax, 0x5000   #Port 80 
    push ax
    mov ax, 2      #AF_INET
    push ax 
    mov rsi, rsp    # address of sockaddr_in 
    mov rax, 49     # BIND SYSCALL
    mov rdx, 16
    syscall

    mov rax, 50     #listen SYS_CALL
    xor rsi, rsi
    syscall

    mov rax, 43     #Accept syscall
    xor rdx, rdx 
    syscall

    push rax            #saving the accept file descriptor
    mov rdi, rax     #read SYS_CALL
    mov rsi, offset buffer
    mov rdx, 1000
    mov rax, 0
    syscall

    mov rdi, offset path
    mov rcx, 30
extract_pathname:
    mov rdx, 0            # counter for the number of characters in the path
    mov r8, 0             # spaces counter
next_char:
    mov al, byte [rsi]    # load the next byte from the buffer
    cmp al, ' '           # check if the character is a space (end of method or path)
    je check              # if it's a space, end extraction
    cmp r8, 0
    je skip
    jmp add
check:
    inc r8
    cmp r8, 2
    je end_extraction
    cmp r8, 1
    je skip
    jmp end_extraction

skip:
    inc rsi               # move to the next byte in the buffer
    jmp next_char
add:
    mov [rdi + rdx], al   # store the character in the path
    inc rsi               # move to the next byte in the buffer
    inc rdx               # increment the counter
    cmp rdx, rcx          # check if we've reached the maximum length of the path
    je end_extraction     # if so, end extraction
    cmp al, 0             # check for end of string
    je end_extraction     # if it's the end of the string, end extraction
    jmp next_char         # continue extracting characters
end_extraction:
    mov byte ptr [rdi + rdx], 0  # null-terminate the path
    jmp open

open:
    mov rax, 2      #open SYS_CALL
    mov rdi, offset path
    mov rsi, 0
    syscall



    push rax        #saving file open descriptor for closing
    mov rdi, rax
    mov rax, 0      #read SysCall
    mov rsi, offset buffer
    mov rdx, 1000
    syscall


    pop rdi         #getting back the open file descriptor to close 
    mov r8,rax             #saving the size value in r8
    mov rax, 3      #close SYS_CALL 
    syscall


    pop rdi         #getting back the accept  file descriptor from the stack
    mov rsi, offset response
    mov rdx, 19
    mov rax, 1          #write SYS_CALL
    syscall

    mov rsi, offset buffer
    mov rdx, r8           #setting the size value
    mov rax, 1          #write SYS_CALL
    syscall



    mov rax, 3      #close SYS_CALL
    syscall

    mov rdi, 0      # EXIT_SYSCALL
    mov rax, 60
    syscall
.section .data
buffer: .space 1000
path: .space 30
response: .string "HTTP/1.0 200 OK\r\n\r\n"