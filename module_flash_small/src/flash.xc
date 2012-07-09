#include <stdio.h>
#include "flash.h"
#include "lld.h"

void spiFlashWriteSmall(int address, char data[],int bytes) {
    spiCommandStatus(SPI_CMD_WRITE_ENABLE, 0);
    spiCommandAddressStatus(SPI_CMD_WRITE,address,data,-(bytes));
    while(spiCommandStatus(SPI_CMD_READSR, 1) & 1) {
        ;
    }
    spiCommandStatus(SPI_CMD_WRITE_DISABLE, 0);
}

void spiFlashWrite(int address, char data[],int bytes) {
    printf("Not supported yet - needs array slicing...\n");
    while (bytes != 0) {
        int len = (address & 0xff) == ((address + bytes) & 0xff) ? bytes : 256-(address & 0xff);
        spiFlashWriteSmall(address, data, len);
        bytes -= len;
        address += len;
    }
}

void spiFlashErase4K(int address, int bytes) {
    char data[1];
    spiCommandStatus(SPI_CMD_WRITE_ENABLE, 0);
    while (bytes > 0) {
        spiCommandAddressStatus(SPI_CMD_ERASE_4K, address, data, 0);
        bytes -= 4096;
        address += 4096;
        while(spiCommandStatus(SPI_CMD_READSR, 1) & 1) {
            ;
        }
    }
    spiCommandStatus(SPI_CMD_WRITE_DISABLE, 0);
}

void spiFlashStorePersistentState(int address, char data[], int bytes) {
    
}
