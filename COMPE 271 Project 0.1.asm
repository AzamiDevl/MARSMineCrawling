# Author:	Randy Figueroa
# Date:		October 2, 2023
# Description:	Custom MIPS Snake Game
# Iteration Version: Ver 0.2 - 1st Draft
# Ver Description: Added Bitmap Display Support. Began working on Snake Movement on display.

.data 						# Global Variables to be established before Main/Child Functions.
	frameBuffer: 	.space 0x80000		# Unit Width/Height in pixels would be set to 8 respectively.
	xCrnt: 		.word 50		# Current X Position
	yCrnt: 		.word 27		# Current Y Position
	xDir: 		.word 0 		# Starting Movement for X, ] When the program starts, the snake's movement is flat.
	yDir: 		.word 0 		# Starting Movement for Y  ]
	xCon: 		.word 64		# X Value for converting xCrnt to Bitmap
	yCon: 		.word 4			# Y Value for converting yCrnt to Bitmap
	tail:		.word 7624		# Pos of Snake Tail on Display					
	foodX: 		.word 32		# Food X Position
	foodY: 		.word 16		# Food Y Position
	mineX: 		.word 16		# Mine X Position
	mineY: 		.word 8			# Mine Y Position

.text
# Initialize Display [Background]
	la 		$t0, frameBuffer	# Load Frame Buffer Address
	li 		$t1, 8192		# Save 512*256 pixels
	li 		$t2, 0x00d3d3d3		# Load the Gray Background Color
l1:
	sw 		$t2, 0($t0)
	addi		$t0,$t0,4		# Increment/Move to next position in the bitmap display individually
	addi		$t1,$t1,-1		# Decrement Number of Pixels
	bnez		$t1,l1			# Until 8192 pixels have all been colored gray, repeat from child call.
# Initialize Display [Borders]
# Top Border
	la 		$t0, frameBuffer
	addi		$t1,$zero,64		# $t1 = 64, being the length of row
	li		$t2,0x00000000		# Loads the Color Black into $t0
displayBorderTop:
	sw 		$t2, 0($t0)		# Color the current pixel Black.
	addi 		$t0,$t0,4		# Move to next pixel
	addi 		$t1,$t1,-1		# decrement pixels from $t1 value (64).
	bnez 		$t1, displayBorderTop	# until $t1 = 0, repeat from the top
# Bottom Border
	la 		$t0, frameBuffer	
	addi		$t0,$t0, 7936		# Sets the starting pixel by the bottom left of the display.
	addi		$t1,$zero,64		# t1 = 512 length of row,
displayBorderBot:
	sw 		$t2,0($t0)		
	addi		$t0,$t0,4		
	addi		$t1,$t1,-1		
	bnez 		$t1, displayBorderBot		
# Left Border
	la		$t0,frameBuffer
	addi		$t1,$zero,256		# t1 = 512 length of Col.
displayBorderLeft:
	sw		$t2,0($t0)		
	addi		$t0,$t0,256		
	addi		$t1,$t1,-1		
	bnez		$t1,displayBorderLeft	
# Right Border
	la 		$t0, frameBuffer	
	addi		$t0,$t0,508		# Sets the Starting Pixel at the top right of the display.
	addi		$t1,$zero,255		# t1 = 512 col length
displayBorderRight:
	sw		$t2,0($t0)		
	addi		$t0,$t0,256		
	addi		$t1,$t1,-1		
	bnez		$t1,displayBorderRight	
# Initial Player Position
	la		$t0, frameBuffer
	lw		$s2, tail		# $s2 = Snake Tail
	lw		$s3, 0x0000ff00		# $s3 = Direction of Snake initially.
	add 		$t1, $s2, $t0		# $t1 is the start position for the player on the display.
	sw		$s3, 0($t1)		# Draw current player pixel position
	addi		$t1,$t1,-256		# set t1 to pixel above

## Game Logic Section

logicUpdateLoop:
	lw		$t3,0xffff0004		# Receives key input from keyboard to the Keyboard and Display MMIO Sim
	addi 		$v0,$zero,32		# syscall sleep, MARS utilizes sleep using a millisecond resolution.
	addi		$a0,$zero,66		# Setting the sleep for 66 ms to try an apporximate a low framerate 
	syscall

# Key press detection branches
	beq		$t3, 119,moveUp		# if input = key press 'w', branch to moveUp call.
	beq		$t3, 97, moveLeft	# else if input = 'a' branch to moveLeft call
	beq		$t3, 115, moveDown	# else if input = 's' branch to moveDown call
	beq		$t3, 100, moveRight	# else if input = 'd' branch to moveRight call.
	beq		$t3, 0,	moveUp		# Initial State. Snake will always move up on start without player input.
# Movement Branches
moveUp:
	lw		$s3,0x0000ff00		# Green Pixel for when the player moves up
	add		$a0,$s3,$zero		# a0 = s3
	jal		updateSnake		# Sends information to update address call, updates the snake on the display and changes velocity.
	# Jumps to address line to move the player's snake position, then exits the move branch.
	jal		updatePlayerHead	
	j		exitMove		
moveDown:
	lw		$s3,0x0100ff00		# Green Pixel for when the player moves down
	add		$a0,$s3,$zero		
	jal		updateSnake
	jal		updatePlayerHead	
	j		exitMove	
moveLeft:
	lw		$s3,0x0200ff00		# Green Pixel for when the player moves left
	add		$a0,$s3,$zero		
	jal		updateSnake
	jal		updatePlayerHead
	j		exitMove
moveRight:
	lw		$s3,0x0300ff00		# Green Pixel for when the player moves right
	add		$a0,$s3,$zero
	jal		updateSnake
	jal		updatePlayerHead
	j		exitMove
exitMove:
	j		logicUpdateLoop		# Jumps to the top of the game logic loop.
# Snake	Velocity and Pos Update Section

updateSnake:
		
