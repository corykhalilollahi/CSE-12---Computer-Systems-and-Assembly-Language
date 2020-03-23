##########################################################################
# Created by:  Khalilollahi, Cory
#              ckhalilo
#              9 March 2020
#
# Assignment:  Lab 5: Functions and Graphics
#              CSE 012, Computer Systems and Assembly Language
#              UC Santa Cruz, Winter 2020
# 
# Description: This program prints graphics on the Bitmap Display.
# 
# Notes:       This program is intended to be run from the MARS IDE.
##########################################################################

#  PSEUDOCODE:
#  -----------
#  This lab file only consists of macros and functions, so the pseudocode for each is present above the macro or function.
#  There is no main function for this lab file.
#  Likewise, because each function uses the registers in different ways, the register usage for each function is below its pseudocode.

#Winter20 Lab5 Template File

# Macro that stores the value in %reg on the stack 
#  and moves the stack pointer.
.macro push(%reg)
    addi $sp, $sp, -4              # Move stack pointer down
    sw %reg, 0($sp)                # Store word from register onto top of stack
.end_macro 

# Macro takes the value on the top of the stack and 
#  loads it into %reg then moves the stack pointer.
.macro pop(%reg)
    lw %reg, 0($sp)                # Load word from top of stack into register
    addi $sp, $sp, 4               # Move stack pointer up
.end_macro

# Macro that takes as input coordinates in the format
# (0x00XX00YY) and returns 0x000000XX in %x and 
# returns 0x000000YY in %y
.macro getCoordinates(%input %x %y)
    move %x, %input        
    srl %x, %x, 16                 # Use right logical shift by 16 bits to put the XX coordinate at the end of the %x word
    move %y, %input        
    andi %y, %y, 0xFF              # Use bit-wise AND with 0xFF to only put the last 8 bits (YY coordinate) of the input word into the %y word
.end_macro

# Macro that takes Coordinates in (%x,%y) where
# %x = 0x000000XX and %y= 0x000000YY and
# returns %output = (0x00XX00YY)
.macro formatCoordinates(%output %x %y)
    sll %output, %x, 16            # Use left logical shift on %x to move the XX coordinate to the appropriate place of the output word
    or %output, %output, %y        # Use bit-wise OR with %y to place the YY coordinate at the end of the output word
.end_macro 


.data
originAddress: .word 0xFFFF0000    # Beginning address of bitmap table

.text
j done 
    
    done: nop                      # Terminate the program
    li $v0 10 
    syscall

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#  Subroutines defined below
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#*****************************************************
# clear_bitmap:
#  Given a clor in $a0, sets all pixels in the display to
#  that color.	
#-----------------------------------------------------
# $a0 =  color of pixel
#*****************************************************

#  PSEUDOCODE:
#  -----------
#  1. Loop through every pixel on the bitmap by looping through memory, starting at address 0xFFFF_0000, one 32-bit word (pixel) at a time
#  2. At each address, store the input color to "color" the pixel
#  3. Stop the loop after pixel 0xFFFF_FFFC, or coordinate (127, 127), has been colored

#  REGISTER USAGE:
#  ---------------
#  $a0: argument for function - color of pixel
#  $t0: original address of the bitmap memory
#  $ra: ddress of the instruction to return to

clear_bitmap: nop
        push($t0)                                              # Save $t0 onto the stack
        lw $t0, originAddress                                  # Load the beginning bitmap address into $t0
        clear_Loop:
            nop
            bgt $t0, 0xFFFFFFFC, end_Clear                     # End the loop once the current pixel exceeds the boundary of the 128x128 bitmap
            sw $a0, ($t0)                                      # Store the chosen color into the pixel
            addi $t0, $t0, 4                                   # Move on to the next pixel by incrementing the bitmap address by 4
            b clear_Loop                                       # Loop back up
        end_Clear:                                             # End of loop
            nop
        pop($t0)                                               # Restore $t0 from the stack        
	jr $ra                                                 # Jump back to the caller function
	
