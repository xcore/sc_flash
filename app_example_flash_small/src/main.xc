#include <lld.h>
#include <flash.h>
#include <stdio.h>

main() {
    char data[256];
    int addr = 0x18800;
    spiInit();
    printf("ID4: %08x\n",spiCommandStatus(SPI_CMD_READID, 4));
    printf("ID4: %08x\n",spiCommandStatus(SPI_CMD_READID, 4));
    printf("ID4: %08x\n",spiCommandStatus(SPI_CMD_READID, 4));
    printf("ID4: %08x\n",spiCommandStatus(SPI_CMD_READID, 4));
    printf("SR: %08x\n", spiCommandStatus(SPI_CMD_READSR, 1));
    printf("SR: %08x\n", spiCommandStatus(SPI_CMD_READSR, 1));
    printf("SR: %08x\n", spiCommandStatus(SPI_CMD_READSR, 1));
    printf("SR: %08x\n", spiCommandStatus(SPI_CMD_READSR, 1));

    for(int i = 0; i < 128; i++) {
//        printf("%02x: %02x\n", i, spiCommandStatus(i, 1));
    }
    spiFlashRead(addr, data, 32);
    for(int i = 0; i < 32; i++) {
        printf(" %02x", data[i]);
        data[i] &= (1<<(i&7));
    }
    printf("\n");
    spiFlashErase4K(addr, 32);
    spiFlashRead(addr, data, 32);
    for(int i = 0; i < 32; i++) {
        printf(" %02x", data[i]);
        data[i] &= (1<<(i&7));
    }
    printf("\n");
    spiFlashWriteSmall(addr, data, 32);
    spiFlashRead(addr, data, 32);
    for(int i = 0; i < 32; i++) {
        printf(" %02x", data[i]);
    }
    printf("\n");
}
