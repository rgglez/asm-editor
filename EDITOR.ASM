.SALL
PAGE 40,132
TITLE  - (EDITOR.ASM) PROGRAMA PARA LA EDICION DE TEXTOS MANEJANDO ARCHIVOS -
SUBTTL - PROYECTO FINAL. MODULO PRINCIPAL. -
COMMENT *           PROGRAMA PARA PROYECTO FINAL DE ENSAMBLADOR.
                                Versi¢n 1.0
          Realizado por: GONZALEZ GONZALEZ RODOLFO.
          11:20:00  Enero 19, 1994

   M¢dulo Principal: EDITOR.ASM
   Este programa es el proyecto final de ensamblador. Es un editor de texto
le¡do de/escrito a archivo de disco, teniendo diversas opciones: copiado de
archivos del formato ASCII (respaldo), inserci¢n de lineas, substituci¢n de
bytes, busqueda de una cadena ASCII en un texto,eliminacion de blancos,
conversion a mayusculas o min£sculas de las palabras de una linea, impresi¢n
del texto en memoria, as¡ como las operaciones del teclado Inicio, Inicio de
p gina, P gina abajo, Inicio de documento, y movimiento del cursor en el texto
operando al mismo tiempo en pantalla y en memoria en todas las rutinas y
funciones.
   Este programa utiliza la libreria de macros MACROS1.LIB, que contiene
rutinas de proposito general. Asi mismo usa el modulo EID.asm (Entorno
Integrado de Desarrollo) que es un modulo externo enlazable, que contiene
rutinas para el manejo del ambiente de edicion.                              *

;--------------------* INCLUSION DE LIBRERIAS DE MACROS *---------------------

IF1                                      ;solo en el primer ciclo de ensamble
   INCLUDE MACROS1.LIB                   ;incluir libreria MACROS1.LIB
   PURGE HexAscii,SalvaRegs,RestauraRegs,Marco
ENDIF                                    ;fin del if

;----------- * PROCEDIMIENTOS Y SIMBOLOS EXTERNOS LEJANOS *-------------------

EXTRN CursorGrande:FAR,NoCursor:FAR,CursorNormal:FAR,Portada:FAR
EXTRN ClsNotePad:FAR,Barras:FAR,Actualiza:FAR,Barra,AtrBar,Mensajes:FAR
EXTRN LimpiaBarra:FAR,Borrador:FAR,Barra_de_Ayuda:FAR
EXTRN Checa_InsOvw:FAR

;------------------------* SEGMENTO DE STACK *--------------------------------

Pila SEGMENT PARA STACK 'Stack'           ;segmento de stack
      DW 64 DUP (0)                       ;64 palabras
Pila ENDS                                 ;fin del segmento

;------------------------* SEGMENTO DE DATOS *--------------------------------

Data SEGMENT PARA PUBLIC 'Datos'            ;segmento de datos
     ;                                       constantes EQU
     RecLen   EQU 80                        ;longitud del registro
     NumLine  EQU 24                        ;numero de lineas por pagina llena
     PagLines EQU 05                        ;m x. num. de lineas por pag. imp.
     Nulo     EQU 00                        ;diversos c¢digos ASCCI usados
     Espacio  EQU 20h
     Vert     EQU 0BAh
     Horiz    EQU 0CDh
     SupIzq   EQU 0C9h
     InfIzq   EQU 0C8h
     SupDer   EQU 0BBh
     InfDer   EQU 0BCh
     CR       EQU 0Dh
     LF       EQU 0Ah
     F1       EQU 59                        ;codigos de exploraci¢n de las
     F2       EQU 60                        ;teclas especiales y de funci¢n
     F3       EQU 61                        ;usadas para acceder a las funcio-
     F4       EQU 62                        ;nes de EDT
     F5       EQU 63
     F6       EQU 64
     F7       EQU 65
     F8       EQU 66
     F9       EQU 67
     F10      EQU 68
     F11      EQU 69
     F12      EQU 70
     PagDown  EQU 51h
     PagUp    EQU 49h
     Right    EQU 77
     Left     EQU 75
     Up       EQU 72
     Down     EQU 80
     Escape   EQU 27
     Home     EQU 71
     InsOvw   EQU 82
     CtrlHome EQU 119
     CtrlPgUp EQU 132
     ;
		 TextSize EQU RecLen*NumLine*4          ;longitud del buffer de texto
     ;
     DTA     LABEL BYTE                     ;area del DTA
     MaxNLen DB RecLen
     ActNLen DB 0
     DTALine DB RecLen DUP (Espacio)        ;DTA (Data Transfer Area)
             DB '$'                         ;terminador
     ;
     BufTransfer DB RecLen DUP (Espacio)          ;buffer para transferencias
                 DB '$'                           ;mem/CRT, y otras
     ;
     PUBLIC FileName
     FileLong DB 14                          ;long. del nombre de archivo
     ActFNLen DB 0                           ;long. actual del nombre
     FileName DB 14 DUP (Espacio)            ;nombre de archivo (lectura)
              DB 00                          ;limitador requerido por FSearch
              DB '$'                         ;limitador para escritura int.21h
     ;
     SearchLong DB RecLen                ;long.buffer de b£squeda/inserci¢n
     SearchActL DB 0                        ;long. actual de ‚ste buffer
     Searched   DB RecLen DUP (Nulo)     ;buffer de b£squeda/inserci¢n
     CompString DB RecLen DUP (Nulo)     ;cadena de comparaci¢n en b£squeda
     ;
     PUBLIC CursorPtr                ;publico para EID
     PoscCima     DW 0000            ;num. de bytes*registro leidos
     BasTxtOffset DW 0000            ;offset base del buffer de texto
     MaxTxtOffset DW 0000            ;max. offset del buffer de texto
     UltChrOffset DW 0000            ;offset del £ltimo car. del texto
     CursorPtr    DW 0000            ;apuntador a caracter de la posc. en txt.
     IniPagOffset DW 0000            ;offset del car. que inicia una p gina
     IniLineaOffs DW 0000            ;offset del car. que inicia una linea
     PoscEnTexto  DW 0000            ;offset del ultimo car. en la p gina
     Searcher     DW 0000            ;apuntador para la b£squeda de cadenas
     TransPtr     DW 0000            ;apuntador usado en inserci¢n de cadenas
     AuxPtr1      DW 0000            ;apuntadores auxiliares temporales
     AuxPtr2      DW 0000
     AuxPtr3      DW 0000
     AuxPtr4      DW 0000
     PUBLIC Xcurs,Ycurs,Insert,Modificado,PagActiva,Insert  ;publicos para EID
     PagActiva    DB 00             ;contador de p ginas
     TeclaActual  DB 00             ;codigo de la tecla presionada
     FinDelTexto  DB 00             ;bandera que indica fin de texto(lectura)
     NoMasLineas  DB 00             ;bandera que indica fin de lineas(Down)
     NumTopes     DB 00             ;bandera para detener cursor (right/left)
     Modificado   DB 00             ;bandera que indica archivo modificado
     Insert       DB 00             ;bandera que indica estado de inserci¢n
     PtrFijado    DB 00             ;bandera que indica si CursorPtr es deten.
     ArchVacio    DB 00             ;bandera que indica si archivo vacio
     SalvadoTotal DB 00             ;bandera que indica archivo salvado
     Eof          DB 00             ;bandera que indica marca de EOF (1Ah)
     Xcurs        DB 01             ;abscisa del cursor el p gina
     Ycurs        DB 03             ;ordenada del cursor en p gina
     CursX        DB 01             ;coordenadas temporales del cursor
     CursY        DB 03
     ;
     FCBfrec1 LABEL BYTE              ;FCB (File Control Block) del archivo 1
     FCBdriv1 DB 00                   ;drive
     FCBfnom1 DB '        '           ;nombre del archivo
     FCBfext1 DB 'EDT'                ;extensi¢n por default
     FCBblk1  DW 0000                 ;bloque actual leido
     FCBrcsz1 DW 0000                 ;tama¤o del registro
     FCBflsz1 DD ?                    ;tama¤o del archivo
     FCBflda1 DW ?                    ;datos de DOS
              DT ?
     FCBsqrc1 DB 00                   ;registro actual
              DD ?
     ;
     FCBfrec2 LABEL BYTE              ;FCB (File Control Block) del archivo 2
     FCBdriv2 DB 00                   ;drive del archivo de respaldo
     FCBfnom2 DB '        '           ;nombre del archivo de respaldo
     FCBfext2 DB 'BAK'                ;extensi¢n por defecto del arch. backup
     FCBblk2  DW 0000                 ;bloque actual
     FCBrcsz2 DW 0000                 ;tama¤o del registro
     FCBflsz2 DD ?                    ;tama¤o del archivo
     FCBflda2 DW ?                    ;datos de DOS
              DT ?
     FCBsqrc2 DB 00                   ;registro actual
              DD ?
     ;
     CodError    DB 00                ;c¢digo de error en operaciones I/O
     ErrorAux    DB 00                ;idem. auxiliar
     ArchActivo  DB 00                ;bandera que indica el arch. activo
     ErrorArch1   DB 'ERROR CREANDO ARCHIVO!',07,'$'
     ErrorArch2   DB 'ERROR DE LECTURA!',07,'$'
     InvalidFName DB 'NOMBRE DE ARCHIVO NO VALIDO.','$'
     NomConComo   DB 'ERROR: NOMBRE CON COMODINES.','$'
     ArchNoExiste DB 'ERROR: ARCHIVO NO EXISTENTE.','$'
     Salvando     DB 'SALVANDO ARCHIVO DE TRABAJO. . .','$'
     ErrorSalvando DB 'ERROR SALVANDO ARCHIVO DE TRABAJO.','$'
     Exito        DB 'OPERACION EXITOSA.','$'
     Respaldando  DB 'RESPALDANDO ARCHIVO DE TRABAJO!, Espere un momento. . .','$'
     Imprimiendo  DB 'IMPRIMIENDO DOCUMENTO. . .','$'
     ErrorImprimiendo1 DB 'ERROR: Fallo en el dispositivo PRN !','$'
     ;
     PUBLIC Mens0,Mens1,Mens2,Mens3,Mens4,Mens5,Press,Enca1,Pagina,Ayuda2
     PUBLIC Columna,Renglon,ByteEd,InsMode,OvwMode,BarraDeAyuda,Ayuda3
       Mens0 DB 07h,'<< PROYECTO FINAL >>','$'
       Mens1 DB 'PROGRAMA: EDITOR DE PAGINAS/LINEAS/BYTES','$'
       Mens2 DB 'Realizado por: RODOLFO GONZALEZ GONZALEZ.','$'
       Mens3 DB 'Matr¡cula:     920007382.','$'
       Mens4 DB 'Grupo :  C 5.   Ensamblador.   Tercer Semestre.','$'
       Mens5 DB 'B.U.A.P.   F.C.F.M.   Computaci¢n.','$'
       Press DB 07h,'PRESIONE CUALQUIER TECLA . . .','$'
       Enca1 DB '   EDITOR de P ginas/Lineas/Bytes.          Por: RODOLFO GONZALEZ GONZALEZ.      '
             DB '$'
       Autor DB 'Autor: RODOLFO GONZALEZ GONZALEZ. Mat.: 920007382. Gpo.: C5. 3er. Sem. 1994','$'
       PideNom DB 'Introduzca Nombre de Archivo: ','$'
       PideLinea       DB 'BUSCAR: ','$'
       Insertar        DB 'INSERTAR: ','$'
       CadNoEncontrada DB 'Cadena NO encontrada. Presione cualquier tecla...','$'
       CadEncontrada   DB 'Cadena encontrada. Presione cualquier tecla...','$'
       BufferLleno     DB 'ERROR: Buffer de texto lleno, memoria insuficiente!, pres. una tecla...','$'
       ArchNoSave      DB ' Archivo modificado NO salvado. ¨Salvar? S=salvar/OTRA=salir ','$'
       Pagina  DB 'P g: ','$'
       Columna DB 'Col: ','$'
       Renglon DB 'Ren: ','$'
       ByteEd  DB 'Byte Editado: ','$'
       InsMode DB '<Inserci¢n>','$'
       OvwMode DB '<SobreEscr>','$'
       BarraDeAyuda DB ' F1-Sig.Men£ F2-Salvar F3-A mayusc. F4-A minusc. '
                    DB ' F5-Camb. Arch.  F6-Just. Izq.  ','$'
       Ayuda2       DB ' F7-Buscar  F8-Insertar linea (si Ins. Activada) '
                    DB ' F9-Imprimir texto   Esc-Salir  ','$'
       Ayuda3       DB ' INS-Ins/SobreEscr.                              '
                    DB '            F10-Sobre el autor  ','$'
       Nul          DB '','$'
       ;
       Texto DB TextSize DUP (Espacio)          ;buffer para el texto EDT
             DB '$'                             ;terminador
       ;
