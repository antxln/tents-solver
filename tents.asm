# File:		tents.asm

#
# Description:	This program reads a Tents puzzle from the
#		standard input and solves it.
#
# Input:	1) the board size (n), 2 <= n <= 12.
#
#		2) n digits, non-separated, the number of tents
#		in each row from top to bottom.
#
#		3) n digits, non-separated, the number of tents
#		in each col from left to right.
#
#		next n lines contain rows of the board. Each row
#		contains n characters, which make up the initial
#		value for each square on the board. Initial squares
#		are grass (.) or tree (T).
#
# Output:	1) blank line, program banner, and a blank line.
#
#		Error message from input, if any.
#
#		2) "Initial puzzle", blank line, the puzzle,
#		formatted to include a box around the puzzle, and
#		a blank line.
#
#		Note: Boxes are made of ( + ) for corners, ( - ) for
#		horizontal lines, and ( | ) for vertical lines.
#		For the content of the puzzle, ( T ) for trees,
#		( . ) for grass, and ( A ) for tents.
#		Row sums are to the right of the puzzle, separated by
#		a space. Column sums are below the puzzle lined up with
#		the individual columns.
#
#		Error message from puzzle solver, if any.
#
#		3) "Final puzzle", blank line, the puzzle with all the
#		tents added, and a blank line. 
#

# CONSTANTS
#
# syscall codes
PRINT_STRING =	4

	.data

prog_banner:
	.ascii	"\n"
	.ascii	"******************\n"
	.ascii	"**     TENTS    **\n"
	.ascii	"******************\n"
	.asciiz	"\n"
msg1:
	.ascii	"Initial Puzzle\n"
	.asciiz	"\n"
msg2:
	.ascii	"Final Puzzle\n"
	.asciiz	"\n"

	.text
	.align	2
	.globl	main		# main is a global label
	.globl	read_tents
	.globl	print_tents
	.globl	solve_tents

#
# Name:		MAIN PROGRAM
#
# Description:	Main logic for the program.
#
#	This program reads in values representing a Tents puzzle and
#	outputs the solution if it exists.
#

main:
	addi	$sp, $sp, -8	# allocate space for the return address
	sw	$ra, 4($sp)	# store the ra on the stack
	sw	$s0, 0($sp)

				# print program banner
	li	$v0, PRINT_STRING
	la	$a0, prog_banner
	syscall

	jal	read_tents	# read tents from input

				# if read_tents returns 0, exit
	beq	$v0, $zero, main_done

				# else continue
	move	$s0, $v0	# save address of puzzle struct

				# print input puzzle
	li	$v0, PRINT_STRING
	la	$a0, msg1
	syscall

	move	$a0, $s0
	jal	print_tents

	move	$a0, $s0	# solve puzzle
	jal	solve_tents

				# if solve_tents returns 0, exit
	beq	$v0, $zero, main_done

				# print solved puzzle
	li	$v0, PRINT_STRING
	la	$a0, msg2
	syscall

	move	$a0, $s0
	jal	print_tents

	j	main_done

#
# All done -- exit the program!
#
main_done:
	lw	$ra, 4($sp)
	lw	$s0, 0($sp)
	addi	$sp, $sp, 8	# deallocate space for the return address
	jr	$ra		# return from main and exit

