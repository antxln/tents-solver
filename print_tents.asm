# File:		print_tents.asm

#
# Description:	Pretty prints a tents puzzle.

# CONSTANTS
#
# syscall codes
PRINT_INT =	1
PRINT_STRING =	4

TREE_ASCII =	84
GRASS_ASCII =	46
TENT_ASCII =	65

	.data

left_corner:
	.asciiz	"+-"
right_corner:
	.asciiz	"+\n"
horizontal:
	.asciiz	"--"
vertical:
	.asciiz	"| "
space:
	.asciiz " "
newline:
	.asciiz	"\n"
tree:
	.asciiz	"T "
grass:
	.asciiz	". "
tent:
	.asciiz	"A "

	.text
	.align	2
	.globl	print_tents

#
# Name:		print_tents
#
# Description:	Pretty print a tent puzzle.
#
# Arguments:	a0 the address of the puzzle struct
# Returns:	none
#

print_tents:
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)

	lw	$t0, 0($a0)	# address of size
	lb	$t0, 0($t0)	# size

	lw	$t1, 4($a0)	# address of row sum
	lw	$t2, 8($a0)	# address of col sum
	lw	$t3, 12($a0)	# address of board

	li	$t4, -1		# row counter
	jal	top_bot		# print top of box
pt_for_row:
	addi	$t4, $t4, 1	# incr. row counter
	beq	$t4, $t0, pt_loop_done

				# print left of box at start of every row
	li	$v0, PRINT_STRING
	la	$a0, vertical
	syscall

	li	$t5, 0		# col counter
pt_for_col:
	beq	$t5, $t0, pt_col_done

	lb	$t6, 0($t3)	# get byte at cell
	addi	$t3, $t3, 1	# go to next cell on board

				# print cell with a space
	li	$t7, TREE_ASCII
	beq	$t6, $t7, print_tree
	li	$t7, GRASS_ASCII
	beq	$t6, $t7, print_grass
	li	$t7, TENT_ASCII
	beq	$t6, $t7, print_tent

print_tree:
	la	$a0, tree
	j	print
print_grass:
	la	$a0, grass
	j	print
print_tent:
	la	$a0, tent
print:
	li	$v0, PRINT_STRING
	syscall

	addi	$t5, $t5, 1	# incr. col counter
	j	pt_for_col

pt_col_done:
				# print right of box at end of every row
	li	$v0, PRINT_STRING
	la	$a0, vertical
	syscall
				# print row sum
	li	$v0, PRINT_INT
	lb	$a0, 0($t1)
	syscall
				# print newline
	li	$v0, PRINT_STRING
	la	$a0, newline
	syscall

	addi	$t1, $t1, 1	# incr. row in row_sums
	j	pt_for_row

pt_loop_done:
				# print bottom of box
	jal	top_bot

				# left padding for printing col_sums
	li	$v0, PRINT_STRING
	la	$a0, space
	syscall

	li	$t5, 0		# col counter
col_sum_loop:
	beq	$t5, $t0, pt_done

				# print space
	li	$v0, PRINT_STRING
	la	$a0, space
	syscall
				# and the sum of the col
	li	$v0, PRINT_INT
	lb	$a0, 0($t2)
	addi	$t2, $t2, 1
	syscall
				# next col sum and loop
	addi	$t5, $t5, 1
	j	col_sum_loop

pt_done:
				# newline to next line
	li	$v0, PRINT_STRING
	la	$a0, newline
	syscall
				# blank line after puzzle
	li	$v0, PRINT_STRING
	la	$a0, newline
	syscall

	lw	$ra, 0($sp)
	addi	$sp, $sp, 4

	jr	$ra

top_bot:
				# print left corner of box
	li	$v0, PRINT_STRING
	la	$a0, left_corner
	syscall

	li	$t5, 0		# col counter
tb_loop:
	beq	$t5, $t0, tb_done
				# print top of box
	li	$v0, PRINT_STRING
	la	$a0, horizontal
	syscall

	addi	$t5, $t5, 1	# increment counter
	j	tb_loop

tb_done:
				# print right corner of box
	li	$v0, PRINT_STRING
	la	$a0, right_corner
	syscall

	jr	$ra

