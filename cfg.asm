; units:
;  - distance = block (terminal row/column) | distance and radius
;  - velocity = block / s
;  - mass     = 1 / (s**2 * block) | (if i did algebra properly)

%define NSEC_SLEEP 1000000
; %define SYNC_SEQUENCES

; do NEVER put 2 bodies on the same x or y coords
; that makes dx or dy equal 0 and then division by 0 NaN which f's it up
; just pray IEEE754 huge decimal precision always has some error
; and don't make them match at some frame
init:
    mov dword [bodies+body.pos_x+(body_size*0)], __float32__(50.0)
    mov dword [bodies+body.pos_y+(body_size*0)], __float32__(25.0)
    mov dword [bodies+body.vel_x+(body_size*0)], __float32__(0.0)
    mov dword [bodies+body.vel_y+(body_size*0)], __float32__(0.0)
    mov qword [bodies+body.col+(body_size*0)], ansi_yellow
    mov byte [bodies+body.col_len+(body_size*0)], ansi_len
    mov word [bodies+body.mass+(body_size*0)], 150
    mov byte [bodies+body.radius+(body_size*0)], 7

    mov dword [bodies+body.pos_x+(body_size*1)], __float32__(50.001)
    mov dword [bodies+body.pos_y+(body_size*1)], __float32__(15.0)
    mov dword [bodies+body.vel_x+(body_size*1)], __float32__(13.0)
    mov dword [bodies+body.vel_y+(body_size*1)], __float32__(0.0)
    mov qword [bodies+body.col+(body_size*1)], ansi_blue
    mov byte [bodies+body.col_len+(body_size*1)], ansi_len
    mov word [bodies+body.mass+(body_size*1)], 0
    mov byte [bodies+body.radius+(body_size*1)], 4

    ret
