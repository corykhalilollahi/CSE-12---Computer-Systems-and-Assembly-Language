
##########################################################################
# Created by:  Khalilollahi, Cory
#              ckhalilo
#              17 February 2020
#
# Assignment:  Lab 4: ASCII-risks (Asterisks)
#              CSE 012, Computer Systems and Assembly Language
#              UC Santa Cruz, Winter 2020
# 
# Description: This program prints a triangle of numbers, tabs, and 
#              asterisks based on user input
# 
# Notes:       This program is intended to be run from the MARS IDE.
##########################################################################


#  PSEUDOCODE:
#  -----------
# - promptLoop
#	-Prompt the user for a height greater than 1
#	-Store the input into a register - this register will be known as the variable “height”
#	-If the input is less than 1, jump to label “error”
#	-If the input is valid and not less than 1, jump to label “noError” 
# - error
#	- Print an error message
#	- Loop back to promptLoop to prompt again 
# - noError
#	- The height is valid, so continue on with the code
#	- Initialize some registers to prepare for the next loop
#	- Store value 1 into a register, which will be known as “count”
#	- Store value 1 into another register, which will be known as “i”
#	- Store the value (height + 1) into another register, which will be known as “height + 1”

# - outerLoop
#	- Check if i is equal to height + 1, and if it is, exit the loop by jumping to label “exit”
#	- If not, continue on with the following code
#	- Store the current value of i into a register, which will be known as “k”
#	- Store the value 0 into another register, which will be known as “j”
#	- Store the value (height - i) into another register, which will be known as “height - i”
#	- Jump to innerLoop1
# 	- printCount
#		- Return to this label after innerLoop1 is finished
#		- Print the current count
#		- Jump to innerLoop2
# 	- skipLine
#		- Return to this label after innerLoop2 is finished
#		- Print “\n”, skipping to the next line
#		- Increase count by 1
#		- Increase i by 1
#	- Repeat outerLoop by jumping to the start of outerLoop

# - innerLoop1
#	- If j is not less than height - i, exit the loop by jumping to label “endInnerLoop1”
#	- Print a single tab
#	- Increase j by 1
#	- Jump back up to the start of innerLoop1

# - innerLoop2
#	- If k is less than 2, exit the loop by jumping to endInnerLoop2
#	- Increase count by 1
#	- Print “[tab] * [tab]”
#	- Print count
#	- Decrease k by 1
#	- Jump back up to the start of innerLoop2

# - endInnerLoop1
#	- innerloop1 is finished, so return to the code in the main outerLoop by jumping to label “printCount”

# - endInnerLoop2
#	- innerloop2 is finished, so return to the code in the main outerLoop by jumping to label “skipLine”

# - exit
#	- outerLoop is finished, so the program is done
#	- Terminate the running program


#    REGISTER USAGE:
#    ---------------
#    $s0: user input - height of the triangle
#    $s1: variable - count
#    $s2: variable - i
#    $s3: variable - height + 1
#    $s4: variable - k
#    $t0: holds the value 1; used for ALU operation in promptLoop
#    $t1: holds either 0 or 1; used to check condition in promptLoop
#    $t2: variable - j
#    $t3: variable - (height - i)
#    $t4: holds either 0 or 1; used to check condition in innerLoop1
#    $t5: holds the value 2; used for ALU operation in innerLoop2
#    $t6: holds either 0 or 1; used to check condition in innerLoop2
#    $v0: used to declare syscall return values
#    $a0: used to store syscall arguments 
#    $zero: used for its value of 0


.data

    promptHeight: .asciiz "\nEnter the height of the triangle (must be greater than 0):  "
    errorMessage: .asciiz "Invalid entry! "
    newLine: .asciiz "\n"
    tab: .asciiz "\t"
    tabAndStar: .asciiz "\t*\t"

