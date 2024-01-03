# Author:	Randy Figueroa
# Date:		October 2, 2023
# Description:	Custom MIPS Snake Game
# Iteration Version: Ver 1.0 - Working

# Ensure both the Keyboard and Display MMIO Sim and the Bitmap Display ARE CONNECTED before beginning.

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
	bodyUp:		.word 0x0000ff00	# Color Loads for the four dedicated direction to be used when setting Velocity.
	bodyDown:	.word 0x0100ff00
	bodyLeft:	.word 0x0200ff00
	bodyRight:	.word 0x0300ff00

.text
# Initialize Display [Background]
	la 		$t0, frameBuffer	# Load Frame Buffer Address
	li 		$t1, 8192		# Save 512*256 pixels
	li 		$t2, 0x00d3d3d3		# Load the Gray Background Color
displayBackground:
	sw 		$t2, 0($t0)
	addi		$t0,$t0,4		# Increment/Move to next position in the bitmap display individually
	addi		$t1,$t1,-1		# Decrement Number of Pixels
	bnez		$t1,displayBackground	# Until 8192 pixels have all been colored gray, repeat from child call.
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
	
###
# Load Frame Buffer and generate a random number from (0 - 127) * 4 
# Write the color hex black at the random number location generated then loop 30 or so times.
###
# Minefield Generation
	la		$t0, frameBuffer	# Loads frameBuffer
	addi		$t0, $t0, 520		# Sets the starting pixel at the top left corner by the border
	addi		$t1, $zero,26		# Integer for decrement to bnez (30 is relatively challanging)
			# $t2 is loaded with 0x00000000 (Black)
displayFieldMines:				
	addi		$v0, $zero,42		# RNG Syscall
	addi		$a1, $zero, 127		# Upper Bound Argumentive (Other Values would be 1023 or 511. 255 also works. The higher number the easier.)
	syscall					# Generate a Number	   ^ The lower this value is, the more that show up

	
	add		$t3, $zero, $a0		# Saves RN to Temp Register 3
	sll		$t3, $t3, 2		# Multiplies by 4
	
	sw		$t2, 0($t0)		# Saves Hex Color at Pointer Position
	add		$t0, $t3,$t0		# Moves to next position from the frameBuffer using the generated number.
	addi		$t1, $t1,-1		# Decrement # of mines to place.
	bnez		$t1,displayFieldMines	# Branch to func call till $t1 == 0
#	
###

# Initial Player Position
	la		$t0, frameBuffer
	lw		$s2, tail		# $s2 = Snake Tail
	lw		$s3, bodyUp		# $s3 = Direction of Snake initially.
	
	add 		$t1, $s2, $t0		# $t1 is the start position for the player on the display.
	sw		$s3, 0($t1)		# Draw current player pixel position
	addi		$t1,$t1,-256		# set t1 to pixel above
	sw		$s3, 0($t1)		# Re-Draw Current Player Position
	
	jal		drawFood

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
	lw		$s3, bodyUp		# Green Pixel for when the player moves up
	add		$a0, $s3,$zero		# a0 = s3
	jal		updateSnake		# Sends information to update address call, updates the snake on the display and changes velocity.
	# Jumps to address line to move the player's snake position, then exits the move branch.
	jal		updatePlayerHead	
	j		exitMove		# Jumps to the end so that the process may repeat again
moveDown:
	lw		$s3, bodyDown		# Green Pixel for when the player moves down
	add		$a0, $s3,$zero		
	jal		updateSnake
	jal		updatePlayerHead	
	j		exitMove	
moveLeft:
	lw		$s3, bodyLeft		# Green Pixel for when the player moves left
	add		$a0, $s3,$zero		
	jal		updateSnake
	jal		updatePlayerHead
	j		exitMove
moveRight:
	lw		$s3, bodyRight		# Green Pixel for when the player moves right
	add		$a0, $s3,$zero
	jal		updateSnake
	jal		updatePlayerHead
	j		exitMove
exitMove:
	j		logicUpdateLoop		# Jumps to the top of the game logic loop.
# Snake	Velocity and Pos Update Section

updateSnake:
	addiu 		$sp, $sp,-24		# Allocate Space for the Stack
	sw		$fp, 0($sp)		# Stores the function caller's frame pointer and return address.
	sw		$ra, 4($sp)
	addiu		$fp, $sp,20		# Sets frame pointer for the current function. (updateSnake)
	
