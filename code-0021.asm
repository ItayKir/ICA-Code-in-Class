;;; code-0021.asm
;;; Bubble Sort in x86/64
;;;
;;; Programmer: Mayer Goldberg, 2026

section .data
fmt_usage:
        db `Usage: program num₁ num₂ ⋯ numₙ, where n ≥ 1\n\0`
fmt_pre_sort:
        db `Before sorting the array:\n\0`
fmt_post_sort:
        db `After sorting the array:\n\0`
fmt_array_element:
        db `Arr[%lld] == %lld; \0`
fmt_newline:
        db `\n\0`

section .bss
size:
        resq 1
array:
        resq 1

extern printf, stderr, fprintf, exit, malloc, atoll
global main
section .text
main:
	push rbp
	mov rbp, rsp
        sub rsp, 8*3
        and rsp, -16

;;; The activation frame:
;;; |         | ret addr | qword [rbp + 8*1] |
;;; | rbp --> | old rbp  | qword [rbp]       |
;;; |         | source   | qword [rbp - 8*1] |
;;; |         | dest     | qword [rbp - 8*2] |
;;; |         | index    | qword [rbp - 8*3] |

	cmp rdi, 2
        jl .usage
        add rsi, 8
        mov qword [rbp - 8*1], rsi
        dec rdi
        mov qword [size], rdi
        mov qword [rbp - 8*3], rdi
        shl rdi, 3              ; rdi *= 8
        call malloc
        mov qword [array], rax
        mov qword [rbp - 8*2], rax

.loop:
        cmp qword [rbp - 8*3], 0        ; check if loaded all numbers
        jz .done                        ; jump to done if loaded all
        mov rdi, qword [rbp - 8*1]      ; put address of string pointer in rdi
        mov rdi, qword [rdi]            ; put the string pointer itself in rdi 
        call atoll                      ; convert string to long long int.
        mov rbx, qword [rbp - 8*2]      ; get the address we will put the number in
        mov qword [rbx], rax            ; put rax (output from atoll) inside the address which is [rbx]
        dec qword [rbp - 8*3]           ; we processed a number, so we do "index--"
        add qword [rbp - 8*1], 8*1      ; we now point to the next string to process
        add qword [rbp - 8*2], 8*1      ; we now point to the next address to save to
        jmp .loop

.done:
        mov rdi, fmt_pre_sort
        mov rax, 0
        call printf
        
        push qword [array]
        push qword [size]
        call print_array
	call bubble_sort

	mov rdi, fmt_post_sort
	mov rax, 0
	call printf
	
        call print_array
	
	mov rax, 0
	mov rsp, rbp
	pop rbp
	ret

.usage:
        mov rdi, qword [stderr]
        mov rsi, fmt_usage
        mov rax, 0
        and rsp, -16
        call fprintf

        mov rax, -1
        call exit

bubble_sort:
        push rbp
        mov rbp, rsp
        sub rsp, 8*3    ; make space for 3 local variables

;;; The activation frame:
;;; |         | array    | qword [rbp + 8*3] |
;;; |         | size     | qword [rbp + 8*2] |
;;; |         | ret addr | qword [rbp + 8*1] |
;;; | rbp --> | old rbp  | qword [rbp]       |
;;; |         | i1       | qword [rbp - 8*1] |
;;; |         | i2       | qword [rbp - 8*2] |
;;; |         | changed  | qword [rbp - 8*3] |

	mov rax, qword [rbp + 8*2]      ; rax = size
	dec rax                         ; if array has n elements, the highest index is (n-1)
	mov qword [rbp - 8*1], rax      ; i1 = max index
.loop1:
	cmp qword [rbp - 8*1], 0        ; if i1 = 0, we finished sorting
	jz .done
	mov qword [rbp - 8*2], 0        ; set i2 = 0, to start swapping until index i1
	mov qword [rbp - 8*3], 0        ; reset flag of if at least one swap occurred for this value of i1
.loop2:
	mov rax, qword [rbp - 8*2]      ; rax = i2
	mov rbx, qword [rbp - 8*1]      ; rbx = i1
	cmp rbx, 0                      ; if i1=0, finished sorting
	jz .done
	cmp rax, rbx                    ; if they are equal, it means we went over all numbers between index 0 to i1
	je .done2
	mov rdx, qword [rbp + 8*3]      ; rdx = address of first element in array
	mov r8, qword [rdx + 8*rax]     ; r8 = Array[i2]
	mov r9, qword [rdx + 8*rax + 8] ; r9 = Array[i2 + 1]
	cmp r8, r9
	jg .swap                        ; if (Array[i2]>Array[i2 + 1]) {swap} else {loop again}
	inc qword [rbp - 8*2]           ; (this is the else part): i2++
	jmp .loop2                      ; loop again
.swap:
	mov qword [rdx + 8*rax], r9     ; Array[i2] = r9 (r9 holds Array[i2 + 1])
	mov qword [rdx + 8*rax + 8], r8 ; Array[i2 + 1] = r8 (r8 holds Array[i2])
	mov qword [rbp - 8*3], 1        ; set "changed" flag to 1 because we swapped
	inc qword [rbp - 8*2]           ; i2++
	jmp .loop2                      ; loop again

.done2:
	cmp qword [rbp - 8*3], 0        ; check if "changed" flag is 0
	jz .done                        ; if yes, it means no swap happened in this run, so array is sorted
	mov qword [rbp - 8*3], 0        ; If we reach this part, it means "changed" was equal to 1, so now we reset back to 0
	dec qword [rbp - 8*1]           ; i1--  (we finished sorting until i1, we will sort again until [i1-1])
	jmp .loop1                      ; loop again 

.done:
        mov rsp, rbp
        pop rbp
        ret

print_array:
        push rbp
        mov rbp, rsp
        sub rsp, 8*2 ; save memory on the stack for local variables AND keep aligned for 16-bytes
        and rsp, -16 ; make sure it is still aligned, just in case

;;; The activation frame:
;;; |         | array    | qword [rbp + 8*3] |
;;; |         | size     | qword [rbp + 8*2] |
;;; |         | ret addr | qword [rbp + 8*1] |
;;; | rbp --> | old rbp  | qword [rbp]       |
;;; |         | index    | qword [rbp - 8*1] |

        mov qword [rbp - 8*1], 0        ;set index as 0
.loop:
        mov rax, qword [rbp - 8*1]      ; rax = index in array to print
        cmp rax, qword [rbp + 8*2]      ; if we printed all numbers, jump to finish
        je .done
        mov rdi, fmt_array_element      ; set format for printf
        mov rsi, rax                    ; put index number in rsi
        mov rdx, qword [rbp + 8*3]      ; put array address (first element) in rdx
        mov rdx, qword [rdx + 8*rax]    ; put the value inside the [address of first + index jump] in rdx
        mov rax, 0                      ; 0 floats
        call printf
        inc qword [rbp - 8*1]           ; index++ since we printed a number
        jmp .loop

.done:
        mov rdi, fmt_newline
        mov rax, 0
        call printf

        mov rsp, rbp
        pop rbp
        ret

section .note.GNU-stack noalloc noexec
