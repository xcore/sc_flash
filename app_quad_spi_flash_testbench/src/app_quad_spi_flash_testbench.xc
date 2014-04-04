#include "xs1.h"
#include "quad_spi_flash.h"
#include <print.h>

#if 1
quad_spi_ports p = {XS1_PORT_4A,
                    XS1_PORT_1B,
                    XS1_PORT_4B,
                    XS1_CLKBLK_1, 0
};
out port leds = XS1_PORT_8B;
#else
quad_spi_ports p = {XS1_PORT_4E,
                    XS1_PORT_1J,
                    XS1_PORT_4F,
                    XS1_CLKBLK_1, 0
};
out port leds = XS1_PORT_8D;
#endif

void set_leds(int zero, int one, int two, int three){
    leds <: ((!zero&1)<<4) | ((!one&1)<<5) | ((!two&1)<<6) | ((!three&1)<<7);
}

unsigned f(unsigned i){
    return i*8;
}

unsigned g(unsigned i){
    return i*7;
}

static int test_chip_erase(quad_spi_ports &p){
    int pass = 1;
    unsigned buffer[64];
    quad_spi_flash_chip_erase(p);
    quad_spi_wait_until_idle(p);
    for(unsigned address = 0x0; address < QUAD_SPI_FLASH_TOTAL_BYTES;
            address+= QUAD_SPI_FLASH_BYTES_PER_PAGE){
        quad_spi_flash_read_block(p, 0, buffer, 64);
        for(unsigned i=0;i<64;i++) pass &= (buffer[i] ==  QUAD_SPI_FLASH_ERASED);
    }
    return pass;
}

#pragma unsafe arrays
static int test_read_write(quad_spi_ports &p,
        unsigned &whole_chip_write_time,
        unsigned &whole_chip_read_time){

    timer t;
    unsigned start_time, end_time;
    int pass = 1;
    unsigned buffer[64];
#define N 128
    unsigned big_buffer[64*N];

    //erase the whole chip
    quad_spi_flash_chip_erase(p);
    quad_spi_wait_until_idle(p);

    //write whole chip
    t:>start_time;
    for(unsigned address = 0; address < QUAD_SPI_FLASH_TOTAL_BYTES;
            address +=QUAD_SPI_FLASH_BYTES_PER_PAGE){
        for(unsigned i=0;i<QUAD_SPI_FLASH_BYTES_PER_PAGE;i++)
            (buffer, char[])[i] = (address+i)&0xff;

        quad_spi_flash_write_page(p, address, buffer);
        quad_spi_wait_until_idle(p);
    }
    t:>end_time;
    whole_chip_write_time = end_time - start_time;

    t:>start_time;
    for(unsigned address = 0; address < QUAD_SPI_FLASH_TOTAL_BYTES;
               address +=QUAD_SPI_FLASH_BYTES_PER_PAGE*N){
        quad_spi_flash_read_block(p,address, big_buffer, 64*N);
    }
    t:>end_time;
    whole_chip_read_time = end_time - start_time;

    for(unsigned address = 0; address < QUAD_SPI_FLASH_TOTAL_BYTES;
               address +=QUAD_SPI_FLASH_BYTES_PER_PAGE){
        quad_spi_flash_read_block(p,address, buffer, 64);
        for(unsigned i=0;i<QUAD_SPI_FLASH_BYTES_PER_PAGE;i++) {
            pass &= ((buffer, char[])[i] == ((address+i)&0xff));
        }
    }

    return pass;
}

