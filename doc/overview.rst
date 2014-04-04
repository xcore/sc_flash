Overview
========

Quad SPI flash controller component
-----------------------------------

The quad SPI flash module is designed for flash I/O at up to 50MHz clock rates. The module currently targets the W25Q80BV but may easily be adapted to any quad SPI flash from other manufacturers.

Quad SPI flash Component Features
+++++++++++++++++++++++++++++++++

The quad SPI flash component has the following features:

  * Supports via API
     * read,
     * write,
     * erase,
     * access to status registers.
  * Runs as a library call, requiring no extra cores or timers.

Memory Requirements
+++++++++++++++++++

+------------------+----------------------------------------+
| Resource         | Usage                            	    |
+==================+========================================+
| Stack            | ??? bytes                              |
+------------------+----------------------------------------+
| Program          | ????? bytes                            |
+------------------+----------------------------------------+

Resource requirements
+++++++++++++++++++++

+---------------+-------+
| Resource      | Usage |
+===============+=======+
| Channels      |   0   |
+---------------+-------+
| Timers        |   0   |
+---------------+-------+
| Clocks        |   1   |
+---------------+-------+
| Logical Cores |   0   |
+---------------+-------+

Performance
+++++++++++

The achievable effective bandwidth varies according to the available xCORE MIPS. This information has been obtained by testing on real hardware.

+------------+-------+--------------+----------------+------------------+
| xCORE MIPS | Cores | System Clock |Max Read (MB/s) | Max Write (MB/s) | 
+============+=======+==============+================+==================+
| 62.5       | 8     | 500MHz       | 23.8           | 0.34             | 
+------------+-------+--------------+----------------+------------------+
| 71         | 7     | 500MHz       | 23.8           | 0.34             | 
+------------+-------+--------------+----------------+------------------+
| 83         | 6     | 500MHz       | 23.8           | 0.34             | 
+------------+-------+--------------+----------------+------------------+
| 100        | 5     | 500MHz       | 23.8           | 0.35             | 
+------------+-------+--------------+----------------+------------------+
| 125        | 4     | 500MHz       | 23.8           | 0.35             | 
+------------+-------+--------------+----------------+------------------+



