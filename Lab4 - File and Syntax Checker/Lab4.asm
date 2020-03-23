
##########################################################################
# Created by:  Khalilollahi, Cory
#              ckhalilo
#              1 March 2020
#
# Assignment:  Lab 4: Syntax Checker
#              CSE 012, Computer Systems and Assembly Language
#              UC Santa Cruz, Winter 2020
# 
# Description: This program reads a file and checks for correct syntax.
# 
# Notes:       This program is intended to be run from the MARS IDE.
##########################################################################

#  PSEUDOCODE:
#  -----------
#  1. Check the file name to ensure that it is a valid input
#     - printFile:
#           - Access the file name by loading the word in $a1 (default register for program arguments)
#	    - Print the file name
#     - check_First:
# 	    - Check the first character of the file name
#	    - If the first character is a letter (test using ASCII ranges), then continue with no error
# 	    - Else, raise an "Invalid Program Argument" error
#     - check_Loop:
#           - Iterate through each character (byte) of the file name to check for correct syntax
#	    - Raise an error if the current character is not a letter, number, ., or _
#           - Keep track of the number of characters, and increment it by 1 at every iteration
#           - If this count goes above 20, the file name is too long, so raise an error
#     - If the file name is valid, proceed to open the file using syscall 13
#
#  2. Check the file contents to ensure it contains correct syntax
#     - Initialize three varaibles before loop:
#           - fileIndex ($t0): current index of the file contents - one for each character
#           - initSP ($t1): memory address that the stack pointer initially held before the loop
#           - numBraces ($s0): number of pairs of braces that the file contains
#     - read_File:
#           - Use syscall 14 to read the opened file
#	    - If the size of the buffer (amount of characters read) is equal to 0, then exit the loop
#           - If not, read the contents of the file and proceed with code
#           - Store the memory address of the buffer
#           - Initialize a variable bufferCount ($s2) to keep track of our place within the buffer
#     - buffer_Loop:
#           - If bufferCount ever reaches above the size of the buffer, exit the loop
#	    - Initialize a variable ($t2) that contains the address of the previous stack pointer location ($sp + 4)
#           - Load the first byte of the current buffer address
#           - check_Open:
#                 - Check if the current character (byte) is a (, [, or {
#		  - If it is:
#                       - Push the current fileIndex onto the stack
#                       - Push the current character onto the stack
#                 - If not, then continue on with code
#           - check_Closed:
#                 - Check if the current character is a ), ], or }
# 		  - If it is, then compare it to the highest character already on the stack
#                       - If the current character matches with the highest character on the stack (ex: [ and ]):
#                             - Pop the highest character from the stack
#                             - Pop the matching fileIndex of that character from the stack
#                       - If the stack is empty, then the current character is an extra brace, so raise an "Mismatch" error with only one input
#                         brace and terminate the program 
#                       - If the current character mismatches with the highest character on the stack (Ex: [ and }), then 
#                         raise a "Mismatch" error with two output braces and terminate the program
#           - update_Loop:
#	          - Increment fileIndex by 1 
#                 - Increment bufferCount by 1
#                 - Increment the current memory address within the buffer by 1 (this allows you to look at the next character)
#           - exit_Loop:
#                 - If the size of the buffer is 128, then jump back to read_File to check the rest of the file contents
#                 - If the size of the buffer is less than 128, then the entire file has been read and the loop can now end
#                 - If initSP is not equal to the current $sp, then there are still open braces left on the stack, so:
#                       - Raise a "Still on Stack" error
#                       - Print the braces that are still on the stack
#                 - If initSP is equal to the current $sp, then the file contains complete syntax and the program is successful, so:
#                       - Print a "Success" message
#                       - Use numBraces to print the number of pairs of braces that were read in the file
#                       - Terminate the program
#
#  REGISTER USAGE:
#  ---------------
#  $s0: contains the number of pairs of braces read in the file
#  $s2: contains the buffer index
#  $s5: contains the number of characters read from the file (the size of the buffer)
#  $s6: contains the file descriptor from syscall 13
#  $t0: 
#      File Name Check: contains the address of the file name
#      Buffer Check: contains the file index
#  $t1: 
#      File Name Check: contains the first character of the file name, and then, the count of the characters in the file name
#      Buffer Check: contains the memory address of the initial stack pointer before the loop
#  $t2: 
#      File Name Check: contains the count of characters in the file name
#      Buffer Check: contains the memory address of the previous stack pointer ($sp + 4)
#  $t3: 
#      File Name Check: contains various immediate values
#      Buffer Check: contains the current memory address within the buffer
#  $t4: contains the current character (byte)
#  $t5: contains the character of the previous stack pointer location (character that $t2 points to)
#  $t6: contains various immediate values
#  $t7: contains the open brace characters when looping through potential braces that are still on the stack
#  $v0: contains syscall parameters and sycall return values such as the file descriptor and number of characters read 
#  $a0: contains syscall arguments
#  $a1: contains the memory address of the program argument (file name)


