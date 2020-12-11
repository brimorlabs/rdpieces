# [BriMor Labs](https://www.brimorlabs.com)

## RDPieces.pl

This script will parse extracted RDP Bitmap Cache directory(ies) and attempt to rebuild some of the screenshots automatically. A user is required to extract the bmp files already, best done by using the script from https://github.com/ANSSI-FR/bmc-tools (The small bug that caused issues within their script has been fixed, and I have removed the modified from this repository. Sorry for not updating this until today!)


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
