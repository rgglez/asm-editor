.SALL
COMMENT * Modulo: EID.ASM      (Entorno Integrado de Desarrollo)
          Realizado por: GONZALEZ GONZALEZ RODOLFO.         
          19:03:22  1/17/1994

     Este modulo enlazable contiene procedimientos para la portada y el final
del programa EDITOR.ASM (modulo principal). Usa la libreria de macros externa
MACROS1.LIB. Define sus constantes y hace uso de datos del modulo principal  *

.MODEL SMALL

IF1
    INCLUDE MACROS1.LIB
    PURGE SalvaRegs,RestauraRegs,ReadStr,WriteLn,LimpiaBuffer,ReadChar
    PURGE SalvaApuntadores,RestauraApuntadores
ENDIF

.DATA
      EXTRN Mens0,Mens1,Mens2,Mens3,Mens4,Mens5,Press,Enca1,PagActiva
      EXTRN Pagina,Columna,Renglon,Xcurs,Ycurs,CursorPtr,ByteEd,Insert,InsMode
      EXTRN OvwMode,BarraDeAyuda,Ayuda2,Modificado:FAR,FileName:FAR,Ayuda3:FAR
      EXTRN Insert
      Vert     EQU 0BAh
      Horiz    EQU 0CDh
      SupIzq   EQU 0C9h
      InfIzq   EQU 0C8h
      SupDer   EQU 0BBh
      InfDer   EQU 0BCh
      Barra    EQU 0DBh
      AtrBar   EQU 0Fh
      Espacio  EQU 20h
      F1       EQU 59

.CODE

PUBLIC CursorGrande,NoCursor,CursorNormal,ClsNotePad,Portada,Barras,Actualiza
PUBLIC Mensajes,LimpiaBarra,Borrador,Barra_de_Ayuda,Checa_InsOvw

Portada PROC FAR                  ;proc. para escribir a CRT la portada de EID
      ClrScr
      Marco  1,1,79,24
      GotoXY 30,5
      Write  Mens0
      GotoXY 19,7
      Write  Mens1
      GotoXY 20,9
      Write  Mens2
      GotoXY 26,11
      Write  Mens3
      GotoXY 17,13
      Write  Mens4
      GotoXY 22,15
      Write  Mens5
      Pause  Press
      ClrScr
      RET                          ;retorno lejano
Portada ENDP                       ;fin del proc.

NoCursor PROC FAR              ;procedimiento para "desaparecer" el cursor
      MOV AH,01                  ;funcion 01 (tipo de cursor)
      MOV CH,20h                 ;comienzo de la linea de exploracion
      MOV CL,20h                 ;fin de esta linea
      INT 10h                    ;int. 10h del BIOS
      RET                        ;retorno lejano
NoCursor ENDP                  ;fin del procedimiento

CursorNormal PROC FAR          ;proc. para poner el cursor al tamano normal
      MOV AH,01                  ;funcion 01 (tipo de cursor)
      MOV CH,11                  ;comienzo del cursor
      MOV CL,12                  ;fin del cursor
      INT 10h                    ;int. 10h del BIOS
      RET                        ;retorno lejano
CursorNormal ENDP              ;fin del proc.

CursorGrande PROC FAR          ;proc. para poner el cursor de tamano "grande"
      MOV AH,01                  ;funcion 01 (tipo de cursor)
      MOV CH,00                  ;comienzo del cursor
      MOV CL,12                  ;fin del cursor
      INT 10h                    ;int. 10h de BIOS
      RET                        ;retorno lejano
CursorGrande ENDP              ;fin del proc

ClsNotePad PROC FAR            ;proc. que borra el area de trabajo solamente
      MOV AX,0600h               ;scroll de una sola linea
      MOV BH,07                  ;atributo normal de video
      MOV CX,0300h               ;de 00,04
      MOV DX,174Fh               ;a 24,79
      INT 10h                    ;int. 10h del BIOS
      RET                        ;retorno lejano