.data
    buffer: .space 128
    fileMessage: .asciiz "You entered the file:\n"
    errorMessage: .asciiz "\nERROR: Invalid program argument.\n"
    errorBraceMismatch1: .asciiz "\nERROR - There is a brace mismatch: "
    errorBraceMismatch2: .asciiz " at index "
    errorExtraOpen: .asciiz "\nERROR - Brace(s) still on stack: "
    successMessage1: .asciiz "\nSUCCESS: There are "
    successMessage2: " pairs of braces.\n"
    space: .asciiz " "
    nextLine: .asciiz "\n"
    
.text
main:
    print_File:
        nop
        li $v0, 4
        la $a0, fileMessage
        syscall                                   # Print "You entered the file: "
        lw $t0, ($a1)                             # Load the address of the file name, which is stored in $a1
        li $v0, 4                                 # Print the string found in that memory address
        la $a0, ($t0)
        syscall
        li $v0, 4                                 # Print "\n" to go the next line
        la $a0, nextLine
        syscall

    check_First:                                  # Checks the first letter of the file name to ensure it is a letter
        nop                                        
        lb $t1, ($t0)                             # Load the first byte of the file name
        li $t3, 65
        blt $t1, $t3, error                       # Uses ASCII table to check for letters, and if it isn't, raise an error
        li $t2, 97
        blt $t1, $t3, error                       # Uses ASCII table to check for letters, and if it isn't, raise an error
                           
    check_Loop:                                   # Check every character of the file name
        nop                                   
        init:
            nop
            li $t2, 0                             # Keeps track of the number of characters in the file name
        check_Loop_Body:
            nop
            lb $t1, ($t0)                         # Load the first byte of the current memory address into $t1
            beq $t1, 0, exit_Check                # Check if the end of file name has been reached
            bgt $t2, 20, error                    # If the file name goes above 20 characters, raise an error
            b check_Period                        # Check if the current character is an invalid character
        update: 
            nop
            addi $t0, $t0, 1                      # Increment the current memory address by 1 to move on to next byte (character)
            addi $t2, $t2, 1                      # Increment the file name length by 1
            b check_Loop_Body                     # Loop back up
     
    # Sequence of helper methods that use the ASCII table to check if the current character is invalid   
                
    check_Period:                                 # Checks if the current character is a period                                                      
        nop
        li $t3, 46
        blt $t1, $t3, error                       # If it is not a period, raise an error
        li $t3, 47
        blt $t1, $t3, update                      # If it is, go back to the loop
            
    check_Number:                                 # Checks if the current character is a number
        nop
        li $t3, 48
        blt $t1, $t3, error                       # If it is not a number, raise an error
        li $t3, 58
        blt $t1, $t3, update                      # If it is, go back to the loop
        
    check_Upper:                                  # Checks if the current character is an uppercase letter
        nop
        li $t3, 65
        blt $t1, $t3, error                       # If it is not a uppercase letter, raise an error
        li $t3, 91                                
        blt $t1, $t3, update                      # If it is, go back to the loop
        
    check_Underscore:                             # Checks if the current character is an underscore
        nop
        li $t3, 95
        blt $t1, $t3, error                       # If it is not an underscore, raise an error
        li $t3, 96
        blt $t1, $t3, update                      # If it is, go back to the loop
        
    check_Lower:                                  # Checks if the current character is a lowercase letter
        nop
        li $t3, 97
        blt $t1, $t3, error                       # If it is not a lowercase letter, raise an error
        li $t3, 122
        bgt $t1, $t3, error                       
        b update                                  # If it is, go back to the loop
                      
    exit_Check:                                   # Check loop has been exited and the file name is valid, so proceed to open the file
        nop
        b open_File
                     
    error:                                        # Called if file name is invalid
        nop
        li $v0, 4
        la $a0, errorMessage
        syscall                                   # Print an error message
        b terminate                               # End the program
          
    open_File:                                    # Uses syscall 13 to open the file
        nop
        li $v0, 13
        lw $a0, ($a1)
        li $a1, 0
        li $a2, 0
        syscall
        move $s6, $v0                             # Move the file descriptor return value into $s6 to later use in the read file syscall
     
     check_Buffer:                                # Main buffer and stack loop
         nop
         initialize:
             nop
             li $t0, 0                            # Index of each character from text file
             la $t1, ($sp)                        # Stores the initial stack pointer location
             li $s0, 0                            # Number of pairs of braces
         read_File:                               # Uses syscall 14 to read the file; called upon repeatedly until entire file has been read
             nop
             li $v0, 14
             move $a0, $s6
             la $a1, buffer
             li $a2, 128
             syscall
             move $s5, $v0                        # Keep track of the number of characters read during syscall (size of buffer)
             beq $s5, 0, exit_Loop                # If no characters were read during the syscall, then exit the loop
             li $s2, 0                            # Buffer index
             la $t3, buffer                       # Current memory address of buffer (will increase during loop to check every character)
         buffer_Loop:
             nop
             bgt $s2, $s5, exit_Loop              # Check if end of buffer has been reached
             addi $t2, $sp, 4                     # Stores the previous stack pointer location
             lb $t4, ($t3)                        # Load current byte based on the current buffer memory address
               
         check_Open:                              # If current byte is (, [, or {, then push the index and character onto the stack
             nop
             beq $t4, 40, push                    # Checks for (
             beq $t4, 91, push                    # Checks for [
             beq $t4, 123, push                   # Checks for {

         check_Closed:                            # If current byte is ), ], or }, compare it to the character of the top of the stack
             nop
             beq $t4, 41, compare_Parentheses     # Checks for )
             beq $t4, 93, compare_Brackets        # Checks for ]
             beq $t4, 125, compare_Braces         # Checks for }
         
         update_Loop:                             # Update variables
             nop
             addi $t0, $t0, 1                     # Increment the file index by 1
             addi $s2, $s2, 1                     # Increment the buffer index by 1
             addi $t3, $t3, 1                     # Increment the current memory address within the buffer
             b buffer_Loop
             
         push:                                    # Helper method that pushes the file index and character onto the stack
             nop
             sw $t0, ($sp)                        # Push file index onto stack
             addi $sp, $sp, -4                    # Move up 1 level in the stack
             sw $t4, ($sp)                        # Push character onto stack
             addi $sp, $sp, -4                    # Move up 1 level in the stack
             addi $s0, $s0, 1                     # Increment the number of pairs of braces by 1
             b update_Loop                        # Go back to loop
             
         compare_Parentheses:                     # Helper method that compares a ) to the previous character on the stack
             nop
             lb $t5, ($t2)                        # Store the character from the previous stack location into $t5
             li $t6, 40                   
             beq $t5, $t6, pop                    # If the previous byte is (, then pop the ( and its matching index off the stack
             bgt $t2, $t1, extra_Closed           # If the stack is empty, then give the mismatch error with one brace output
             b mismatch                           # If the previous byte is [ or {, then give the mismatch error with two brace outputs
             
         compare_Brackets:                        # Helper method that compares a ] to the previous character on the stack
             nop
             lb $t5, ($t2)                        # Store the character from the previous stack location into $t5
             li $t6, 91     
             beq $t5, $t6, pop                    # If the previous byte is [, then pop the [ and its matching index off the stack
             bgt $t2, $t1, extra_Closed           # If the stack is empty, then give the mismatch error with one brace output
             b mismatch                           # If the previous byte is ( or {, then give the mismatch error with two brace outputs
             
         compare_Braces:                          # Helper method that compares a } to the previous character on the stack
             nop
             lb $t5, ($t2)                        # Store the character from the previous stack location into $t5
             li $t6, 123                          
             beq $t5, $t6, pop                    # If the previous byte is {, then pop the { and its matching index off the stack
             bgt $t2, $t1, extra_Closed           # If the stack is empty, then give the mismatch error with one brace output
             b mismatch                           # If the previous byte is ( or [, then give the mismatch error with two brace outputs
                
         pop:                                     # Helper method that pops a character and index off the stack
             nop
             addi $sp, $sp, 8                     # Move down 2 levels in the stack
             b update_Loop
             
         extra_Closed:                            # Mismatch error with one brace output
             nop
             li $v0, 4 
             la $a0, errorBraceMismatch1
             syscall                              # Print "ERROR - There is a brace mismatch: "
             li $v0, 11                           
             move $a0, $t4
             syscall                              # Print current incorrect brace
             li $v0, 4
             la $a0, errorBraceMismatch2
             syscall                              # Print " at index "
             li $v0, 1                            
             move $a0, $t0
             syscall                              # Print the current index of the incorrect brace
             li $v0, 4
             la $a0, nextLine
             syscall                              # Print "\n" to go to the next line
             b terminate                          # End the program
             
         mismatch:                                # Mismatch error with two brace outputs
             nop
             li $v0, 4 
             la $a0, errorBraceMismatch1
             syscall                              # Print "ERROR - There is a brace mismatch: "
             li $v0, 11                           
             move $a0, $t5
             syscall                              # Print the left mismatched brace - (, [, or {
             li $v0, 4
             la $a0, errorBraceMismatch2
             syscall                              # Print " at index "
             addi $t2, $t2, 4                     # move $t2 1 level lower to get the index
             lw $t5, ($t2)                        # Load the index into $t5
             li $v0, 1
             move $a0, $t5
             syscall                              # Print the index of the left mismatched brace
             li $v0, 4
             la $a0, space
             syscall                              # Print " " 
             li $v0, 11                           
             move $a0, $t4
             syscall                              # Print the right mismatched brace - ), ], or }
             li $v0, 4
             la $a0, errorBraceMismatch2
             syscall                              # Print " at index "
             li $v0, 1                            
             move $a0, $t0
             syscall                              # Print index of the right mismatched brace (current index)
             li $v0, 4
             la $a0, nextLine
             syscall                              # Print "\n" to go to the next line
             b terminate                          # End the program
             
         exit_Loop:                               # All characters in the buffer have been checked with no close brace errors
             nop
             beq $s5, 128, read_File              # If the buffer size was 128, read the file again to check for remaining characters in the file
             bne $sp, $t1, extra_Open             # If the current stack pointer isnt equal to the initial stack pointer, 
                                                  # there must still be extra braces left on the stack, so raise the "Extra Open" error
                                                  # If the current stack pointer is equal to the initial stack pointer, then the program is successful
             li $v0, 4                            
             la $a0, successMessage1
             syscall                              # Print "SUCCESS: There are "  
             li $v0, 1
             move $a0, $s0
             syscall                              # Print the number of pairs of braces
             li $v0, 4
             la $a0, successMessage2
             syscall                              # Print " pairs of braces."
             b terminate                          # End the program
             
         extra_Open:                              # Braces still on stack error
              nop
              li $v0, 4
              la $a0, errorExtraOpen
              syscall                             # Print "ERROR - Brace(s) still on stack: "
              extra_Open_loop:                    # Loop through the stack to print each open brace
                  nop
                  beq $t1, $sp, exit_Extra_Open   # If the stack is empty, exit this loop
                  addi $sp, $sp, 4                # Move 1 level down the stack
                  lb $t7, ($sp)                   # Load the byte at the current stack pointer into $t7
                  li $v0, 11
                  move $a0, $t7
                  syscall                         # Print the character on the top of the stack
                  addi $sp, $sp, 4                # Move 1 level down the stack to skip
                  b extra_Open_loop               # Loop back up
              exit_Extra_Open:                    # Exiting the loop
                  nop
                  li $v0, 4
                  la $a0, nextLine
                  syscall                         # Print "\n" to go to the next line
                  b terminate                     # End the program
                                                                
    terminate: 
        nop
        li $v0, 10                                # Terminates the program
    
              
  
              
    
              
       
              
                
        
