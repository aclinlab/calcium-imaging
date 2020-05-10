// "StartupMacros"
// The macros and macro tools in this file ("StartupMacros.txt") are
// automatically installed in the Plugins>Macros submenu and
//  in the tool bar when ImageJ starts up.

//  About the drawing tools.
//
//  This is a set of drawing tools similar to the pencil, paintbrush,
//  eraser and flood fill (paint bucket) tools in NIH Image. The
//  pencil and paintbrush draw in the current foreground color
//  and the eraser draws in the current background color. The
//  flood fill tool fills the selected area using the foreground color.
//  Hold down the alt key to have the pencil and paintbrush draw
//  using the background color or to have the flood fill tool fill
//  using the background color. Set the foreground and background
//  colors by double-clicking on the flood fill tool or on the eye
//  dropper tool.  Double-click on the pencil, paintbrush or eraser
//  tool  to set the drawing width for that tool.
//
// Icons contributed by Tony Collins.

// Global variables
var pencilWidth=1,  eraserWidth=10, leftClick=16, alt=8;
var brushWidth = 10; //call("ij.Prefs.get", "startup.brush", "10");
var floodType =  "8-connected"; //call("ij.Prefs.get", "startup.flood", "8-connected");

// The macro named "AutoRunAndHide" runs when ImageJ starts
// and the file containing it is not displayed when ImageJ opens it.

// macro "AutoRunAndHide" {}

function UseHEFT {
	requires("1.38f");
	state = call("ij.io.Opener.getOpenUsingPlugins");
	if (state=="false") {
		setOption("OpenUsingPlugins", true);
		showStatus("TRUE (images opened by HandleExtraFileTypes)");
	} else {
		setOption("OpenUsingPlugins", false);
		showStatus("FALSE (images opened by ImageJ)");
	}
}

UseHEFT();

// The macro named "AutoRun" runs when ImageJ starts.

macro "AutoRun" {
	// run all the .ijm scripts provided in macros/AutoRun/
	autoRunDirectory = getDirectory("imagej") + "/macros/AutoRun/";
	if (File.isDirectory(autoRunDirectory)) {
		list = getFileList(autoRunDirectory);
		// make sure startup order is consistent
		Array.sort(list);
		for (i = 0; i < list.length; i++) {
			if (endsWith(list[i], ".ijm")) {
				runMacro(autoRunDirectory + list[i]);
			}
		}
	}
}

var pmCmds = newMenu("Popup Menu",
	newArray("Help...", "Rename...", "Duplicate...", "Original Scale",
	"Paste Control...", "-", "Record...", "Capture Screen ", "Monitor Memory...",
	"Find Commands...", "Control Panel...", "Startup Macros...", "Search..."));

macro "Popup Menu" {
	cmd = getArgument();
	if (cmd=="Help...")
		showMessage("About Popup Menu",
			"To customize this menu, edit the line that starts with\n\"var pmCmds\" in ImageJ/macros/StartupMacros.txt.");
	else
		run(cmd);
}

macro "Abort Macro or Plugin (or press Esc key) Action Tool - CbooP51b1f5fbbf5f1b15510T5c10X" {
	setKeyDown("Esc");
}

var xx = requires138b(); // check version at install
function requires138b() {requires("1.38b"); return 0; }

var dCmds = newMenu("Developer Menu Tool",
newArray("ImageJ Website","News", "Documentation", "ImageJ Wiki", "Resources", "Macro Language", "Macros",
	"Macro Functions", "Startup Macros...", "Plugins", "Source Code", "Mailing List Archives", "-", "Record...",
	"Capture Screen ", "Monitor Memory...", "List Commands...", "Control Panel...", "Search...", "Debug Mode"));

macro "Developer Menu Tool - C037T0b11DT7b09eTcb09v" {
	cmd = getArgument();
	if (cmd=="ImageJ Website")
		run("URL...", "url=http://rsbweb.nih.gov/ij/");
	else if (cmd=="News")
		run("URL...", "url=http://rsbweb.nih.gov/ij/notes.html");
	else if (cmd=="Documentation")
		run("URL...", "url=http://rsbweb.nih.gov/ij/docs/");
	else if (cmd=="ImageJ Wiki")
		run("URL...", "url=http://imagejdocu.tudor.lu/imagej-documentation-wiki/");
	else if (cmd=="Resources")
		run("URL...", "url=http://rsbweb.nih.gov/ij/developer/");
	else if (cmd=="Macro Language")
		run("URL...", "url=http://rsbweb.nih.gov/ij/developer/macro/macros.html");
	else if (cmd=="Macros")
		run("URL...", "url=http://rsbweb.nih.gov/ij/macros/");
	else if (cmd=="Macro Functions")
		run("URL...", "url=http://rsbweb.nih.gov/ij/developer/macro/functions.html");
	else if (cmd=="Plugins")
		run("URL...", "url=http://rsbweb.nih.gov/ij/plugins/");
	else if (cmd=="Source Code")
		run("URL...", "url=http://rsbweb.nih.gov/ij/developer/source/");
	else if (cmd=="Mailing List Archives")
		run("URL...", "url=https://list.nih.gov/archives/imagej.html");
	else if (cmd=="Debug Mode")
		setOption("DebugMode", true);
	else if (cmd!="-")
		run(cmd);
}

var sCmds = newMenu("Stacks Menu Tool",
	newArray("Add Slice", "Delete Slice", "Next Slice [>]", "Previous Slice [<]", "Set Slice...", "-",
		"Convert Images to Stack", "Convert Stack to Images", "Make Montage...", "Reslice [/]...", "Z Project...",
		"3D Project...", "Plot Z-axis Profile", "-", "Start Animation", "Stop Animation", "Animation Options...",
		"-", "MRI Stack (528K)"));
