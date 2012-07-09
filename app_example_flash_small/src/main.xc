#include <flash.h>
#include <stdio.h>

//::spi program
#include <spi.h>

useSPI() {
    spiInit();
    printf("ID4: %08x\n",spiCommandStatus(SPI_CMD_READID, 4));
}
//::

#define spiInit()    ;

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
    spiFlashErase(addr, 32);
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

char state[15];

usePersistence() {
    int valid;
    spiInit();

    valid = spiFlashPersistentStateRead(state);
    if (!valid) {
        // fill state[] with factory default
    }

    //...
    // update state
    spiFlashPersistentStateWrite(state);
    //...
}
//::

main() {
    useSPI();
    useFlash();
    usePersistence();
}