Data ENDS                     ;fin del segmento de datos

;-------------------------* SEGMENTO DE CODIGO *------------------------------

Code SEGMENT PARA PUBLIC 'Code'                 ;segmento de codigo

Prog PROC FAR                                   ;programa principal
      ASSUME DS:Data,ES:Data,SS:Pila,CS:Code    ;prologo del programa
      PUSH DS
      SUB  AX,AX
      PUSH AX
      MOV  AX,SEG Data
      MOV  DS,AX
      MOV  ES,AX
      CALL NoCursor                            ;sin cursor
      CALL Portada                             ;poner portada
      CALL Barras                              ;poner barras de la pantalla
  Inicia_Proceso:                              ;inicio de la sesi¢n de edici¢n
      LEA  DX,Texto                            ;en DX la dir. de inic. del txt.
      MOV  MaxTxtOffset,DX                     ;salvara en el max. offset
      ADD  MaxTxtOffset,TextSize               ;max. offset real del texto
      CALL Parser                              ;parsing del nombre de arch.
      CMP  ArchVacio,01                        ;si el arch. esta vacio
      JE   NoRespaldes1                        ;no respaldes
           LEA  DX,Respaldando                 ;sino, respaldar
           CALL Mensajes
           CALL CargaTexto_A_Memoria_Y_Respalda          ;y cargar texto a mem.
   NoRespaldes1:
           CALL LimpiaBarra                    ;limpiar barra
           LEA  DX,Texto                       ;en DX el offs. del buffer
           MOV  BasTxtOffset,DX                ;salvarlo en el ptr. a al base
           MOV  IniPagOffset,DX                ;idem.en el ptr. al inic. de pag
           ADD  DX,PoscCima                    ;sumarle el no. de bytes leidos
           DEC  DX                             ;menos 1
           MOV  UltChrOffset,DX                ;y salvar ‚ste offs. en el ptr al ult chr.
           CMP  ArchVacio,01                   ;si el archivo fu‚ vac¡o,
           JE   NoRespaldes2                   ;salta...
                CALL NoCursor                     ;si no, sin cursor...
                CALL Despliega_Pagina_Abajo       ;ver prim. p gina del txt.
                MOV  AX,CursorPtr                 ;salva ptr. al caracter act.
                MOV  IniLineaOffs,AX              ;y al inic. de linea actual
   NoRespaldes2:
       LEA  DX,Texto                           ;en DX el offs. del buffer
       MOV  BasTxtOffset,DX                    ;salvarlo en el offset base
       MOV  IniPagOffset,DX                    ;en el inic. de pag.
       MOV  CursorPtr,DX                       ;en el ptr. al caracter actual
       MOV  IniLineaOffs,DX                    ;y en el ptr. al inic.de linea
       MOV  Xcurs,01                           ;abscisa inicial del cursor
       MOV  Ycurs,03                           ;ordenada inicial del cursor
       CALL Checa_InsOvw                       ;checar estado de ins/srobreesc.
       CALL Actualiza                          ;actualizar
    OtraVez:
       ReadKey TeclaActual                     ;leer tecla
       CMP TeclaActual,00                      ;si es tecla especial...
       JE  TeclaEspecial                       ;saltar
           CMP TeclaActual,Escape              ;sino, si fu‚ escape...
           JE  ConfirmarSalida                 ;confirmar salida
               CMP Insert,00                   ;sino, ver si esta en ins.
               JNE OtraVez                     ;si lo est , saltar atras
                   CALL SobreEscribe_Byte             ;sobreesc. byte
            JMP OtraVez
    ConfirmarSalida:                          ;conf. salida
          CMP Modificado,01                   ;ver si el texto se modific¢
          JNE SalteDeAqui                     ;si no, salir
              LEA  DX,ArchNoSave              ;si s¡, ver si se desea modificar
              CALL Mensajes                   ;mensaje de precauci¢n
              CALL NoCursor                   ;sin cursor
              ReadKey AL                      ;leer tecla
              CMP AL,'S'                      ;ver si fu‚ 'S'
              JE  SiSalvo                     ;si no, comparar...
                  CMP AL,'s'                  ;con la 's'
                  JNE SalteDeAqui             ;si no es igual, salir
              SiSalvo:                        ;si es igual, salvar
                  CALL Salvar_Archivo         ;el texto modificado
     SalteDeAqui:                             ;y salir
          JMP El_Final                        ;terminar
     TeclaEspecial:                           ;si fu‚ tecla especial
        ReadKey TeclaActual                   ;obtener c¢digo de exploraci¢n
        CMP TeclaActual,PagDown               ;ver si es p gina abajo
        JNE Sig1                              ;si no...
            CMP FinDelTexto,01                ;si es fin del texto...
            JNE AunHayMas1
                CALL Fin_De_Texto             ;desplegar primera p gina
                JMP  OtraVez
         AunHayMas1:                          ;si a£n hay p gs. abajo...
               CALL Pagina_Abajo              ;despliega sig. p g.
               JMP  OtraVez
        Sig1:
           CMP TeclaActual,Right              ;flecha derecha
           JNE Sig2
               CALL Cursor_Derecha            ;mover curs./ptr. a derecha
               JMP  OtraVez
        Sig2:
           CMP TeclaActual,Left               ;flecha izquierda
           JNE Sig3
               CALL Cursor_Izquierda          ;mover curs./ptr. a izq.
               JMP  OtraVez
        Sig3:
           CMP TeclaActual,Up              ;flecha arriba
           JNE Sig4
               CALL Cursor_Arriba          ;mover curs./ptr. al inic. linea ant
               JMP  OtraVez
        Sig4:
           CMP TeclaActual,Down            ;flecha abajo
           JNE Sig5
               CALL Cursor_Abajo           ;mover curs./ptr. al inic. linea sig
               JMP  OtraVez
        Sig5:
           CMP TeclaActual,Home            ;tecla Home
           JNE Sig6
               CALL Cursor_Home            ;mover curs./ptr. al inic. de linea
               JMP  OtraVez
        Sig6:
           CMP TeclaActual,CtrlHome        ;teclas Ctrl-Home
           JNE Sig7
               CALL Cursor_IniPag          ;mover curs./ptr. al inic. de p gina
               JMP  OtraVez
        Sig7:
           CMP TeclaActual,CtrlPgUp        ;teclas Ctrl-PgUp
           JNE Sig8
               CALL Fin_De_Texto           ;ir al inicio del texto
               JMP  OtraVez
        Sig8:
           CMP TeclaActual,InsOvw          ;tecla Insert
           JNE Sig9
               CALL Checa_InsOvw           ;reportar estado de inserci¢n
               JMP  OtraVez
        Sig9:
           CMP TeclaActual,F1              ;tecla F1
           JNE Sig10
               CALL Barra_de_ayuda         ;mostrar ayuda inferior (men£s)
               JMP  OtraVez
        Sig10:
           CMP TeclaActual,F2              ;tecla F2
           JNE Sig11
               CALL Salvar_Archivo         ;salvar el archivo
               JMP  OtraVez
        Sig11:
           CMP TeclaActual,F3              ;tecla F3
           JNE Sig12
               CALL A_Mayusculas           ;convertir a may£sculas
               JMP  OtraVez
        Sig12:
           CMP TeclaActual,F4              ;tecla F4
           JNE Sig13
               CALL A_Minusculas           ;convertir a min£sculas
               JMP OtraVez
        Sig13:
           CMP TeclaActual,F5              ;tecla F5
           JNE Sig14
               CALL NoCursor               ;cargar nuevo archivo
               CALL ClsNotePad             ;saltando a inicia_proceso
               CALL Reinicia_Variables
               JMP  Inicia_Proceso
        Sig14:
           CMP TeclaActual,F6              ;tecla F6
           JNE Sig15
               CALL Justifica_Izq          ;eliminaci¢n de espacios
               JMP  OtraVez
        Sig15:
           CMP TeclaActual,F7              ;tecla F7
           JNE Sig16
               CALL Busca_Cadena           ;buscar una cadena
               JMP  OtraVez
        Sig16:
           CMP TeclaActual,F8              ;tecla F8
           JNE Sig17
               CMP Insert,01               ;checar si inserci¢n activa
               JNE Pasa
                   CALL Inserta_Linea_Y_Reescribe_Pag           ;inserta linea
                   JMP  OtraVez
           Pasa:
               JMP  OtraVez                ;pasar atras
        Sig17:
           CMP TeclaActual,F9              ;tecla F9
           JNE Sig18
               CALL Imprime_Texto          ;imprimir texto en LPT1
               JMP  OtraVez
        Sig18:
           CMP TeclaActual,F10             ;tecla F10
           JNE Sig19
               CALL Borrador               ;informaci¢n acerca del autor
               LEA  DX,Autor               ;de EDT (y¢), Rodolfo Gonz lez
               CALL Mensajes               ;Glez. mat. 920007382
               CALL NoCursor
               Pause Nul
               CALL LimpiaBarra
               CALL Actualiza
               JMP  OtraVez
        Sig19:                             ;no es funci¢n EDT, no hacer algo
           JMP OtraVez                     ;m s que regresar
      El_Final:                            ;‚ste es el final
         ClrScr                            ;limpiar pantalla
         CALL CursorNormal                 ;restaurar el cursor a normal
         RET                               ;retornar a DOS
