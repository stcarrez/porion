#include <stdio.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <termios.h>

int porion_get_cols() 
{
   struct winsize size;
   
   if (ioctl(STDIN_FILENO, TIOCGWINSZ, &size) != 0) 
     {
        return -1;
     }
   
   return size.ws_col;
}

int porion_get_rows() 
{
   struct winsize size;
   
   if (ioctl(STDIN_FILENO, TIOCGWINSZ, &size) != 0) 
     {
        return -1;
     }
   
   return size.ws_row;
}

   