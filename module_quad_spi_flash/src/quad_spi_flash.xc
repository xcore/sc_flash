#include "quad_spi_flash.h"
#include <stdio.h>
#include <print.h>

#define CS_HI 0xf
#define CS_LO 0xb
#define INST_MASK 0xaaaaaaaa

#define DELAY 12

#define MIN_CLOCKS_BETWEEN_INSTRUCTIONS 14

#define ZIP(x) \
       ( (x&0x01)<<(28 - 0) \
        |(x&0x02)<<(24 - 1) \
        |(x&0x04)<<(20 - 2) \
        |(x&0x08)<<(16 - 3) \
        |(x&0x10)<<(12 - 4) \
        |(x&0x20)<<(8  - 5) \
        |(x&0x40)>>(6  - 4) \
        |(x&0x80)>>(7  - 0) )

static unsigned char do_to_byte(unsigned x){
    unsigned t = x&0x22222222;
    t = (t>>1)|(t>>4)|(t>>7)|(t>>10);
    t&=0x000f000f;
    t=t|(t>>12);
    return t&0xff;
}

static void quad_spi_flash_quad_enable(quad_spi_ports &p){
    unsigned time;
    p.CS <: CS_HI @ time;
    time += DELAY;
    p.CS @ time <: CS_LO;
    p.DQ @ time <: ZIP(0x01) | INST_MASK;
    p.CS @ time + 24 <: CS_HI;
    p.DQ <: 0x00000000 | INST_MASK;
    p.DQ <: 0x01000000 | INST_MASK;
    p.DQ <: INST_MASK;
}

void quad_spi_flash_write_enable(quad_spi_ports &p){
    unsigned time;
    p.CS <: CS_HI @ time;
    time += DELAY;
    p.CS @ time <: CS_LO;
    p.DQ @ time <: ZIP(0x06)|INST_MASK;
    p.CS @ time + 8 <: CS_HI;
    //p.DQ <: INST_MASK;
}

void quad_spi_flash_init(quad_spi_ports &p){
    if (!p.initialised){
        configure_clock_ref(p.cb, 1);
        configure_out_port(p.DQ, p.cb, 0xf);
        configure_out_port(p.CS, p.cb, CS_HI);
        configure_port_clock_output(p.CLK, p.cb);
        start_clock(p.cb);
        p.initialised = ~0;
    }
    quad_spi_flash_write_enable(p);
    quad_spi_flash_quad_enable(p);
    quad_spi_wait_until_idle(p);
}

void quad_spi_flash_chip_erase(quad_spi_ports &p){
    quad_spi_flash_write_enable(p);
    unsigned time;
    p.CS <: CS_HI @ time;
    time += DELAY;
    p.CS @ time <: CS_LO;
    p.DQ @ time <: ZIP(0xc7)|INST_MASK;
    p.CS @ time + 8 <: CS_HI;
    p.DQ <: INST_MASK;
}

static void erase(quad_spi_ports &p, unsigned inst, unsigned address){

    unsigned a_msb = ZIP((address>>16)&0xff) | INST_MASK;
    unsigned a     = ZIP((address>> 8)&0xff) | INST_MASK;
    unsigned a_lsb = ZIP((address>> 0)&0xff) | INST_MASK;
    unsigned time;

    quad_spi_flash_write_enable(p);

    asm(""::"r"(a_msb), "r"(a), "r"(a_lsb));
    p.CS <: CS_HI @ time;
    time += DELAY;
    p.CS @ time <: CS_LO;
    p.DQ @ time <: ZIP(0x20) | INST_MASK;
    p.CS @ time + 32 <: CS_HI;
    p.DQ <: a_msb;
    p.DQ <: a;
    p.DQ <: a_lsb;
    p.DQ <: INST_MASK;
}

void quad_spi_flash_sector_erase(quad_spi_ports &p, unsigned address){
    erase(p, 0x20, address);
}

void quad_spi_flash_block_erase(quad_spi_ports &p, unsigned address){
    erase(p, 0xd8, address);
}

void quad_spi_flash_read_block(quad_spi_ports &p, unsigned address,
        unsigned data[], unsigned no_of_words){
    unsigned time;
    address = (byterev(address&0x00f0f0f0)>>12)|
            (byterev(address&0x000f0f0f)>>4);
    unsigned instruction = ZIP(0xeb);

    //asm("":: "r"(address), "r"(instruction));

    p.CS <: CS_HI @ time;
    time += 10;
    p.CS @ time <: CS_LO;
    p.DQ @ time <: instruction;
    p.CS @ time + no_of_words * 8 + 20 <: CS_HI ;
    p.DQ <: address;
    p.DQ :> int;
    p.DQ @ time + 20 + 8 :> data[0];
    for(unsigned i=1;i<no_of_words;i++)
        p.DQ :> data[i];
}

