# File:		solve_tents.asm
#

#
# Description:	Solves a tents puzzle if possible.

# CONSTANTS
#
# syscall codes
PRINT_STRING =	4

ERROR =		0

TREE_ASCII =	84
GRASS_ASCII =	46
TENT_ASCII =	65

	.data

impossible_puzzle:
	.asciiz	"Impossible Puzzle\n\n"

	.text
	.align	2
	.globl	solve_tents

#
# Name:		solve_tents
#
# Description:	Solve a tent puzzle, modifying the input
#		to reveal tents on the board.
#
# Arguments:	a0 the address of the puzzle struct
# Returns:	if impossible, 0
#		else, the address of the puzzle struct (argument received)
#

solve_tents:
	addi	$sp, $sp, -12
	sw	$ra, 8($sp)
	sw	$s1, 4($sp)
	sw	$s0, 0($sp)

	move	$s1, $a0	# save argument

	lw	$t0, 0($a0)
	lb	$t0, 0($t0)	# size

	lw	$t1, 4($a0)	# row_sum
	lw	$t2, 8($a0)	# col_sum

	lw	$t3, 12($a0)	# start addr of board
	move	$s0, $t3	# curr addr in board
	mul	$t4, $t0, $t0	# size of board
	add	$t4, $t3, $t4	# end addr of board

	jal	solve_tent
	beq	$v0, $zero, impossible

	move	$v0, $s1	# set return and exit
	j	st_done

solve_tent:
	addi	$sp, $sp, -28
	sw	$ra, 24($sp)
	sw	$s5, 20($sp)
	sw	$s4, 16($sp)
	sw	$s3, 12($sp)
	sw	$s2, 8($sp)
	sw	$s1, 4($sp)
	sw	$s0, 0($sp)

find_tree:
				# reached end of puzzle,
				# check solution
	beq	$s0, $t4, check_solution

	li	$t5, TREE_ASCII
	lb	$t6, 0($s0)	# if tree, find tent for tree
	beq	$t5, $t6, find_tent

	addi	$s0, $s0, 1	# incr. position in board
	j	find_tree

find_tent:
	sub	$t5, $s0, $t3	# index in board array
	div	$t5, $t0

	mflo	$s2		# quotient = row index
	mfhi	$s4		# remainder = col index

	addi	$t5, $t0, -1
	slt	$t5, $s4, $t5	# if col index >= size - 1, no cell on right
	beq	$t5, $zero, try_bot

	addi	$s1, $s0, 1	# attempt to set tent at right of tree
	addi	$s4, $s4, 1	# update s4 to represent col index of tent
	jal	try_tent
	addi	$s4, $s4, -1	# restore s4 to represent col index of tree

	bne	$v0, $zero, solve_tent_done

try_bot:
	addi	$t5, $t0, -1
	slt	$t5, $s2, $t5	# if row index >= size - 1, no cell below
	beq	$t5, $zero, try_left

	add	$s1, $s0, $t0	# attempt to set tent below tree
	addi	$s2, $s2, 1	# update s2 to represent row index of tent
	jal	try_tent
	addi	$s2, $s2, -1	# restore s2 to represent row index of tree

	bne	$v0, $zero, solve_tent_done

try_left:
				# if col index == 0, no cell on left
	beq	$s4, $zero, try_top

	addi	$s1, $s0, -1	# attempt to set tent at left of tree
	addi	$s4, $s4, -1	# update s4
	jal	try_tent
	addi	$s4, $s4, 1	# restore s4

	bne	$v0, $zero, solve_tent_done

try_top:
				# if row index == 0, no cell above
	beq	$s2, $zero, solve_tent_done

	sub	$s1, $s0, $t0	# attempt to set tent above tree
	addi	$s2, $s2, -1	# update s4
	jal	try_tent
	addi	$s2, $s2, 1	# restore s4

	j	solve_tent_done

try_tent:
	addi	$sp, $sp, -4	# save return address
	sw	$ra, 0($sp)

	li	$t5, GRASS_ASCII
	lb	$t6, 0($s1)	# tent may only be set on grass
	bne	$t5, $t6, bad_tent

	add	$t5, $s2, $t1	# row index + start addr of row_sum
	lb	$s3, 0($t5)	# sum of tents in this row

	slt	$t5, $zero, $s3	# if sum of tents <= 0, tent cannot be placed
	beq	$t5, $zero, bad_tent

	add	$t5, $s4, $t2	# col index + start addr of col_sum
	lb	$s5, 0($t5)	# sum of tents in this col

	slt	$t5, $zero, $s5	# if sum of tents <= 0, tent cannot be placed
	beq	$t5, $zero, bad_tent

	#
	# Check if tents exist in immediate adjacent cells
	#

				# if row of tent == 0, skip top
	beq	$s2, $zero, check_bot

	sub	$t5, $s1, $t0	# top
	jal	is_tent
	bne	$v0, $zero, bad_tent

				# if col index == 0, skip top left
	beq	$s4, $zero, check_tr

	addi	$t5, $t5, -1	# top left
	jal	is_tent
	bne	$v0, $zero, bad_tent

