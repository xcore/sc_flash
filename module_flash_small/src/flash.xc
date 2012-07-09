#include <stdio.h>
#include "flash.h"
#include "lld.h"
#include "flashDefaults.h"

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

static int flashStartAddress = 0;

#define VALID    0x0F
#define INVALID  0x00

/*
 * Persistent data is stored in flash between addresses
 * FLASH_PERSISTENT_BASE and FLASH_PERSISTENT_BASE +
 * FLASH_PERSISTENT_SEGMENT_SIZE. Each data item is always a power of 2
 * long, and the last byte is a guard byte which is one of 0xFF (unused),
 * 0x0F (valid) or 0x00 (no longer valid).
 *
 * This function finds the first valid persistent data in flash. This is
 * probably the most recent state, unless the syste got switched off prior
 * to it being made invalid, in which case this data is still valid but
 * just one step old.
 */
int spiFlashPersistentStateRead(char data[]) {
    for(int i = flashStartAddress;
        i < flashStartAddress + FLASH_PERSISTENT_SEGMENT_SIZE; 
        i+= FLASH_PERSISTENT_SIZE + 1) {
        int index = (i&(FLASH_PERSISTENT_SEGMENT_SIZE-1));
        spiFlashRead(FLASH_PERSISTENT_BASE + index, data, FLASH_PERSISTENT_SIZE + 1);
        if (data[FLASH_PERSISTENT_SIZE] == VALID) {
            flashStartAddress = index;
            return 1;
        }
    }
    return 0;
}

/*
 * This function writes persistent data by first finding valid persistent
 * data. If it cannot find any it will commence writing from the start
 * (default writeIndex is 0), otherwise writeIndex is set to be immediately
 * after the valid block. If the writeIndex is at the start of a sector,
 * then the sector is erased. The data is written, the guard byte for the
 * data is set to valid (in a separate write, that guarantees that the data
 * write has completed before the guard byte write is completed), and
 * finally the old guard byte is cleared.
 *
 * This process can eb interrupted at the following places without disruption:
 *
 *   After erase - it will find the old block (there are always at least
 *   two sectors)
 *
 *   After write of data - the guard will not be written, so it will not
 *   find the next one valid
 *
 *   After the guard is written - a read will still find the old data,
 *   leading to this being erased again
 *
 *   After the old guard is cleared - this will now have progressed the
 *   state.
 *
 * If interrupt during erase, there is a chance that any guard is set to
 * 'valid'. This code cannot deal with it, but a full and large version
 * would put a CRC over the data to validate the guard.
 */
void spiFlashPersistentStateWrite(char data[]) {
    char guard[1];
    int i, writeIndex = 0, clearIndex = FLASH_PERSISTENT_SEGMENT_SIZE - FLASH_PERSISTENT_SIZE;
    for(i = flashStartAddress;
        i < flashStartAddress + FLASH_PERSISTENT_SEGMENT_SIZE; 
        i+= FLASH_PERSISTENT_SIZE + 1) {
        int readIndex = (i&(FLASH_PERSISTENT_SEGMENT_SIZE-1));
        spiFlashRead(FLASH_PERSISTENT_BASE + readIndex + FLASH_PERSISTENT_SIZE, guard, 1);
        if (guard[0] == VALID) {
            clearIndex = readIndex;
            writeIndex = (readIndex+FLASH_PERSISTENT_SIZE+1)&(FLASH_PERSISTENT_SEGMENT_SIZE-1);
            break;
        }
    }
    if ((writeIndex & (FLASH_PERSISTENT_SECTOR_SIZE -1)) == 0) {
        spiFlashErase4K(FLASH_PERSISTENT_BASE + writeIndex, FLASH_PERSISTENT_SECTOR_SIZE);
    }
    spiFlashWriteSmall(FLASH_PERSISTENT_BASE + writeIndex, data, 15);
    guard[0] = VALID;
    spiFlashWriteSmall(FLASH_PERSISTENT_BASE + writeIndex + FLASH_PERSISTENT_SIZE, guard, 1);
    guard[0] = INVALID;
    spiFlashWriteSmall(FLASH_PERSISTENT_BASE + clearIndex + FLASH_PERSISTENT_SIZE, guard, 1);
    flashStartAddress = writeIndex;
}
