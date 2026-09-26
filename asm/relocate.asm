;; Script relocation. Scripts are addressed as [$0400] (bank in $0402) + 16-bit Y.
;;   $0405 == 0 : was $DB:8000 -> now $E1:0000 (Y base 0)
;;   $0405 == 2 : was $DB:0000 -> now $E2:0000
;;   otherwise  : was $C2 (table $C2:0000) -> now $E3 (table $E3:0000)
;; Three places choose the bank: label scanner $C0:0BF5, script (re)start $C0:0D90, sub-thread $C0:2F0C.
org $C00BFB : db $A9,$E3      ; LDA #$E3 (default)
org $C00C0D : db $A9,$E1
org $C00C14 : db $A9,$00,$00  ; LDA #$0000 (Y base, was $8000)
org $C00C1B : db $A9,$E2
org $C00C2E : LDA.l $E30000,x ; start table
org $C00D9F : db $A9,$E1
org $C00DA6 : db $A9,$E2
org $C00DAD : db $A9,$E3
org $C02F1A : db $A9,$E1
org $C02F1E : db $A9,$E2
org $C02F22 : db $A9,$E3
