module_flash_small
''''''''''''''''''

This module implements a simple flash library, sufficient for DFU and
similar applications. There are two include files: ``spi.h`` which is to be
used if only low level SPI functions are used, or ``flash.h`` which includes
higher level functions to interact with SPI flash.

In order to set one or more of the ``#define`` below, create a source file
``spi_conf.h`` containing all the defines.

SPI API
=======

Defines
-------

There are two defines to deal with flash interoperability. There is no need
to worry about these if you only read flash. If you need to write to flash,
you must check that these are compatible with *all* flash devices that you
intend to support. See See the section on interoperability for an
explanation.

**SPI_CMD_ERASE**

  The command byte that erases a sector in SPI. The default value 0x20,
  works for about half the SPI flash devices.

**SPI_SECTOR_SIZE**

  The number of bytes that a sector-erase erases. The default value, 4096
  bytes, is compatible with about half of the flash devices.


Functions
---------

.. doxygenfunction:: spiInit
.. doxygenfunction:: spiCommandStatus
.. doxygenfunction:: spiCommandAddressStatus

Flash API
=========

Defines
-------

There are three defines that can be tuned to change the persistent state
handling - only important if  spiFlashPersistentStateRead() and
spiFlashPersistentStateWrite() are used.

**FLASH_PERSISTENT_SIZE**

  The size of persistent data in bytes. When using the functions
  spiFlashPersistentStateRead() and spiFlashPersistentStateWrite() this
  indicates how much data is read or written. The default is 15 bytes; the
  number of bytes plus one must be a power of 2.

**FLASH_PERSISTENT_BASE**

  The based address of the persistent data in flash. This must be a sector
  boundary. The default is 65536.


**FLASH_PERSISTENT_SEGMENT_SIZE**

  The size of the persistent data segment in bytes. The persistent data
  segment must be at least two sectors long; longer segments take more
  space but wear out less quickly. The default is 2 sectors.

Functions
---------

.. doxygenfunction:: spiFlashRead
.. doxygenfunction:: spiFlashWriteSmall
.. doxygenfunction:: spiFlashWrite
.. doxygenfunction:: spiFlashErase
.. doxygenfunction:: spiFlashPersistentStateRead
.. doxygenfunction:: spiFlashPersistentStateWrite


Compatibility
=============

Not all SPI flash devices are the same, and there is considerable variation
in how to erase part of the flash. The two parameters to be set are the
'Erase command' and the 'Erase sector size'. The default settings are 0x20
and 4K, and all devices marked with an 'X' in this column should be
compatible. 

Please note that it is that once the sector and erase code are compiled in,
then the binary is only compatible with that set of devices. If greater
compatibility is required, the full flash library should be used instead.
You must consult the datasheets of the flash-chips that you intend to
employ and verify that all of those are compatible.

A test application is provided in ``app_test_flash_small/`` which tests
whether an erase code and erase sector size work on a particular piece of
hardware.

+-------------------------+------+------+------+------+------+
| Erase code              | 0x20 | 0x52 | 0xD8 | 0xD8 | Size |
+-------------------------+------+------+------+------+------+
| Erase sector size       | 4K   | 32K  | 64K  | 32K  | bytes|
+----------+--------------+------+------+------+------+------+
| ALTERA   | EPCS1        |      |      |      |  X   | 128K |
|          +--------------+------+------+------+------+------+
|          | EPCS4/16/64  |      |      |  X   |      |      |
+----------+--------------+------+------+------+------+------+
| AMIC     | A25L016      |  X   |      |      |      |   2M |
|          +--------------+------+------+------+------+------+
|          | A25L40       |      |      |  X   |      | 512K |
|          +--------------+------+------+------+------+------+
|          | A25L80       |      |      |  X   |      |   1M |
+----------+--------------+------+------+------+------+------+
| ATMEL    | AT25DF021    |  X   |      |  X   |      | 256K |
|          +--------------+------+------+------+------+------+
|          | AT25DF041A   |  X   |      |  X   |      | 512K |
|          +--------------+------+------+------+------+------+
|          | AT25F512/1024|      |  X   |      |      |      |
|          +--------------+------+------+------+------+------+
|          | AT25FS010    |  X   |      |      |  X   | 128K |
+----------+--------------+------+------+------+------+------+
| ESMT     | F25L004A     |  X   |      |  X   |      | 512K |
+----------+--------------+------+------+------+------+------+
| MACRONIX | MX25L1005C   |  X   |      |  X   |      | 128K |
+----------+--------------+------+------+------+------+------+
| NUMONYX  | M25P10       |      |      |      |  X   | 128K |
|          +--------------+------+------+------+------+------+
| MICRON   | M25P16       |      |      |  X   |      |   2M |
|          +--------------+------+------+------+------+------+
|          | M25PE10      |  X   |      |  X   |      | 128K |
|          +--------------+------+------+------+------+------+
|          | M45PE10      |      |      |  X   |      |      |
+----------+--------------+------+------+------+------+------+
| SST      | SST25VF010   |  X   |  X   |      |  X   | 128K |
|          +--------------+------+------+------+------+------+
|          | SST25VF016   |  X   |  X   |  X   |      |   2M |
|          +--------------+------+------+------+------+------+
|          | SST25VF040   |  X   |  X   |  X   |      | 512K |
+----------+--------------+------+------+------+------+------+
| ST       | M25PE10      |      |      |  X   |      | 128K |
|          +--------------+------+------+------+------+------+
|          | M25PE20      |      |      |  X   |      | 256K |
+----------+--------------+------+------+------+------+------+
| WINBOND  | W25X10       |  X   |  X   |  X   |      | 128K |
|          +--------------+------+------+------+------+------+
|          | W25X20       |  X   |  X   |  X   |      | 256K |
|          +--------------+------+------+------+------+------+
|          | W25X40       |  X   |  X   |  X   |      | 512K |
+----------+--------------+------+------+------+------+------+

Example
=======

An example that uses the SPI library to read the ID:

.. literalinclude:: app_example_flash_small/src/main.xc
  :start-after: //::spi program
  :end-before: //::

An example that reads, erases and writes data:

.. literalinclude:: app_example_flash_small/src/main.xc
  :start-after: //::flash program
  :end-before: //::

An example that uses the flash library to store some persistent data (such
as volume, or mixer settings) with some simple wear levelling:

.. literalinclude:: app_example_flash_small/src/main.xc
  :start-after: //::persistence program
  :end-before: //::