Prog ENDP                                  ;fin del programa principal

;---------------* PROCEDIMIENTOS PARA LA EDICION *-----------------------------

SobreEscribe_Byte PROC NEAR     ;‚ste proc. sobreescribe un byte en mem. y CRT
      MOV BX,UltChrOffset               ;ver si no es el final del texto
      MOV DI,CursorPtr
      CMP DI,BX
      JB  SigueAdelante
          WriteChar 07                  ;si es, salir
          RET
   SigueAdelante:                       ;si no...
      MOV AL,TeclaActual
      CMP BYTE PTR [DI],CR
      JE  FinEditByte
          CMP BYTE PTR [DI-1],CR
          JE FinEditByte
             CMP PtrFijado,01
             JE  FinEditByte
                 INC Xcurs
                 CMP BYTE PTR [DI],CR
                 JE  FinEditByte
                     INC CursorPtr
                     STOSB
                     WriteChar AL
                     MOV Modificado,01
                     CALL Actualiza
                     RET
   FinEditByte:
      MOV PtrFijado,01
      CALL Actualiza
      RET
SobreEscribe_Byte ENDP

Inserta_Linea_Y_Reescribe_Pag PROC NEAR
       LimpiaRegs
       CLD
       CALL Borrador
       LEA  DX,Insertar
       CALL Mensajes
       LEA  DI,Searched
       MOV  CX,RecLen
    LimpiarBuf:
       MOV  BYTE PTR [DI],Nulo
       INC  DI
       LOOP LimpiarBuf
       WriteCAttr 13,24,20h,00,60,00
       WriteCAttr 13,24,00h,15,60,00
       CALL CursorNormal
       ReadStr SearchLong,SearchActL,Searched
       CALL NoCursor
       CMP  SearchActL,00
       JNE  HayCar1
            CALL LimpiaBarra
            CALL Actualiza
            RET
    HayCar1:
        CALL LimpiaBarra
        CALL NoCursor
        LimpiaRegs
        MOV  AL,CR
        MOV  AH,LF
        LEA  DI,Searched
        MOV  BL,SearchActL
        ADD  DI,BX
        STOSW
        ADD  SearchActL,02
        MOV  BX,UltChrOffset
        ADD  BX,0002
        SUB  BX,CursorPtr
        MOV  CX,BX
        MOV  DI,UltChrOffset
        XOR  BX,BX
        MOV  BL,SearchActL
        ADD  DI,BX
        CMP  DI,MaxTxtOffset
        JB   AunHayMemoria
             LEA  DX,BufferLleno
             CALL Mensajes
             ReadKey AL
             CALL LimpiaBarra
             CALL Actualiza
             RET
    AunHayMemoria:
        MOV  SI,UltChrOffset
        STD
        REP  MOVSB
        CLD
        LEA  SI,Searched
        MOV  DI,CursorPtr
        MOV  CL,SearchActL
        REP  MOVSB
        XOR  BX,BX
        MOV  BL,SearchActL
        ADD  UltChrOffset,BX
        MOV  FinDelTexto,00
        SalvaApuntadores
        CALL ClsNotePad
        CALL Despliega_Pagina_Abajo
        RestauraApuntadores
        CALL Actualiza
        RET
