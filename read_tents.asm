# File:		read_tents.asm

#
# Description:	This program reads a Tents puzzle from the
#		standard input.

# CONSTANTS
#
# syscall codes
PRINT_STRING =	4
READ_INT =	5
READ_STRING =	8

ERROR =		0

CHAR_TO_INT =	-48

MIN_SIZE =	2
MAX_SIZE =	12

TREE_ASCII =	84
GRASS_ASCII =	46

	.data

str_buff:
	.space	MAX_SIZE+2	# +2 for '\n' and '\0'

	.align	2

	#
	# Memory for allocating up to 12 x 12 puzzle
	#
puzzle:
	.word	size, row_sum, col_sum, board

size:
	.byte	0
row_sum:
	.space	MAX_SIZE*1
col_sum:
	.space	MAX_SIZE*1
board:
	.space	MAX_SIZE*MAX_SIZE+1

	#
	# the print constants for the code
	#

invalid_size:
	.asciiz	"Invalid board size, Tents terminating\n"
illegal_sum:
	.asciiz	"Illegal sum value, Tents terminating\n"
illegal_char:
	.asciiz	"Illegal board character, Tents terminating\n"

	.text
	.align	2
	.globl	read_tents

#
# Name:		read_tents
#
# Description:	Read a tent puzzle from standard input.
#
# Arguments:    none
# Returns:      if error, 0
#		else, the address of the puzzle data structure
#		at offset 0, pointer to byte as size
#		at offset 4, pointer to array of bytes as row sums
#		at offset 8, pointer to array of bytes as col sums
#		at offset 12, pointer to array of bytes as cells of board
#

read_tents:
	addi	$sp, $sp, -16	# allocate space for the return address
	sw	$ra, 12($sp)	# store the ra on the stack
	sw	$s2, 8($sp)
	sw	$s1, 4($sp)
	sw	$s0, 0($sp)

	jal	read_size
	jal	read_sums
	jal	read_board

	la	$v0, puzzle	# set return to addr of puzzle
	j	rt_done

read_size:
	li	$v0, READ_INT
	syscall

	li	$t0, MIN_SIZE	# if n < MIN_SIZE, invalid size
	slt	$t0, $v0, $t0
	bne	$t0, $zero, size_error

	li	$t0, MAX_SIZE	# or MAX_SIZE < n, invalid size
	slt	$t0, $t0, $v0
	bne	$t0, $zero, size_error

				# else, valid size
				# save value
	la	$t0, size
	sb	$v0, 0($t0)

	jr	$ra

size_error:
				# print invalid board size error message
	li	$v0, PRINT_STRING
	la	$a0, invalid_size
	syscall

	li	$v0, ERROR	# set return and exit
	j	rt_done

read_sums:
	la	$s0, row_sum

read_sum:
				# read line into str_buff
	li	$v0, READ_STRING
	la	$a0, str_buff
	li	$a1, MAX_SIZE+2	# +2 for '\n' and '\0'
	syscall

	move	$t0, $s0	# addr to save sums read, row_sums or col_sums

	la	$t1, size
	lb	$t1, 0($t1)	# t1 = size

	addi	$t2, $t1, 1
	li	$t3, 2
	div	$t2, $t2, $t3	# t2 = max tents per row/col
				# (size + 1) // 2

	la	$t3, str_buff	# t3 = start_addr
	add	$t4, $t3, $t1	# t4 = start_addr + size (end_addr)
rs_loop:
				# rs_loop_done if reached end of sum str
	beq	$t3, $t4, rs_loop_done

	lb	$t5, 0($t3)	# t5 = ascii value of digit
	addi	$t5, $t5, CHAR_TO_INT

	slt	$t6, $t5, $zero	# if sum < 0, illegal sum

	bne	$t6, $zero, sum_error

	slt	$t6, $t2, $t5	# or max_tents < sum, illegal sum

	bne	$t6, $zero, sum_error

				# else, legal sum
	sb	$t5, 0($t0)	# save to t0, addr of row_sum or col_sum
	addi	$t0, $t0, 1	# update location to save vals

	addi	$t3, $t3, 1	# increment addr to next digit char in sum str
	j	rs_loop

rs_loop_done:
				# read_sums reads row_sum first, then col_sum
	la	$t0, col_sum	# if col_sum read, done

	beq	$s0, $t0, rs_done

	la	$s0, col_sum	# else, read col_sum
	j	read_sum

rs_done:
	jr	$ra

sum_error:
				# print illegal sum error message
	li	$v0, PRINT_STRING
	la	$a0, illegal_sum
	syscall

	li	$v0, ERROR	# set return and exit
	j	rt_done

read_board:
	la	$s0, board

	li	$s1, -1		# init row counter
	la	$t0, size
	lb	$s2, 0($t0)
rb_for_row:
	addi	$s1, $s1, 1	# increment row counter

				# if all rows processed, rb_done
	beq	$s1, $s2, rb_done

	li	$v0, READ_STRING
	la	$a0, str_buff	# read row
	li	$a1, MAX_SIZE+2	# +2 for '\n' and '\0'
	syscall

	la	$t0, TREE_ASCII
	la	$t1, GRASS_ASCII

	la	$t2, str_buff	# t2 = start_addr
	add	$t3, $t2, $s2	# t3 = start_addr + size (end_addr)
rb_for_col:
	beq	$t2, $t3, rb_for_row

	lb	$t4, 0($t2)

				# if char == TREE or char == GRASS,
				# save value in board
	beq	$t4, $t0, valid_char
	beq	$t4, $t1, valid_char

	j	char_error	# else, illegal character

valid_char:
	sb	$t4, 0($s0)	# save char, s0 = addr in board
	addi	$s0, $s0, 1	# update to next location to save char

	addi	$t2, $t2, 1	# increment col position
	j	rb_for_col

rb_done:
	sb	$zero, 0($s0)	# null terminate board

	jr	$ra

char_error:
				# print illegal char error message
	li	$v0, PRINT_STRING
	la	$a0, illegal_char
	syscall

	li	$v0, ERROR	# set return and exit
	j	rt_done

#
# All done -- exit the program!
#
rt_done:
	lw	$ra, 12($sp)
	lw	$s2, 8($sp)
	lw	$s1, 4($sp)
	lw	$s0, 0($sp)
	addi	$sp, $sp, 16	# deallocate space for the return address

	jr	$ra		# return

