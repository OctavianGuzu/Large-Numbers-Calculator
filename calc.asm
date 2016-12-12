; decomment according to platform (Linux or Windows)
;%include "include/io.lin.inc"
%include "include/io.win.inc"

section .data
    rezultat:    times 256    db 0

section .text

global do_operation

; TODO dissasemble the main.o file. Be sure not to overwrite registers used
; by main.o that he does not save himself.
; If you see your program going nuts, consider looking in the main.o disassembly
; for the causes mentioned earlier.

do_operation:
	push ebp
        mov ebp, esp
        mov eax, [ebp + 8] ; Store the function arguments
        mov ebx, [ebp + 12]
        mov ecx, [ebp + 16]
        mov ecx, [ecx]
        cmp cl, '|' ; Check the operation and advance to execute it
        je or_operation
        cmp cl, '&'
        je and_operation
        cmp cx, '<<'
        je shift_left_operation
        cmp cx, '>>'
        je shift_right_operation
        cmp cl, '+'
        je add_operation
        cmp cl, '*'
        je mul_operation
        jmp exit
        
or_operation:   ; Beginning of the "or" operation
        mov edx, [eax + 4] ; Store the dimensions of the two numbers
        mov ecx, [ebx + 4]
        cmp edx, ecx
        jl or_size  ; And find the smallest one
        
continue_or:
        xor esi, esi
        jmp or_loop
        
or_loop:    ; Iterate through the numbers byte by byte and "or" them
        push ecx
        xor ecx, ecx
        xor edx, edx
        mov cl, byte [eax + 8 + esi]
        mov dl, byte [ebx + 8 + esi]
        or cl, dl
        mov byte [eax + 8 + esi], cl
        pop ecx
        inc esi
        cmp ecx, esi
        jg or_loop
        jmp exit
        
or_size:
        mov ecx, edx
        jmp continue_or
        
and_operation:  ; Beginning of the "and" operation
        mov edx, [eax + 4]
        mov ecx, [ebx + 4]
        cmp edx, ecx
        jl and_size ; Find the smallest dimension
        
continue_and:
        xor esi, esi
        jmp and_loop
        
and_loop:   ; Iterate byte by byte and "and" the numbers
        push ecx
        xor ecx, ecx
        xor edx, edx
        mov cl, byte [eax + 8 + esi]
        mov dl, byte [ebx + 8 + esi]
        and cl, dl
        mov byte [eax + 8 + esi], cl
        pop ecx
        inc esi
        cmp ecx, esi
        jg and_loop
        mov [eax + 4], ecx
        jmp exit

and_size:
        mov ecx, edx
        jmp continue_and
        
shift_left_operation:   ; Beginning of the shift left operation
        mov edx, [ebx + 8]
        mov ecx, [eax + 4]
        xor esi, esi
        xor edi, edi
        jmp shift_left_main_loop
        
shift_left_main_loop: ; Main loop for the numbers of shifts
        dec edx
        xor esi, esi
        xor edi, edi
        
shift_left_secondary_loop:  ; Secondary loop for a single shift, byte by byte
                            ; I will also keep in mind the possible carry
        push ecx
        push edx
        xor ecx, ecx
        xor edx, edx
        mov cl, byte [eax + 8 + esi]
        cmp cl, 0x7f
        ja add_carry
        
continue_shl1:
        shl cl, 1
        cmp edi, 1
        je increment_shl    ; Increment number size if needed
        
continue_shl2:

        mov byte [eax + 8 + esi], cl
        mov edi, edx
        pop edx
        pop ecx
        inc esi
        cmp ecx, esi
        jg shift_left_secondary_loop
        cmp edi, 1
        je increment_size_shl
        
continue_shl3:
        cmp edx, 0
        jg shift_left_main_loop
        jmp exit
        
add_carry:  ; For storing the carry
        mov edx, 1
        jmp continue_shl1
        
increment_shl:  ; For incrementing the size
        inc cl
        jmp continue_shl2
        
increment_size_shl:
        push edx
        add dword [eax + 4], 1
        xor edx, edx
        mov edx, [eax + 4]
        add byte [eax + 8 + edx - 1], 1
        pop edx
        inc ecx
        jmp continue_shl3
        
shift_right_operation: ; Beginning of the shift right operation
        mov edx, [ebx + 8]
        mov ecx, [eax + 4]
        dec ecx
        xor esi, esi
        xor edi, edi
        jmp shift_right_main_loop
        
shift_right_main_loop:  ; Main loop for numbers of shifts
        mov ecx, [eax + 4]
        xor esi, esi
        xor edi, edi
        
