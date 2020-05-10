# multiActivityMaps

Make and compare multiple activityMaps.

## 1. Make a text file specifying the input files

See the example file, `template input file.txt`.

Make the file in Excel and save it as 'Tab-delimited text.' It's easiest if you put this .txt file in the same directory as your movie files.

There are 5 columns:

1. file name, e.g. `180604 movie1.tif`
2. path name, e.g. `/Users/aclin/Lab/Data/180604/` (on Windows, directory separators are `\` instead of `/`) **Note: make sure you include the last `/` or `\` !** On a Mac, to find the path name for a file, select the file in Finder and run "Get Info..." (cmd-I) - you will have to add the / at the end.
3. conditions - this is for your benefit, to label each movie with a descriptor relevant to the experiment (e.g., what odor was presented, what drug given, temperature, etc.)
4. background - this is the value that you want Matlab to subtract from every pixel in the movie. The easiest way to find this is to select an ROI for the background in Fiji and run Image > Stacks > Plot z-axis profile, and estimate from the graph what the average value for the ROI is over the course of the movie. On 16-bit movies from ScanImage, you need to subtract 32768 (ScanImage pixel values are 16-bit unsigned integers and for some reason Fiji reads them in so that the 0 value is 32768 [2<sup>15</sup>] but Matlab reads them in with zero as 0). Note that if you registered the movie in Fiji, the registered movie will **8-bit** and then you don't have to subtract 32768. Make sure you enhance the contrast so that you can be sure that your ROI is really black. It's usually fair to assume this value is the same across all your movies if it's the same field of view and the imaging settings were the same.
5. correlation threshold. Set this to let Matlab ignore frames where the fly moved. Set it to 0 the first time you run the activity maps - after the activity maps are calculated, look at the correlation graphs to see if there are any sudden drops in correlation that correspond to sudden brain motion, which you can then exclude by setting a minimum correlation that each frame must meet to be included in the activity map. See Methods of Lin et al. 2014: "Frames in which the brain moved in the axial direction were automatically discarded by correlating each frame to the baseline image and discarding it if the correlation fell below a threshold value, which was manually selected for each brain by noting the constant high correlation value when the brain was stationary and sudden drops in correlation when the brain moved." 

**IMPORTANT: Put the movies all in the same order for your different flies (according to the conditions, e.g. different stimuli). This will make your life easier when you are combining all the data from different flies!**

### Troubleshooting

#### Error using mexScanImageTiffOpen: Could not open file.
* There may be a problem in the file names or path names in your .txt file. Check that
	* The file name ends with `.tif`
	* The path name is correct
	* The path name ends with a directory separator (`/` for Mac and `\` for Windows)


## 2. Run multiActivityMap

1. In Matlab, go to the directory where your movie files are.

2. At the Matlab prompt, run

	`multiActivityMap`
	
3. Matlab will prompt you to select a .txt file that contains the information in step 1 above.

4. You should get 2 figures. The first will show all the activity maps generated from the movies specified in your .txt file. Each row will be an 1 X N montage (N = number of slices) with 'hot' false color (dF/F) overlaid on grayscale (F0). Each map is labeled by the text you put under the 'conditions' column in your .txt file. If you want to change the scale of the grayscale or dF/F, you can edit the settings in displayMultiActivityMaps.m. The second shows a plot of the correlations over time of each movie, to let you decide if you want to set a correlation threshold to exclude frames where the fly moved too much. If so, go back to the original .txt file, put a correlation value under the correlation threshold column, and run multiActivityMap again.

5. multiActivityMap will store the activity maps in an array of activityMap objects called `allMaps`, and will save them in a .mat file with the same name as your input .txt file. This .mat file will go in the directory where you are currently.

## 3. Inspect the activity maps and the correlations

Do the activity maps look good? 

Do they match what you see with your own eyes when you watch the movie?

Any motion artifacts? (e.g lots of "activity" right at the edge of the object)

Do you want to set a correlation threshold?

### Troubleshooting

#### Motion artifacts
* Run xy registration and run the activity maps again

* Set a correlation threshold

#### Lots of "activity" where there is no baseline GCaMP signal
This might be noise, or maybe your driver has some weak GCaMP signal outside your cells of interest, in neurons that also respond to your stimulus. This might not be a problem - when you run the compareMaps operation to calculate the sparseness and correlation of your activity maps, you can exclude certain regions from the analysis.

## 4. Run compareMaps

1. At the Matlab prompt, run

	`result = compareMaps(allMaps, -1, f0Thres)`
	
	allMaps is an array of activityMap objects created by the function multiActivityMap
	
	-1 is a flag meaning that the function will ask you to draw areas to exclude from the analysis. Other possible flags are 0 (no manual drawing) and 1 (draw an area to INclude)
	
	**You need to replace f0Thres with an actual number. This is the threshold F0 value for including a pixel in the analysis, e.g. if you set it to 4, then only pixels where the F0 is above 4 will be included in the analysis. Matlab will show you a mask that it automatically creates based on this threshold. If you think this is wrong, cancel the analysis and run compareMaps again with a different threshold.** I am trying to think of a way to set the threshold automatically but haven't got it yet.
	
	Type `help compareMaps` to see the general syntax.
	
2. If your flag in step 1 was -1 or 1, Matlab will display a montage of the "maximum intensity" activity map across all your movies and ask you to outline areas to EXclude (-1) or INclude (1). The green outline indicates the mask defined by the f0Thres you set. Draw an outline. If you want to add another outline (e.g. because it's a montage and you need to add an area from another Z-slice), press the `a` key on the keyboard (while the figure is the top window), then draw another outline. If you want to subtract from your outline (e.g. you made a mistake), press the `s` key. If you are finished, press any other key.
	
3. `result` is a struct containing the following fields:

	```
             corrMatrix: [4×4 double]
    scrambledcorrMatrix: [4×4 double]
           angsepMatrix: [4×4 double]
             sparseness: [4×1 double]
                offsets: [4×2 double]
        linearMapMatrix: [4×51201 double]
                   mask: [150×256×10 logical]
                f0Thres: 2
     ```
     * `corrMatrix` is an N x N matrix where N is the number of movies. Each element is the correlation between one pair of activity maps
     * `scrambledcorrMatrix` is corrMatrix except the pixels in the activity maps have been scrambled. This should be 0!
     * `angsepMatrix` - like corrMatrix except it's the angular separation between activity maps (i.e. cosine distance)
     * `sparseness` -  N x 1 matrix of the population sparseness of each map, calculated pixel-wise
     * `offsets` stores the xy offsets needed to register the maps to each other according to their F0
     * `linearMapMatrix` stores the activity maps (one per row), only the pixels inside the mask, linearized into a row vector
     * `mask` the mask that was used to exclude pixels with no baseline fluorescence or pixels that aren't relevant to the analysis
     * `f0Thres` stores the threshold on F0 for defining the mask, which the user set
     
     The order of sparseness and correlation values will match the order of the files you had in your original .txt file
     
## 5. Save your compareMaps results

Run:

`save(strcat(experimentName, ' compareMaps.mat'), 'result');`

This will create a .mat file named after your input .txt file (with the suffix 'compareMaps'), containing the struct `result`.

----
Note: I put all the commands in a single script called multiActivityMapCompare, but you should probably run them separately so that you can inspect the activity maps before running the correlations.

## 6. Copy results into Excel or other program
Run in Matlab:

`copy(result.corrMatrix);`

This will copy the data into the clipboard. Then go to Excel (or other program) and paste the correlation data. This is what you should run if you have more than 2 odors.

If you only have 2 odors, you probably only care about the correlation between the two odors. Then you could do:

`copy(result.corrMatrix(1,2));`

to get the element in the 1st row, 2nd column of the correlation matrix (i.e. correlation between odor 1 and odor 2).

For sparseness:

`copy(result.sparseness');`

The `'` will transpose the sparseness data into a row instead of a column.

For maxDFF:

`copy(result.maxDFF');`