#*****************************************************
# draw_pixel:
#  Given a coordinate in $a0, sets corresponding value
#  in memory to the color given by $a1
#  [(row * row_size) + column] to locate the correct pixel to color
#-----------------------------------------------------
# $a0 = coordinates of pixel in format (0x00XX00YY)
# $a1 = color of pixel
#*****************************************************

#  PSEUDOCODE:
#  -----------
#  1. Get the x and y coordinates of the input coordinate pair
#  2. Calculate the matching memory address of the coordinate pair using: 
#     memory address = 0xFFFF_0000 + 4[(y * 128) + x]
#  3. Store the input color at this memory address to "color" the pixel

#  REGISTER USAGE:
#  ---------------
#  $a0: argument for function - coordinate pair of pixel in format (0x00XX00YY)
#  $a1: argument for function - color of pixel
#  $t0: x coordinate of pixel
#  $t1: y coordinate of pixel
#  $t2: immediate value 128
#  $t3: (y * 128)
#  $t4: (y * 128) + x
#  $t5: immediate value 4
#  $t6: 4 * [(y * 128) + x]
#  $t7: base address (0xFFFF_0000)
#  $t8: address of pixel: 0xFFFF_0000 + 4[(y * 128) + x]
#  $ra: address of the instruction to return to

draw_pixel: nop
        push($t0)                                 # Save registers $t0-$t8 onto the stack
        push($t1) 
        push($t2) 
        push($t3) 
        push($t4) 
        push($t5) 
        push($t6) 
        push($t7) 
        push($t8) 
        getCoordinates($a0, $t0, $t1)             # Store x into $t0 and y into $t1
        li $t2, 128                               # Size of each row
	mult $t1, $t2                             # Multiply y and 128 
	mflo $t3                                  # Store the product into $t3
	add $t4, $t3, $t0                         # Store the sum of (y * 128) and x into $t4
	li $t5, 4                                 
	mult $t4, $t5                             # Multiply (y * 128) + x and 4
	mflo $t6                                  # Store the product into $t6
	lw $t7, originAddress                     # Load the original address of the bitmap into $t7
	add $t8, $t7, $t6                         # Store the sum of 0xFFFF_0000 and 4 * [(y * 128) + x] into $t8
	sw $a1, ($t8)                             # $t8 is the memory address of the input pixel, so store the color into that address
	pop($t8)                                  # Restore registers $t8-$t0 from the stack
        pop($t7) 
        pop($t6) 
        pop($t5) 
        pop($t4) 
        pop($t3) 
        pop($t2) 
        pop($t1) 
        pop($t0)         
	jr $ra                                    # Jump back to the caller function
	
#*****************************************************
# get_pixel:
#  Given a coordinate, returns the color of that pixel	
#-----------------------------------------------------
# $a0 = coordinates of pixel in format (0x00XX00YY)
# returns pixel color in $v0	
#*****************************************************

#  PSEUDOCODE:
#  -----------
#  1. Get the x and y coordinates of the input coordinate pair
#  2. Calculate the matching memory address of the coordinate pair using: 
#     memory address = 0xFFFF_0000 + 4[(y * 128) + x]
#  3. Return the color stored at this memory address

#  REGISTER USAGE:
#  ---------------
#  $a0: argument for function - coordinate pair of pixel in format (0x00XX00YY)
#  $v0: return value of function - color of pixel
#  $t0: x coordinate of pixel
#  $t1: y coordinate of pixel
#  $t2: immediate value 128
#  $t3: (y * 128)
#  $t4: (y * 128) + x
#  $t5: immediate value 4
#  $t6: 4 * [(y * 128) + x]
#  $t7: base address (0xFFFF_0000)
#  $t8: address of pixel: 0xFFFF_0000 + 4[(y * 128) + x]
#  $ra: address of the instruction to return to
  
