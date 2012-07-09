#include <lld.h>
#include <flash.h>
#include <stdio.h>

//::spi program
#include <spi.h>

useSPI() {
    spiInit();
    printf("ID4: %08x\n",spiCommandStatus(SPI_CMD_READID, 4));
}
//::

//::flash program
#include <flash.h>

useFlash() {
    char data[256];
    int addr = 0x18800;
    spiInit();

    spiFlashRead(addr, data, 32);
    for(int i = 0; i < 32; i++) {
        printf(" %02x", data[i]);
    }
    printf("\n");
    spiFlashErase4K(addr, 32);
    spiFlashRead(addr, data, 32);
    for(int i = 0; i < 32; i++) {
        printf(" %02x", data[i]);
    }
    printf("\n");
    for(int i = 0; i < 32; i++) {
        data[i] = i;
    }
    printf("\n");
    spiFlashWriteSmall(addr, data, 32);
    spiFlashRead(addr, data, 32);
    for(int i = 0; i < 32; i++) {
        printf(" %02x", data[i]);
    }
    printf("\n");
}
//::

//::persistence program
#include <flash.h>

usePersistence() {
    char data[16];
    int valid;
    spiInit();

    valid = spiFlashPersistentStateRead(data);
    if (!valid) {
        // fill data with factory default
    }
    // update state

    spiFlashPersistentStateWrite(data);
}
//::

main() {
    useSPI();
    useFlash();
    usePersistence();
}