Inserta_Linea_Y_Reescribe_Pag ENDP

Justifica_Izq PROC NEAR
       CLD
       CALL Transfer4
       LEA  DI,Searched
       MOV  AL,Espacio                 ;el AL el caracter 20H (espacio blanco)
    Lazo:
        REPNE SCASB
        CMP   CX,0
        JZ    Fin1
        CALL  Busca20h
        LOOP  Lazo
     Fin1:
         MOV AL,CR
         MOV AH,LF
         STOSW
         MOV CX,0FFFFh
         LEA DI,Searched
         MOV AL,CR
         REPNE SCASB
         XOR CX,0FFFFh
         INC CX
         LEA SI,Searched
         MOV DI,IniLineaOffs
         REP MOVSB
         MOV BX,DI
         CMP DI,MaxTxtOffset
         JBE Bien0
             CALL Actualiza
             RET
      Bien0:
         DEC DI                                ;decrementa offs. del ult. car
         MOV CX,0FFFFh                         ;de la nueva linea
         REPNE SCASB                           ;para ver en cuanto se "achic¢"
         CMP DI,MaxTxtOffset                   ;ver si no se sale del Texto
         JBE Bien1                             ;si hay memoria salta, si no...
             SUB  UltChrOffset,DX        ;dec. el offs. del ult. car. del doc.
             MOV  BX,UltChrOffset              ;obtener long. restante del
             MOV  CX,MaxTxtOffset              ;buffer del Texto
             SUB  CX,BX                        ;y dejarla en CX
             MOV  DI,UltChrOffset              ;y apartir del ult. caracter
             STD                               ;con la band. de dir. = 1
             MOV  AL,LF                        ;buscar LF (0Ah)
             REPNE SCASB
             ADD  DI,0002                      ;sumar dos a donde se encontr¢
             MOV  AL,Espacio                   ;y apartir de ah¡ llenar la
             CLD                               ;memoria del buffer de texto
             REP  STOSB                        ;con 20h (espacios)
             CALL Actualiza                    ;actualizar
             RET                               ;retorno
      Bien1:                                   ;si hubo memoria...
         XOR CX,0FFFFh                         ;obtener la long. de la parte
         MOV DX,CX                             ;del texto que se debe "subir"
         MOV DI,BX                             ;es decir, el n£mero de bytes
         MOV SI,DI                             ;que debe haber entre la posc.
         MOV BX,CX                             ;final de la vieja linea
         ADD SI,BX                             ;y el fin del texto, dado por
         MOV BX,UltChrOffset                   ;el offset del £ltimo caracter
         SUB BX,SI
         MOV CX,BX                             ;y dejarla en CX
         INC CX                                ;aumentada en uno
         REP MOVSB                             ;para mover estos bytes
         CMP DI,MaxTxtOffset                   ;ver si no es el fin del texto
         JBE Bien2                             ;si hay memoria...
             CALL Actualiza                    ;si no, actualizar
             RET                               ;retorno
      Bien2:                                   ;si s¡...
         SUB  UltChrOffset,DX                  ;poner UltChrOffset al fin real
         SalvaApuntadores                      ;salvar apuntadores
         MOV  FinDelTexto,00                   ;indicar que no es fin de texto
         CALL NoCursor                         ;sin cursor aqu¡
         CALL ClsNotePad                       ;limpiar  rea de trabajo
         CALL Despliega_Pagina_Abajo           ;y refrescar p gina actual
         RestauraApuntadores                   ;restaurar apuntadores
         MOV  Modificado,01                    ;indicar que el texto se modif.
         CALL Actualiza                        ;actualizar todo
         RET                       ;retorno
Justifica_Izq ENDP                 ;fin del proc.

Busca20h PROC NEAR             ;procedimiento para la busqueda de espacios
     MOV  SI,DI                ;en SI, DI que apunta a la cadena
     MOV  DX,0                 ;iniciar un contador en DX
  Compara:
     CMP AL,[SI]               ;comparar AL=20h contra el byte apuntado en SI
     JNE Acabo                 ;si no es igual, termina esta parte
         INC SI                ;si es igual, procesar el sig. byte (caracter)
         INC DX                ;incrementar contador (un caracter mas)
         JMP Compara           ;repetir proceso hasta no encontrar blanco
  Acabo:                       ;eliminacion de los blancos
     CMP DX,0                  ;si fue un espacio, terminar
     JZ FinProc
     CALL Quitalos             ;sino, quitar blancos
     RET                       ;retorno
  FinProc:
     INC CX                    ;un caracter mas
     RET                       ;retorno
Busca20h ENDP                  ;fin del procedimiento

Quitalos PROC                  ;procedimiento para eliminar blancos
      PUSH DI                     ;salvar apuntador al caracter actual
      DEC  DX                     ;decrementar un caracter
      SUB  CX,DX                  ;colocar en CX longitud de cadena a mover
      PUSH CX                     ;salvar longitud a mover
      REP  MOVSB                  ;mover CX bytes
      POP  CX                     ;restaurar longitud
      POP  DI                     ;restaurar apuntador
      RET                         ;retorno
Quitalos ENDP                  ;fin del procedimiento

A_Mayusculas PROC NEAR             ;proc. para convertir todos los cars. de la
      CLD                          ;linea actual a may£sculas, en CRT y mem.
      MOV  DI,CursorPtr            ;en DI el offs. del car. (byte) actual
   OtroByte1:
      CALL NoCursor                ;sin cursor
      CMP PtrFijado,01                       ;si el cursor esta fijo...
      JE  FinConversion1                     ;no convertir
          CMP BYTE PTR [DI],CR               ;si no,ver si se lleg¢ al final
          JE  FinConversion1                 ;de la linea.
              MOV BX,UltChrOffset            ;en BX el offs. del ult. car.
              CMP DI,BX                      ;ver si no es el fin de texto
              JE  FinConversion1             ;acabar
                  MOV AL,BYTE PTR [DI]       ;ver si el caracter actual
                  CMP AL,61h                 ;tiene ASCII entre 61h ("a")
                  JB  Cont1
                      CMP AL,7Ah             ;y 7Ah ("z")
                      JA  Cont1
                          AND AL,0DFh                ;convertir a may£scula
                          STOSB                      ;y guardar nuevo car.
                          WriteChar AL               ;mostrarlo en el CRT
                          INC  Xcurs                 ;incrementar la abscisa
                          MOV  CursorPtr,DI          ;y el ap. del cursor
                          CALL Actualiza             ;y actualizar todo
                          JMP  OtroByte1             ;para ir al sig. byte
                  Cont1:
                     CMP BYTE PTR [DI+1],CR          ;ver si el sig. byte
                     JE  FinConversion1              ;es 0Dh
                         INC  DI                     ;si no, incrementa DI
                         INC  Xcurs                  ;y la abcisa del cursor
                         MOV  CursorPtr,DI           ;y poner al ap. en DI
                         CALL Actualiza              ;actualizar todo
                         JMP  OtroByte1              ;e ir por otro byte
     FinConversion1:
         MOV PtrFijado,01                            ;fijar apuntedor cursor
         WriteChar 07                                ;pitido
         CALL Actualiza                              ;actualizar
         RET                                         ;retorno
A_Mayusculas ENDP                                    ;fin del proc.

