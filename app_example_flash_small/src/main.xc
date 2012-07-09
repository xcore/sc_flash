#include <lld.h>
#include <flash.h>
#include <stdio.h>

main() {
    char data[256];
    int addr = 0x18800;
    int valid;
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

    for(int i = 0; i < 100; i++) {
        timer t;
        int t0, t1, t2, t3;
    t :> t0;
        valid = spiFlashPersistentStateRead(data);
    t :> t1;
        if (valid) {
            for(int i = 0; i < 15; i++) {
                printf(" %02x", data[i]);
            }
            for(int i = 0; i < 15; i++) {
                data[i] += i;
            }
        } else {
            for(int i = 0; i < 15; i++) {
                data[i] = 1;
            }        
        }
    t :> t2;
        spiFlashPersistentStateWrite(data);
    t :> t3;
        printf(" <<< Persistent; read: %d write: %d\n", t1-t0, t3-t2);
    }
}