shift_right_secondary_loop: ; Secondary loop for a single shift, byte by byte with carry
        mov esi, ecx
        push ecx
        push edx
        xor ecx, ecx
        xor edx, edx
        mov cl, byte [eax + 8 + esi]
        shr cl, 1
        adc edx, 0
        cmp edi, 1
        je add_carry_shr
        
continue_shr1:
        mov byte [eax + 8 + esi], cl
        mov edi, edx
        pop edx
        pop ecx
        dec ecx
        cmp ecx, 0
        jge shift_right_secondary_loop
        push ecx
        xor ecx, ecx
        mov ecx, [eax + 4]
        mov cl, [eax + 8 + ecx - 1]
        cmp cl, 0
        je decrement_size
        
continue_shr2:
        pop ecx
        dec edx
        cmp edx, 0
        jg shift_right_main_loop
        jmp exit
        
add_carry_shr:  ; Used store the carry
        add cl, 0x80
        jmp continue_shr1
        
decrement_size: ; Decrement the size of the number if needed
        dec dword [eax + 4]
        jmp continue_shr2
        
add_operation:  ; Beginning of the add operation
        jmp check_equal
        
continue_add_op: ; Lots of labels for multiple cases
        jmp check_sec_nr_bigger
        
continue_add_op2:
        mov edx, [eax + 4]
        mov ecx, [ebx + 4]
        cmp edx, ecx
        jg add_size

continue_add1:
        xor esi, esi
        xor edi, edi
        mov esi, [eax]
        mov edi, [ebx]
        cmp esi,edi
        je continue_add5
        mov edi, [eax + 4]
        dec edi
        cmp dword [eax], 0xffffffff
        je two_complement_first ; Second complement the first number if negative
        
continue_add4:
        xor esi, esi
        xor edi, edi
        mov edi, [ebx + 4]
        dec edi
        cmp dword [ebx], 0xffffffff
        je two_complement_second ; Second complement the second number if negative
        
continue_add5:
        xor esi, esi
        xor edi, edi
        jmp add_loop
        
add_loop:   ; Main add loop, byte by byte, keeping the carry in mind
        push ecx
        push edx
        xor ecx, ecx
        xor edx, edx
        mov cl, byte [ ebx + 8 + esi]
        add byte [eax + 8 + esi], cl
        adc edx, 0
        cmp edi, 1
        je add_carry_add
        
continue_add2:
        mov edi, edx
        pop edx
        pop ecx
        inc esi
        cmp esi, ecx
        jl add_loop
        mov ecx, [eax]
        mov edx, [ebx]
        cmp ecx, edx
        jne continue_add3
        cmp edi, 1
        je increment_size_add
        
continue_add3:
        jmp compare_numbers
        
continue_add7:
        mov ecx, [eax + 4]
        dec ecx
        dec byte [eax + 8]
        jmp two_complement_third
        
continue_add6:
        jmp exit
        
        
add_size:
        mov ecx, edx
        jmp continue_add1
        
add_carry_add:  ; Used for storing the carry
        add byte [eax + 8 +esi], 1
        jmp continue_add2
        
increment_size_add: ; Increment the size of the number if needed
        inc dword [eax + 4]
        mov ecx, [eax + 4]
        dec ecx
        add byte [eax + 8 + ecx], 1
        jmp continue_add3 
        
two_complement_first:   ; Second complement of the first number
        xor byte [eax + 8 + edi], 0xff
        dec edi
        cmp edi, 0
        jge two_complement_first
        add byte [eax + 8], 1
        jmp continue_add4
        
two_complement_second:  ; Second complement of the third number
        xor byte [ebx + 8 + edi], 0xff
        dec edi
        cmp edi, 0
        jge two_complement_second
        add byte[ebx + 8], 1
        jmp continue_add5
        
two_complement_third:   ; Second complement of the result if needed
        xor byte [eax + 8 + ecx], 0xff
        dec ecx
        cmp ecx, 0
        jge two_complement_third
        jmp continue_add6
        
compare_numbers: ; Compare the two numbers
        mov ecx, [eax + 4]
        mov edx, [ebx + 4]
        cmp ecx, edx
        jne continue_add6
        mov esi, [eax + 8 + ecx -1]
        mov edi, [ebx + 8 + edx - 1]
        jmp continue_add6
        
check_equal: ; Check if the two numbers are equal in a certain case
        mov ecx, [eax + 4]
        mov edx, [ebx + 4]
        cmp ecx, edx
        jne continue_add_op
        mov ecx, [eax]
        mov edx, [ebx]
        cmp ecx, edx
        je continue_add_op
        xor ecx, ecx
        xor edx, edx
        xor esi, esi
        mov ecx, [eax + 4]
        
