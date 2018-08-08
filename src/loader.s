* = $0000

    !source "config.s"

EASYFLASH_BANK    = $DE00
EASYFLASH_CONTROL = $DE02
EASYFLASH_LED     = $80
EASYFLASH_16K     = $07
EASYFLASH_KILL    = $04

; =============================================================================
; 00:0:0000 (LOROM, bank 0)
bankStart_00_0:
    ; This code resides on LOROM, it becomes visible at $8000

    !pseudopc $8000 {

        ; === the main application entry point ===

        ; copy the loader to RAM - we don't run it here
        ; since the banking would make it invisible

        ldx #$00
-       lda crtLoader,x
        sta loader,x
        inx
        cpx #(crtLoaderEnd - crtLoader)
        bne -

        !source "main.s"

crtLoader:
        !pseudopc loader {

; =============================================================================
;
; Main loader
;
; =============================================================================

            ; Switch to bank 0 to access the file table and ROM helpers
            lda #0
            sta EASYFLASH_BANK

            ; Backup ZP locations to $df00
            ;jsr backupZP

            ; Copy file details to ZP
            jsr setPointers

            ; Switch to the bank where the file starts
            lda bank
            sta EASYFLASH_BANK

            ldy #$00

            ; PRG start address
            lda (srcptr),y
            sta dstptr
            iny
            lda (srcptr),y
            sta dstptr+1

            ; Displace source pointer by 2 bytes for data
            lda srcptr
            clc
            adc #$02
            sta srcptr
            bcc +
            inc srcptr+1

+
            dey

copyRAM:
            lda (srcptr),y

            !if LOAD_UNDER_IO > 0 {
                php
                sei
                ldx $01
                stx rest01
                ldx #$34
                stx $01
            }

            sta (dstptr),y

            !if LOAD_UNDER_IO > 0 {
rest01=*+1
                ldx #$37
                stx $01
                pla
                and #$04
                bne noCLI
                cli
noCLI:
            }

            inc srcptr
            bne +
            inc srcptr+1

+
            inc dstptr
            bne +
            inc dstptr+1

            !if BORDER_FLASHING > 0 {
                inc $d020
                dec $d020
            }

+
            lda srcptr ; End of the 16k ROM?
            bne nextLoc
            lda srcptr+1
            cmp #$c0
            bne nextLoc

            inc bank   ; Next bank
            lda bank
            sta EASYFLASH_BANK
            lda #$00   ; Restart from $8000
            sta srcptr
            lda #$80
            sta srcptr+1

nextLoc:
            lda srcptr
            cmp srcptrn
            bne copyRAM
            lda srcptr+1
            cmp srcptrn+1
            bne copyRAM
            lda bank
            cmp banknxt
            bne copyRAM

            ; Restore ZP locations
            ;jsr restoreZP

            rts

fnum:       !byte 0

        }
crtLoaderEnd:

        ; Insert a few helper functions here
        !align $ffff, $9000, $ff

; =============================================================================
;
; Utility functions for main loader
;
; =============================================================================

backupZP:
        ; Backup ZP
        ldx #7
-       lda zpbase,x
        sta $df00,x
        dex
        bpl -
        rts

restoreZP:
        ; Restore ZP
        ldx #7
-       lda $df00,x
        sta zpbase,x
        dex
        bpl -
        rts

setPointers:
        ; Read file details from file table
        ldy fnum
        tya
        asl
        asl
        tay
        lda fileTable,y    ; Start bank
        sta bank

        iny
        lda fileTable,y    ; Start location in bank (displaced from $8000)
        sta srcptr
        iny
        lda fileTable,y
        sta srcptr+1

        iny
        iny
        lda fileTable,y    ; Start bank of next file
        sta banknxt

        iny
        lda fileTable,y    ; Start location of next file
        sta srcptrn
        iny
        lda fileTable,y
        sta srcptrn+1
        rts

; =============================================================================
;
; File table included here
;
; =============================================================================

        ; Insert file table here
        !align $ffff, $9400, $ff

fileTable:
        !source "iffltable.s"

        ; fill the whole bank with value $ff
        !align $ffff, $a000, $ff

    }

; =============================================================================
; 00:1:0000 (HIROM, bank 0)
bankStart_00_1:
    ; This code runs in Ultimax mode after reset, so this memory becomes
    ; visible at $E000..$FFFF first and must contain a reset vector

    !pseudopc $e000 {
coldStart:
        ; === the reset vector points here ===
        sei
        ldx #$ff
        txs
        cld

        ; enable VIC (e.g. RAM refresh)
        lda #8
        sta $d016

        ; write to RAM to make sure it starts up correctly (=> RAM datasheets)
startWait:
        sta $0100, x
        dex
        bne startWait

        ; copy the final start-up code to RAM (bottom of CPU stack)
        ldx #(startUpEnd - startUpCode)
l1:
        lda startUpCode, x
        sta $0100, x
        dex
        bpl l1
        jmp $0100

startUpCode:
        !pseudopc $0100 {
            ; === this code is copied to the stack area, does some inits ===
            ; === scans the keyboard and kills the cartridge or          ===
            ; === starts the main application                            ===
            lda #EASYFLASH_16K + EASYFLASH_LED
            sta EASYFLASH_CONTROL

            ; Check if one of the magic kill keys is pressed
            ; This should be done in the same way on any EasyFlash cartridge!

            ; Prepare the CIA to scan the keyboard
            lda #$7f
            sta $dc00   ; pull down row 7 (DPA)

            ldx #$ff
            stx $dc02   ; DDRA $ff = output (X is still $ff from copy loop)
            inx
            stx $dc03   ; DDRB $00 = input

            ; Read the keys pressed on this row
            lda $dc01   ; read coloumns (DPB)

            ; Restore CIA registers to the state after (hard) reset
            stx $dc02   ; DDRA input again
            stx $dc00   ; Now row pulled down

            ; Check if one of the magic kill keys was pressed
            and #$e0    ; only leave "Run/Stop", "Q" and "C="
            cmp #$e0
            bne kill    ; branch if one of these keys is pressed

            ; same init stuff the kernel calls after reset
            ldx #0
            stx $d016
            jsr $ff84   ; Initialise I/O

            ; These may not be needed - depending on what you'll do
            jsr $ff87   ; Initialise System Constants
            jsr $ff8a   ; Restore Kernal Vectors
            jsr $ff81   ; Initialize screen editor

            ; start the application code
            jmp $8000

kill:
            lda #EASYFLASH_KILL
            sta EASYFLASH_CONTROL
            jmp ($fffc) ; reset
        }
startUpEnd:

        ; fill it up to $e300 to put the default name
        !align $ffff, $e300 + $1800, $ff

        ; Insert a default name for the menu entry
        !convtab "asc2ulpet.ct"
        !text "EF-Name:Loader example"
        !align $ffff, $e000 + $1b18, $00

        ; fill it up to $FFFA to put the vectors there
        !align $ffff, $fffa, $ff

        !word reti        ; NMI
        !word coldStart   ; RESET

        ; we don't need the IRQ vector and can put RTI here to save space :)
reti:
        rti
        !byte 0xff
    }

; =============================================================================
; 01:0:0000 (LOROM, bank 1)
bankStart_01_0:
