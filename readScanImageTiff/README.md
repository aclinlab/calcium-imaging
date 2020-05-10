# readScanImageTiff
Read and parse ScanImage .tif files

Use the function readScanImageTiffLinLab - type `help readScanImageTiffLinLab` at the Matlab command line for more info.

To use this you must first install the ScanImageTiffReader and add the ScanImageTiffReader folder (WITH SUBFOLDERS) to your Matlab path:

https://vidriotech.gitlab.io/scanimagetiffreader-matlab/

Troubleshooting:
If you need to remove frames or slices from your tiff file: You can use Fiji Image>Stacks>Tools>Make Substack to select the stacks you want to keep. Save the substack under a new filename. In order to edit the metadata file to match the changes you have made, in Fiji go to Plugins>Macros>saveMetadataAsText. This will create a metadata text file, with the name of the saved substack, followed by -metadata suffix, in the same location as the substack file. Now open this metadata file (can open in Fiji) and edit the entries "Series 0 Name" and "Location" to reflect the name and location of the substack, and change "SizeT" to match the size of the substack. 