macro "Stacks Menu Tool - C037T0b11ST8b09tTcb09k" {
	cmd = getArgument();
	if (cmd!="-") run(cmd);
}

var luts = getLutMenu();
var lCmds = newMenu("LUT Menu Tool", luts);
macro "LUT Menu Tool - C037T0b11LT6b09UTcb09T" {
	cmd = getArgument();
	if (cmd!="-") run(cmd);
}
function getLutMenu() {
	list = getLutList();
	menu = newArray(16+list.length);
	menu[0] = "Invert LUT"; menu[1] = "Apply LUT"; menu[2] = "-";
	menu[3] = "Fire"; menu[4] = "Grays"; menu[5] = "Ice";
	menu[6] = "Spectrum"; menu[7] = "3-3-2 RGB"; menu[8] = "Red";
	menu[9] = "Green"; menu[10] = "Blue"; menu[11] = "Cyan";
	menu[12] = "Magenta"; menu[13] = "Yellow"; menu[14] = "Red/Green";
	menu[15] = "-";
	for (i=0; i<list.length; i++)
		menu[i+16] = list[i];
	return menu;
}

function getLutList() {
	lutdir = getDirectory("luts");
	list = newArray("No LUTs in /ImageJ/luts");
	if (!File.exists(lutdir))
		return list;
	rawlist = getFileList(lutdir);
	if (rawlist.length==0)
		return list;
	count = 0;
	for (i=0; i< rawlist.length; i++)
		if (endsWith(rawlist[i], ".lut")) count++;
	if (count==0)
		return list;
	list = newArray(count);
	index = 0;
	for (i=0; i< rawlist.length; i++) {
		if (endsWith(rawlist[i], ".lut"))
			list[index++] = substring(rawlist[i], 0, lengthOf(rawlist[i])-4);
	}
	return list;
}

macro "Pencil Tool - C037L494fL4990L90b0Lc1c3L82a4Lb58bL7c4fDb4L5a5dL6b6cD7b" {
	getCursorLoc(x, y, z, flags);
	if (flags&alt!=0)
		setColorToBackgound();
	draw(pencilWidth);
}

macro "Paintbrush Tool - C037La077Ld098L6859L4a2fL2f4fL3f99L5e9bL9b98L6888L5e8dL888c" {
	getCursorLoc(x, y, z, flags);
	if (flags&alt!=0)
		setColorToBackgound();
	draw(brushWidth);
}

macro "Flood Fill Tool -C037B21P085373b75d0L4d1aL3135L4050L6166D57D77D68La5adLb6bcD09D94" {
	requires("1.34j");
	setupUndo();
	getCursorLoc(x, y, z, flags);
	if (flags&alt!=0) setColorToBackgound();
	floodFill(x, y, floodType);
}

function draw(width) {
	requires("1.32g");
	setupUndo();
	getCursorLoc(x, y, z, flags);
	setLineWidth(width);
	moveTo(x,y);
	x2=-1; y2=-1;
	while (true) {
		getCursorLoc(x, y, z, flags);
		if (flags&leftClick==0) exit();
		if (x!=x2 || y!=y2)
			lineTo(x,y);
		x2=x; y2 =y;
		wait(10);
	}
}

function setColorToBackgound() {
	savep = getPixel(0, 0);
	makeRectangle(0, 0, 1, 1);
	run("Clear");
	background = getPixel(0, 0);
	run("Select None");
	setPixel(0, 0, savep);
	setColor(background);
}

// Runs when the user double-clicks on the pencil tool icon
macro 'Pencil Tool Options...' {
	pencilWidth = getNumber("Pencil Width (pixels):", pencilWidth);
}

// Runs when the user double-clicks on the paint brush tool icon
macro 'Paintbrush Tool Options...' {
	brushWidth = getNumber("Brush Width (pixels):", brushWidth);
	call("ij.Prefs.set", "startup.brush", brushWidth);
}

// Runs when the user double-clicks on the flood fill tool icon
macro 'Flood Fill Tool Options...' {
	Dialog.create("Flood Fill Tool");
	Dialog.addChoice("Flood Type:", newArray("4-connected", "8-connected"), floodType);
	Dialog.show();
	floodType = Dialog.getChoice();
	call("ij.Prefs.set", "startup.flood", floodType);
}

macro "Set Drawing Color..."{
	run("Color Picker...");
}

macro "-" {} //menu divider

macro "About Startup Macros..." {
	title = "About Startup Macros";
	text = "Macros, such as this one, contained in a file named\n"
		+ "'StartupMacros.txt', located in the 'macros' folder inside the\n"
		+ "Fiji folder, are automatically installed in the Plugins>Macros\n"
		+ "menu when Fiji starts.\n"
		+ "\n"
		+ "More information is available at:\n"
		+ "<http://imagej.nih.gov/ij/developer/macro/macros.html>";
	dummy = call("fiji.FijiTools.openEditor", title, text);
}

macro "Save As JPEG... [j]" {
	quality = call("ij.plugin.JpegWriter.getQuality");
	quality = getNumber("JPEG quality (0-100):", quality);
	run("Input/Output...", "jpeg="+quality);
	saveAs("Jpeg");
}

macro "Save Inverted FITS" {
	run("Flip Vertically");
	run("FITS...", "");
	run("Flip Vertically");
}
/**************************************************
 * Everything above this comment came with standard Fiji
 * Everything below this comment was written by Andrew Lin and members of the Lin lab
 **************************************************
 */
/*
 * To use:
 * Draw an ROI, save it to the ROI manager (shortcut: t)
 * Then draw an ROI for the background, save that to the ROI manager
 * This will then print the delta-F/F for the first ROI over the course of the movie to the Log
 * It will also draw a plot of the delta-F/F, over time if it found the frame rate
 */