ClsNotePad ENDP                ;fin del proc.

Borrador PROC FAR              ;proc. para limpiar la barra inf.
      GotoXY 00,24                             ;de basura
      WriteCattr 00,24,Barra,AtrBar,50h,00
      RET
Borrador ENDP

LimpiaBarra PROC FAR    ;este proc. limpia la barra inf. de cualquier mensaje
      CALL NoCursor                          ;sin cursor
      CALL Borrador
      GotoXY 00,24                           ;ir a la barra
      MOV SI,OFFSET BarraDeAyuda             ;direccion de la barra de ayuda
      XOR CX,CX                              ;limpiar cx
      MOV CL,80                              ;79 caracteres
   OtroCarDeBar:
      PUSH CX                                ;salvar contador
      MOV  DL,80                             ;obtener posc. del sig. car
      SUB  DL,CL
      MOV  AL,BYTE PTR [SI]                  ;pasarlo a AL
      WriteCAttr DL,24,AL,70h,01h,00         ;escribirlo
      INC  SI                                ;ir al sig. car.
      POP  CX
      LOOP OtroCarDeBar
      CALL CursorGrande                                    ;cursor grande
      RET                                                  ;retorno
LimpiaBarra ENDP                                           ;fin del proc.

Barras PROC FAR                ;este proc. escribe la pantalla del notepad
      Marco 0,0,79,2
      WriteCAttr 00,00,Barra,AtrBar,50h,00                   ;barra superior
      CALL LimpiaBarra                                       ;barra inferior
      GotoXY 00,00
      MOV SI,OFFSET Enca1                    ;direccion del encabezado
      XOR CX,CX                              ;limpiar cx
      MOV CL,80                              ;76 caracteres
   OtroCarDeEnca:
      PUSH CX                                ;salvar contador
      MOV  DL,80                             ;obtener posc. del sig. car
      SUB  DL,CL
      MOV  AL,BYTE PTR [SI]                  ;pasarlo a AL
      WriteCAttr DL,00,AL,70h,01h,00         ;escribirlo
      INC  SI                                ;ir al sig. car.
      POP  CX
      LOOP OtroCarDeEnca
      RET                        ;retorno
Barras ENDP                    ;fin del procedimiento

Actualiza PROC FAR        ;este proc. actualiza los nums. de PAG.,COL. y REN.
      CALL NoCursor                        ;desaparecer cursor
      GotoXY 02,01
      Write  Pagina                        ;escribir "Pag"
      MOV DL,BYTE PTR PagActiva            ;en DL el numero de pagina
      ADD DL,30h                           ;convertir a ASCII
      WriteChar DL                         ;escribir el Ascii del # de pag.
      GotoXY 10,01
      Write  Renglon                       ;escribir "Ren"
      MOV DL,BYTE PTR Ycurs                ;en DL la coordenada Y del cursor,
      SUB DL,02                            ;menos 2 (ajuste a linea real)
      HexAscii                             ;convertir a Ascii's
      GotoXY 19,01
      Write Columna                        ;escribir "Col"
      MOV DL,BYTE PTR Xcurs                ;en DL la coordenada X del cursor
      HexAscii                             ;convertir a Ascii's
      GotoXY 29,01
      Write  ByteEd                        ;escribir el byte que es editado
      PUSH SI
      MOV  SI,CursorPtr
      LODSB
      CMP  AL,20h
      JAE  Escribe
           MOV AL,20h
   Escribe:
      WriteChar AL
      POP SI
      GotoXY 45,01                        ;reportar estado de inserc./sobreesc.
      CMP Insert,01
      JE  EscrIns
          Write OvwMode
          JMP EscrModificacion
      EscrIns:
          Write InsMode
   EscrModificacion:                     ;reportar si el archivo ha sido modif.
      GotoXY 58,01
      MOV AL,BYTE PTR Modificado
      CMP AL,01
      JE  EscrModif
          MOV AL,' '                     ;si no, escribir blanco
          WriteChar AL
          JMP FinActualiza
   EscrModif:                            ;si fu‚, escribir asterisco
      MOV AL,'*'
      WriteChar AL
   FinActualiza:                         ;fin de la actualizaci¢n
      GotoXY 60,01
      Write FileName                     ;escribir nom. de arch. de trabajo
      MOV AL,BYTE PTR Xcurs              ;restaurar coordenadas del cursor
      MOV BL,BYTE PTR Ycurs
      GotoXY AL,BL                       ;recolocar el cursor donde estaba
      CALL CursorGrande                    ;cursor grande
      RET                                  ;retorno
