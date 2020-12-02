;-------------------------------------------------------------------
pila    segment stack
        dw 100 dup(0)
pila    ends
;-------------------------------------------------------------------
datos   segment
  espacio equ 1     ; Tiempo entre notes
  octava  equ 3     ; varía entre 0 y 7 para escoger la octava, pero
                    ; para '0' el 8254 ya no responde
  ;-----------------------------------------------------------------
  ; Notas y duración de cada nota para la canción los pollitos dicen
  notes     dw  0523,0587,0659,0698,0784,0784,0880,0880,0880,0880
            dw  0784,0784,0698,0698,0698,0698,0659,0784,0587,0587
            dw  0587,0587,0523,0523
  duration  dw  0008,0008,0008,0008,0016,0016,0008,0008,0008,0008
            dw  0016,0016,0008,0008,0008,0008,0016,0016,0008,0008
            dw  0008,0008,0016,0016
  ;-----------------------------------------------------------------
  spkOld    db  0   ; Estado del parlante
  ktic      dw  0   ; Tic del sistema
  k         dw  0   ; Control de retardo
  cont      dw  24  ; cantidad de notes
datos   ends
;-------------------------------------------------------------------
codigo  segment
  program proc far
    assume  ss:pila, ds:datos, cs:codigo
    push  ds
    sub   ax, ax
    push  ax
    mov   ax, datos
    mov   ds, ax

    in    al, 61h         ; Salva el parlante
    and   al, 11111100b
    mov   spkOld, al
    ;---------------------------------------------------------------
    ;                   Los pollitos dicen en 5ta octava
    ;---------------------------------------------------------------
    mov   si,0
  otra_nota:
    mov   cx, notes[si]   ; obtenemos la nota
    mov   ax, duration[si]  ; obtenemos la duración de la nota
    mov   k, ax
    call  play_note
    inc   si
    inc   si
    dec   cont
    cmp   cont,0
    jne   otra_nota
    ;---------------------------------------------------------------
    mov   al, spkOld      ; Apagar y desconectar
    and   al, 11111100b   ; parlante del canal 2 del 8254
    out   61h, al
    ret
  program endp
  ;-----------------------------------------------------------------
  play_note  proc
    mov   dx, 12h         ; Convertir periodo
    mov   ax, 34DCh       ; a frecuencia
    div   cx              ; en CX esta el periodo
    mov   dx, ax
    mov   al, 0B6h        ; Configurar el 8254 (palabra de control -> )
    out   43h, al         ;
    mov   al, dl          ; Pasamos el byte bajo del contador
    out   42h, al
    mov   al, dh          ; Y ahora el alto
    out   42h, al
    mov   al, spkOld      ; Encender el parlante
    or    al, 00000011b
    out   61h, al
    call  retardo
    mov   al, spkOld      ; Apagamos el parlante
    and   al, 11111100b
    out   61h, al
    mov   k, espacio
    call  retardo
    ret
  play_note endp
  ;-----------------------------------------------------------------
  ;                         Leer TIC del sistema
  ;-----------------------------------------------------------------
  tic   proc
    mov   ah, 0
    int   01ah
    ret
  tic   endp
  ;-----------------------------------------------------------------
  ;                        Retardo en base al TIC
  ;-----------------------------------------------------------------
  retardo proc
    push  cx
    call  tic
    add   dx, k            ;Modificar el Tic
    mov   ktic, dx
  r10:
    call  tic
    cmp   dx, ktic
    jne   r10
    pop   cx
	ret
  retardo   endp
  ;-----------------------------------------------------------------
codigo  ends
end program