macro "DFF [b]" {

	// try to find the frame rate from the header info
	info = getMetadata("Info");
	indexScanVolumeRate = indexOf(info,"scanVolumeRate");
	indexLogAverageFactor = indexOf(info,"logAverageFactor");
	// if you can't find the frame rate, ask user to input F0 limits
	if ((indexScanVolumeRate==-1)||(indexLogAverageFactor==-1)) {
		frameTime = 1;
		foundFrameRate = 0;
		Dialog.create("Frames over which to average F0");
		Dialog.addMessage("Couldn't find the frame rate!\nPick frames for F0");
		Dialog.addNumber("From", 1000);
		Dialog.addNumber("To", 1100);
	} else {
		foundFrameRate = 1;
		// if you did find the frame rate, ask user ot input F0 limits in seconds
		newlineIndex = indexOf(info,"\n",indexScanVolumeRate);
		frameTime = 1/parseFloat(substring(info, indexScanVolumeRate+17,newlineIndex));		
		newlineIndex = indexOf(info,"\n",indexLogAverageFactor);
		logAverageFactor = parseFloat(substring(info, indexLogAverageFactor+19,newlineIndex));	
		frameTime *= logAverageFactor;	
		Dialog.create("Time over which to average F0");
		Dialog.addNumber("From", 18, 0, 3, "s");
		Dialog.addNumber("To", 20, 0, 3, "s");
	}
	Dialog.show();
	from = Dialog.getNumber();
	to = Dialog.getNumber();
	if (foundFrameRate == 1) {
		from = round(from/frameTime);
		to = round(to/frameTime);
	}
	if (from<1) from=1;
	if (to <= from) exit("Error: To value must be greater than from value");
	nAvg = to - from + 1;
	// nAvg = getNumber("Average F0 over first X frames: (enter X)", 50);
	numSlices = nSlices;
	
	title = getTitle();
	
	xArray = newArray(numSlices);
	for (i=0; i<numSlices; i++) xArray[i] = i*frameTime;
	
	print("\\Clear");
	
	selectWindow(title);
	
	// Select second-to-last ROI in ROI manager
	roiManager("select", (roiManager("count") - 2));
	run("Plot Z-axis Profile");
	Plot.getValues(x,f);
	run("Close");
	
	selectWindow(title);
	
	// Select last ROI in ROI manager
	roiManager("select", (roiManager("count") - 1));
	run("Plot Z-axis Profile");
	Plot.getValues(x,bkgnd);
	run("Close");
	
	// Subtract bkgnd
	for (i=0; i<numSlices; i++) f[i] = f[i] - bkgnd[i];
	
	// Calculate average over frames specified by from-to
	sum = 0;
	for (i=from-1; i<to; i++) sum = sum + f[i];
	f0 = sum / nAvg;
	
	// Calculate DF/F
	dff = newArray(numSlices);
	for (i=0; i<numSlices; i++) dff[i] = (f[i] - f0) / f0;
	
	// Print
	String.resetBuffer;
	for (i=0; i<numSlices; i++) {
		print(dff[i]);
		String.append(dff[i]+"\n");
	}
	String.copy(String.buffer);
	if (foundFrameRate==0) {
		Plot.create("DFF/F "+title, "Frame [frame rate unknown]", "DF/F", xArray, dff);	
	} else {
		Plot.create("DFF/F "+title, "Time (s) Frame time = "+frameTime+" s, frame rate = "+1/frameTime+" Hz", "DF/F", xArray, dff);
	}
	selectWindow("Log");
}

/*
 * To use:
 * Draw a series of ROIs, save them to the ROI manager (shortcut: t)
 * Then draw an ROI for the background, save that to the ROI manager
 * This will then print the delta-F/F for all the ROIs over the course of the movie to the Log
 * It will also draw a plot of the delta-F/F traces, over time if it found the frame rate
 */
 