static int test_sector_erase(quad_spi_ports &p){

    int pass = 1;
    unsigned buffer[64];

    //erase the whole chip
    quad_spi_flash_chip_erase(p);
    quad_spi_wait_until_idle(p);

    //write to sector 0
    for(unsigned i=0;i<64;i++) buffer[i] = f(i);
    quad_spi_flash_write_page(p, 0, buffer);
    quad_spi_wait_until_idle(p);

    //write to sector 1
    for(unsigned i=0;i<64;i++) buffer[i] = g(i);
    quad_spi_flash_write_page(p, 0x10000, buffer);
    quad_spi_wait_until_idle(p);

    //verify we have written to sector 0 and sector 1
    quad_spi_flash_read_block(p, 0, buffer, 64);
    for(unsigned i=0;i<64;i++) pass &= (buffer[i] == f(i));

    quad_spi_flash_read_block(p, 0x10000, buffer, 64);
    for(unsigned i=0;i<64;i++) pass &= (buffer[i] == g(i));

    //erase sector 0
    quad_spi_flash_sector_erase(p, 0);
    quad_spi_wait_until_idle(p);

    //verify sector 0 is erased and sector 1 is still present
    quad_spi_flash_read_block(p, 0, buffer, 64);
    for(unsigned i=0;i<64;i++) pass &= (buffer[i] == QUAD_SPI_FLASH_ERASED);

    quad_spi_flash_read_block(p, 0x10000, buffer, 64);
    for(unsigned i=0;i<64;i++) pass &= (buffer[i] == g(i));

    //erase sector 1
    quad_spi_flash_sector_erase(p, 0x10000);
    quad_spi_wait_until_idle(p);

    //verify sector 1 is erased
    quad_spi_flash_read_block(p, 0, buffer, 64);
    for(unsigned i=0;i<64;i++) pass &= (buffer[i] == QUAD_SPI_FLASH_ERASED);

    quad_spi_flash_read_block(p, 0, buffer, 64);
    for(unsigned i=0;i<64;i++) pass &= (buffer[i] == QUAD_SPI_FLASH_ERASED);

    return pass;
}

#define DEVICE_ID 0x13
#define MAN_ID 0xEF

int regression_single_core(unsigned cores) {
    int pass = 1;
    unsigned char device_id = 0xf;
    unsigned char man_id = 0xf;
    unsigned whole_chip_write_time;
    unsigned whole_chip_read_time;

    quad_spi_flash_init(p);


    printstr("Testing for ");
    printint(cores);
    printstrln(" cores");
    quad_spi_flash_device_id(p, device_id, man_id);
    pass = (device_id == DEVICE_ID && man_id == MAN_ID);
    printstr("Device and Man ID: ");
    printstrln(pass?"pass":"fail");

    printstr("Chip Erase       : ");
    pass = test_chip_erase(p);
    printstrln(pass?"pass":"fail");

    printstr("Sector Erase     : ");
    pass = test_sector_erase(p);
    printstrln(pass?"pass":"fail");

    printstr("Read + Write     : ");
    pass = test_read_write(p, whole_chip_write_time, whole_chip_read_time);
    printstrln(pass?"pass":"fail");

    printstr("1MB write time   : ");
    printintln(whole_chip_write_time);
    printstr("1MB read time    : ");
    printintln(whole_chip_read_time);
    printstrln("");
    return 0;
}

static void regression(chanend in_t, chanend out_t, unsigned cores) {
  regression_single_core(cores);
  out_t <: 1;
  in_t :> int;
}

static void load_thread(chanend in_t, chanend out_t) {
  set_thread_fast_mode_on();
  in_t  :> int;
  out_t <: 1;
}

static void test_4_threads() {
  chan c[3];
  par {
    regression(c[0], c[1], 4);
    load_thread(c[1], c[2]);
    load_thread(c[2], c[0]);
  }
}

static void test_5_threads() {
  chan c[4];
  par {
    regression(c[0], c[1], 5);
    load_thread(c[1], c[2]);
    load_thread(c[2], c[3]);
    load_thread(c[3], c[0]);
  }
}
static void test_6_threads() {
  chan c[5];
  par {
    regression(c[0], c[1], 6);
    load_thread(c[1], c[2]);
    load_thread(c[2], c[3]);
    load_thread(c[3], c[4]);
    load_thread(c[4], c[0]);
  }
}

static void test_7_threads() {
  chan c[6];
  par {
    regression(c[0], c[1], 7);
    load_thread(c[1], c[2]);
    load_thread(c[2], c[3]);
    load_thread(c[3], c[4]);
    load_thread(c[4], c[5]);
    load_thread(c[5], c[0]);
  }
}

static void test_8_threads() {
  chan c[7];
  par {
    regression(c[0], c[1], 8);
    load_thread(c[1], c[2]);
    load_thread(c[2], c[3]);
    load_thread(c[3], c[4]);
    load_thread(c[4], c[5]);
    load_thread(c[5], c[6]);
    load_thread(c[6], c[0]);
  }
}

int main() {
  printstrln("Quad SPI Flash Testbench");
  test_8_threads();
  test_7_threads();
  test_6_threads();
  test_5_threads();
  test_4_threads();
  return 0;
}


