#include <flash.h>
#include <stdio.h>

int errors = 0;

void testBytes(int start, int end, int value) {
    char data[1];
//    printf("Testing that bytes %d..%d are 0x%02x\n", start, end, value);
    for(int i = start; i < end; i++) {
        spiFlashRead(i, data, 1);
        if (data[0] != value) {
            printf("Byte %d is 0x%02x rather than 0x%02x- sector size/erase command are not consistent\n", i, data[0] & 0xff, value);
            errors++;
        }
    }
}

int main(void) {
    char data[256];

    spiInit();
//    printf("Erasing %d bytes (2 sectors)\n", SPI_SECTOR_SIZE*2);
    spiFlashErase(0, SPI_SECTOR_SIZE*2);
    testBytes(0, SPI_SECTOR_SIZE*2, 0xff);
    for(int i = 0; i < 256; i++) {
        data[i] = 0;
    }
//    printf("Setting 2 sectors to 0x00\n");
    for(int i = 0; i < SPI_SECTOR_SIZE*2; i+=256) {
        spiFlashWriteSmall(i, data, 256);
    }
    testBytes(0, SPI_SECTOR_SIZE*2, 0x00);
//    printf("Erasing %d bytes (1 sectorx)\n", SPI_SECTOR_SIZE);
    spiFlashErase(0, SPI_SECTOR_SIZE);
    testBytes(0, SPI_SECTOR_SIZE, 0xff);
    testBytes(SPI_SECTOR_SIZE, SPI_SECTOR_SIZE*2, 0x00);
    printf("Erase code 0x%02x and sector size %d ", SPI_CMD_ERASE, SPI_SECTOR_SIZE);
    if (errors == 0) {
        printf("appear to work for this device\n");
    } else {
        printf("appear to be broken for this device\n");
    }
}
