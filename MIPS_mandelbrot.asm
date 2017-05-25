        .data
output:	.asciiz "output.bmp"
input:	.asciiz "input.bmp"
header:	.space 54

rozmiar:	.word 1		# rozmiar pliku
szerokosc:	.word 1		# szerokosc pliku
wysokosc:	.word 1		# wysokosc pliku
iloscPikseli:	.word 1
poczatekPliku:	.word 1
poczatekTablicy:.word 1
deskryptor:	.word 1
padding:	.word 1
Xpocz:		.word 1
Ypocz:		.word 1
lbnw:		.word 1		# liczba bitow na wiersz - uwzgledniony padding

b1:		.asciiz "Nie udalo sie otworzyc pliku 'input.bmp'. Koncze program."
b2:		.asciiz "Nie udalo sie wczytac naglowka pliku. Koncze program."

	.text
	.globl main
	
main:
otworzenieNaglowka:
	li $v0, 13		# 13 - otwarcie pliku
	la $a0, input   	# sciezka pliku
	syscall
	bltz $v0, blad1
	sw $v0, deskryptor
	
wczytanieNaglowka:
	li $v0, 14		# 14 - oczyt z pliku
	lw $a0, deskryptor	# deskryptor pliku
	la $a1, header		# bufor docelowy
	li $a2, 54		# ilosc bajtow do wczytania (54 - naglowek)
	syscall
	blez $v0, blad2
	
zapisanieRozmiarow:
	ulw $t0, 18($a1)
	sw $t0, szerokosc	# width - szerokosc
	ulw $t0, 22($a1)
	sw $t0, wysokosc	# height - wysokosc
	ulw $t0, 2($a1)
	sw $t0, rozmiar		# size - ile bajtow ma plik
	lw $a0, szerokosc
	lw $a1, wysokosc
	mul $a0, $a0, $a1
	sw $a0, iloscPikseli
	
zamkniecieNaglowka:
	li $v0, 16
	lw $a0, deskryptor
	syscall
	
alokacja:
	lw $a0, rozmiar
	li $v0, 9
	syscall
	sw $v0, poczatekPliku
	
otworzeniePlikuDoOdczytu:
	li $v0, 13		# 13 - otwarcie pliku
	la $a0, input   	# sciezka pliku
	la $a1, 0   		# sciezka pliku
	la $a2, 0   		# sciezka pliku
	syscall
	bltz $v0, blad1
	sw $v0, deskryptor
	
wczytanieCalegoPliku:
	li $v0, 14
	lw $a0, deskryptor
	lw $a1, poczatekPliku
	lw $a2, rozmiar
	syscall
	blez $v0, blad2
	
zamknieciePlikuDoOdczytu:
	li $v0, 16
	lw $a0, deskryptor
	syscall
	
obliczeniePaddingu:
	lw $a0, szerokosc
	andi $a0, $a0, 3
	sw $a0, padding

obliczenieBitowNaWiersz:
	lw $a0, szerokosc
	li $a1, 3
	mul $a0, $a0, $a1
	lw $a1, padding
	add $a0, $a0, $a1
	sw $a0, lbnw

obliczeniePoczatkuTablicy:
	lw $a0, poczatekPliku
	add $a0, $a0, 54
	sw $a0, poczatekTablicy

obliczenieSrodkaWspolrzednych:
	lw $a0, szerokosc
	srl $a0, $a0, 1
	addi $a0, $a0, -2
	sw $a0, Xpocz
	move $t8, $a0
	lw $a0, wysokosc
	div $a0, $a0, 3
	sll $a0, $a0, 1
	addi $a0, $a0, -1
	sw $a0, Ypocz
	move $t9, $a0

inicjalizujPetle:
	li $s0, 0				# $s0 - iterator po pikselach
	lw $s1, iloscPikseli			# $s1 - ilosc pikseli
	
	li $t0, 4
	mtc1 $t0, $f26				# move to coprocessor
	cvt.d.w $f26, $f26			# konwersja na double
	
	lw $t6, szerokosc			# $t6 - jednostka szerokosci
	srl $t6, $t6, 1
	lw $t7, wysokosc			# $t7 - jednostka wysokosci
	div $t7, $t7, 3
	
	lw $t0, wysokosc
	lw $t1, szerokosc
	lw $t2, Ypocz				# $t2 - Y poczatka wspolrzednych
	lw $t3, Xpocz				# $t3 - X poczatka wspolrzednych
	
	li $t5, 0xff				# kolor bialy
	
