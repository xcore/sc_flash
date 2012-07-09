module_flash_small
''''''''''''''''''

This module implements a simple flash library, sufficient for DFU and
similar applications.

API
===


.. doxygenfunction:: spiFlashRead
.. doxygenfunction:: spiFlashWriteSmall
.. doxygenfunction:: spiFlashWrite
.. doxygenfunction:: spiFlashErase4K
.. doxygenfunction:: spiFlashPersistentStateRead
.. doxygenfunction:: spiFlashPersistentStateWrite


Example
=======

To be provided.

.. literalinclude:: app_example_flash_small/src/main.xc
  :start-after: //::declaration
  :end-before: //::


.. literalinclude:: app_example_flash_small/src/main.xc
  :start-after: //::main program
  :end-before: //::
