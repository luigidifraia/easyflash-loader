        ; copy the kick-off code to RAM - we don't run it here
        ; since the banking would make it invisible and it uses
        ; self-modifying code in the trainer menu

        ldx #$00
-       lda crtKickOff,x
        sta kickoff,x
        inx
        bne -

-       lda crtKickOff+$0100,x
        sta kickoff+$0100,x
        inx
        cpx #(crtKickOffEnd - crtKickOff - $0100)
        bne -

        jmp kickoff

crtKickOff:
        !pseudopc kickoff {

; =============================================================================
;
; Load and relocate files, play tune, and show picture
;
; =============================================================================

            sei

            lda #$00       ; Disable VIC-II interrupts
            sta $d01a
            asl $d019      ; Acknowledge pending requests

            sta $d020
            sta $d021

            lda #$7f
            sta $dc0d      ; Disable CIA #1 interrupts
            sta $dd0d      ; Disable CIA #2 interrupts
            lda $dc0d      ; Acknowledge pending requests
            lda $dd0d

            ldy #$00       ; Load tune
            sty fnum
            jsr loader

            !if LOAD_UNDER_IO = 0 {
                ; Relocate 0x1a pages from $2200 to $a200
                ldx #<$2200
                ldy #>$2200
                stx srcptr
                sty srcptr+1

                ldx #<$a200
                ldy #>$a200
                stx dstptr
                sty dstptr+1

                ldx #$1a
                jsr relocator
            }

            sei

            lda #$35       ; Disable both ROMs
            sta $01

            lda #$00       ; Init tune
            jsr $bbb8

            lda #$37       ; Enable both ROMs
            sta $01

            ; Install Non-Maskable Interrupt handlers
            lda #<nmih
            sta $fffa
            sta $0318
            lda #>nmih
            sta $fffb
            sta $0319

            ; Install Maskable Interrupt handlers
            lda #<tuneplayer_ram
            sta $fffe
            lda #>tuneplayer_ram
            sta $ffff
            lda #<tuneplayer_rom
            sta $0314
            lda #>tuneplayer_rom
            sta $0315

            lda #$10       ; Set raster line for interrupt
            sta $d012
            lda #$0b       ; Also blank the screen
            sta $d011

            lda #$01       ; Enable raster line interrupt
            sta $d01a
            asl $d019      ; Clear pending requests

            cli            ; Allow tune playback

            inc fnum       ; Load picture
            jsr loader

            !if LOAD_UNDER_IO = 0 {
                ; Relocate 0x28 pages from $2c00 to $bc00
                ldx #<$2c00
                ldy #>$2c00
                stx srcptr
                sty srcptr+1

                ldx #<$bc00
                ldy #>$bc00
                stx dstptr
                sty dstptr+1

                ldx #$28
                jsr relocator
            }

            lda #$35       ; Disable both ROMs
            sta $01

            lda #EASYFLASH_KILL
            sta EASYFLASH_CONTROL

            lda $dd00
            and #$fc
            sta $dd00      ; Set videobank
            lda #$2b
            sta $d011      ; Set Y-scrolling / bitmap mode
            lda #$d8
            sta $d016      ; Set multicolor mode
            lda #$80
            sta $d018      ; Set screen pointer
            lda #$00
            sta $d020      ; Set correct background colors
            lda #$00
            sta $d021
            ldx #$00
-
            lda $bc00,x    ; Copy the colorscreen
            sta $d800,x
            lda $bd00,x
            sta $d900,x
            lda $be00,x
            sta $da00,x
            lda $bee8,x
            sta $dae8,x
            inx
            bne -

            bit $d011
            bmi *-3
            bit $d011
            bpl *-3

            lda $d011      ; Unblank screen
            ora #$10
            sta $d011

            jmp *

; =============================================================================
;
; Block relocator
;
; =============================================================================

relocator:
            !if LOAD_UNDER_IO = 0 {
                ldy #$00

-               sei
                lda #$34   ; Disable both ROMs and IO
                sta $01
copyblk:
                lda (srcptr),y
                sta (dstptr),y
                iny
                bne copyblk
                lda #$37
                sta $01
                cli
                inc srcptr+1
                inc dstptr+1
                dex
                bne -

                rts
            }

; =============================================================================
;
; Tune player
;
; =============================================================================

tuneplayer_ram:
            pha
            tya
            pha
            txa
            pha
            jsr $b21e      ; Play tune
            asl $d019
            pla
            tay
            pla
            tax
            pla
nmih:       rti

tuneplayer_rom:
            lda #$35       ; Disable both ROMs
            sta $01
            jsr $b21e      ; Play tune
            lda #$37       ; Enable both ROMs
            sta $01
            asl $d019
            pla
            tay
            pla
            tax
            pla
            rti

        }
crtKickOffEnd:
