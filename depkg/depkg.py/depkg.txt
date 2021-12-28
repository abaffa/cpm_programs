#!/usr/bin/env python

# ************************************************************
# depkg.py Extract Z80 CPM .pkg files
# by Mark Bramwell, London Canada
# http://www.foxhollow.ca/cpm
# ************************************************************
"""
example: 
  depkg.py zork123.pkg

This script will take a package file prepared for Z80 CPM
computers and extract the contents into the current directory.

Package files are described on Grant Searle's web site:
http://searle.hostei.com/grant/cpm

Updates to this script can be found at foxhollow:
http://www.foxhollow.ca/cpm

"""

MY_VERSION = "2018-04-11"

import argparse

# Instantiate the parser
parser = argparse.ArgumentParser(epilog=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)

# Optional argument, if specified the value to saved to args.checkHost
parser.add_argument('filename',
        metavar='filename',
        nargs='+',
        help='name of package to extract')

parser.add_argument("-p", "--print",
        default=False,
        dest='print_only',
        help="print embedded filenames but do not extract",
        action="store_true")

parser.add_argument("-q", "--quiet",
        default=False,
        dest='quiet',
        help="display no output while extracting files",
        action="store_true")

parser.add_argument('-v', '--version', action='version', version='%(prog)s (' + MY_VERSION + ')')

# check the args!
args = parser.parse_args()


# ************************************************************
# Extract the data of an embedded file
# ************************************************************
def extract(embedded_filename, embedded_data):
  
  if args.print_only == True:
    print embedded_filename
    return

  if args.quiet == False:
    print ("-- Extracting " + embedded_filename)

  if (args.quiet == False) and (embedded_data[-5:-4] != ">"):
    print ("   Invalid Data - file ignored\n")
    return

  if (args.quiet == False) and (embedded_data[0] != ":"):
    print ("   Invalid Data - file ignored\n")
    return

  embedded_size = embedded_data[-4:-2]
  embedded_checksum = embedded_data[-2:]
  hex_data = embedded_data[1:-5]
  file_size = 0
  file_checksum = 0

  try:
    out_file = open(embedded_filename,"w") 

    # scan the hex data (2 characters at a time) and convert to binary
    for spot in range(0,len(hex_data),2):
      binary_data = int(hex_data[spot] + hex_data[spot+1], 16)
      # write out the result
      out_file.write( chr(binary_data) )
      # update our counters
      file_size += 1
      file_checksum += binary_data

  except:
    print ("Unable to save " + embedded_filename)
    out_file.close()
    return

  # we are done writing the data
  out_file.close()

  # Let's check to see if the results make sense  
  hex_size = hex(file_size).upper()
  calculated_size = ("00" + hex_size.split("X")[1])[-2:]
  hex_checksum = hex(file_checksum).upper()
  calculated_checksum = ("00" + hex_checksum.split("X")[1])[-2:]

  if args.quiet == False:
    if (calculated_size == embedded_size) and (calculated_checksum == embedded_checksum):
      print("   OK: File size=" + "{:,}".format(file_size) + "\n")
    else:
      print("   WARNING: File size error\n")

  return



# ************************************************************
# Read the pkg file and process the lines in groups of 3
# ************************************************************
# Line 1 contains the embedded filename
# Example:  A:DOWNLOAD myfile.txt
#
# Line 2 contais the CPM user area  (ignored)
# Example: U0
#
# Line 3 contains the binary data and checksum
# Example:  :112233445566778899>1122
# ************************************************************
def process(the_filename):

  line_count = 0
  cpm_filename = ""
  cpm_user = ""
  cpm_hex = ""

  try:
    with open(the_filename, "r") as pkg_file:
      for the_line in pkg_file:

        # remove <cr> and/or <lf>
        the_line = the_line.strip()

        # Line 1 contains the embedded filename
        # Example:  A:DOWNLOAD myfile.txt
        if (line_count % 3) == 0: 
          cpm_download = (the_line+" ").split(" ")[0]
          if cpm_download.find("DOWNLOAD"):
            cpm_filename = (the_line+" ").split(" ")[1]
          else:
            cpm_filename = ""        

        # Line 2 contais the CPM user area  (ignored)
        # Example: U0
        if (line_count % 3) == 1: cpm_user_area = the_line
        
        # Line 3 contains the binary data and checksum
        # Example:  :112233445566778899>1122
        if (line_count % 3) == 2: 
          cpm_hex = the_line
          if (cpm_filename != ""): extract(cpm_filename, cpm_hex)
 
        line_count += 1

  except:
    print ("Oops, we have a problem reading " + the_filename)

  return



# ************************************************************
#                 S T A R T   of   S C R I P T
#               check filenames specified on CLI
# ************************************************************
for the_filename in args.filename:
  process(the_filename)
