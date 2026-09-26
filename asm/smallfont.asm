;; 8x8 profile font: lowercase + punctuation written over the unused placeholder tiles $9E-$C3
;; (font at ROM 0x37000 = $C3:7000, 16 bytes/tile, 2bpp). Source: font/en_small/glyphs8.txt
org $C37000+($9E*16)
    incbin "../build/font/small_add.bin"