get_pixel: nop
	push($t0)                                 # Save registers $t0-$t8 onto the stack    
        push($t1) 
        push($t2) 
        push($t3) 
        push($t4) 
        push($t5) 
        push($t6) 
        push($t7) 
        push($t8) 
        getCoordinates($a0, $t0, $t1)             # Store x into $t0 and y into $t1
        li $t2, 128                               # Size of each row
	mult $t1, $t2                             # Multiply y and 128 
	mflo $t3                                  # Store the product into $t3
	add $t4, $t3, $t0                         # Store the sum of (y * 128) and x into $t4
	li $t5, 4                                 
	mult $t4, $t5                             # Multiply (y * 128) + x and 4
	mflo $t6                                  # Store the product into $t6
	lw $t7, originAddress                     # Load the original address of the bitmap into $t7
	add $t8, $t7, $t6                         # Store the sum of 0xFFFF_0000 and 4 * [(y * 128) + x] into $t8
	lw $v0, ($t8)                             # $t8 is the memory address of the input pixel, so load the color from that address into $v0
	pop($t8)                                  # Restore registers $t8-$t0 from the stack
        pop($t7) 
        pop($t6) 
        pop($t5) 
        pop($t4) 
        pop($t3) 
        pop($t2) 
        pop($t1) 
        pop($t0) 
	jr $ra                                    # Jump back to the caller function
	

#***********************************************
# draw_line:
#  Given two coordinates, draws a line between them 
#  using Bresenham's incremental error line algorithm	
#-----------------------------------------------------
#  PSEUDOCODE:
#  -----------
# 	Bresenham's line algorithm (incremental error)
# plotLine(int x0, int y0, int x1, int y1)
#    dx =  abs(x1-x0);
#    sx = x0<x1 ? 1 : -1;
#    dy = -abs(y1-y0);
#    sy = y0<y1 ? 1 : -1;
#    err = dx+dy;  /* error value e_xy */
#    while (true)   /* loop */
#        plot(x0, y0);
#        if (x0==x1 && y0==y1) break;
#        e2 = 2*err;
#        if (e2 >= dy) 
#           err += dy; /* e_xy+e_x > 0 */
#           x0 += sx;
#        end if
#        if (e2 <= dx) /* e_xy+e_y < 0 */
#           err += dx;
#           y0 += sy;
#        end if
#   end while
#-----------------------------------------------------
# $a0 = first coordinate (x0,y0) format: (0x00XX00YY)
# $a1 = second coordinate (x1,y1) format: (0x00XX00YY)
# $a2 = color of line format: (0x00RRGGBB)
#***************************************************

#  REGISTER USAGE:
#  ---------------
#  $a0: argument for function - first coordinate
#  $a1: argument for function - second coordinate
#  $a2: argument for function - color of line
#  $t0: x0
#  $t1: y0
#  $t2: x1
#  $t3: y1
#  $t4: x1 - x0
#  $t5: dx = abs(x1 - x0)
#  $t6: sx
#  $t7: y1 - y0
#  $t8: dy = -abs(y1 - y0)
#  $t9: sy
#  $s0: err
#  $s1: 2e
#  $ra: address of the instruction to return to

