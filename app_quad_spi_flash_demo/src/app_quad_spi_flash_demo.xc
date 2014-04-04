#include "xs1.h"
#include "quad_spi_flash.h"
#include <print.h>

#if 1
//use this for STAR or SQUARE slots on XP-SKC-L2
quad_spi_ports p = {XS1_PORT_4A, XS1_PORT_1B, XS1_PORT_4B, XS1_CLKBLK_1, 0};
out port leds = XS1_PORT_8B;
#else
//use this for TRIANGLE or CIRCLE slots on XP-SKC-L2
quad_spi_ports p = {XS1_PORT_4E, XS1_PORT_1J, XS1_PORT_4F, XS1_CLKBLK_1, 0};
out port leds = XS1_PORT_8D;
#endif

unsigned f(unsigned i){
    return i;
}

int main() {
    unsigned buffer[64];
    for(unsigned i=0;i<64;i++)
        buffer[i] = f(i);

    quad_spi_flash_init(p);

    quad_spi_flash_chip_erase(p);
    quad_spi_wait_until_idle(p);

    quad_spi_flash_write_page(p, 0, buffer);
    quad_spi_wait_until_idle(p);

    quad_spi_flash_read_block(p, 0, buffer, 64);
    for(unsigned i=0;i<64;i++) {
        if(buffer[i] != f(i))
            return 1;
    }
    printstrln("Quad SPI flash demo complete");
    return 0;
}
