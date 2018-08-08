BORDER_FLASHING = 1                     ; Set to nonzero to enable border flashing
                                        ; when fastloading :)
LOAD_UNDER_IO   = 1                     ; Set to nonzero to enable possibility to load
                                        ; under I/O areas.
zpbase  = $58                           ; Zeropage base address. Loader needs 8
                                        ; addresses.

bank    = zpbase
banknxt = zpbase + 1
srcptr  = zpbase + 2   ; 2 bytes
dstptr  = zpbase + 4   ; 2 bytes
srcptrn = zpbase + 6   ; 2 bytes

kickoff      = $0800   ; Kick-off code (custom)
loader       = $1000   ; Main loader