Actualiza ENDP                            ;fin del proc.

Barra_de_Ayuda PROC FAR
      CALL NoCursor                          ;sin cursor
      CALL Borrador
      GotoXY 00,24                           ;ir a la barra
      MOV SI,OFFSET Ayuda2                   ;direccion de la barra de ayuda
      XOR CX,CX                              ;limpiar cx
      MOV CL,80                              ;79 caracteres
   OtroCarDeHlp1:
      PUSH CX                                ;salvar contador
      MOV  DL,80                             ;obtener posc. del sig. car
      SUB  DL,CL
      MOV  AL,BYTE PTR [SI]                  ;pasarlo a AL
      WriteCAttr DL,24,AL,70h,01h,00         ;escribirlo
      INC  SI                                ;ir al sig. car.
      POP  CX
      LOOP OtroCarDeHlp1
   LeeTk1:
      ReadKey AL                             ;presionar F1 para salir
      CMP AL,F1
      JNE LeeTk1
      CALL Borrador
      GotoXY 00,24                           ;ir a la barra
      MOV SI,OFFSET Ayuda3                   ;direccion de la barra de ayuda
      XOR CX,CX                              ;limpiar cx
      MOV CL,80                              ;79 caracteres
 OtroCarDeHlp2:
      PUSH CX                                ;salvar contador
      MOV  DL,80                             ;obtener posc. del sig. car
      SUB  DL,CL
      MOV  AL,BYTE PTR [SI]                  ;pasarlo a AL
      WriteCAttr DL,24,AL,70h,01h,00         ;escribirlo
      INC  SI                                ;ir al sig. car.
      POP  CX
      LOOP OtroCarDeHlp2
    LeeTk2:
      ReadKey AL                             ;presionar F1 para salir
      CMP AL,F1
      JNE LeeTk2
      CALL LimpiaBarra                       ;limpiar barra
      CALL Actualiza
      CALL CursorGrande                      ;cursor grande
      RET                                    ;retorno
Barra_De_Ayuda ENDP                          ;fin del proc.

Mensajes PROC FAR         ;este proc. escribe un mensaje en la barra inferior
      PUSH DX
      CALL NoCursor                ;desaparecer cursor
      CALL Borrador                ;borrar barra
      GotoXY 03,24
      POP DX
      MOV AH,09                    ;escribir mensaje
      INT 21h
      WriteChar 07                 ;pitido
      CALL CursorGrande            ;cursor grande
      RET                          ;retorno lejano
Mensajes ENDP                    ;fin del proc.

Checa_InsOvw PROC FAR            ;proc. para checar el estado de inserci¢n
      MOV  AH,02                   ;func. para checar estado del teclado
      INT  16h                     ;por int. 16 (BIOS)
      TEST AL,80h                  ;si AL and 80h es cierto...
      JNE  EstadoOvw
           MOV    Insert,01            ;entonces, estado de inserci¢n
           CALL   Actualiza            ;actualizar
           RET                         ;retorno
      EstadoOvw:
         MOV    Insert,00              ;sino, modo de sobreescritura
         CALL   Actualiza              ;actualizar
         RET                           ;retorno
Checa_InsOvw ENDP                    ;fin del proc.

END                            ;fin del modulo de programa
