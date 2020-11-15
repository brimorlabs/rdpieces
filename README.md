# [BriMor Labs](https://www.brimorlabs.com)

## RDPieces.pl

This script will parse extracted RDP Bitmap Cache directory(ies) and attempt to rebuild some of the screenshots automatically. A user is required to extract the bmp files already, best done by using the script from https://github.com/ANSSI-FR/bmc-tools 

(NOTE November 15, 2020: There is a bug with the "bmc-tools" script in that the data within the header of the output bitmap file size is four bytes too small. A modified version of the bmc-tools script that fixes this issue will be uploaded here, I recommend using this version until the bmc-tools script is updated)

Usage example:
rdpieces.pl -source "RDPBitmapFiles" -output "Rebuilt Images"

SUPPORTED PLATFORMS:
- Windows
- macOS
- \*nix

REQUIREMENTS:
- Needs output from ANSSI bmc-tools Python script (use Python 2) 
- May require some additional Perl modules
- On Windows, highly suggest using Strawberry Perl
- Users must have Imagemagick installed on their system, as that program does most of the heavy lifting. Please visit https://imagemagick.org and install imagemagick if you have not done so already


### Test-Cache-Files.zip

This contains a total of three RDP Bitmap Cache file that you can use for testing. Many thanks to Kat Hedley (https://twitter.com/4enzikat0r) for providing them!
