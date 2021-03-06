/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-22
*/

//SPDX-License-Identifier: Unlicensed

pragma solidity >=0.8.4;

contract Helloyay {
    /*
  ⢀⣴⣶⣶⣶⣶⣶⠄⠀⠀⠀⠀⠀⠀⢶⣦⠀⠀⣴⡶⠀⠀⠀⠀⠀⠀⠀⣴⣶⣶⣶⣶⣶⡆⠀⠀⠀⠀⠀⠀⣴⣦⡀⠀⠀⢰⡆⠀⠀⠀⠀⠀⠀⢰⡆⠀⠀⠀⢠⣶⠀⠀⠀⠀⠀⠀⢠⣶⣶⣶⣶⣶⣶⠀⠀⠀⠀
⠀⠀⢸⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠻⣷⣾⠟⠀⠀⠀⠀⠀⠀⠀⠀⣿⠀⠀⠀⣤⣤⡄⠀⠀⠀⠀⠀⠀⣿⡟⢿⣦⠀⢸⡇⠀⠀⠀⠀⠀⠀⢸⡇⠀⠀⠀⢸⣿⠀⠀⠀⠀⠀⠀⢸⣧⣤⣤⣤⣤⣀⠀⠀⠀⠀
⠀⠀⢸⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢹⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⡀⠀⠀⠉⣹⡇⠀⠀⠀⠀⠀⠀⣿⡇⠀⠙⢷⣼⡇⠀⠀⠀⠀⠀⠀⢸⡇⠀⠀⠀⢸⣿⠀⠀⠀⠀⠀⠀⠀⠉⠉⠉⠉⢉⣿⠀⠀⠀⠀
⠀⠀⠀⠛⠛⠛⠛⠛⠛⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⠛⠛⠛⠛⠛⠃⠀⠀⠀⠀⠀⠀⠛⠃⠀⠀⠀⠙⠃⠀⠀⠀⠀⠀⠀⠈⠛⠛⠛⠛⠛⠋⠀⠀⠀⠀⠀⠀⠘⠛⠛⠛⠛⠛⠋⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣄⠀⢀⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣄⠀⢀⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⠀⠀⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⢸⣿⣿⠿⠿⠿⠿⠿⠿⣿⣿⣿⠀⢸⣿⣿⣿⣿⡿⠿⣿⣿⣿⣿⣿⠀⢸⣿⣿⣿⠿⠿⠿⠿⠿⢿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⢸⣿⣿⠀⢠⣤⣤⣤⠀⢸⣿⣿⠀⢸⣿⣿⣿⣿⠁⠀⠸⣿⣿⣿⣿⠀⢸⣿⣿⡇⢠⣤⣤⣤⡄⠈⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⢸⣿⣿⠀⢸⣿⣿⣿⠀⢸⣿⣿⠀⢸⣿⣿⣿⠃⢠⣷⠀⠹⣿⣿⣿⠀⢸⣿⣿⡇⢸⣿⣿⣿⡇⠀⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⡟⠛⣿⣿⣿⣿⣿⠀⢸⣿⣿⠀⠈⠉⠉⠉⠀⣸⣿⣿⠀⢸⣿⣿⠏⢀⣀⣀⣀⠀⢻⣿⣿⠀⢸⣿⣿⡇⠈⠉⠉⠉⠁⢀⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠁⠀⠈⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠀⠀⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠀⠀⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠀⠀⠀⠀⠀⠀⠀`

                                           
             ░█▀▀█ █──█ █▀▀▀ █▀▀▄ █──█ █▀▀ 
             ░█─── █▄▄█ █─▀█ █──█ █──█ ▀▀█ 
             ░█▄▄█ ▄▄▄█ ▀▀▀▀ ▀──▀ ─▀▀▀ ▀▀▀ 


            *                                                                                      
          * ***                                                                       
        *  ****  *                                                                    
       *  *  ****                                                                     
      *  **   **                                                                      
     *  ***        **   ****                                 **   ****        ****    
    **   **         **    ***  *      ****      ***  ****     **    ***  *   * **** * 
    **   **         **     ****      *  ***  *   **** **** *  **     ****   **  ****  
    **   **         **      **      *    ****     **   ****   **      **   ****       
    **   **         **      **     **     **      **    **    **      **     ***      
    **   **         **      **     **     **      **    **    **      **       ***    
     **  **         **      **     **     **      **    **    **      **         ***  
      ** *      *   **      **     **     **      **    **    **      **    ****  **  
       ***     *     *********     **     **      **    **     ******* **  * **** *   
        *******        **** ***     ********      ***   ***     *****   **    ****    
          ***                ***      *** ***      ***   ***                          
                      *****   ***          ***                                        
                    ********  **     ****   ***                                       
                   *      ****     *******  **                                        
                                  *     ****
                            echo "  ______                                                  ";
 /      \                                                   
|  $$$$$$\ __    __   ______   _______   __    __   _______ 
| $$   \$$|  \  |  \ /      \ |       \ |  \  |  \ /       \
| $$      | $$  | $$|  $$$$$$\| $$$$$$$\| $$  | $$|  $$$$$$$
| $$   __ | $$  | $$| $$  | $$| $$  | $$| $$  | $$ \$$    \ 
| $$__/  \| $$__/ $$| $$__| $$| $$  | $$| $$__/ $$ _\$$$$$$\
 \$$    $$ \$$    $$ \$$    $$| $$  | $$ \$$    $$|       $$
  \$$$$$$  _\$$$$$$$ _\$$$$$$$ \$$   \$$  \$$$$$$  \$$$$$$$ 
          |  \__| $$|  \__| $$                              
           \$$    $$ \$$    $$                              
            \$$$$$$   \$$$$$$
            
   █████████                                                   
  ███░░░░░███                                                  
 ███     ░░░  █████ ████  ███████ ████████   █████ ████  █████ 
░███         ░░███ ░███  ███░░███░░███░░███ ░░███ ░███  ███░░  
░███          ░███ ░███ ░███ ░███ ░███ ░███  ░███ ░███ ░░█████ 
░░███     ███ ░███ ░███ ░███ ░███ ░███ ░███  ░███ ░███  ░░░░███
 ░░█████████  ░░███████ ░░███████ ████ █████ ░░████████ ██████ 
  ░░░░░░░░░    ░░░░░███  ░░░░░███░░░░ ░░░░░   ░░░░░░░░ ░░░░░░  
               ███ ░███  ███ ░███                              
              ░░██████  ░░██████                               
               ░░░░░░    ░░░░░░

 ███████████  ███                                                   
░░███░░░░░░█ ░░░                                                    
 ░███   █ ░  ████  ████████    ██████   ████████    ██████   ██████ 
 ░███████   ░░███ ░░███░░███  ░░░░░███ ░░███░░███  ███░░███ ███░░███
 ░███░░░█    ░███  ░███ ░███   ███████  ░███ ░███ ░███ ░░░ ░███████ 
 ░███  ░     ░███  ░███ ░███  ███░░███  ░███ ░███ ░███  ███░███░░░  
 █████       █████ ████ █████░░████████ ████ █████░░██████ ░░██████ 
░░░░░       ░░░░░ ░░░░ ░░░░░  ░░░░░░░░ ░░░░ ░░░░░  ░░░░░░   ░░░░░░

 .--.                         .---.                         
:                             |    o                        
|    .  . .-...--. .  . .--.  |--- .  .--. .-.  .--. .-..-. 
:    |  |(   ||  | |  | `--.  |    |  |  |(   ) |  |(  (.-' 
 `--'`--| `-`|'  `-`--`-`--'  '  -' `-'  `-`-'`-'  `-`-'`--'
        ; ._.'                                              
     `-'                                                    

                                  █                     
███                       ███                       
█   █ █ ███ ███ █ █ ███   █   █ ███ ███ ███ ███ ███ 
█   █ █ █ █ █ █ █ █ █     ███ █ █ █   █ █ █ █   ███ 
█   █ █ █ █ █ █ █ █   █   █   █ █ █ ███ █ █ █   █   
███ ███ ███ █ █ ███ ███   █   █ █ █ ███ █ █ ███ ███ 
      █   █                                         
    ███ ███




    */
    uint256 public hi = 12;
}