macro "DFFmulti [g]" {

	// try to find the frame rate from the header info
	info = getMetadata("Info");
	indexScanVolumeRate = indexOf(info,"scanVolumeRate");
	indexLogAverageFactor = indexOf(info,"logAverageFactor");
	// if you can't find the frame rate, ask user to input F0 limits
	if ((indexScanVolumeRate==-1)||(indexLogAverageFactor==-1)) {
		frameTime = 1;
		foundFrameRate = 0;
		Dialog.create("Frames over which to average F0");
		Dialog.addMessage("Couldn't find the frame rate!\nPick frames for F0");
		Dialog.addNumber("# ROIs", 2);
		Dialog.addNumber("From", 1000);
		Dialog.addNumber("To", 1100);
	} else {
		foundFrameRate = 1;
		// if you did find the frame rate, ask user ot input F0 limits in seconds
		newlineIndex = indexOf(info,"\n",indexScanVolumeRate);
		frameTime = 1/parseFloat(substring(info, indexScanVolumeRate+17,newlineIndex));		
		newlineIndex = indexOf(info,"\n",indexLogAverageFactor);
		logAverageFactor = parseFloat(substring(info, indexLogAverageFactor+19,newlineIndex));	
		frameTime *= logAverageFactor;	
		Dialog.create("Time over which to average F0");
		Dialog.addNumber("# ROIs", 2);
		Dialog.addNumber("From", 18, 0, 3, "s");
		Dialog.addNumber("To", 20, 0, 3, "s");
	}
	Dialog.show();
	numROIs = Dialog.getNumber();
	from = Dialog.getNumber();
	to = Dialog.getNumber();
	if (foundFrameRate == 1) {
		from = round(from/frameTime);
		to = round(to/frameTime);
	}
	if (from<1) from=1;
	
	if (to <= from) exit("Error: To value must be greater than from value");
	nAvg = to - from + 1;
	// nAvg = getNumber("Average F0 over first X frames: (enter X)", 50);
	numSlices = nSlices;
	title = getTitle();

	xArray = newArray(numSlices);
	for (i=0; i<numSlices; i++) xArray[i] = i*frameTime;
	
	print("\\Clear");

	// f will be a 1D array simulating a numSlices x (numROIs+1) matrix
	// the (i,j) position in the matrix will be (i+numSlices*j)
	// NB indexing in ImageJ macro language starts at 0
	// we do numROIs + 1 because the last ROI is the background ROI
	f = newArray(numSlices*(numROIs+1));
	for (j=0; j<(numROIs+1); j++) {
		selectWindow(title);
		// load the ROIs into f in forward order
		// so background ROI is last
		roiManager("select", (roiManager("count") - (numROIs+1-j)));
		run("Plot Z-axis Profile");
		Plot.getValues(x,y);
		for (i=0; i<numSlices; i++) {
			f[i+numSlices*j] = y[i];
		}
		run("Close");
	}

	// now we only work on the real ROIs
	dff = newArray(numSlices*numROIs);
	for (j=0; j<numROIs; j++) {
		// subtract bkgnd
		for (i=0; i<numSlices; i++) {
			// remember, the bkgnd ROI is the last column
			dff[i+numSlices*j] = f[i+numSlices*j] - f[i+numSlices*numROIs];
		}
		// Calculate average over frames specified by from-to
		sum = 0;
		for (i=from-1; i<to; i++) {
			sum = sum+dff[i+numSlices*j];
		}
		f0 = sum/nAvg;
		// calculate DFF
		for (i=0; i<numSlices; i++) {
			dff[i+numSlices*j] = (dff[i+numSlices*j] - f0) / f0;
		}
	}
	
	// Print
	String.resetBuffer;
	for (i=0; i<numSlices; i++) {
		thisLine = "";
		for (j=0; j<numROIs; j++) {
			if (j<(numROIs-1)) {
				thisLine = thisLine+dff[i+numSlices*j]+"	"; //tab
			} else {
				thisLine = thisLine+dff[i+numSlices*j];
			}
		}
		print(thisLine);
		String.append(thisLine+"\n");
	}
	String.copy(String.buffer);
	if (foundFrameRate==0) {
		Plot.create("DFF/F "+title, "Frame [unknown frame rate]", "DF/F");
	} else {
		Plot.create("DFF/F "+title, "Time (s) Frame time = "+frameTime+" s, frame rate = "+1/frameTime+" Hz", "DF/F");		
	}
	colors = newArray("black", "blue", "red", "green", "cyan", "darkGray", "gray", "lightGray", "magenta", "orange", "pink", "yellow");
	for (j=0; j<numROIs; j++) {
		Plot.setColor(colors[j]);
		Plot.add("line", xArray, Array.slice(dff,j*numSlices,(j+1)*numSlices-1));
	}
	Plot.setLimitsToFit();
	selectWindow("Log");
}


macro "Smooth and Register All..." {

	directory = getDirectory("Directory contining files to register:");
	// output = getDirectory("Output directory"); // use this line if you want to put the output files in a different folder
	
	// only process files ending in .tif
	suffix = ".tif";
	
	smoothAndRegisterFolder(directory, suffix);
}

/*
 * This will call "Smooth and Register This Movie" for every file ending in suffix in the folder directory,
 * and save the outputs to the same folder
 * It will also deal with subdirectories recursively
 */
function smoothAndRegisterFolder(directory, suffix) {
	list = getFileList(directory);
	for (i = 0; i < list.length; i++) {
		// process subdirectories recursively
		if(File.isDirectory(directory + list[i]))
			smoothAndRegisterFolder("" + directory + list[i]);
		// process only files ending in suffix
		if(endsWith(list[i], suffix)) {
			run("Bio-Formats Windowless Importer", "open=["+directory+list[i]+"]");
			run("Smooth and Register This Movie", "Crop to last ROI=false Volume=true Template average from=1 Template average to="+nSlices+" Maximum displacement="+20);
			run("Close All","OK");
		}
	}
}

/*
 * This function will take the open window,
 * smooth it (Gaussian sigma=4), and run the moco motion correction algorithm against a z-projection of that movie,
 * save the displacement log as filename-moco-log.xls,
 * close the smoothed file, and use the displacement log to register the original file
 * then save that as filename-reg.[whatever the file suffix was], in the same directory
 * It will also transfer over the original metadata of the file
 * Note: the file must be opened BEFORE you call this macro! (so that users can also use this function on a file they opened themselves)
 * Options:
 * Crop wih last ROI: register the moving using only the subregion defined by the last ROI in the ROI manager
 * Volume: if you have volume imaging from ScanImage - collapse the volume into a single plane, find the registration needed for that,
 * then register the entire original movie based on that
 * Multi-channel: if you have multiple channels, select the channel you want to use for registration
 */