A_Minusculas PROC NEAR              ;proc. para convertir todos los car. de la
      CLD                           ;linea actual a min£sculas en CRT y mem.
      MOV  DI,CursorPtr                     ;en DI la posc. en mem. del cursor
   OtroByte2:
      CALL NoCursor                              ;sin cursor
      CMP PtrFijado,01                           ;ver si el cursor est  fijo
      JE  FinConversion2
          CMP BYTE PTR [DI],CR                   ;ver si es fin de linea
          JE  FinConversion2
              MOV BX,UltChrOffset                ;en BX el offs. del ult. car.
              CMP DI,BX                          ;ver si ya no hay texto
              JE  FinConversion2
                  MOV AL,BYTE PTR [DI]           ;ver si el byte actual
                  CMP AL,41h                     ;tiene ASCII entre 41h ("A")
                  JB  Cont2
                      CMP AL,5Ah                 ;y 5Ah ("Z")
                      JA  Cont2
                          ADD AL,20h             ;convertir a min£scula
                          STOSB                  ;y guardar el byte en mem.
                          WriteChar AL           ;mostrandolo en el CRT
                          INC  Xcurs             ;incrementar la abscisa
                          MOV  CursorPtr,DI      ;y el ap. del cursor
                          CALL Actualiza         ;actualizar
                          JMP  OtroByte2
                  Cont2:
                     CMP BYTE PTR [DI+1],CR      ;ver si el sig. car. es 0Dh
                     JE  FinConversion2          ;(fin de linea)
                         INC  DI                 ;aumentar DI
                         INC  Xcurs              ;y la abscisa del cursor
                         MOV  CursorPtr,DI       ;poner CursorPtr a DI
                         CALL Actualiza          ;actualizar
                         JMP  OtroByte2          ;ir al siguiente byte
     FinConversion2:
         MOV PtrFijado,01                        ;fijar el cursor
         WriteChar 07                            ;pitido
         CALL Actualiza                          ;actualizar
         RET                                     ;retorno
A_Minusculas ENDP                                ;fin del procedimiento

Busca_Cadena PROC NEAR         ;proc. para buscar una cadena de caracteres en
    LimpiaRegs                                           ;el texto en memoria
    CLD                                           ;limpiar DF
    CALL Borrador                                 ;limpiar barra inferior
    LEA  DX,PideLinea                             ;mensaje pidiendo cadena
    CALL Mensajes                                 ;a buscar
    WriteCAttr 11,24,20h,00,60,00                 ;limpiar campo de entrada
    WriteCAttr 11,24,00h,15,60,00
    CALL CursorNormal                             ;cursor normal
    MOV CX,RecLen                                 ;limpiar buffer's
    LEA SI,Searched                               ;tanto de lectura
    LEA DI,CompString                             ;como de comparaci¢n
  LoopLimpio:
    MOV BYTE PTR [SI],Nulo                        ;con caracteres nulos
    MOV BYTE PTR [DI],Nulo
    INC SI
    INC DI
    LOOP LoopLimpio
    ReadStr SearchLong,SearchActL,Searched        ;leer cadena a buscar
    CMP  SearchActL,00                            ;ver si es cadena vac¡a
    JNE  HayCar
      CALL LimpiaBarra                            ;limpiar barra
      CALL Actualiza                              ;actualizar
      RET                                         ;retorno
  HayCar:
    XOR  CX,CX                            ;limpiar CX
    MOV  Searcher,CX                      ;inicializar apuntador de b£squeda
    MOV  BX,BasTxtOffset                  ;con el offset base del buffer
    MOV  Searcher,BX                      ;del texto
    DEC  Searcher                         ;menos uno
  MueveCad:                               ;trans. cadena de texto a CompString
    XOR CX,CX                             ;limpiar CX
    MOV CL,RecLen                         ;y ponerlo a la long. de la cadena
    LEA DI,CompString                     ;en DI la dir. de CompString
  OtroLimpio:                             ;limpiar ‚ste buffer
        MOV  BYTE PTR [DI],Nulo           ;con caracteres nulos
        INC  DI
        LOOP OtroLimpio
     INC  Searcher                        ;incrementar el ap. de b£squeda
     MOV  BX,UltChrOffset                 ;ver si no se sale del texto
     CMP  Searcher,BX
     JAE  FinBuscar                       ;si se sale...
          MOV  SI,Searcher                ;si no... en SI el ap. de busq.
          LEA  DI,CompString              ;en DI la dir. de CompString
          XOR  CX,CX                      ;limpiar CX
          MOV  CL,SearchActL              ;en CX poner 80
          REP  MOVSB                      ;y mover 80 bytes del texto
          LEA  SI,Searched                ;en DI el ap. de b£squeda
          LEA  DI,CompString              ;en DI la dir. de CompString
          MOV  AH,00                      ;limpiar todas las banderas
          SAHF                            ;que intervienen
          MOV  CL,SearchActL       ;se compararan tantos bytes como los leidos
          REPE CMPSB                      ;buscar cadena
          JE LoEncontre                   ;si se encuentra...
             JMP MueveCad                 ;si no, otra vez...
          JMP FinBuscar                   ;no la encontr‚!, fin de la op.
  LoEncontre:                             ;se encontr¢ la cadena
      LEA  DX,CadEncontrada               ;avisarlo al usuario
      CALL Mensajes
      ReadKey AL                          ;presione una tecla, por favor
      CALL LimpiaBarra                    ;limpiar barra
      CALL Actualiza                      ;actualizar todo
      RET                                 ;retorno
  FinBuscar:                              ;fin de la b£squeda
      LEA  DX,CadNoEncontrada             ;avisar que no se encontr¢ la cad.
      CALL Mensajes
      ReadKey AL                          ;presione una tecla...
      CALL LimpiaBarra                    ;limpiar barra
      CALL Actualiza                      ;actualizar
      RET                                 ;retornar
Busca_Cadena ENDP                         ;fin del proc.

Fin_De_Texto PROC NEAR                    ;
      WriteChar 07h
      MOV  PagActiva,00
      MOV  PoscEnTexto,0000
      MOV  FinDelTexto,00
      CALL ClsNotePad
      CALL NoCursor
      CALL Despliega_Pagina_Abajo
      MOV  PtrFijado,00
      MOV  NumTopes,00
      MOV  NoMasLineas,00
      MOV  AX,BasTxtOffset
      MOV  CursorPtr,AX
      MOV  IniLineaOffs,AX
      MOV  Xcurs,01
      MOV  Ycurs,03
      CALL Actualiza
      RET
Fin_De_Texto ENDP

Pagina_Abajo PROC NEAR
      MOV  PtrFijado,00
      MOV  AX,PoscEnTexto
      MOV  CursorPtr,AX
      MOV  IniPagOffset,AX
      MOV  IniLineaOffs,AX
      ADD  PagActiva,01
      CALL ClsNotePad
      CALL NoCursor
      CALL Despliega_Pagina_Abajo
      MOV  Ycurs,03
      MOV  Xcurs,01
      CALL Actualiza
      RET
Pagina_Abajo ENDP

Cursor_Home PROC NEAR
      MOV  Xcurs,01
      MOV  AX,IniLineaOffs
      MOV  CursorPtr,AX
      MOV  PtrFijado,00
      CALL Actualiza
      RET
Cursor_Home ENDP

Cursor_IniPag PROC NEAR
       MOV  Xcurs,01
       MOV  Ycurs,03
       MOV  DX,IniPagOffset
       MOV  CursorPtr,DX
       MOV  IniLineaOffs,DX
       MOV  PtrFijado,00
       MOV  NoMasLineas,00
       CALL Actualiza
       RET
Cursor_IniPag ENDP

Cursor_Derecha PROC NEAR
      MOV BX,UltChrOffset
      CMP CursorPtr,BX
      JB  PuedesSeguir
          WriteChar 07
          RET
 PuedesSeguir:
      INC Xcurs
      CMP Xcurs,79
      JBE AvDerecha
          WriteChar 07
          DEC Xcurs
          RET
   AvDerecha:
      MOV BX,CursorPtr
      CMP BYTE PTR [BX+1],CR
      JE  NoAvanzaPtrDer
          CMP BYTE PTR [BX],CR
          JE  NoAvanzaPtrDer2
              CMP PtrFijado,01
              JE  NoAvanzaPtrDer
                  INC CursorPtr
                  CALL   Actualiza
                  RET
   NoAvanzaPtrDer:
      DEC Xcurs
      WriteChar 07
      MOV PtrFijado,01
      RET
   NoAvanzaPtrDer2:
      DEC Xcurs
      DEC CursorPtr
      MOV PtrFijado,01
      WriteChar 07
      RET