check_loop: ; Continue to store the result if the two numbers are equal
        push ecx
        mov cl, [eax + 8 + esi]
        mov dl, [ebx + 8 + esi]
        cmp cl,dl
        jne continue_add_op
        pop ecx
        inc esi
        cmp esi, ecx
        jl check_loop
        mov dword [eax], 0
        mov dword [eax + 4], 1
        mov dword [eax + 8], 0
        jmp continue_add6
        
check_sec_nr_bigger:    ; Check if the second number is bigger when sigs differ
        mov ecx, [eax]
        mov edx, [ebx]
        cmp ecx, 0
        jne continue_add_op2
        cmp edx, 0xffffffff
        jne continue_add_op2
        mov esi, 0
        mov edi, [eax + 4]
check_sec_nr_bigger_loop:
        mov ecx, [eax + 8]
        mov edx, [ebx + 8]
        cmp ecx, edx
        jge continue_add_op2
        mov dword [eax], 0xffffffff
        jmp use_sub_instead
        
use_sub_instead:    ; Use sub when sings differ and second number is bigger
        mov ecx, [ebx + 4]
        xor esi, esi
        
check_carry_exception:  ; Special case when the adding the carry generates another carry
        push ecx
        mov cl, byte [eax + 8 + esi - 1]
        mov dl, byte [ebx + 8 + esi - 1]
        cmp cl, dl
        je sub_this_carry
        

        pop ecx
        dec ecx
        cmp ecx, 0
        jge check_carry_exception
        
continue_sub:
        xor esi, esi
        xor edi, edi

sub_loop:   ; Main loop for the sub operation, byte by byte, with carry
        push ecx
        mov cl, byte [eax + 8 + esi]
        mov dl, byte [ebx + 8 + esi]
        push ebx
        mov ebx, 0
        sub dl, cl
        adc ebx, 0
        mov [eax + 8 + esi], dl
        mov edx, edi
        sub byte [eax + 8 + esi], dl
        adc ebx, 0
        mov edi, 0
        add edi, ebx
        pop ebx
        pop ecx
        inc esi
        cmp esi, ecx
        jl sub_loop
        jmp exit
        
sub_this_carry:
        pop ecx
        jmp continue_sub
        
mul_operation:  ; Beginning of the multiply operation
        mov ebx, [ebp + 8]
        mov ecx, [ebp + 12]
        mov eax, [ebx + 4]
        mov esi, [ebx]
        mov edi, [ecx]
        xor esi, edi
        mov [ebx], esi
        xor esi, esi
        xor edi, edi
        xor edx, edx
        jmp mul_main_loop
        
mul_main_loop:  ; Main loop for multiplying each byte of the smaller number
                ; with all the bytes of the other number
        xor edx, edx
        xor esi, esi
        
mul_secondary_loop: ; Secondary loop for multiplying a single byte of the smaller number
                    ; with all the bytes of the other number
                    ; Store the result in a pre-intialized array of bytes
        push eax
        push edx
        mov eax, 0
        mov al, [ebx + 8 + esi]
        mov dl, [ecx + 8 + edi]
        mul dl
        add byte [rezultat + esi + edi], al
        pop edx
        push ebx
        mov bl, 0
        adc bl, 0
        add byte [rezultat + esi + edi], dl
        mov dl, 0
        adc dl, 0
        add dl, bl
        add dl, ah
        pop ebx
        pop eax
        inc esi
        cmp esi, eax
        jl mul_secondary_loop
        cmp dl, 0
        jne exit_with_carry
continue_mul1:
        
        mov edx, [ebp + 12]
        mov edx, [edx + 4]
        inc edi
        cmp edi, edx
        jl mul_main_loop
        jmp write_result2
        
exit_with_carry:    ; Increments the size and add the carry if needed
        push eax
        push ecx
        mov ecx, [ebx + 4]
        mov al, dl
        add byte [rezultat + ecx + edi], al
        pop ecx
        pop eax
        jmp continue_mul1
        
        
write_result2:  ; Write the result in the first number
        mov eax, [ebp + 8]
        mov ebx, [ebp + 12]
        mov ecx, [eax + 4]
        mov edx, [ebx + 4]
        add ecx, edx
        add ecx, 1

find_first_number:  ; See where the number begins
        dec ecx
        mov esi, [rezultat + ecx]
        cmp esi, 0
        je find_first_number
        inc ecx
        mov [eax + 4], ecx
        mov esi, 0
        
write_loop: ; And start writing it byte by byte
        mov dl, byte [rezultat + esi]
        mov byte [eax + 8 + esi], dl
        inc esi
        cmp esi, ecx
        jl write_loop
        
        jmp exit
        
exit:   ; Exits the function
        mov esp, ebp
        pop ebp
	ret