void quad_spi_wait_until_idle(quad_spi_ports &p){
    int busy = 1;
    unsigned time;
    unsigned val;
    //must be in quad mode!

    p.CS <: CS_HI @ time;
    time += DELAY;
    unsigned instruction = ZIP(0x05);

    while(busy){
        p.CS @ time <: CS_LO;
        p.DQ @ time <: instruction;
        p.CS @ time + 16 <: CS_HI;
        p.DQ @ time + 16 :> val;
        busy = val&0x20000000;
        time += 16 + MIN_CLOCKS_BETWEEN_INSTRUCTIONS;
    }
}

void quad_spi_flash_write_page(quad_spi_ports &p, unsigned address, unsigned data[64]){
    unsigned instruction = ZIP(0x32);
    unsigned a_msb = ZIP((address>>16)&0xff) | 0;
    unsigned a     = ZIP((address>> 8)&0xff) | 0;
    unsigned a_lsb = ZIP((address>> 0)&0xff) | 0;

    quad_spi_flash_write_enable(p);

    asm(""::"r"(a_msb), "r"(a), "r"(a_lsb));
    unsigned time;


    p.CS <: CS_HI @ time;
    time += DELAY;
    p.CS @ time <: CS_LO;
    p.DQ @ time <: instruction;
    p.CS @ time + 64*8 + 32 <: CS_HI ;
    p.DQ <: a_msb;
    p.DQ <: a;
    p.DQ <: a_lsb;
    for(unsigned i=0;i<64;i++)
        p.DQ <: data[i];

}
void quad_spi_flash_device_id(quad_spi_ports &p, unsigned char &device_id, unsigned char &man_id){
    unsigned time;
    unsigned t;
    p.CS <: CS_HI @ time;
    time += DELAY;
    p.CS @ time <: CS_LO;
    p.DQ @ time <: ZIP(0x94) | INST_MASK;
    p.CS @ time + 24 <: CS_HI;
    p.DQ <: 0x0;
    p.DQ :> int;
    p.DQ @ time + 28 :> t;
    sync(p.DQ);
    p.DQ <: INST_MASK;
    man_id = (t&0xf)<<4 | (t&0xf0)>>4;
    t=t>>8;
    device_id = (t&0xf)<<4 | (t&0xf0)>>4;
}

void quad_spi_flash_set_burst_with_wrap(quad_spi_ports &p, int wrap_around, int wrap_length){
    unsigned time;
    unsigned w5w6;
    switch (wrap_length){
    case 8: w5w6=0;break;
    case 16: w5w6=1;break;
    case 32: w5w6=2;break;
    case 64: w5w6=3;break;
    }
    unsigned data = 0;//ZIP(((wrap_around&1) << 3) | ((w5w6&3)<<4));
    p.CS <: CS_HI @ time;
    time += DELAY;
    p.CS @ time <: CS_LO;
    p.DQ @ time <: ZIP(0x06);
    p.CS @ time + 16 <: CS_HI;
    p.DQ<: data;
}


//Not possible
unsigned char quad_spi_flash_read_status_reg(quad_spi_ports &p,  unsigned no){
    unsigned time;
    unsigned reg;
    p.CS <: CS_HI @ time;
    time += DELAY;
    p.CS @ time <: CS_LO;
    if(no == 1){
        p.DQ @ time <: ZIP(0x05) | INST_MASK;
    } else if (no == 2) {
        p.DQ @ time <: ZIP(0x35) | INST_MASK;
    } else {
        return -1;
    }
    p.CS @ time + 16 <: CS_HI;
    p.DQ :> int;
    p.DQ @ time + 16 :> reg;

    printhexln(do_to_byte(reg));
    return 0;

}

void quad_spi_flash_write_status_reg(quad_spi_ports &p, unsigned char status_register_1, unsigned char status_register_2){
    /*
    unsigned time;
    unsigned sr1= ZIP(status_register_1);
    unsigned sr2= ZIP(status_register_2);
    p.CS <: CS_HI @ time;
    time += DELAY;
    p.CS @ time <: CS_LO;
    p.DQ @ time <: ZIP(0x01) | INST_MASK;
    p.CS @ time + 24 <: CS_HI;
    p.DQ <: 0x00000000 | INST_MASK;
    p.DQ <: 0x01000000 | INST_MASK;
    */
}