przejdzTablice:
	
	div $a0, $s0, $t1
	move $a1, $a0
	mul $a1, $a1, $t1
	sub $a1, $s0, $a1
	
	move $s6, $a1				# $s6 - X danego punktu
	move $s7, $a0				# $s7 - Y danego punktu
	
	sub $a0, $a0, $t2			# $a0 - wspolrzedna Y piksela
	sub $a1, $a1, $t3			# $a1 - wspolrzedna Y piksela
	sub $a1, $a1, 1
	
	mtc1 $a0, $f0				# move to coprocessor
	cvt.d.w $f0, $f0			# konwersja na double
	mtc1 $t7, $f2				# move to coprocessor
	cvt.d.w $f2, $f2			# konwersja na double
	div.d $f0, $f0, $f2			# znormalizowanie
	
	mtc1 $a1, $f2				# move to coprocessor
	cvt.d.w $f2, $f2			# konwersja na double
	mtc1 $t6, $f4				# move to coprocessor
	cvt.d.w $f4, $f4			# konwersja na double
	div.d $f2, $f2, $f4			# znormalizowanie
	
	mtc1 $zero, $f4				# wyzerowanie $f4
	cvt.d.w $f4, $f4			# konwersja na double
	mtc1 $zero, $f6				# wyzerowanie $f4
	cvt.d.w $f6, $f6			# konwersja na double

sprawdzPiksel:
	li $t4, 0				# indeks

petla:
	beq $t4, 16, kolorowaniePiksela		# jesli udalo sie dojsc na koniec petli to pokolruj piksel
	
	mul.d $f8, $f4, $f4			# zr^2
	mul.d $f10, $f6, $f6			# zu^2
	sub.d $f8, $f8, $f10			# $f4 = zr^2 - zu^2
	mul.d $f10, $f4, $f6			# zr * zu
	add.d $f10, $f10, $f10			# $f6 = 2 * zr * zu
	add.d $f4, $f8, $f0			# z^2 + p
	add.d $f6, $f10, $f2			# z^2 + p
	
	mul.d $f28, $f4, $f4			# zr^2
	mul.d $f30, $f6, $f6			# zu^2
	add.d $f28, $f28, $f30			# zr^2 + zu^2
	
	c.lt.d $f28, $f26			# ? z^2 + p >= 4 ?
	bc1f kolejnyPiksel			# jesli tak to przejdz do kolejnego piksela
	
	addi $t4, $t4, 1
	b petla

kolorowaniePiksela:
	lw $t0, lbnw
	
	mul $a0, $s7, $t0
	mul $a1, $s6, 3
	add $a0, $a0, $a1
	lw $a1, poczatekTablicy
	add $a0, $a1, $a0
	sb $t5, ($a0)
	sb $t5, 1($a0)
	sb $t5, 2($a0)

kolejnyPiksel:
	addi $s0, $s0, 1
	beq $s0, $s1,  otworzeniePlikuDoZapisu
	b przejdzTablice

otworzeniePlikuDoZapisu:
	li $v0, 13				# 13 - otwarcie pliku
	la $a0, output   			# sciezka pliku
	li $a1, 1
	li $a2, 0
	syscall
	sw $v0, deskryptor

zapisaniePliku:
	li $v0, 15
	lw $a0, deskryptor
	lw $a1, poczatekPliku
	lw $a2, rozmiar
	syscall

zamknieciePlikuDoZapisu:
	li $v0, 16
	lw $a0, deskryptor
	syscall
	b wyjscieZProgramu

blad1:
	li $v0, 4
	la $a0, b1
	syscall
	b wyjscieZProgramu
	
blad2:
	li $v0, 4
	la $a0, b2
	syscall
	b wyjscieZProgramu

wyjscieZProgramu:
	li $v0, 17
	syscall