macro "Smooth and Register This Movie" {
	directory = getInfo("image.directory");
	filename = getInfo("image.filename");

	run("8-bit");
	
	nameOriginalImage = tagFileName(filename, "-original");
	rename(nameOriginalImage);
	
	Dialog.create("Parameters for moco");
	Dialog.addCheckbox("Crop with last ROI", false);
	Dialog.addCheckbox("Volume", false);
	Dialog.addCheckbox("Multi-channel", false);
	Dialog.addCheckbox("Ceiling at mean", false);
	Dialog.addNumber("Template average from", 1);
	Dialog.addNumber("Template average to", nSlices);
	Dialog.addNumber("Maximum displacement", 20);
	Dialog.addNumber("Register on channel:", 1);
	Dialog.addString("File suffix:", "-reg", 6);
	Dialog.show();
	crop = Dialog.getCheckbox();
	volume = Dialog.getCheckbox();
	multiChannel = Dialog.getCheckbox();
	ceilingAtMean = Dialog.getCheckbox();
	from = Dialog.getNumber();
	to = Dialog.getNumber();
	w = Dialog.getNumber();
	channelToRegister = Dialog.getNumber();
	tag = Dialog.getString();

	// save the metadata from the original image
	info = getMetadata("Info");

	// duplicate the stack, keep the original image open
	run("Duplicate...", "duplicate");

	// if you want to register only a sub-region of the movie
	if (crop) {
		roiManager("select", (roiManager("count") - 1));
		run("Crop");
	}
	// default values
	numFramesPerVolume = 1;
	numDiscardFlybackFrames = 0;
	numChannels = 1;

	if ((volume)||(multiChannel)) {
		// find the volume stack info from the header info
		hyperstackParams = getHyperstackParams(info);
		numFramesPerVolume = hyperstackParams[0];
		numDiscardFlybackFrames = hyperstackParams[1];
		numChannels = hyperstackParams[2];
		tempName = getTitle();
		run("VolumeMovieToHyperstack");
		selectWindow(tagFileName(tempName,"-hyper"));
	}
	if (multiChannel) {
		// go to the channel you want to register
		Stack.setChannel(channelToRegister);
		// delete the other channel(s)
		run("Reduce Dimensionality...", "slices frames");
		rename(tagFileName(getTitle(),"-singlechannel"));
	}
	// if you have a volume, collapse the volume for each time point and register on that z-projection
	if (volume) {
		thisName = getTitle();
		run("Z Project...", "projection=[Average Intensity] all");
		rename(tagFileName(thisName,"-zproject")); // so it doesn't have the prefix "AVG_" in front but just the suffix -zproject
	}

	// call registerReturnLog to register the movie and get the log file name
	registerReturnValues = registerReturnLog(getTitle(), from, to, w, ceilingAtMean);
	regLogName = registerReturnValues[0];
	template = registerReturnValues[1];
	// go back to the original file
	selectWindow(nameOriginalImage);
	if ((volume)||(multiChannel)) {
		open(directory + regLogName);
		// for volume imaging, translate the frames "manually"
		for (i=1; i<=nSlices; i++) {
			setSlice(i);
			volumeIndex = floor((i-1)/(numFramesPerVolume*numChannels));
			run("Translate...", "x="+getResult("x",volumeIndex)+" y="+getResult("y",volumeIndex)+" interpolation=None slice");
		}
	} else {
		// run moco using the saved displacements from registering the smoothed movie
		run("moco ", "value=51 downsample_value=0 template=["+template+"] stack=["+filename+"] log=[Choose log file] plot=[No plot] choose=["+directory+regLogName+"]");
	} 
	run("Fire");
	// add the original metadata to the new file
	setMetadata("Info", info);
	regName = tagFileName(filename, tag);
	rename(regName);
	saveAs("tiff", directory+regName);
	run("saveMetadataAsText");
}

function registerReturnLog(windowName, from, to, w, ceilingAtMean) {
	/*
	 * take an open movie, smooth and register it, then save and return the name of the log file
	 * so that the calling function can use it to register an arbitrary movie
	 */
	selectWindow(windowName);
	if ((from==0)||(to==0)||(w==0)) {
		Dialog.create("Parameters for moco");
		Dialog.addNumber("Template average from", 1);
		Dialog.addNumber("Template average to", nSlices);
		Dialog.addNumber("Maximum displacement", 20);
		Dialog.show();
		from = Dialog.getNumber();
		to = Dialog.getNumber();
		w = Dialog.getNumber();
	}
	// convert file to 8-bit, use Fire lookup table
	run("8-bit");

	// smooth the file
	run("Gaussian Blur...", "sigma=4 stack");
	smoothedFileName = windowName+"-smoothed";
	rename(smoothedFileName);

	/*
	 make the average for the registration template
	 The reason for allowing different limits is sometimes the object is stationary for 1/2 the movie and then starts moving
	 around wildly, so better to use the stationary part as your template
	*/
	run("Z Project...", "start="+from+" stop="+to+" projection=[Average Intensity]");
	template = "AVG_"+smoothedFileName;

	if (ceilingAtMean) {
		/* 
		 * Find the mean pixel value in the template. Then set that mean as a "ceiling" so anything above that mean is set to that mean
		 * This is to prevent genuine responses that might be asymmetrical from making moco think that the sample moved even though it didn't
		 * I'm not sure if using the mean is the correct ceiling - this will take some playing around with!
		 */
		getStatistics(area, mean, min, max, std);
		for (x=0; x<getWidth(); x++) {
			for (y=0; y<getHeight(); y++) {
				if (getPixel(x,y)>mean) {
					setPixel(x,y,mean);
				}
			}
		}
		selectWindow(smoothedFileName);
		
		for (i=1; i<=nSlices; i++) {
			setSlice(i);
			for (x=0; x<getWidth(); x++) {
				for (y=0; y<getHeight(); y++) {
					if (getPixel(x,y)>mean) {
						setPixel(x,y,mean);
					}
				}
			}
		}
	}

	// run the registration algorithm on the SMOOTHED movie
	run("moco ", "value="+w+" downsample_value=0 template=["+template+"] stack=["+smoothedFileName+"] log=[Generate log file] plot=[No plot]");
	selectWindow("Results");
	// save the log storing the displacement info
	regLogName = windowName+"-moco-log.xls";
	saveAs("Results", directory+regLogName);
	// close the registered movie without saving
	selectWindow("New Stack");
	run("Close", "Don't Save");
	// close the smoothed movie without saving
	selectWindow(smoothedFileName);
	run("Close", "Don't Save");
	return newArray(regLogName, template);
	// leave the template window open because moco requires a template image even if it's not using it

}

