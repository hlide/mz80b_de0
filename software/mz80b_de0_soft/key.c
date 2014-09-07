/*
 * MZ-80C on FPGA (Altera DE0 version)
 * PS/2 Keyboard Input routines
 *
 * (c) Nibbles Lab. 2012-2014
 *
 */

#include "system.h"
#include "io.h"
#include "altera_avalon_pio_regs.h"
#include "sys/alt_irq.h"
#include "key.h"
#include "mzctrl.h"

// Key Code -> ASCII Code table
unsigned char kcconv[2][128]=
   {{0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x09,0x00,0x00,
     0x00,0x00,0x00,0x00,0x00,0x71,0x31,0x00,0x00,0x00,0x7a,0x73,0x61,0x77,0x32,0x00,
	 0x00,0x63,0x78,0x64,0x65,0x34,0x33,0x00,0x00,0x20,0x76,0x66,0x74,0x72,0x35,0x00,
	 0x00,0x6e,0x62,0x68,0x67,0x79,0x36,0x00,0x00,0x00,0x6d,0x6a,0x75,0x37,0x38,0x00,
	 0x00,0x2c,0x6b,0x69,0x6f,0x30,0x39,0x00,0x00,0x2e,0x2f,0x6c,0x3b,0x70,0x2d,0x00,
	 0x00,0x5c,0x3a,0x00,0x40,0x5e,0x00,0x00,0x00,0x00,0x0d,0x5b,0x00,0x5d,0x00,0x00,
	 0x00,0x00,0x00,0x00,0x00,0x00,0x08,0x00,0x00,0x00,0x5c,0x1d,0x00,0x00,0x00,0x00,
	 0x00,0x7f,0x1f,0x00,0x1c,0x1e,0x1b,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00},
    {0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x09,0x00,0x00,
     0x00,0x00,0x00,0x00,0x00,0x51,0x21,0x00,0x00,0x00,0x5a,0x53,0x41,0x57,0x22,0x00,
     0x00,0x43,0x58,0x44,0x45,0x24,0x23,0x00,0x00,0x20,0x56,0x46,0x54,0x52,0x25,0x00,
     0x00,0x4e,0x42,0x48,0x47,0x59,0x26,0x00,0x00,0x00,0x4d,0x4a,0x55,0x27,0x28,0x00,
     0x00,0x3c,0x4b,0x49,0x4f,0x00,0x29,0x00,0x00,0x3e,0x3f,0x4c,0x2b,0x50,0x3d,0x00,
     0x00,0x5f,0x2a,0x00,0x60,0x7e,0x00,0x00,0x00,0x00,0x0d,0x7b,0x00,0x7d,0x00,0x00,
     0x00,0x00,0x00,0x00,0x00,0x00,0x08,0x00,0x00,0x00,0x7c,0x1d,0x00,0x00,0x00,0x00,
     0x00,0x7f,0x1f,0x00,0x1c,0x1e,0x1b,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00}};
//      0    1    2    3    4    5    6    7    8    9    a    b    c    d    e    f

extern volatile z80_t z80_sts;
int pushed;	// Push Flag

/*
 * Get 1 character
 */
unsigned char get_key(void)
{
	unsigned char c=0,k;

	while(z80_sts.rptr!=z80_sts.wptr){
		k=z80_sts.kcode[z80_sts.rptr++];
		z80_sts.rptr=z80_sts.rptr&0x1f;
		switch(k){
		case 0xf0:
			z80_sts.flagf0=1;	// Break Code
			break;
		case 0xe0:
			z80_sts.flage0=1;	// Extended Code
			break;
		case 0x12:		// Left Shift Key
			if(z80_sts.flage0==0){
				if(z80_sts.flagf0){
					z80_sts.Lshift=0;
				}else{
					z80_sts.Lshift=1;
				}
			}
			z80_sts.flagf0=0;
			z80_sts.flage0=0;
			break;
		case 0x59:		// Right Shift Key
			if(z80_sts.flage0==0){
				if(z80_sts.flagf0){
					z80_sts.Rshift=0;
				}else{
					z80_sts.Rshift=1;
				}
			}
			z80_sts.flagf0=0;
			z80_sts.flage0=0;
			break;
		default:		// Convert to ASCII
			if(z80_sts.flagf0==0){
				c=kcconv[z80_sts.Lshift|z80_sts.Rshift][k];
				pushed=1;
			}else{
				pushed=0;
			}
			z80_sts.flagf0=0;
			z80_sts.flage0=0;
			break;
		}
		if(c) break;
	}

	return(c);
}

/*
 * Pre-Input Keys
 */
void key0(unsigned char *kdata)
{
	while(*kdata!='\0'){
		z80_sts.kcode[z80_sts.wptr++]=*(kdata++);
		z80_sts.wptr=z80_sts.wptr&0x1f;
	}
}

/*
 * Clear Key Buffer
 */
void keybuf_clear(void)
{
	while(pushed!=0){
		get_key();
	}
}