Cursor_Derecha ENDP

Cursor_Izquierda PROC NEAR
      MOV PtrFijado,00
      DEC Xcurs
      CMP Xcurs,01
      JAE AvIzquierda
          WriteChar 07
          INC Xcurs
          RET
   AvIzquierda:
      MOV AX,CursorPtr
      CMP AX,IniLineaOffs
      JE  NoAvanzaPtrIzq
          DEC CursorPtr
   NoAvanzaPtrIzq:
      CALL   Actualiza
      RET
Cursor_Izquierda ENDP

Cursor_Arriba PROC NEAR
      MOV PtrFijado,00
      MOV AX,IniLineaOffs
      MOV CursorPtr,AX
      MOV NoMasLineas,00
      DEC Ycurs
      CMP Ycurs,03
      JAE AvArriba
          WriteChar 07
          INC Ycurs
          MOV NumTopes,00
          MOV AX,IniPagOffset
          MOV CursorPtr,AX
          MOV IniLineaOffs,AX
          RET
  AvArriba:
      MOV  Xcurs,01
      CALL BuscaAntLinea
      CALL Actualiza
      MOV  AX,CursorPtr
      MOV  IniLineaOffs,AX
      RET
Cursor_Arriba ENDP

Cursor_Abajo PROC NEAR
      MOV PtrFijado,00
      MOV AX,IniLineaOffs
      MOV CursorPtr,AX
      INC Ycurs
      CMP Ycurs,22
      JBE AvAbajo
          WriteChar 07
          DEC Ycurs
          RET
   AvAbajo:
      MOV  Xcurs,01
      CALL BuscaSigLinea
      CMP  NoMasLineas,01
      JNE  AvAbajo1
           DEC  Ycurs
           CALL Actualiza
           MOV  AX,CursorPtr
           MOV  IniLineaOffs,AX
           RET
   AvAbajo1:
      CALL Actualiza
      MOV  AX,CursorPtr
      MOV  IniLineaOffs,AX
      RET
Cursor_Abajo ENDP

BuscaAntLinea PROC NEAR
      STD
      MOV   DI,CursorPtr
      MOV   AL,LF
      MOV   CX,CursorPtr
      SUB   CX,BasTxtOffset
      REPNE SCASB
      REPNE SCASB
      MOV   CursorPtr,DI
      CMP   DI,BasTxtOffset
      JNE   AunHayAntes
         CMP   BYTE PTR [DI],CR
         JE    NoEsLaUltima
               RET
      NoEsLaUltima:
         CMP NumTopes,01
         JNE PrimVez
             MOV NumTopes,00
             RET
         PrimVez:
             CMP NumTopes,02
             JE  Suma
                 MOV NumTopes,01
                 ADD CursorPtr,0002
                 RET
             Suma:
                MOV NumTopes,02
                ADD CursorPtr,0002
                RET
   AunHayAntes:
      ADD CursorPtr,0002
      CLD
      RET
BuscaAntLinea ENDP

BuscaSigLinea PROC NEAR
      CMP NumTopes,01
      JNE Resta1
          MOV NumTopes,00
          JMP Normal
      Resta1:
         CMP NumTopes,02
         JNE Normal
             MOV NumTopes,01
             JMP Normal
   Normal:
      CLD
      MOV   DI,CursorPtr
      MOV   AL,CR
      MOV   CX,MaxTxtOffset
      SUB   CX,CursorPtr
      REPNE SCASB
      CMP   DI,UltChrOffset
      JB    AunHayOtraLinea
            MOV NoMasLineas,01
            WriteChar 07
            RET
   AunHayOtraLinea:
      MOV   CursorPtr,DI
      INC   CursorPtr
      RET
BuscaSigLinea ENDP

CargaTexto_A_Memoria_Y_Respalda PROC NEAR
      MOV  ArchActivo,01
      CALL Reset
      MOV  ArchActivo,02
      CALL ReWrite
   Lectura:
      MOV  ArchActivo,01
      CALL ReadFile
      CMP  Eof,01
      JE   FinLeer
           XOR  AX,AX
           MOV  AL,CodError
           MOV  ErrorAux,AL
           MOV  ArchActivo,02
           CALL Append
           MOV  ArchActivo,01
           CALL Transfer1
           ADD  PoscCima,RecLen
           CMP  PoscCima,TextSize
           JAE  FinLeer
           XOR  AX,AX
           MOV  AL,ErrorAux
           MOV  BYTE PTR CodError,AL
           CMP  CodError,0
           JNZ  FinLeer
                JMP Lectura
   FinLeer:
      MOV  ArchActivo,01
      CALL Close
      MOV  ArchActivo,02
      CALL Close
      RET
CargaTexto_A_Memoria_Y_Respalda ENDP

Despliega_Pagina_Abajo PROC NEAR
       LimpiaRegs
       MOV Ycurs,03
       GotoXY 01,03
       MOV CL,NumLine-4
    OtraLinea:
       PUSH  CX
       LimpiaBuffer RecLen,BufTransfer
       CALL  Transfer2
       GotoXY 01,YCurs
       Write BufTransfer
       INC Ycurs
       CMP FinDelTexto,01
       JE  FinDespliegue
       POP   CX
       LOOP  OtraLinea
       RET
    FinDespliegue:
       POP   CX
       RET
Despliega_Pagina_Abajo ENDP

Salvar_Archivo PROC NEAR
       CALL Borrador
       LEA  DX,Salvando
       CALL Mensajes
       LEA  SI,Texto
       MOV  TransPtr,SI
       MOV  ArchActivo,01
       CALL ReWrite
       CMP  CodError,01
       JE   ErrorDeSalvacion
       MOV  ArchActivo,01
       CALL Close
       MOV  ArchActivo,01
       CALL Reset
       CMP  CodError,01
       JE   ErrorDeSalvacion
       MOV  FCBsqrc1,00
    SalvaTexto:
       CMP SalvadoTotal,01
       JE  YaAcabeDeSalvar
           CALL Transfer3
           MOV  ArchActivo,01
           CMP  SalvadoTotal,02
           JE   YaAcabeDeSalvar
                CALL Append
                JMP  SalvaTexto
    YaAcabeDeSalvar:
       MOV  SalvadoTotal,00
       MOV  ArchActivo,01
       CALL Close
       MOV  AX,0000
       MOV  TransPtr,AX
       CALL LimpiaBarra
       MOV  Modificado,00
       CALL Actualiza
       RET
    ErrorDeSalvacion:
       CALL Borrador
       LEA  DX,ErrorSalvando
       CALL Mensajes
       CALL LimpiaBarra
       CALL Actualiza
Salvar_Archivo ENDP

Imprime_texto PROC NEAR
      LimpiaRegs
      CMP ArchVacio,01
      JE  FinDeImpresion1
          JMP NoArchVac
      FinDeImpresion1:
               CALL LimpiaBarra
               CALL Actualiza
               RET
    NoArchVac:
          CALL Borrador
          CALL NoCursor
          PortStatus AH
          CMP  AH,28h
          JNE  Correcto1
          ErrorImp:
               CALL Borrador
               LEA  DX,ErrorImprimiendo1
               CALL Mensajes
               ReadKey AL
               CALL LimpiaBarra
               CALL Actualiza
               RET
     Correcto1:
          CMP AH,0CBh
          JE  ErrorImp
          InicPrinter
          LEA  DX,Imprimiendo
          CALL Mensajes
          MOV  DI,BasTxtOffset
      ImpOtroCar:
          MOV BX,UltChrOffset
          CMP DI,BX
          JAE FinDeImpresion
              CMP BYTE PTR [DI],0D
              JNE CarNormal
                  INC DI
                  MOV DL,BYTE PTR [DI]
                  BIOSPrintChar DL
                  PortStatus AH
                  CMP AH,0C8h
                  JE  ErrorImp
                  CMP AH,28h
                  JE  ErrorImp
                      INC DI
                      JMP ImpOtroCar
              CarNormal:
                  MOV DL,BYTE PTR [DI]
                  BIOSPrintChar DL
                  INC DI
                  JMP ImpOtroCar
      FinDeImpresion:
         MOV  DI,0000
         CALL LimpiaBarra
         CALL Actualiza
         RET
Imprime_Texto ENDP

