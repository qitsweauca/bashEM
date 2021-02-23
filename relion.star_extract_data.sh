#!/bin/bash
#
#
############################################################################
#
# Author: "Kyle L. Morris"
# MRC London Institute of Medical Sciences 2021
#
# This program is free software: you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation, either version 3 of the License, or
#     (at your option) any later version.
#
#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
#
#     You should have received a copy of the GNU General Public License
#     along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
############################################################################

# As of Relion3 star file formatting changed, use relion.star_extract_data.sh to extract data and header lines
# Outputs will be .mainDataLine.dat, .opticsDataLines.dat, .mainDataHeader.dat

# Input star file
starin=$1

# Tidy up from last round
rm -rf .mainDataLine.dat
rm -rf .opticsDataLines.dat
rm -rf .mainDataHeader.dat

################################################################################
# Get header and data lines
################################################################################

##As of relion3 a version header is included in star file, ascertain for reporting and removal
versionSearch=$(cat ${starin} | grep "version" | head -n 1)

if [[ -z ${versionSearch} ]] ; then
  version=$(echo "No Relion version header found...")
  versionSearch="Unknown"
  #### INSERT CODE HERE TO CREATE A FAKE OPTICS GROUP FILE FOR READING PIXEL SIZE ETC ####
else
  version=$(echo "Relion version: ${versionSearch}")
fi

echo $version
echo ""

##The following code implements a new way to find relion star file headers since version 3.1 changes
# Find data_ blocks
dataBlocks=$(grep -n data_ ${starin} | sed 's/:/ /g')

echo "Found the following number of data_ blocks in header: $(echo "$dataBlocks" | wc -l)"
echo ""

# Report data_ block names without line numbers
echo "$dataBlocks" | awk '{print "\t",$2,"(@ line: "$1")"}'
echo ""

# Store data_optics line number
opticsDataBlockNo=$(echo "$dataBlocks" | head -n 1 | awk '{print $1}')
# Store main data_ block line number
mainDataBlockNo=$(echo "$dataBlocks" | tail -n 1 | awk '{print $1}')

# Store the first optic line (i.e. containing > 3 columns) after first data_optics block
opticsDataLine=$(cat ${starin} | awk -v opticsDataBlockNo=$opticsDataBlockNo 'NR>=opticsDataBlockNo' | awk 'NF > 3' | head -n 1)
# Find the first dataline number
opticsDataLineNo=$(grep -n "${opticsDataLine}" ${starin} | sed 's/:/ /g' | awk '{print $1}')
echo "First optics line appears on line no: ${opticsDataLineNo}"

# Store the first data line (i.e. containing > 3 columns) after final data_ block
mainDataLine=$(cat ${starin} | awk -v mainDataBlockNo=$mainDataBlockNo 'NR>=mainDataBlockNo' | awk 'NF > 3' | head -n 1)
# Find the first dataline number
mainDataLineNo=$(grep -n "${mainDataLine}" ${starin} | sed 's/:/ /g' | awk '{print $1}')
echo "First data line appears on line no: ${mainDataLineNo}"

# Save optics group to file and clean up header
cat ${starin} | sed -n ${opticsDataBlockNo},${mainDataBlockNo}p | sed "/${versionSearch}/Q" | awk 'NF < 3' > .opticsDataHeader.dat
# Save optics group to file and clean up header
cat ${starin} | sed -n ${opticsDataBlockNo},${mainDataBlockNo}p | sed "/${versionSearch}/Q" | awk 'NF > 3' > .opticsDataLines.dat
# Save mainDataBlock header
cat ${starin} | sed -n ${mainDataBlockNo},${mainDataLineNo}p | sed "/${versionSearch}/Q" | sed '$ d' > .mainDataHeader.dat
# Save mainDataLines, remove blank lines
cat ${starin} | sed -n "${mainDataLineNo},$ p" | sed '/^\s*$/d' > .mainDataLines.dat
# Save a single line of starin for certain calculations
sed -n '1p' .mainDataLines.dat > .mainDataLine.dat

# Files for diagnostics
#scp .opticsDataHeader.dat opticsDataHeader.dat
#scp .opticsDataLines.dat opticsDataLines.dat
#scp .mainDataHeader.dat mainDataHeader.dat
#scp .mainDataLines.dat mainDataLines.dat
#scp .mainDataLine.dat mainDataLine.dat