draw_line: nop
        push($t0)                                  # Save registers $t0-$t9 and $s0-$s1 onto the stack
	push($t1) 
	push($t2) 
	push($t3) 
	push($t4) 
	push($t5)  
	push($t6) 
	push($t7) 
	push($t8) 
	push($t9) 
	push($s0) 
	push($s1) 
	getCoordinates($a0, $t0, $t1)              # Store x0 into $t0 and y0 into $t1
	getCoordinates($a1, $t2, $t3)              # Store x1 into $t2 and y1 into $t3
	sub $t4, $t2, $t0                          # Store (x1 - x0) into $t4
	abs $t5, $t4                               # Store the absolute value of (x1 - x0) into $t5 (dx)
        blt $t0, $t2, sxpos1                       # If x0 < x1, jump to True branch
        li $t6, -1                                 # Else, False Branch: sx = -1
        b sxneg1                                   # Skip over the True branch
        sxpos1:                                    # True branch
        nop                                        
        li $t6, 1                                  # sx = 1
        sxneg1:                     
        nop               
        sub $t7, $t3, $t1                          # Store (y1 - y0) into $t7
        abs $t8, $t7                               # Store the absolute value of (y1 - y0) into $t8
        mul $t8, $t8, -1                           # Multiply abs(y1 - y0) by -1 and store the product into $t8 (dy)
        blt $t1, $t3, sypos1                       # If y0 < y1 --> jump to True branch
        li $t9, -1                                 # Else --> False Branch: sy = -1
        b syneg1                                   # Skip over the True branch
        sypos1:                                    # True branch
        nop
        li $t9, 1                                  # sy = 1
        syneg1:
        nop
        add $s0, $t5, $t8                          # err = dx + dy
        push($a0)                                  # Store $a0 onto the stack
        whileLoop:                                 # While loop
            nop
            formatCoordinates($a0, $t0, $t1)       # Format the current x0 and y0 into a coordinate ($a0)
            push($a1)                              # Store $a1 onto the stack
            move $a1, $a2                          # Store the line color into $a1
            push($ra)                              # Store $ra onto the stack
            jal draw_pixel                         # Draw the colored pixel at the current coordinate
            pop($ra)                               # Restore $ra from the stack
            pop($a1)                               # Restore $a1 from the stack
            bne $t0, $t2, continueLoop             # If x0 != x1 --> continue on with the loop
            beq $t1, $t3, exitLoop                 # If (x0 == x1) && (y0 == y1) --> exit the loop
            continueLoop:
            nop
            mul $s1, $s0, 2                        # e2 = err * 2
            blt $s1, $t8, endIf1                   # If e2 < dy --> skip to end if
            add $s0, $s0, $t8                      # err += dy
            add $t0, $t0, $t6                      # x0 += sx 
            endIf1:
            nop
            bgt $s1, $t5, endIf2                   # If e2 > dx --> skip to end if
            add $s0, $s0, $t5                      # err += dx
            add $t1, $t1, $t9                      # y0 += sy
            endIf2:
            nop
            b whileLoop                            # Loop back up
        exitLoop:                                  # End of loop
        nop
        pop($a0)                                   # Restore $a0, $s1-$s0, and $t9-$t0 from the stack
        pop($s1) 
	pop($s0) 
	pop($t9) 
	pop($t8) 
	pop($t7) 
	pop($t6) 
	pop($t5) 
	pop($t4) 
	pop($t3) 
	pop($t2) 
        pop($t1) 
        pop($t0)
        jr $ra                                     # Jump back to the caller function
	
#*****************************************************
# draw_rectangle:
#  Given two coordinates for the upper left and lower 
#  right coordinate, draws a solid rectangle	
#-----------------------------------------------------
# $a0 = first coordinate (x0,y0) format: (0x00XX00YY)
# $a1 = second coordinate (x1,y1) format: (0x00XX00YY)
# $a2 = color of line format: (0x00RRGGBB)
#***************************************************

#  PSEUDOCODE:
#  -----------
#  /// Loop that creates a rectangle by drawing one horizontal line in each row
#  L = UL
#  R = UR
#  Ly = ULy
#  Ry = ULy
#  while (True):
#      draw_line(L, R, color)
#      if (L == LL) && (R == LR): break
#      Ly += 1
#      Ry += 1
#  end While

#  REGISTER USAGE:
#  ---------------
#  $a0: argument for function - Upper Left Pixel (UL)
#  $a1: argument for function - Lower Right Pixel (LR)
#  $a2: argument for function (color of rectangle)
#  $t0: x coordinate of Upper Left pixel (ULx)
#  $t1: y coordinate of Upper Left pixel (ULy)
#  $t2: x coordinate of Lower Right pixel (LRx)
#  $t3: y coordinate of Lower Right pixel (LRy)
#  $t4: Lower Left pixel (LL)
#  $t5: current Left pixel (L)
#  $t6: current Right pixel (R)
#  $ra: address of the instruction to return to