.text

    # This label loops until a valid height (integer > 0) is given by the user
    # If an invalid height is given, print an error message and prompt again
    # If a valid height is given, store it into a register
    promptLoop: nop
                li $v0, 4                        # Prompt user for height of triangle by printing a message
                la $a0, promptHeight
                syscall
                li $v0, 5                        # Get the height from user input
                syscall
                add $s0, $v0, $zero              # Store the height in $s0
                li $t0, 1                        # Store 1 into $t0
                slt $t1, $s0, $t0                # Stores 1 in $t1 if the height ($s0) is less than 1
                beq $t1, 1, error                # If the height is less than 1, an error occurs - branch to error label
                nop
                b noError                        # If the height is not less than 1, no error occurs, prompt loop ends
    
    # This label is called when an invalid height is given by the user
    # It prints a message and repeats the promptLoop
    error: nop
           li $v0, 4                             # print an error message
           la $a0, errorMessage                
           syscall
           j promptLoop                          # Repeat the prompt again until a valid height is entered
    
    # Serves as a label to jump to once the promptLoop is finished; continue on with program and initialize variables      
    noError: nop                                     
             li $s1, 1                           # Initialize count; store 1 into $s1
             li $s2, 1                           # Initialize i; store 1 into $s2 
             addi $s3, $s0, 1                    # Store (height + 1) into $s3
    
    # This label is the main loop of the program
    # Each iteration of this loop is prints one row of the pyramid
    # Consists of two inner loops and other commands to print everything needed in the row
    outerLoop: nop
               beq $s2, $s3, exit                # Once i reaches end of range (height + 1), end loop
               add $s4, $s2, $zero               # Initialize k; store i into $s4
               li $t2, 0                         # Initialize j; store 0 into $t2
               sub $t3, $s0, $s2                 # Store (height - i) into $t3
               b innerLoop1                      # Branch to innerLoop1, which prints centers the first character of each line
                
               # Serves as a label to jump back to after innerLoop1 finishes; also prints the current count once
               printCount:
                   li $v0, 1                     # Print the current count
                   add $a0, $s1, $zero
                   syscall
               
               b innerLoop2                      # Branch to innerLoop2, which prints the remaining characters of each line
               
               # Serves as a label to jump back to after innerLoop2 finishes; also skips to the next line 
               skipLine:
                   li $v0, 4                     # Print "\n", skipping to the next line
                   la $a0, newLine
                   syscall
               
               addi $s1, $s1, 1                  # count = count + 1
               addi $s2, $s2, 1                  # i = i + 1
               b outerLoop                       # The current line is completely finished, so loop back to the main outerLoop to print the next line
    
    # This label loops until the current row is centered properly
    # Repeatedly prints tabs (based on the current row) to center the first character
    innerLoop1: nop
                slt $t4, $t2, $t3                # Store 1 into $t4 if j less than (height - i)
                bne $t4, 1, endInnerLoop1        # If j is not less than (height - i), exit innerLoop1
                nop
                li $v0, 4                        # Print a single tab
                la $a0, tab
                syscall 
                addi $t2, $t2, 1                 # j = j + 1
                b innerLoop1                     # Repeat innerLoop1 until enough tabs are printed to correctly center the row
                
    # This label loops until the current row is correctly completed 
    # Repeatedly prints the appropriate amount of asterisks, tabs, and numbers (based on the current row)          
    innerLoop2: nop
                li $t5, 2                        # Store 2 into $t5
                slt $t6, $s4, $t5                # If k less than 2, store 1 into $t6
                beq $t6, 1, endInnerLoop2        # If k is less than 2, exit innerLoop2
                nop
                addi $s1, $s1, 1                 # count = count + 1
                li $v0, 4                        # Print "    *    "
                la $a0, tabAndStar
                syscall
                li $v0, 1                        # Print the current count
                add $a0, $s1, $zero
                syscall
                subi $s4, $s4, 1                 # k = k - 1
                b innerLoop2                     # Repeat innerLoop2 until the correct amount of tabs, asterisks, and counts are printed in the row
      
    # This label is called upon when innerLoop1 finishes and subsequently jumps back to the middle of the outerLoop     
    endInnerLoop1: nop
                   b printCount 
              
    # This label is called upon when innerLoop2 finishes and subsequently jumps back to the middle of the outerLoop                   
    endInnerLoop2: nop
                   b skipLine
      
    # This label is called upon when outerLoop finishes and terminates the program                                              
    exit: nop
    	  li $v0, 10
    	  syscall
    	  

          
                   
               
               
    	       
    
