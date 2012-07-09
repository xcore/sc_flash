module_flash_small
''''''''''''''''''

This module implements a simple flash library, sufficient for DFU and
similar applications. Two files are to be included ``lld.h`` and
``flash.h``.


SPI API
=======

.. doxygenfunction:: spiInit
.. doxygenfunction:: spiCommandStatus
.. doxygenfunction:: spiCommandAddressStatus

.. doxygendefine:: SPI_CMD_WRITE_ENABLE
.. doxygendefine:: SPI_CMD_WRITE_DISABLE

Flash API
=========

.. doxygenfunction:: spiFlashRead
.. doxygenfunction:: spiFlashWriteSmall
.. doxygenfunction:: spiFlashWrite
.. doxygenfunction:: spiFlashErase4K
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

+-------------------------+------+------+------+------+
| Erase code              | 0x20 | 0x52 | 0xD8 | 0xD8 |
+-------------------------+------+------+------+------+
| Erase sector size       | 4K   | 32K  | 64K  | 32K  |
+----------+--------------+------+------+------+------+
| ALTERA   | EPCS1        |      |      |      |  X   |
|          +--------------+------+------+------+------+
|          | EPCS4/16/64  |      |      |  X   |      |
+----------+--------------+------+------+------+------+
| AMIC     | A25L016      |  X   |      |      |      |
|          +--------------+------+------+------+------+
|          | A25L40       |      |      |  X   |      |
|          +--------------+------+------+------+------+
|          | A25L80       |      |      |  X   |      |
+----------+--------------+------+------+------+------+
| ATMEL    | AT25DF021    |  X   |      |  X   |      |
|          +--------------+------+------+------+------+
|          | AT25DF041A   |  X   |      |  X   |      |
|          +--------------+------+------+------+------+
|          | AT25F512/1024|      |  X   |      |      | 
|          +--------------+------+------+------+------+
|          | AT25FS010    |  X   |      |      |  X   |
+----------+--------------+------+------+------+------+
| ESMT     | F25L004A     |  X   |      |  X   |      |
+----------+--------------+------+------+------+------+
| MACRONIX | MX25L1005C   |  X   |      |  X   |      |
+----------+--------------+------+------+------+------+
| NUMONYX  | M25P10       |      |      |      |  X   |
|          +--------------+------+------+------+------+
|          | M25P16       |      |      |  X   |      | 
|          +--------------+------+------+------+------+
|          | M25PE10      |  X   |      |  X   |      |
|          +--------------+------+------+------+------+
|          | M45PE10      |      |      |  X   |      |
+----------+--------------+------+------+------+------+
| SST      | SST25VF010   |  X   |  X   |      |  X   |
|          +--------------+------+------+------+------+
|          | SST25VF016   |  X   |  X   |  X   |      |
|          +--------------+------+------+------+------+
|          | SST25VF040   |  X   |  X   |  X   |      |
+----------+--------------+------+------+------+------+
| ST       | M25PE10/20   |      |      |  X   |      |
+----------+--------------+------+------+------+------+
| WINBOND  | W25X10/20/40 |  X   |  X   |  X   |      |
+----------+--------------+------+------+------+------+

Example
=======

An example that reads, erases and writes data:

.. literalinclude:: app_example_flash_small/src/main.xc
  :start-after: //::flash program
  :end-before: //::

An example that uses the SPI library to read the ID:

.. literalinclude:: app_example_flash_small/src/main.xc
  :start-after: //::spi program
  :end-before: //::

An example that uses the flash library to store some persistent data (such
as volume, or mixer settings) with some simple wear levelling:

.. literalinclude:: app_example_flash_small/src/main.xc
  :start-after: //::persistence program
  :end-before: //::
