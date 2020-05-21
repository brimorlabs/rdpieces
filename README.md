# [BriMor Labs](https://www.brimorlabs.com)

## RDPieces.pl

This script will parse extracted RDP Bitmap Cache directory(ies) and attempt to rebuild some of the screenshots automatically. A user is required to extract the bmp files already, best done by using the script from https://github.com/ANSSI-FR/bmc-tools

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