draw_rectangle: nop
        push($t0)                                        # Save registers $t0-$t6 onto the stack
        push($t1) 
        push($t2) 
        push($t3) 
        push($t4) 
        push($t5) 
        push($t6) 
        getCoordinates($a0, $t0, $t1)                    # Store ULx into $t0 and ULy into $t1
        getCoordinates($a1, $t2, $t3)                    # Store LRx into $t2 and LRy into $t3
        formatCoordinates($t4, $t0, $t3)                 # Create LL using the coordinate pair of ULx and LRy
        while:                                           # While loop
            nop
            formatCoordinates($t5, $t0, $t1)             # Create the current L using the coordinate pair of ULx and y
            formatCoordinates($t6, $t2, $t1)             # Create the current R using the coordinate pair of LRx and y
            push($a0)                                    # Save $a0 onto the stack
            push($a1)                                    # Save $a1 onto the stack
            move $a0, $t5                                # Set first coordinate input of draw_line to L
            move $a1, $t6                                # Set second coordinate input of draw_line to R
            push($ra)                                    # Save $ra onto the stack
            jal draw_line                                # draw_line(L, R, color)
            pop($ra)                                     # Restore $ra from the stack
            pop($a1)                                     # Restore $a1 from the stack
            pop($a0)                                     # Restore $a0 from the stack
            bne $t5, $t4, continue                       # If L != LL, continue with the loop
            beq $t6, $a1, exit                           # If (L == LL) && (R = RR) --> exit the loop 
            continue:
            nop
            addi $t1, $t1, 1                             # y += 1 (move down 1 row to draw the next horizontal line)
            b while                                      # Loop back up                   
        exit:                                            # End of loop
        nop
        pop($t6)                                         # Restore registers $t6-$t0 from the stack
        pop($t5)
        pop($t4)
        pop($t3)
        pop($t2)
        pop($t1)
        pop($t0)
        jr $ra                                           # Jump back to the caller function
	
#*****************************************************
#Given three coordinates, draws a triangle
#-----------------------------------------------------
# $a0 = coordinate of point A (x0,y0) format: (0x00XX00YY)
# $a1 = coordinate of point B (x1,y1) format: (0x00XX00YY)
# $a2 = coordinate of traingle point C (x2, y2) format: (0x00XX00YY)
# $a3 = color of line format: (0x00RRGGBB)
#-----------------------------------------------------
# Traingle should look like:
#               B
#             /   \
#            A --  C
#***************************************************	

#  PSEUDOCODE:
#  -----------
#  1. Draw a line from A to B (A --> B)
#  2. Draw a line from A to C (A --> C)
#  3. Draw a line from B to C (B --> C)

#  REGISTER USAGE:
#  ---------------
#  $a0: argument for function - coordinate of point A
#  $a1: argument for function - coordinate of point B
#  $a2: argument for function - coordinate of point C
#  $a3: argument for function - color of triangle
#  $ra: address of the instruction to return to

draw_triangle: nop
        push($a0)                       # Save registers $a0-$a3 onto the stack
        push($a1)                       
        push($a2)
        push($a3)
        move $a2, $a3                   # Set color input of draw_line to color of triangle
        push($ra)                       # Save $ra onto the stack
        jal draw_line                   # draw_line(A, B, color): A --> B
        pop($ra)                        # Restore $ra from the stack
        pop($a3)                        # Restore $a3 from the stack
        pop($a2)                        # Restore $a2 from the stack
        push($a2)                       # Save $a2 to the stack
        push($a3)                       # Save $a3 to the stack
        move $a1, $a2                   # Set second coordinate input of draw_line to C
        move $a2, $a3                   # Set color input of draw_line to color of triangle
        push($ra)                       # Save $ra onto the stack
        jal draw_line                   # draw_line(A, C, color): A --> C
        pop($ra)                        # Restore $ra from the stack
        pop($a3)                        # Restore $a3 from the stack
        pop($a2)                        # Restore $a2 from the stack
        pop($a1)                        # Restore $a1 from the stack
        push($a1)                       # Save $a1 onto the stack
        push($a2)                       # Save $a2 onto the stack
        push($a3)                       # Save $a3 onto the stack
        move $a0, $a1                   # Set first coordinate input of draw_line to B
        move $a1, $a2                   # Set second coordinate input of draw_line to C
        move $a2, $a3                   # Set color input of draw_line to color of triangle
        push($ra)                       # Save $ra onto the stack
        jal draw_line                   # draw_line(B, C, color): B --> C
        pop($ra)                        # Restore $ra from the stack
        pop($a3)                        # Restore $a3-$a0 from the stack
        pop($a2)
        pop($a1)
        pop($a0)  
	jr $ra	                        # Jump back to the caller function
	