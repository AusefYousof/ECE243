/* This files provides address values that exist in the system */

#define SDRAM_BASE            0xC0000000
#define FPGA_ONCHIP_BASE      0xC8000000
#define FPGA_CHAR_BASE        0xC9000000

/* Cyclone V FPGA devices */
#define LEDR_BASE             0xFF200000
#define HEX3_HEX0_BASE        0xFF200020
#define HEX5_HEX4_BASE        0xFF200030
#define SW_BASE               0xFF200040
#define KEY_BASE              0xFF200050
#define TIMER_BASE            0xFF202000
#define PIXEL_BUF_CTRL_BASE   0xFF203020
#define CHAR_BUF_CTRL_BASE    0xFF203030

/* VGA colors */
#define WHITE 0xFFFF
#define YELLOW 0xFFE0
#define RED 0xF800
#define GREEN 0x07E0
#define BLUE 0x001F
#define CYAN 0x07FF
#define MAGENTA 0xF81F
#define GREY 0xC618
#define PINK 0xFC18
#define ORANGE 0xFC00

#define ABS(x) (((x) > 0) ? (x) : -(x))

/* Screen size. */
#define RESOLUTION_X 320
#define RESOLUTION_Y 240

/* Constants for animation */
#define BOX_LEN 2
#define NUM_BOXES 8

#define FALSE 0
#define TRUE 1

#include <stdlib.h>
#include <stdio.h>

// Begin part1.s for Lab 7

volatile int pixel_buffer_start; // global variable
void draw_line (int x0,int y0,int x1,int y1,int line_colour);
void clear_screen();
int main(void)
{
    volatile int * pixel_ctrl_ptr = (int *)0xFF203020;// front pixel buffer adress
    /* Read location of the pixel buffer from the pixel buffer controller */
    pixel_buffer_start = *pixel_ctrl_ptr;

    clear_screen();
    draw_line(0, 0, 150, 150, 0x001F);   // this line is blue
    draw_line(150, 150, 319, 0, 0x07E0); // this line is green
    draw_line(0, 239, 319, 239, 0xF800); // this line is red
    draw_line(319, 0, 0, 239, 0xF81F);   // this line is a pink color
}

// code not shown for clear_screen() and draw_line() subroutines

void plot_pixel(int x, int y, short int line_color)
{
    *(short int *)(pixel_buffer_start + (y << 10) + (x << 1)) = line_color;
}

void draw_line (int x0,int y0,int x1,int y1,int line_colour){
	
	int deltax;
	int deltay;
	int error;
	int current_y;
	int is_steep;
	
	deltax=x1-x0;
	int absdeltax=ABS(deltax);
	
	int deltay_step=y1-y0;
	deltay=ABS(deltay_step);
	
	if(deltay>absdeltax){//line3 in suedo code
		is_steep =TRUE;
		int temp;
		temp=x0;
		x0=y0;
		y0=temp;
		temp=x1;
		x1=y1;
		y1=temp;
	
	}else{
		is_steep=FALSE;
	}
	if(x0>x1){//line6 in suedo code
		int temp;
		temp=x0;
		x0=x1;
		x1=temp;
		temp=y0;
		y0=y1;
		y1=temp;
	}

	
	error=( (-1)*(deltax/2) );
	int y_step=-1;
	current_y=y0;
	
	if (y0<y1){
		y_step=1;
	}
	
	for(int current_x=x0;current_x<=x1;current_x++){
		if (is_steep){
			plot_pixel(current_y,current_x,line_colour);
		}else{
			plot_pixel(current_x,current_y,line_colour);
		}
		error= error+deltay;
		if(error>0){
			current_y=current_y+y_step;
			error = (error-deltax);
		
		}
	}
	
}


void clear_screen(){

	volatile int * current_pixel_ptr;
	
	for (int x=0;x<RESOLUTION_X;x++){	
		for(int y=0;y<RESOLUTION_Y;y++){
			*(short int *)(pixel_buffer_start + (y << 10) + (x << 1)) = 0x00;
		
		}
	}


}