macro "Close All Windows [F4]" { 
	while (nImages>0) { 
		selectImage(nImages); 
		close(); 
	}
}

/*
 * takes in a string which is the ScanImage metadata
 * returns an array with the extracted parameters in this order:
 * 0. numFramesPerVolume
 * 1. numDiscardFlybackFrames
 * 2. numChannels
 */
function getHyperstackParams(info) {
	indexNumFramesPerVolume = indexOf(info,"numFramesPerVolume");
	indexNumDiscardFlybackFrames = indexOf(info,"numDiscardFlybackFrames");
	indexChannelSave = indexOf(info,"channelSave");
	if ((indexNumFramesPerVolume==-1)||(indexNumDiscardFlybackFrames==-1)||(indexChannelSave==-1)) {
		foundFramesPerVolume = 0;
		Dialog.create("Frames per volume");
		Dialog.addMessage("Couldn't find # frames per volume\n");
		Dialog.addNumber("# frames per volume (incl. discarded)", 10);
		Dialog.addNumber("# frames discarded", 2);
		Dialog.addNumber("# channels", 1);
		Dialog.show();
		numFramesPerVolume = Dialog.getNumber();
		numDiscardFlybackFrames = Dialog.getNumber();
		numChannels = Dialog.getNumber();
	} else {
		foundFramesPerVolume = 1;
		newlineIndex = indexOf(info,"\n",indexNumFramesPerVolume);
		numFramesPerVolume = parseFloat(substring(info, indexNumFramesPerVolume+21,newlineIndex));
		if (isNaN(numFramesPerVolume)) {
			numFramesPerVolume = 1;
		}
		newlineIndex = indexOf(info,"\n",indexNumDiscardFlybackFrames);
		numDiscardFlybackFrames = parseFloat(substring(info, indexNumDiscardFlybackFrames+26,newlineIndex));	
		newlineIndex = indexOf(info,"\n",indexChannelSave);
		channelSaveParam = substring(info, indexChannelSave+14,newlineIndex);
		// this is a hack because the SI.hChannels.channelSave parameter is "1" for one channel, "[1;2]" for 2 channels
		// I don't know what it would be for 3 channels but I assume "[1;2;3]"
		if (lengthOf(channelSaveParam) < 2) {
			numChannels = 1;
		} else {
			numChannels = (lengthOf(channelSaveParam)-1)/2;
		}	
	}
	return newArray(numFramesPerVolume, numDiscardFlybackFrames, numChannels);
	
}

// creates a hyperstack that will be the name of the original file + "hyper" eg test.tif --> test-hyper.tif
macro "VolumeMovieToHyperstack" {
	name = getTitle();
	info = getMetadata("Info");
	// try to find the volume stack info from the header info
	hyperstackParams = getHyperstackParams(info);
	numFramesPerVolume = hyperstackParams[0];
	numDiscardFlybackFrames = hyperstackParams[1];
	numChannels = hyperstackParams[2];

	// get the floor of nSlices/(numFramesPerVolume*numChannels)
	numVolumes = floor(nSlices/(numFramesPerVolume*numChannels));
	correctNumSlices = numVolumes*numFramesPerVolume*numChannels;
	numSlicesToAdd = correctNumSlices - nSlices;
	setSlice(nSlices); // go to last slice
	// add or delete slices to pad the stack out to the correct number of slices
	if (numSlicesToAdd<0) {
		for (i=numSlicesToAdd; i<0; i++) {
			run("Delete Slice");
		}
	}
	else if (numSlicesToAdd>0) {
		for (i=0; i<numSlicesToAdd; i++) {
			run("Add Slice");
		}
	}
	// note running "Stack to Hyperstack..." doesn't keep the original stack
	run("Stack to Hyperstack...", "order=xyczt(default) channels="+numChannels+" slices="+numFramesPerVolume+" frames="+numVolumes+" display=Grayscale");
	// we assume that the discarded frames come at the end of the stack
	run("Make Substack...", "slices=1-"+(numFramesPerVolume-numDiscardFlybackFrames)+" frames=1-"+numVolumes);
	rename(tagFileName(name,"-hyper"));
	setMetadata("Info", info+"\nSI.LinLab.flybackFramesDeleted = true\n");
	// close the original window
	selectWindow(name);
	run("Close", "Don't Save");	
}

macro "HyperstackToMontage" {
	name = getTitle();
	if (!Stack.isHyperstack) {
		exit(name + " is not a hyperstack!");
	}
	info = getMetadata("Info");
	getDimensions(width,height,channels,slices,frames);

	for (c=1; c<=channels; c++) {
		selectWindow(name);
		if (channels>1) {
			Stack.setChannel(c);
			run("Reduce Dimensionality...", "slices frames keep");
			thisChannelName = tagFileName(name,"-channel"+toString(c));
			rename(thisChannelName);
		} else {
			thisChannelName = name;
		}
		run("Deinterleave","how="+slices);
		// we assume that the discarded frames come at the end of the stack
		paramsForMultiStackMontage = "";
		for (i=1; i<=slices; i++) {
			paramsForMultiStackMontage += "stack_"+i+"=["+thisChannelName+" #"+i+"] ";
		}
		// how many rows and columns?
		// I started to try to do this more elegantly but gave up
		// refRows and refCols define how many rows and columns you want for up to 20 elements. After that, just use floor(sqrt())+1
		refRows = newArray(0,1,1,1,2,2,2,2,2,3,2,2,2,3,3,3,4,3,3,4,4);
		refCols = newArray(0,1,2,3,2,3,3,4,4,3,5,6,6,5,5,5,4,6,6,5,5);
		if (slices<=20) {
			numRows = refRows[slices];
			numCols = refCols[slices];
		} else {
			numRows = floor(sqrt(slices))+1;
			numCols = floor(sqrt(slices))+1;
		}
		paramsForMultiStackMontage += "rows="+numRows+" columns="+numCols;
		//print(paramsForMultiStackMontage);
		run("Multi Stack Montage...", paramsForMultiStackMontage);
		run("Fire");
		rename(tagFileName(thisChannelName, "-montage"));
		setMetadata("Info", info);
		run("Z Project...", "start="+1+" stop="+nSlices+" projection=[Average Intensity]");	
		// close the de-interleaving intermediates
		for (i=1; i<=slices; i++) {
			selectWindow(thisChannelName+" #"+i);
			run("Close", "Don't Save");
		}
	}
}