check_tr:
	addi	$t6, $t0, -1
	slt	$t6, $s4, $t6	# if col index >= size - 1, skip top right
	beq	$t6, $zero, check_bot

	addi	$t5, $t5, 2	# top right
	jal	is_tent
	bne	$v0, $zero, bad_tent

check_bot:
	addi	$t6, $t0, -1
	slt	$t6, $s2, $t6	# if row index >= size - 1, skip bottom
	beq	$t6, $zero, check_left

	add	$t5, $s1, $t0	# cell below tent = addr of tent + size
	jal	is_tent		# bottom
	bne	$v0, $zero, bad_tent

				# if col index == 0, skip bottom left
	beq	$s4, $zero, check_br

	addi	$t5, $t5, -1	# bottom left
	jal	is_tent
	bne	$v0, $zero, bad_tent

check_br:
	addi	$t6, $t0, -1
	slt	$t6, $s4, $t6	# if col index >= size - 1, skip bottom right
	beq	$t6, $zero, check_left

	addi	$t5, $t5, 2	# bottom right
	jal	is_tent
	bne	$v0, $zero, bad_tent

check_left:
	beq	$s4, $zero, check_right

	addi	$t5, $s1, -1	# left
	jal	is_tent
	bne	$v0, $zero, bad_tent

check_right:
	addi	$t6, $t0, -1
	slt	$t6, $s4, $t6
	beq	$t6, $zero, good_tent

	addi	$t5, $s1, 1	# right
	jal	is_tent
	bne	$v0, $zero, bad_tent

	j	good_tent

is_tent:
	li	$v0, 0		# set default return value, cell is not tent

	li	$t6, TENT_ASCII
	lb	$t7, 0($t5)
	bne	$t6, $t7, is_tent_done

	li	$v0, 1		# if location is tent, change return value

is_tent_done:
	jr	$ra

good_tent:
	li	$t5, TENT_ASCII
	sb	$t5, 0($s1)	# set cell to contain tent

	addi	$s3, $s3, -1	# decr. sum of tents in row
	add	$t5, $s2, $t1
	sb	$s3, 0($t5)	# update row_sum

	addi	$s5, $s5, -1	# decr. sum of tents in col
	add	$t5, $s4, $t2
	sb	$s5, 0($t5)	# update col_sum

				# incr. location in board
				# to continue searching for tree
	addi	$s0, $s0, 1
	jal	solve_tent	# solve_tent for next tree
	addi	$s0, $s0, -1	# restore s0 value for this recursive call

				# if good solution,
				# skip undoing tent placement
	bne	$v0, $zero, good_cleanup

	li	$t5, GRASS_ASCII
	sb	$t5, 0($s1)	# bad solution, undo tent placement

good_cleanup:
	addi	$s3, $s3, 1	# reset sum in row
	add	$t5, $s2, $t1
	sb	$s3, 0($t5)	# update row_sum

	addi	$s5, $s5, 1	# reset sum in col
	add	$t5, $s4, $t2
	sb	$s5, 0($t5)	# update col_sum

	j	try_tent_done

bad_tent:
	li	$v0, 0

try_tent_done:
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra

check_solution:
	li	$v0, 1		# set default return value, valid solution
	li	$t5, 0		# init counter for rows/cols
cs_loop:
	beq	$t5, $t0, solve_tent_done

	add	$t6, $t5, $t1	# solution is good if all row sums zero
	lb	$t6, 0($t6)
	bne	$t6, $zero, bad_solution

	add	$t6, $t5, $t2	# and all col sums zero
	lb	$t6, 0($t6)
	bne	$t6, $zero, bad_solution

	addi	$t5, $t5, 1
	j	cs_loop

bad_solution:
	li	$v0, 0

solve_tent_done:
	lw	$s0, 0($sp)
	lw	$s1, 4($sp)
	lw	$s2, 8($sp)
	lw	$s3, 12($sp)
	lw	$s4, 16($sp)
	lw	$s5, 20($sp)
	lw	$ra, 24($sp)
	addi	$sp, $sp, 28
	jr	$ra

impossible:
	li	$v0, PRINT_STRING
	la	$a0, impossible_puzzle
	syscall

	li	$v0, ERROR	# set return and exit
	j	st_done

st_done:
	lw	$s0, 0($sp)
	lw	$s1, 4($sp)
	lw	$ra, 8($sp)
	addi	$sp, $sp, 12
	jr	$ra