# Print Player Pos
	lw		$t0, xCrnt		# Current position values for the Snake on the array.
	lw		$t1, yCrnt		
	lw		$t2, xCon		# $t2 = 64
	mult		$t1, $t2		# Current Y Value * 64
	mflo		$t3			# Sets $t3 = $t1 * 64
	add		$t3, $t3,$t0		# $t3 = Current Y * 64 + Current X
	lw		$t2, yCon		# $t2 = 4
	mult		$t3, $t2		# Row Major Formula. (yCrnt * 64 + xCrnt) * 4
	mflo		$t0			# Sets $t0 = Row Major Formula.
	
	la		$t1,frameBuffer		# Loads the Bitmap Display Buffer
	add		$t0,$t1,$t0		# Sets $t0 = Row Major Formula + Frame Address
	lw		$t4,0($t0)		# Store original value of pixel in $t4
	sw		$a0,0($t0)		# Stores the Direction and Color on the Bitmap Display
# Set constant velocity direction
	# Velocity = Up
	lw		$t2,bodyUp		# Global Body Variable word that loads up the color for the given player direction.
	beq		$a0, $t2,setDirConstantUp	# Branch path if player direction and hex color is equal to address lines moveUp/Down/Left/Right
	# Velocity = Down
	lw		$t2,bodyDown
	beq		$a0, $t2,setDirConstantDown
	# Velocity = Left
	lw		$t2,bodyLeft
	beq		$a0, $t2,setDirConstantLeft
	# Velocity = Right
	lw		$t2,bodyRight
	beq		$a0, $t2,setDirConstantRight
setDirConstantUp:				# $t5 = xDir and $t6 = yDir
	addi 		$t5, $zero,0		# Sets horizonal move constant to 0, which is left unchanged for y-axis direction
	addi 		$t6, $zero,-1		# Sets vertical move constant to -1, which moves the player upward.
	sw		$t5, xDir		# Updates the (x,y) Direction Constants for the player with new values
	sw		$t6, yDir		
	j		exitDirConstant
setDirConstantDown:
	addi		$t5, $zero,0		
	addi		$t6, $zero,1		# Sets the vertical move constant to 1, which moves the player downward
	sw		$t5, xDir
	sw		$t6, yDir
	j		exitDirConstant
setDirConstantLeft:
	addi		$t5, $zero,-1		# Sets the horizontal move constant to -1, which moves the player to the left
	addi		$t6, $zero,0		# Sets the vertical move constant to 0, which is also left unchanged for the x-axis direction.
	sw		$t5, xDir
	sw		$t6, yDir
	j		exitDirConstant
setDirConstantRight:
	addi		$t5, $zero,1		# Sets horizontal move constant to 1, which moves the player to the right
	addi		$t6, $zero,0
	sw		$t5, xDir
	sw		$t6, yDir
	j		exitDirConstant
exitDirConstant:
	li		$t2, 0x00ffccff		# Loads Pink Color
	bne		$t2, $t4, posOverFood	# If the player position (the head) is not on the food color, branch to func
	
	jal		newFoodLocal
	jal		drawFood
	j		exitPositionUpdate
posOverFood:
	li		$t2, 0x00d3d3d3		# Loads the Background Color
	beq		$t2, $t4,legalPixelPos	# Program checks if current player pos is legal, and branches away if true
	
	addi		$v0, $zero, 10		# Calls Program Close if player is in an illegal pixel (Border Color)
	syscall
	
legalPixelPos:
# Old Tail Remove
	lw		$t0, tail		# Sets $t0 to the .word tail
	la		$t1, frameBuffer	# Load frame buffer
	add		$t2, $t0, $t1		# Sets $t2 to be the location of the tail witin the frame buffer
	li		$t3, 0x00d3d3d3		# Loads the BG color
	lw		$t4, 0($t2)		# $t4 = the tail's current direction and color
	sw		$t3, 0($t2)		# overwrites the tail's position with the BG color (Grey)
# Redraw Recent Tail Pos
	lw		$t5, bodyUp		# Branch Logic similar to the direction constants.
	beq		$t5, $t4,setTailPosUp	# Loads up the color code dedicated to the four directions, and branch accordingly.
	lw		$t5, bodyDown
	beq		$t5, $t4, setTailPosDown
	lw		$t5, bodyLeft
	beq		$t5, $t4, setTailPosLeft
	lw		$t5, bodyRight
	beq		$t5, $t4, setTailPosRight
setTailPosUp:
	addi		$t0, $t0,-256		# Tail Pos - 256 pixels
	sw		$t0, tail		# Save position after calculation.
	j 		exitPositionUpdate
setTailPosDown:
	addi		$t0, $t0,256		# Tail Pos + 256 pixels
	sw		$t0, tail
	j 		exitPositionUpdate
setTailPosLeft:
	addi		$t0, $t0,-4		# Tail Pos - 4 Pixels
	sw		$t0, tail
	j 		exitPositionUpdate
setTailPosRight:
	addi		$t0, $t0,4		# Tail Pos + 4 Pixels
	sw		$t0, tail
	j 		exitPositionUpdate

