;; Expand 16 Mbit -> 32 Mbit HiROM. Header ROM size byte $0C (4 MB). asar grows the file and fixes the checksum.
org $C0FFD7
    db $0C
org $FFFFFF
    db $00
