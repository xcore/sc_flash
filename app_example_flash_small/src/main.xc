#include <flash.h>
#include <stdio.h>


//::program that tests erase sector

testBytes(int start, int end, int value) {
    char data[1];
    printf("Testing that bytes %d..%d are 0x%02x\n", start, end, value);
    for(int i = start; i < end; i++) {
        spiFlashRead(i, data, 1);
        if (data[0] != value) {
            printf("Byte %d is 0x%02x rather than 0x%02x- sector size/erase command are not consistent\n", i, data[0] & 0xff, value);
        }
    }
}

testErase() {
    char data[256];

    spiInit();
    printf("Erasing %d bytes (2 sectors)\n", SPI_SECTOR_SIZE*2);
    spiFlashErase(0, SPI_SECTOR_SIZE*2);
    testBytes(0, SPI_SECTOR_SIZE*2, 0xff);
    for(int i = 0; i < 256; i++) {
        data[i] = 0;
    }
    printf("Setting 2 sectors to 0x00\n");
    for(int i = 0; i < SPI_SECTOR_SIZE*2; i+=256) {
        spiFlashWriteSmall(i, data, 256);
    }
    testBytes(0, SPI_SECTOR_SIZE*2, 0x00);
    printf("Erasing %d bytes (1 sectorx)\n", SPI_SECTOR_SIZE);
    spiFlashErase(0, SPI_SECTOR_SIZE);
    testBytes(0, SPI_SECTOR_SIZE, 0xff);
    testBytes(SPI_SECTOR_SIZE, SPI_SECTOR_SIZE*2, 0x00);
}
//::

#define spiInit()    ;

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
    testErase();
    useSPI();
    useFlash();
    usePersistence();
}