exitPositionUpdate:
	lw		$ra, 4($sp)		# Load Caller's Return Address and restores it's frame and stack pointers.
	lw		$fp, 0($sp)
	addiu		$sp, $sp, 24
	jr		$ra			# Return to caller func.
updatePlayerHead:
# Stack Allocation
	addiu		$sp, $sp, -24		# Stack Allocation and Prep.
	sw		$fp, 0($sp)
	sw		$ra, 4($sp)
	addiu		$fp, $sp, 20		# Setup $fp for the updatePlayerHead function.
# Update Process
	lw		$t3, xDir		# Loads current X and Y direction constant from saved memory
	lw		$t4, yDir		
	lw		$t5, xCrnt		# Loads current X and Y player head positions.
	lw		$t6, yCrnt
	add		$t5, $t5,$t3		# Utilizing the current direction constant, update the current player position.
	add		$t6, $t6,$t4		# Ditto, using the Y direction constant and current position.
	sw		$t5, xCrnt		# Saves updated X and Y positions as the new Current Positions.
	sw		$t6, yCrnt
# Stack De-allowcation
	lw		$ra, 4($sp)		# Load Caller's Return Address
	lw		$fp, 0($sp)		# Restores frame pointer
	addiu		$sp, $sp,24		# Restores stack pointer
	jr		$ra			# Return to the caller's code.
drawFood:
	addiu		$sp, $sp,-24		# Stack Allocation Setup
	sw		$fp, 0($sp)
	sw		$ra, 4($sp)
	addiu		$fp, $sp, 20
# Draw Initial Food Position to Bitmap Display
	lw		$t0, foodX		# Given Static Food Positions, which places it in the middle.
	lw		$t1, foodY		# $t0 = X, $t1 = Y
	lw		$t2, xCon		# $t2 set to xCon which is 64
	mult		$t1, $t2		
	mflo		$t3			# $t3 = foodY * xCon
	add		$t3, $t3, $t0		# foodY * xCon + foodX
	lw		$t2, yCon		# Replaces $t2's xCon to yCon, being 4
	mult		$t3, $t2		# [foodY * 64 + foodX] * 4
	mflo		$t0			# $t0 = [foodY * 64 + foodX] * 4
# Stores new direction in bitmap display
	la		$t1, frameBuffer	# Loads frame buffer
	add 		$t0, $t1,$t0		# adds converted x/y food positions to the frame address for display.
	li		$t4, 0x00ffccff		# Loads the color pink for the food.
	sw		$t4, 0($t0)		# saves the color and position of the food onto the bitmap display

	lw		$ra, 4($sp)		# Load Caller's Return Address
	lw		$fp, 0($sp)		# Restores frame pointer
	addiu		$sp, $sp,24		# Restores stack pointer
	jr		$ra			# Return to the caller's code
newFoodLocal:
	addiu		$sp, $sp,-24		# Stack Allowcation
	sw		$fp, 0($sp)
	sw		$ra, 4($sp)
	addiu		$fp, $sp,20
calculateLocal:
# X Pos RNG
	addi		$v0, $zero,42		# Random Number Call
	addi		$a1, $zero,63		# Upper X Bound Argumentive
	syscall
	add		$t1, $zero, $a0		# Saves results to temp register 1
# Y Pos RNG
	addi		$v0, $zero,42		
	addi		$a1, $zero,31		# Upper Y Bound Argumentive
	syscall
	add		$t2, $zero, $a0		# Saves results to temp register 2
# X and Y Display Map Conversion
	lw		$t3, xCon		# Set temporary register to 64
	mult		$t2, $t3		# Generated Y Pos * 64
	mflo		$t4			# $t4 = yRNGPos * 64
	add		$t4,$t4,$t1		# yRNGPos * 64 + xRNGPos
	lw		$t3, yCon		# Replace temporary register value with 4
	mult		$t3, $t4		# [yRNGPos * 64 + xRNGPos] * 4
	mflo		$t4			# $t4 = [yRNGPos * 64 + xRNGPos] * 4
	
	la		$t0, frameBuffer	# Loads the Frame Buffer
	add		$t0, $t4, $t0		# Adds the Frame Buffer to the generated X/Y positions of the food.
	lw		$t5, 0($t0)		# Set the temp register = bitmap location from the add line prior
	
	li		$t6, 0x00d3d3d3		# Loads the background color
	beq		$t5, $t6,validFood	# if selected position is indeed the background, branch to valid, otherwise redo calculation
	j		calculateLocal		# Jump to the top should the chosen location be invalid

validFood:
	sw		$t1,foodX		# RN Generated values for X and Y are valid, and overwrite the global .data for the food's x and y pos
	sw		$t2,foodY
	
	lw		$ra, 4($sp)		# Load Caller Return Address
	lw		$fp, 0($sp)		# Restore the Frame and Stack pointer of the caller.
	addiu		$sp, $sp,24
	jr		$ra			# Return to caller.