Transfer1 PROC NEAR
       LimpiaRegs
       CLD
       LEA SI,DTALine
       LEA DI,Texto
       ADD DI,PoscCima
       MOV CX,RecLen
       REP MOVSB
       XOR AX,AX
       CMP ErrorAux,00
       JE  FinTransfer1
           MOV AL,'$'
           STOSB
    FinTransfer1:
       RET
Transfer1 ENDP

Transfer2 PROC NEAR
      LimpiaRegs
      CLD
      CMP PagActiva,00
      JNE NoPrimPag
          LEA SI,Texto
          MOV PoscEnTexto,SI
          MOV IniPagOffset,SI
          MOV CursorPtr,SI
          MOV IniLineaOffs,SI
          ADD PagActiva,1
   NoPrimPag:
      MOV SI,PoscEnTexto
      LEA DI,BufTransfer
      CMP SI,UltChrOffset
      JAE FinTexto
      MOV CX,RecLen
   TransLoop2:
      CMP BYTE PTR [SI],CR
      JE FinTransLinea1
         CMP BYTE PTR [SI],LF
         JE FinTransLinea2
         MOVSB
            CMP SI,UltChrOffset
            JAE  FinTexto
      LOOP TransLoop2
      MOV  PoscEnTexto,SI
      RET
   FinTransLinea1:
      MOVSB
      CMP SI,UltChrOffset
      JAE  FinTexto
      CMP BYTE PTR [SI],LF
      JNE FinTotal
       FinTransLinea2:
          MOVSB
          CMP SI,UltChrOffset
          JAE FinTexto
              JMP FinTotal
                FinTexto:
                   MOV FinDelTexto,01
                   JMP FinTotal
   FinTotal:
      MOV PoscEnTexto,SI
      RET
Transfer2 ENDP

Transfer3 PROC NEAR
       CLD
       LimpiaBuffer RecLen,DTALine
       MOV BX,UltChrOffset
       INC BX
       MOV SI,TransPtr
       CMP SI,BX
       JB  PasoASalva
           MOV SalvadoTotal,02
           RET
   PasoASalva:
       LEA DI,DTALine
       MOV CL,RecLen
   TransCar:
       MOV BX,UltChrOffset
       INC BX
       CMP SI,BX
       JAE FinTotalDeTrans
           MOVSB
           LOOP TransCar
           MOV  TransPtr,SI
           RET
   FinTotalDeTrans:
       MOV SalvadoTotal,01
       RET
Transfer3 ENDP

Transfer4 PROC NEAR            ;procedimiento para la transfer. de la cadena
    LimpiaRegs                       ;limpiar registros
    LEA  DI,Searched             ;en DI la dir. de la cadena
       MOV  CX,RecLen
       MOV  AL,Nulo
       REP  STOSB
    MOV  CX,0000                 ;inicializar contador de caracteres a 0
       MOV  SI,IniLineaOffs
    LEA  DI,Searched             ;cargar en DI direccion de la cadena
   Arriba:
    LODSB                        ;cargar a AL caracter del texto
    CMP SI,UltChrOffset          ;ver si ya se acab¢ el texto
    JBE VasBien                  ;si va bien (a£n hay texto)...
      JMP FinLee          ;si no, el texto se acab¢.
  VasBien:
       CMP AL,0Dh              ;termino la cadena?
       JZ  FinLee              ;si termino, ir al final
           INC CX              ;si no, fue un caracter mas...
           STOSB               ;guardarlo
       JMP Arriba              ;seguir leyendo caracteres
     FinLee:                    ;fin de la lectura
        RET                    ;retorno
Transfer4 ENDP               ;fin del procedimiento

Reinicia_Variables PROC NEAR
       LimpiaRegs
       CLD
       MOV CX,TextSize
       MOV AL,Espacio
       LEA DI,Texto
       REP STOSB
       LimpiaBuffer RecLen,DTAline
       LimpiaBuffer 14,FileName
       LimpiaBuffer RecLen,Searched
       LimpiaBuffer RecLen,CompString
       LimpiaBuffer RecLen,BufTransfer
       MOV PoscCima    ,0000
       MOV BasTxtOffset,0000
       MOV MaxTxtOffset,0000
       MOV UltChrOffset,0000
       MOV CursorPtr   ,0000
       MOV IniPagOffset,0000
       MOV IniLineaOffs,0000
       MOV PoscEnTexto ,0000
       MOV Searcher    ,0000
       MOV TransPtr    ,0000
       MOV PagActiva   ,00
       MOV TeclaActual ,00
       MOV FinDelTexto ,00
       MOV NoMasLineas ,00
       MOV NumTopes    ,00
       MOV PtrFijado   ,00
       MOV ArchVacio   ,00
       MOV SalvadoTotal,00
       MOV Modificado  ,00
       MOV Eof         ,00
       MOV CodError    ,00
       MOV ErrorAux    ,00
       MOV ArchActivo  ,00
       MOV Xcurs       ,01
       MOV Ycurs       ,03
       LimpiaRegs
       RET
Reinicia_Variables ENDP

;----------------------* PROCEDIMIENTOS DE I/O A DISCO *----------------------

Parser PROC NEAR
    Parsing:
       LEA DX,PideNom
       CALL Mensajes
       WriteCAttr 33,24,20h,00,13,00
       WriteCAttr 33,24,00h,15,13,00
       CALL CursorNormal
       LimpiaBuffer FileLong,FileName
       ReadStr FileLong,ActFNLen,FileName
       CALL NoCursor
       CALL LimpiaBarra
       MOV AH,29h
       MOV AL,0FFh
       LEA SI,FileName
       LEA DI,FCBfrec1
       INT 21h
       CMP AL,0FFh
       JNE NoErrorParsing
           LEA   DX,InvalidFName
           CALL  Mensajes
           Pause Press
           MOV   CodError,01
           CALL  LimpiaBarra
           JMP   Parsing
   NoErrorParsing:
      CMP AL,01
      JNE TotalmenteCorrecto
          LEA  DX,NomConComo
          CALL Mensajes
          CALL LimpiaBarra
          JMP  Parsing
      TotalmenteCorrecto:
         LEA  DI,FileName
         MOV  AL,00h
         MOV  CX,0014
         REP  STOSB
         LEA  DI,FileName
         LEA  SI,FCBdriv1
         CMP  BYTE PTR [SI],00
         JE   DefaultDrv
              CMP BYTE PTR [SI],01
              JNE DriveB
                  MOV AL,'A'
                  JMP GuardaDrive
              DriveB:
                  CMP BYTE PTR [SI],02
                  JNE DriveC
                      MOV AL,'B'
                      JMP GuardaDrive
                  DriveC:
                      CMP BYTE PTR [SI],03
                      JNE DriveD
                          MOV AL,'C'
                          JMP GuardaDrive
                      DriveD:
                          CMP BYTE PTR [SI],04
                          JNE DefaultDrv
                              MOV AL,'D'
                              JMP GuardaDrive
    GuardaDrive:
         STOSB
         MOV  AL,':'
         STOSB
    DefaultDrv:
         LEA  SI,FCBFnom1
         MOV  CX,0008
         REP  MOVSB
         MOV  AL,'.'
         MOV  CX,0001
         REP  STOSB
         LEA  SI,FCBFext1
         MOV  CX,0003
         REP  MOVSB
         CALL FSearch
         CMP  ErrorAux,00
         JE   ArchivoExistente
              LEA DX,ArchNoExiste
              CALL Mensajes
              MOV  ArchActivo,01
              CALL ReWrite
              MOV  ArchActivo,01
              CALL Close
              MOV  ArchVacio,01
              CALL LimpiaBarra
              RET
         ArchivoExistente:
            LEA  DX,Exito
            CALL Mensajes
            MOV  ArchActivo,01
            CALL Reset
            MOV  ArchActivo,01
            CALL Close
            CALL LimpiaBarra
            MOV  AL,FCBdriv1
            MOV  FCBdriv2,AL
            LEA  SI,FCBfnom1
            LEA  DI,FCBfnom2
            MOV  CX,8
            REP  MOVSB
            LEA  BX,FCBflsz1
            MOV  AX,WORD PTR [BX]
            CMP  AX,0000
            JE   ArchivoVacio
                 RET
            ArchivoVacio:
               MOV ArchVacio,01
               RET
Parser ENDP