macro "VolumeMovieToMontage [6]" {
	name = getTitle();
	run("VolumeMovieToHyperstack");
	selectWindow(tagFileName(name,"-hyper"));
	run("HyperstackToMontage");
}


/*
 * adds a tag into a filename before the .
 * eg if you call tagFileName("test.tif", "-foo") you will get back "test-foo.tif"
 * if there is no dot, you just append the tag to the end, eg tagFileName("testtif", "-foo") returns "testtif-foo")
 */
function tagFileName(filename, tag) {
	suffixIndex = lastIndexOf(filename,"."); // find the last '.' in the file name to find the suffix
	if (suffixIndex != -1) {
		namePrefix = substring(filename, 0, suffixIndex); // everything up to the .
		nameSuffix = substring(filename, suffixIndex, lengthOf(filename)); //everything after the . including the .
	} else {
		namePrefix = filename;
		nameSuffix = "";
	}
	return namePrefix+tag+nameSuffix;
	
}

// note: this saves the .txt file in whatever directory was last opened by open(), saveAs(), File.open() or File.openAsString().
macro "saveMetadataAsText" {
	filename = getTitle()
	suffixIndex = lastIndexOf(filename,"."); // find the last '.' in the file name to find the suffix
	if (suffixIndex != -1) {
		namePrefix = substring(filename, 0, suffixIndex); // everything up to the .
	} else {
		namePrefix = filename;
	}
	metadataTextFileName = namePrefix+"-metadata.txt";
	info = getMetadata("Info");
	File.saveString(info,File.directory+metadataTextFileName);
}

// Use this macro to set the x y z calibration of confocal stacks captured on the 2P
// and also to set the frames to be z-slices instead of time points
// Works by extracting ScanImage properties from the metadata in "Get Info..."
macro "set2PConfocalProperties" {

	info = getMetadata("Info");
	zoomFactor = getMetadataParam(info, "SI.hRoiManager.scanZoomFactor");
	pixelsPerLine = getMetadataParam(info, "SI.hRoiManager.pixelsPerLine");
	linesPerFrame = getMetadataParam(info, "SI.hRoiManager.linesPerFrame");
	scanAngleMultiplierFast = getMetadataParam(info, "scanAngleMultiplierFast");
	scanAngleMultiplierSlow = getMetadataParam(info, "scanAngleMultiplierSlow");
	anchor = 0.16; // 0.16 microns per pixel for 8x zoom, 512x512 image
	anchorPixelsPerLine = 512;
	anchorLinesPerFrame = 512;
	anchorZoom = 8;
	xcal = anchor * scanAngleMultiplierFast / (zoomFactor/anchorZoom) / (pixelsPerLine/anchorPixelsPerLine);
	ycal = anchor * scanAngleMultiplierSlow / (zoomFactor/anchorZoom) / (linesPerFrame/anchorLinesPerFrame);
	zcal = getMetadataParam(info, "SI.hStackManager.stackZStepSize");
	numSlices = getMetadataParam(info, "SI.hStackManager.numSlices");

	run("Properties...", "slices="+numSlices+" frames=1 unit=micron pixel_width="+xcal+" pixel_height="+ycal+" voxel_depth="+zcal);
}

// input info string and keyword
// return the number associated with that keyword in ScanImage parameters
// returns NaN if no value found or it's not a number
function getMetadataParam(info, keyword) {
	index = indexOf(info,keyword);
	if (index==-1) {
		return NaN;
		print("couldn't find keyword: ", keyword);
	}
	else {
		newlineIndex = indexOf(info,"\n",index);
		return parseFloat(substring(info, index+lengthOf(keyword)+3,newlineIndex));
	}
}

