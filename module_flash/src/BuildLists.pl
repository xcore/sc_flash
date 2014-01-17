##
## Script to generate files used in the libflash build from all spispec files.
##


#
# Open files.  Change filenames here if necessary.
#
$specPath = $ARGV[0];
$specFileName = $ARGV[1]; # "SpecDefinitions.h";
$macroFileName = $ARGV[2]; # "SpecMacros.h";
$enumFileName = $ARGV[3]; # "SpecEnum.h";
$xflashFileName = $ARGV[4]; # "XflashCode.cpp";
#
# Specs that are built into libflash.  Add or remove from here only.
#
@builtinspecs = ( "ALTERA_EPCS1", "ATMEL_AT25DF041A", "ST_M25PE10", "ST_M25PE20", "ATMEL_AT25FS010", "WINBOND_W25X40" );

#
# Names in enum order. All devices must appear here.
#
@enumorder = ( "ALTERA_EPCS1",    "ATMEL_AT25DF041A", "ST_M25PE10",     "ST_M25PE20",     "ATMEL_AT25FS010",
               "WINBOND_W25X40",  "AMIC_A25L016",     "AMIC_A25L40PT",  "AMIC_A25L40PUM", "AMIC_A25L80P",
               "ATMEL_AT25DF021", "ATMEL_AT25F512",   "ESMT_F25L004A",  "NUMONYX_M25P10", "NUMONYX_M25P16",
               "NUMONYX_M45P10E", "SPANSION_S25FL204K", "SST_SST25VF010",   "SST_SST25VF016", "SST_SST25VF040", 
               "WINBOND_W25X10", "WINBOND_W25X20",  "AMIC_A25L40P",     "MACRONIX_MX25L1005C" , "MICRON_M25P40" );

#
# Some names which should be listed in xflash last to avoid confusion between devices.
#
@lateentries = ( "ALTERA_EPCS1" );


sub removeOutputs
{
  unlink $specFileName;
  unlink $macroFileName;
  unlink $enumFileName;
}

# Open all the output file for writing.
$okay = open SPECFILE, ">$specFileName";
if( ! $okay ) { removeOutputs(); die("Could not open file \"$specFileName\""); }
$okay = open MACROFILE, ">$macroFileName";
if( ! $okay ) { removeOutputs(); die("Could not open file \"$macroFileName\""); }
$okay = open ENUMFILE, ">$enumFileName";
if( ! $okay ) { removeOutputs(); die("Could not open file \"$enumFileName\""); }
$okay = open XFLASHFILE, ">$xflashFileName";
if( ! $okay ) { removeOutputs(); die("Could not open file \"$xflashFileName\""); }


#
# Do initialisation and output headers.
#

# Header for SpecDefinitions.h
print SPECFILE "/*\n * Generated file - do not edit.\n */\n";
print SPECFILE "#define FL_DEVICESPECS { \\\n";

# Header for SpecMacros.h
print MACROFILE "/*\n * Generated file - do not edit.\n */\n";

# Header for SpecEnums.h
print ENUMFILE "/*\n * Generated file - do not edit.\n */\n";
print ENUMFILE "typedef enum\n{\n  UNKNOWN = 0,\n";
@usedorder = ();

# No header for XflashCode.cpp


#
# Output bodies.
#
@specs = <$specPath/*>;
foreach $file (@specs)
{
  # Extract base name of device.
  $basename = $file;
  $basename =~ s/^.*\///;
  $basename =~ s/.spispec$//;

  # Body for SpecDefinitions.h, only if we want it as a builtin.
  $index = 1;
  $resultindex = 0;
  foreach $device (@builtinspecs)
  {
    if( $device eq $basename )
    {
      $resultindex = $index;
    }
    $index = $index + 1;
  }
  if( $resultindex != 0 )
  {
    print SPECFILE "  {\\\n";
    open SINGLESPEC, "<$file";
    @raw_spec = <SINGLESPEC>;
    foreach $x (@raw_spec) {
        chomp($x);
        print SPECFILE "$x\\\n";
    }
    close( SINGLESPEC );
    print SPECFILE "  },\\\n";
  }

  # Body for SpecMacros.h
  print MACROFILE "#define FL_DEVICE_$basename \\\n{ \\\n";
  open SINGLESPEC, "<$file";
  @raw_spec = <SINGLESPEC>;
  foreach $specline (@raw_spec)
  {
    $specline =~ s/\r//g;
    $specline =~ s/\n$//;
    print MACROFILE "$specline \\\n";
  }
  close( SINGLESPEC );
  print MACROFILE "}\n";

  # Body for enumeration.
  # This array defines the enum order which we try to keep constant.
  $index = 1;
  $resultindex = 0;
  foreach $device (@enumorder)
  {
    if( $device eq $basename )
    {
      $resultindex = $index;
    }
    $index = $index + 1;
  }
  if( $resultindex == 0 )
  {
    removeOutputs();
    die( "Device $basename is not listed in fixed enum order. Please add it.\n" );
  }
  print ENUMFILE "  $basename = $resultindex,\n";
}

# Body for xflash code.  Same list as enum but don't bother re-checking stuff, and potentially
# in a different order to avoid mis-identification.
foreach $device (@enumorder)
{
  $islate = 0;
  foreach $lateentry (@lateentries)
  {
    $islate = $islate || ( $lateentry eq $device );
  }
  if( not $islate )
  {
    print XFLASHFILE "  fprintf(outFile,\"  FL_DEVICE_$device,\\n\");\n";
  }
}
foreach $lateentry (@lateentries)
{
  print XFLASHFILE "  fprintf(outFile,\"  FL_DEVICE_$lateentry,\\n\");\n";
}

#
# Ouput footers
#

# Footer for SpecDefinitions.h
print SPECFILE "};\n";

# No footer for SpecMacros.h

# Footer for SpecEnums.h
print ENUMFILE "} fl_FlashId;\n";


#
# Finish up.
#

close( SPECFILE );
close( MACROFILE );
close( ENUMFILE );
close( XFLASHFILE );