FSearch PROC NEAR                 ;‚ste proc. busca un archivo en el directorio
     MOV AH,4Eh                   ;funci¢n de b£squeda de archivo por DOS
     MOV CL,00                    ;atributo de archivo normal
     LEA DX,FileName              ;direcci¢n del nombre del archivo
     INT 21h                      ;int. 21h del DOS
     MOV ErrorAux,AL              ;error di I/O
     RET                          ;retorno
FSearch ENDP                      ;fin del proc.

ReWrite PROC NEAR                 ;este procedimiento abre un archivo de disco
     LimpiaRegs                    ;si existe lo sobreescribe
     MOV BL,ArchActivo             ;en BL el numero de archivo activo: 1 o 2
     CMP BL,01                     ;ver cual archivo esta activo
     JNZ Archivo2                  ;si es el 2...
         LEA DX,FCBfrec1            ;si no, en DX la dir. del FCB del arch. 1
         JMP Abre                   ;saltar
    Archivo2:                       ;si fue el 2
     LEA DX,FCBfrec2               ;en DX la dir. del FCB del arch. 2
   Abre:                           ;abrir archivo
     MOV AH,16h                    ;funcion 16h de apertura
     INT 21h                       ;int. 21h
     MOV CodError,AL
     CMP AL,00                     ;hubo error? AH=00h o AH=FFh
     JNZ Error1                    ;si hubo, decirlo...
        CMP BL,01                  ;si no...
        JNZ DTAfijado
           MOV FCBrcsz1,RecLen     ;fijar long. del registro del arch. 1
           JMP Fija
     DTAfijado:
        MOV FCBrcsz2,RecLen        ;fijar long. del registro del archivo 2
     Fija:
        LEA DX,DTALine             ;fijar direccion de la DTA
        MOV AH,1Ah                 ;funcion 1Ah de fijacion de DTA
        INT 21h                    ;int. 21h
        RET                        ;retorno
     Error1:                       ;hubo error
        LEA DX,ErrorArch1
        CALL Mensajes              ;mensaje al usuario
        RET                        ;retorno
ReWrite ENDP                      ;fin del proc.

ReadFile PROC NEAR                ;este procedimiento abre un archivo de disco
      LimpiaRegs                    ;para leer
      MOV BL,ArchActivo             ;en BL el numero de archivo activo: 1 o 2
      CMP BL,01                     ;ver cual archivo esta activo
      JNZ ArchivoLeer2              ;si es el 2...
         LEA DX,FCBfrec1            ;si no, en DX la dir. del FCB del arch. 1
         JMP AbreLeer               ;saltar
    ArchivoLeer2:                   ;si fue el 2
      LEA DX,FCBfrec2               ;en DX la dir. del FCB del arch. 2
    AbreLeer:                       ;abrir archivo
      MOV AH,14h                    ;funcion 14h de lectura secuencial
      INT 21h                       ;int. 21h
      MOV CodError,AL               ;salvar codigo de error
      CMP AL,00
      JNZ Fin
      RET                           ;retorno
    Fin:
      CMP CodError,01               ;ver si es DTAline vacio...
      JE  Salte                     ;si lo es salir
          CLD                       ;si no AL=3, lectura parcial
          XOR CX,CX                 ;limpiar CX
          MOV CL,80                         ;en AL, Ctrl-Z
          MOV AL,1Ah                        ;en DI el offset del DTA
          LEA DI,DTALine                    ;buscar marca de fin de archivo
          BuscaCtrl_Z:
                CMP AL,BYTE PTR [DI]
                JE  LlenaBlancos            ;si se encuentra,llenar...
                INC DI                      ;si no, seguir
          LOOP BuscaCtrl_Z
          DEC DI
          LlenaBlancos:
                MOV BYTE PTR [DI],Espacio           ;llenar con espacios
                INC DI                              ;el final del DTAline
                LOOP LlenaBlancos
                RET                ;retorno
   Salte:                                  ;si el error fue AL=01
      MOV CodError,01                      ;codigo de error correspondiente
      MOV ErrorAux,01
      MOV Eof,01
      RET                          ;retorno
ReadFile ENDP                     ;fin del proc.

Append PROC NEAR                  ;este procedimiento agrega datos aun archivo
     MOV BL,ArchActivo             ;en BL el numero de archivo activo: 1 o 2
     CMP BL,01                     ;ver cual archivo esta activo
     JNZ ArchivoAmpliar1           ;si es el 2...
         LEA DX,FCBfrec1            ;si no, en DX la dir. del FCB del arch. 1
         JMP EscriArch              ;saltar
   ArchivoAmpliar1:                ;si fue el 2
     LEA DX,FCBfrec2               ;en DX la dir. del FCB del arch. 2
   EscriArch:                      ;escribir secuencialmente
     MOV AH,15h                    ;funcion 15h de escritura secuencial
     INT 21h                       ;int. 21h
     MOV CodError,AL               ;salvar codigo de error
     CMP AL,00                     ;hubo error? AH=00h o AH=FFh
     JNZ Error3                    ;si hubo, decirlo...
     RET                           ;retorno
   Error3:                         ;hubo error
     LEA DX,ErrorArch1
     CALL Mensajes                 ;mensaje al usuario
     RET                           ;retorno
Append ENDP                       ;fin del proc.

Reset PROC NEAR                   ;este procedimiento abre un archivo de disco
     LimpiaRegs                    ;para leer
     MOV BL,ArchActivo             ;en BL el numero de archivo activo: 1 o 2
     CMP BL,01                     ;ver cual archivo esta activo
     JNZ Archivo21                 ;si es el 2...
         LEA DX,FCBfrec1            ;si no, en DX la dir. del FCB del arch. 1
         JMP AbreLeer2              ;saltar
   Archivo21:                      ;si fue el 2
      LEA DX,FCBfrec2               ;en DX la dir. del FCB del arch. 2
   AbreLeer2:                      ;abrir archivo
     MOV AH,0Fh                    ;funcion 0Fh de apertura
     INT 21h                       ;int. 21h
     MOV CodError,AL
     CMP AL,00                     ;hubo error? AH=00h o AH=FFh
     JNZ Error4                    ;si hubo, decirlo...
        CMP BL,01                  ;si no...
        JNZ DTAfijado2
           MOV FCBrcsz1,RecLen     ;fijar long. del registro del arch. 1
           MOV FCBsqrc1,00         ;colocar al primer registro para leer
           JMP Fija2
     DTAfijado2:
        MOV FCBrcsz2,RecLen        ;fijar long. del registro del archivo 2
        MOV FCBsqrc2,00            ;colocar al primer registro para leer
     Fija2:
        LEA DX,DTALine             ;fijar direccion de la DTA
        MOV AH,1Ah                 ;funcion 1Ah de fijacion de DTA
        INT 21h                    ;int. 21h
        RET                        ;retorno
     Error4:                       ;hubo error
        LEA  DX,ErrorArch1         ;mensaje al usuario
        CALL Mensajes
        RET                        ;retorno
Reset ENDP                      ;fin del proc.

Close PROC NEAR                   ;este procedimiento cierra un archivo
     LimpiaRegs                    ;ya existente
     MOV BL,ArchActivo             ;en BL el numero de archivo activo: 1 o 2
     CMP BL,01                     ;ver cual archivo esta activo
     JNZ ArchivoCerrar1            ;si es el 2...
         LEA DX,FCBfrec1            ;si no, en DX la dir. del FCB del arch. 1
         JMP CierraArch             ;saltar
   ArchivoCerrar1:                 ;si fue el 2
     LEA DX,FCBfrec2               ;en DX la dir. del FCB del arch. 2
   CierraArch:                     ;escribir secuencialmente
     MOV AH,10h                    ;funcion 10h de cierre de archivo
     INT 21h                       ;int. 21h
     MOV CodError,AL               ;salvar codigo de error
     CMP AL,00                     ;hubo error? AH=00h o AH=FFh
     JNZ Error5                    ;si hubo, decirlo...
     RET                           ;retorno
   Error5:                         ;hubo error
     LEA  DX,ErrorArch1            ;mensaje al usuario
     CALL Mensajes
     RET                           ;retorno
Close ENDP                        ;fin del proc.

Code ENDS                ;fin del segmento de codigo
END Prog                 ;fin del programa