macro "DRRmulti" {

	// to do later: allow this to be set by user or auto-detected
	numChannels=2;
	
	// try to find the frame rate from the header info
	info = getMetadata("Info");
	indexScanVolumeRate = indexOf(info,"scanVolumeRate");
	indexLogAverageFactor = indexOf(info,"logAverageFactor");
	// if you can't find the frame rate, ask user to input F0 limits
	if ((indexScanVolumeRate==-1)||(indexLogAverageFactor==-1)) {
		frameTime = 1;
		foundFrameRate = 0;
		Dialog.create("Frames over which to average R0");
		Dialog.addMessage("Couldn't find the frame rate!\nPick frames for F0\n(don't multiply by # channels)");
		Dialog.addNumber("# ROIs", 2);
		Dialog.addNumber("From", 1000);
		Dialog.addNumber("To", 1100);
		Dialog.addCheckbox("Also capture green & red dF/F", false);
	} else {
		foundFrameRate = 1;
		// if you did find the frame rate, ask user ot input F0 limits in seconds
		newlineIndex = indexOf(info,"\n",indexScanVolumeRate);
		frameTime = 1/parseFloat(substring(info, indexScanVolumeRate+17,newlineIndex));		
		newlineIndex = indexOf(info,"\n",indexLogAverageFactor);
		logAverageFactor = parseFloat(substring(info, indexLogAverageFactor+19,newlineIndex));	
		frameTime *= logAverageFactor;	
		Dialog.create("DRRmulti");
		Dialog.addNumber("# ROIs", 2);
		Dialog.addMessage("Time over which to calculate R0");
		Dialog.addNumber("From", 18, 0, 3, "s");
		Dialog.addNumber("To", 20, 0, 3, "s");
		Dialog.addCheckbox("Also capture green & red dF/F", false);
	}
	Dialog.show();
	numROIs = Dialog.getNumber();
	from = Dialog.getNumber();
	to = Dialog.getNumber();
	captSepGR = Dialog.getCheckbox();
	if (foundFrameRate == 1) {
		from = round(from/frameTime);
		to = round(to/frameTime);
	}
	if (from<1) from=1;
	
	if (to <= from) exit("Error: To value must be greater than from value");
	nAvg = to - from + 1;
	// nAvg = getNumber("Average F0 over first X frames: (enter X)", 50);
	numSlices = nSlices;
	numFrames = nSlices/numChannels;
	title = getTitle();

	xArray = newArray(numFrames);
	for (i=0; i<numFrames; i++) xArray[i] = i*frameTime;
	
	print("\\Clear");

	// f will be a 1D array simulating a numSlices x (numROIs+1) matrix
	// the (i,j) position in the matrix will be (i+numSlices*j)
	// NB indexing in ImageJ macro language starts at 0
	// we do numROIs + 1 because the last ROI is the background ROI
	// NB f still holds the raw slices not separated by channel
	f = newArray(numSlices*(numROIs+1));
	for (j=0; j<(numROIs+1); j++) {
		selectWindow(title);
		// load the ROIs into f in forward order
		// so background ROI is last
		roiManager("select", (roiManager("count") - (numROIs+1-j)));
		run("Plot Z-axis Profile");
		Plot.getValues(x,y);
		for (i=0; i<numSlices; i++) {
			f[i+numSlices*j] = y[i];
		}
		run("Close");
	}

	// now we only work on the real ROIs
	fminusbkgnd = newArray(numSlices*numROIs);

	r = newArray(numFrames*numROIs);
	green = newArray(numFrames*numROIs);
	red = newArray(numFrames*numROIs);
	drr = newArray(numFrames*numROIs);
	dffG = newArray(numFrames*numROIs);
	dffR = newArray(numFrames*numROIs);
	for (j=0; j<numROIs; j++) {
		// subtract bkgnd
		for (i=0; i<numSlices; i++) {
			// remember, the bkgnd ROI is the last column
			fminusbkgnd[i+numSlices*j] = f[i+numSlices*j] - f[i+numSlices*numROIs];
		}
		// calculate R (channel 1 / channel 2)
		for (i=0; i<numFrames; i++) {
			r[i+numFrames*j] = fminusbkgnd[2*i + numSlices*j]/fminusbkgnd[2*i + 1 + numSlices*j];
			green[i+numFrames*j] = fminusbkgnd[2*i + numSlices*j];
			red[i+numFrames*j] = fminusbkgnd[2*i + 1 + numSlices*j];
		}
		
		// Calculate average over frames specified by from-to
		sum = 0;
		sumgreen = 0;
		sumred = 0;
		
		for (i=from-1; i<to; i++) {
			sum = sum+r[i+numFrames*j];
			sumgreen = sumgreen+green[i+numFrames*j];
			sumred = sumred+red[i+numFrames*j];
		}
		r0 = sum/nAvg;
		green0 = sumgreen/nAvg;
		red0 = sumred/nAvg;
		
		// calculate DRR
		for (i=0; i<numFrames; i++) {
			drr[i+numFrames*j] = (r[i+numFrames*j] - r0) / r0;
			dffG[i+numFrames*j] = (green[i+numFrames*j] - green0) / green0;
			dffR[i+numFrames*j] = (red[i+numFrames*j] - red0) / red0;
		}
	}
	
	// Print
	String.resetBuffer;
	for (i=0; i<numFrames; i++) {
		thisLine = "";
		for (j=0; j<numROIs; j++) {
			if (captSepGR) { // capture separate green and red channels
				thisLine = thisLine+dffG[i+numFrames*j]+"	"; //tab
				thisLine = thisLine+dffR[i+numFrames*j]+"	"; //tab
			}
			thisLine = thisLine+drr[i+numFrames*j]+"	"; //tab
		}
		thisLine = substring(thisLine, 0, lengthOf(thisLine)-1);
		print(thisLine);
		String.append(thisLine+"\n");
	}
	String.copy(String.buffer);
	if (foundFrameRate==0) {
		Plot.create("DR/R "+title, "Frame [unknown frame rate]", "DR/R");
	} else {
		Plot.create("DR/R "+title, "Time (s) Frame time = "+frameTime+" s, frame rate = "+1/frameTime+" Hz", "DR/R");		
	}
	colors = newArray("black", "blue", "red", "green", "cyan", "darkGray", "gray", "lightGray", "magenta", "orange", "pink", "yellow");
	for (j=0; j<numROIs; j++) {
		if (captSepGR) { // capture separate green and red channels
			Plot.setColor("green");
			Plot.add("line", xArray, Array.slice(dffG,j*numFrames,(j+1)*numFrames-1));
			Plot.setColor("red");
			Plot.add("line", xArray, Array.slice(dffR,j*numFrames,(j+1)*numFrames-1));
		}
		Plot.setColor(colors[j]);
		Plot.add("line", xArray, Array.slice(drr,j*numFrames,(j+1)*numFrames-1));
	}
	Plot.setLimitsToFit();
	selectWindow("Log");
}