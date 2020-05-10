#pragma rtGlobals=1		// Use modern global access method.
#include  <SaveGraph>
#include  <Wave Arithmetic Panel>
#include <AllStatsProcedures>
#include <XY Pair To Waveform>

// Lin lab Igor procedures
// Written by Andrew Lin and members of the Lin lab

// closes all open windows (tables, graphs)
Function closeAllWindows()
	String windowName	
	do 
		windowName = WinName(0,1+2)
		if (CmpStr(windowName,"")==0)
			break
		endif
		DoWindow/K $windowName
	while (1)
End

// sets the global variables relied on by the rest of the procedures
// these variables need to be set in each experiment file (and you may wish to vary them)
// if they are not set, the other procedures will use their own hard-coded defaults
Function setAllGlobalVariablesToDefault()
	Variable/G globalSmoothTime = 0.2 // seconds
	Variable/G globalExpPrefixLength = 14
	Variable/G globalInterpFrameTime = 0.018
End

// Use this function immediately after pasting in a wave as wave0
// frameTime = seconds per frame
// name = desired name for the wave
// it will call mySmooth to smooth the wave (see doc for that function) and put 's' as a prefix in front of the name
// if optional argument w is provided, will do this to wave w
// and it will change the wave to single-precision to save memory
Function changeWave(frameTime, name, [startTime, w])
	Variable frameTime, startTime
	String name
	WAVE w
	String sname = "s"+name
	if (ParamIsDefault(startTime))
		startTime = 0
	endif
	if (ParamIsDefault(w))
		Redimension/S wave0
		SetScale/P x startTime,frameTime,"",wave0
		Rename wave0,$name
	else
		SetScale/P x startTime,frameTime,"",w
		Rename w,$name
	endif
	Duplicate/O $name,$sname
	mySmooth(sname)//Smooth/B 5, $sname
End

// change the smoothing of the "s" paired smooth wave of all waves matching regexp to box smooth over smoothTime
Function changeSmoothAll(regexp, smoothTime)
	String regexp
	Variable smoothTime
	Variable nframes
	
	WAVE w
	String wname, sname
	Variable wcnt
	String wlist = GrepList(WaveList("*",";",""), regexp)
	for (wcnt = 0; wcnt < ItemsInList(wlist); wcnt=wcnt+1)
		// only smooth the non-s waves (the s waves are already smoothed!)
		wname = StringFromList(wcnt, wlist)
		if (char2num(wname) != char2num("s"))
			Print wname
			WAVE w = $wname
			sname = "s"+wname
			Duplicate/O $wname, $sname
			nframes = floor(smoothTime/deltax(w))
			Smooth/B nframes, $sname
		endif
	endfor
End

// smooth a wave using box smooth over what's specified in globalNumFramesSmooth
// or hard-coded default (0.2 s) if that global variable doesn't exist
Function mySmooth(wname)
	String wname
	Wave w = $wname
	NVAR/Z st = globalSmoothTime
	Variable smoothTime, nframes
	if (!NVAR_Exists(st))
		smoothTime = 0.2
	else
		smoothTime = st
	endif
	nframes = floor(smoothTime/deltax(w))
	Smooth/B nframes, $wname
End

// prefixes is string list separated by semi-colons
// e.g.: a;p
// This function will take newly pasted-in waves (wave0, wave1, etc) and
// - redimension them as single-precision
// - rename to have the prefix + name (e.g., "a" + "ay4ex1607251r22")
// - create a smoothed version of the wave with "s" at the front of the name
// The number of waves that the function is expecting is defined by the number of items in prefixes
// so if prefixes is "a;p;m" the function expects wave0, wave1, and wave2 and will give an error if any of these don't exist
Function multiWaves(frameTime, name, prefixes, [startTime])
	Variable frameTime, startTime
	String name, prefixes
	
	if (ParamIsDefault(startTime))
		startTime = 0
	endif

	Variable wcnt
	String startName, newName, sNewName
	for (wcnt=0;wcnt<ItemsInList(prefixes);wcnt+=1)
		startName = "wave"+num2str(wcnt)
		if (!exists(startname))
			printf "error: %s does not exist", startname
			return NaN
		endif
	endfor		
	for (wcnt=0;wcnt<ItemsInList(prefixes);wcnt+=1)
		startName = "wave"+num2str(wcnt)
		newName = StringFromList(wcnt,prefixes)+name
		sNewName = "s"+newName
		Redimension/S $startName
		SetScale/P x startTime,frameTime,"",$startName
		Rename $startName, $newName
		Duplicate/O $newName, $sNewName
		mySmooth(sNewName)
	endfor
End

// marks 2 vertical lobe waves, wave0 marked as alpha prime (prefix "p"), wave1 as alpha (prefix "a")
Function change2vertwaves(frameTime,name)
	Variable frameTime
	String name
	multiWaves(frameTime,name,"p;a")
End

// marks 2 horizontal lobe waves, wave0 marked as beta ("b"), wave1 as gamma (prefix "g")
Function change2horlobewaves(frameTime,name)
	Variable frameTime
	String name
	multiWaves(frameTime,name,"b;g")
End

// marks 2 horizontal lobe waves, wave0 marked as beta prime ("q"), wave1 as gamma (prefix "g")
Function change2horprimewaves(frameTime,name)
	Variable frameTime
	String name
	multiWaves(frameTime,name,"q;g")
End

// marks 2 vertical lobe waves
// wave0 marked as alpha prime anterior (prefix "n")
// wave1 marked as alpha prime middle (prefix "m")
// wave2 marked as alpha prime posterior (prefix "r")
// wave3 marked as alpha (prefix "a")
Function change4kcwaves(frameTime,name)
	Variable frameTime
	String name
	multiWaves(frameTime,name,"n;m;r;a")
End


// take all waves matching the regular expression regexp and set their frame time to frameTime and start time to start
// useful if you accidentally marked the wrong frame time and start time for a set of experiments
// startTime and frameTime are optional parameters so you can change one or the other
Function changeAllScale(regexp, [startTime,frameTime])
	Variable startTime,frameTime
	String regexp
	if (ParamIsDefault(startTime))
		startTime = 0
	endif	
	
	String wname
	Variable wcnt, thisStartTime, thisFrameTime
	String wlist = GrepList(WaveList("*",";",""),regexp)
	WAVE w
	for (wcnt = 0; wcnt < ItemsInList(wlist); wcnt=wcnt+1)
		wname = StringFromList(wcnt, wlist)
		WAVE w = $wname
		if (ParamIsDefault(startTime))
			thisStartTime = leftx(w)
		else
			thisStartTime = startTime
		endif
		if (ParamIsDefault(frameTime))
			thisFrameTime = deltax(w)
		else
			thisFrameTime = frameTime
		endif
		Print wname, "startTime=", thisStartTime, "frameTime=", thisFrameTime // so user can see what waves have been changed
		SetScale/P x thisStartTime,thisFrameTime,"",w
	endfor
End

// take all waves matching the regular expression regexp and set their start time to start
// useful if you accidentally marked the wrong start time for a set of experiments, or need to shift the traces of a lot of experiments
// match them with other experiments, e.g. if the delay of odor response is different in one batch of experiments
Function changeAllStart(start,regexp)
	Variable start
	String regexp
	String wname
	Variable wcnt, frameTime
	String wlist = GrepList(WaveList("*",";",""),regexp)
	WAVE w
	for (wcnt = 0; wcnt < ItemsInList(wlist); wcnt=wcnt+1)
		wname = StringFromList(wcnt, wlist)
		Print wname
		WAVE w = $wname
		frameTime = deltax(w)
		SetScale/P x start,frameTime,"",w
	endfor
End

// Find all waves whose names have origpat in them (ie match *origpat*)
// Useful if you accidentally mis-named some waves
// replace  origpat with replacepat
// important: run checkRenamePattern before doing this in case you make a mistake!
Function renamePattern(origpat, replacepat)
	String origpat, replacepat
	String wavestr
	String wname, newname
	Variable wcnt, strindex
	String wlist = WaveList("*"+origpat+"*",";","")
	WAVE w
	for (wcnt = 0; wcnt < ItemsInList(wlist); wcnt=wcnt+1)
		wname = StringFromList(wcnt, wlist)
		WAVE w = $wname
		strindex = strsearch(wname,origpat,0)
		newname = wname[0,strindex-1] + replacepat + wname[strindex+strlen(origpat),strlen(wname)-1]
		Print wname, newname
		rename w $newname
	endfor
End

// runs the same pattern recognition as renamePattern but doesn't actually rename any waves
// so that you can make sure your patterns recognize only the wave you want to rename
Function checkRenamePattern(origpat, replacepat)
	String origpat, replacepat
	String wavestr
	String wname, newname
	Variable wcnt, strindex
	String wlist = WaveList("*"+origpat+"*",";","")
	WAVE w
	for (wcnt = 0; wcnt < ItemsInList(wlist); wcnt=wcnt+1)
		wname = StringFromList(wcnt, wlist)
		WAVE w = $wname
		strindex = strsearch(wname,origpat,0)
		newname = wname[0,strindex-1] + replacepat + wname[strindex+strlen(origpat),strlen(wname)-1]
		Print wname, newname
	endfor
End

// kill all waves matching the regular expression regexp(e.g.: "160725" to kill all waves from date 160725)
// Check with command: print GrepList(WaveList("*",";",""), regexp) to make sure you are killing what you intend!
Function KillAll(regexp)
	String regexp
	String wlist, wname
	Variable wcnt
	wlist = GrepList(WaveList("*",";",""),regexp)
	Print wlist
	for (wcnt = 0; wcnt<ItemsInList(wlist);wcnt+=1)
		wname = StringFromList(wcnt,wlist)
		KillWaves $wname
	endfor
End

// Interpolate wave wname to give it new delta-x of newdx
// Save the new wave as i+wname
// Linear interpolation
// returns a string with the name of the new wave
Function /S myInterp(wname, newdx)
	String wname
	Variable newdx
	String newname = "i"+wname
	Variable oldnumpnts, newnumpnts

	WAVE w = $wname
	newnumpnts = numpnts(w) * deltax(w) / newdx
	
	Interpolate2/T=1/N=(newnumpnts)/Y=$newname w
	
	return newname
End

// take all the waves in wlist -
// if they all have the same frame time (same dx), just average them
// otherwise, force them all onto the frame time newdx, then average them
// creates new waves with the names avgname and sdvname to hold the avg and standard deviation
// kills the temporary waves along the way (interpolated waves, U_Avg, U_Sdv)
Function interpAvg(wlist, newdx, avgname, sdvname)
	String wlist
	Variable newdx
	String avgname, sdvname
	
	Variable wcnt, dx, thisdx, firstdx
	Variable allsamedx = 1
	Variable items = ItemsInList(wlist)
	String wname, newwave
	String interplist = "" // to store the names of the interpolated waves
	String listtokill = "" // to store names of the interpolated waves to kill them
	
	// if they don't all have the same deltax, force all the waves onto newdx
	wname = StringFromList(0, wlist)
	WAVE w = $wname
	firstdx = deltax(w)
	for (wcnt = 1; wcnt < items; wcnt += 1)
		wname = StringFromList(wcnt, wlist)
		WAVE w = $wname
		thisdx = deltax(w)
		if (thisdx!=firstdx)
			allsamedx = 0
			break
		endif
	endfor
	if (allsamedx==0)
		for (wcnt = 0; wcnt < items; wcnt += 1)
			wname = StringFromList(wcnt, wlist)
			WAVE w = $wname
			dx = deltax(w)
			// if the wave's dx doesn't match newdx, interpolate it!
			if (dx != newdx)
				// myInterp should create a new interpolated wave and return the name of that wave
				newwave = myInterp(wname,newdx)
				interplist = AddListItem(newwave, interplist, ";", inf)
				listtokill = AddListItem(newwave, listtokill, ";", inf)
			else
				interplist = AddListItem(wname, interplist, ";", inf)
			endif
		endfor
	else
		interplist = wlist
	endif
	
	if (strlen(interplist)==0)
		return 0;
	endif
	
	if (itemsinlist(interplist)>1)
		myAvgWaves(interplist)
		Duplicate/O U_Avg, $avgname
		Duplicate/O U_Sdv, $sdvname
		
		KillWaves /Z U_Avg, U_Sdv
	
	else
		wname = StringFromList(0,interplist)
		WAVE w = $wname
		Duplicate/O w, $avgname
	endif
	
	// Kill the new interpolated waves
	for (wcnt = 0; wcnt < ItemsInList(listtokill); wcnt+=1)
		wname = StringFromList(wcnt, listtokill)
		WAVE w = $wname
		KillWaves w
	endfor
	return 1;
End

// All waves must have same deltax
// This function creates U_Avg and U_Sdv to hold the average and standard deviation of
// the list of waves passed to it
// IMPORTANT: follows the convention that waves starting with "U_" are temporary for this purpose
Function myAvgWaves(wlist)
	String wlist
	Variable index = 0
	// start with first wave
	String wname = StringFromList(0, wlist)
	WAVE firstwave = $wname
	String avg_dest = "U_Avg"
	String sdv_dest = "U_Sdv"
	
	KillAll("U_*")
	
	// if they don't all have the same deltax, give an error
	wname = StringFromList(0, wlist)
	WAVE w = $wname
	Variable firstdx = deltax(w)
	Variable wcnt, thisdx
	for (wcnt = 1; wcnt < ItemsInList(wlist); wcnt += 1)
		wname = StringFromList(wcnt, wlist)
		WAVE w = $wname
		thisdx = deltax(w)
//		if (thisdx!=firstdx) // Do not do this error-checking because Igor interpolation does not return exactly the same dx
//			print thisdx, firstdx
//			print "error, myAvgWaves received waves that had different deltax !"
//			return -1
//		endif
	endfor
	
	Variable i
	Variable max_leftx = 0
	Variable min_rightx = Inf
	for (i=0;i<ItemsInList(wlist);i+=1)
		wname = StringFromList(i, wlist)
		WAVE w = $wname
		if (leftx(w) > max_leftx)
			max_leftx = leftx(w)
		endif
		if (rightx(w) < min_rightx)
			min_rightx = rightx(w)
		endif
	endfor
	
	Variable dx = firstdx
	Variable nPoints = (min_rightx - max_leftx)/dx
	Make/O/N=(nPoints) U_Avg
	U_Avg = 0
	SetScale/P x, max_leftx, dx, "", U_Avg
	Duplicate/O U_Avg, U_Sdv
	
	// Calculate average
	do
		wname = StringFromList(index, wlist)      // get next wave
		if (strlen(wname) == 0)	// no more names in list?
			break	// break out of loop
		endif
		WAVE source = $wname	// create wave reference for source
		
		//if 
		// this is commented out because apparently Igor's interpolation doesn't give exactly the same deltax
//		if ((numpnts(source)!=numpnts(firstwave))||(deltax(source)!=deltax(firstwave)))
//			print numpnts(source)
//			print numpnts(firstwave)
//			print deltax(source)
//			print deltax(firstwave)
//			
//		endif
		U_Avg += source	(x)// add source to U_Avg
		index += 1
	while (1)   // do unconditional loop

	U_Avg /= index           // divide by number of waves

	// Calculate standard deviation
	index = 0
	do
		wname = StringFromList(index, wlist)      // get next wave
		if (strlen(wname) == 0)	// no more names in list?
			break	// break out of loop
		endif
		WAVE source = $wname	// create wave reference for source
		U_Sdv += (source(x) - U_Avg)^2
		index += 1
	while (1)   // do unconditional loop
	U_Sdv /= index           // divide by number of waves
	U_Sdv = U_Sdv^0.5
		
	return 1
end
	

// return the average of all the maxes (over 20-25 s) of all the waves defined by regexp
// the key lines are:
//		WaveStats/Q/R=(20,25) $wname
//		maxsum += V_max
// you can copy this and change it if you want to find a different parameter (e.g. average, or over a different time period)
Function grepAvgMax2025(regexp)
	String regexp
	String wlist, glist, wname
	Variable wcnt
	Variable maxsum = 0;
	
	wlist = WaveList("*",";","")
	glist = GrepList(wlist, regexp)

	for (wcnt = 0; wcnt < ItemsInList(glist); wcnt += 1)
		wname = StringFromList(wcnt,glist)
		WaveStats/Q/R=(20,25) $wname
		maxsum += V_max
	endfor
	
	return maxsum / ItemsInList(glist) // / 2

End

// Display all waves matching the regular expression regexp
Function grepDisplay(regexp)
	String regexp
	String wlist, glist, wname
	Variable wcnt
	
	wlist = WaveList("*",";","")
	glist = GrepList(wlist, regexp)

	for (wcnt = 0; wcnt < ItemsInList(glist); wcnt += 1)
		wname = StringFromList(wcnt,glist)
		if (wcnt == 0)
			Display $wname
		else
			AppendToGraph $wname
		endif
	endfor

End

// Use this to turn color names (red, green, blue, orange, yellow, purple, black)
// default color is black if you pass in a string not on this list
// Creates a wave called tempcolorRGB for the color
// and templightcolorRGB for a lighter version of the color
Function colornametoRGB(color)
	String color
	Variable r,g,b,lr,lg,lb
	strswitch(color)
		case "red":
			r = 234*256//65535
			g = 45*256//0
			b = 46*256//0
			break
		case "green":
			r = 0
			g = 39320
			b = 0
			break
		case "blue":
			r = 51*256//0
			g = 59*256//0
			b = 150*256//65535
			break
		case "orange":
			r = 65535
			g = 32768
			b = 0
			break
		case "yellow":
			r = 26214
			g = 26212
			b = 0
			break
		case "purple":
			r = 29524
			g = 1
			b = 58982
			break
		case "black":
			r = 0
			g = 0
			b = 0
			break
		case "magenta":
			r = 65535
			g = 0
			b = 65535
			break
		case "aqua":
			r = 0
			g = 32768
			b = 65535
			break
		case "lgray":
			r = 168*256
			g = 168*256
			b = 167*256
			break
		case "dgray":
			r = 64*256
			g = 64*256
			b = 64*256
			break
		case "brown":
			r = 146*256
			g = 17*256
			b = 0*256
			break
		case "ared":
			r = 239*256
			g = 97*256
			b = 98*256
			break
		case "aorange":
			r = 255*256
			g = 149*256
			b = 1*256
			break	
		default:
			Print color+ " is an invalid color; setting color to black"
			r = 0
			g = 0
			b = 0
			break
	endswitch
	lr = r + 0.8*(65535-r)
	lg = g + 0.8*(65535-g)
	lb = b + 0.8*(65535-b)

	Make/O/N=3 tempcolorRGB={r,g,b}
	Make/O/N=3 templightcolorRGB={lr,lg,lb}
End	

// Mandatory parameters:
// regexp: regular expression to find all the waves you want to average
// Optional parameters:
// newgraph = 1 for new graph, 0 to append to existing graph
// name: the name you want to give to the average wave. If you pass in, e.g., "tnt", the average wave will be named
//		"Avg_tnt", the standard deviation wave will be named "Sdv_tnt"
// 	If no value is given, it will use a cleaned up version of regexp
// r, g, b: red, green and blue color values
// color = string, pick among red, green, blue, orange, yellow, purple, black. If none specified, color will be black or go with specified rgb values
// If you specify color, this will override the rgb values!
// newaxis: if this is appended to an existing graph, add the new traces using a secondary axis
// shadeSEM: if 0, draw all individual traces; if 1, just draw the average trace with shading around it to indicate SEM
//
// This function takes a regular expression, finds all waves that match it
// displays the indiv traces in transparent color and avg in dark color with thick line
// calls: DisplayListAvg
Function DisplayGrepAvg(regexp, [newgraph, name, r, g, b, color, newaxis, shadeSEM, shadeCI])
	String regexp, name, color
	Variable newgraph, newaxis, shadeSEM, shadeCI, r, g, b

	if (ParamIsDefault(name))
		name = CleanupName(regexp,0)
	endif
	if (ParamIsDefault(newgraph))
		newgraph = 1
	endif
	if (!ParamIsDefault(color))
		String tcRGBs = "tempcolorRGB"
		colornametoRGB(color)
		WAVE tempcolorRGB = $tcRGBs
		r = tempcolorRGB(0)
		g = tempcolorRGB(1)
		b = tempcolorRGB(2)
	endif	
	String wlist, glist
	
	wlist = WaveList("*",";","")
	glist = GrepList(wlist, regexp)
	
	DisplayListAvg(glist, newgraph, name, newaxis, shadeSEM, shadeCI, r=r, g=g, b=b)

End

// Mandatory parameters:
// wlist: a list of wave names
// newgraph = 1 for new graph, 0 to append to existing graph
// name: the name you want to give to the average wave.
// r, g, b: red, green and blue color values
// newaxis: if this is appended to an existing graph, add the new traces using a secondary axis
// shadeSEM: if 0, draw all individual traces; if 1, just draw the average trace with shading around it to indicate SEM
//
// This function takes a list of waves
// displays the indiv traces in transparent color and avg in dark color with thick line
// calls: DisplayAll
Function DisplayListAvg(wlist, newgraph, name, newaxis, shadeSEM, shadeCI [r, g, b])
	String wlist, name
	Variable newgraph, newaxis, shadeSEM, shadeCI, r, g, b

	String avgname = "Avg_"+name
	String sdvname = "Sdv_"+name
		
	// if user has set the global variable interpFrameTime, then use that
	// otherwise, use 0.018 (~55.55 Hz)
	NVAR/Z ift = globalInterpFrameTime
	Variable interpFrameTime
	if (!NVAR_Exists(ift))
		interpFrameTime = 0.018
	else
		interpFrameTime = ift
	endif
	Variable result = interpAvg(wlist, interpFrameTime, avgname, sdvname)
	if (result == 0)
		print "failed to create average wave"
		print wlist
	endif
	
//	Print "suffix for Avg_ and Sdv_ waves:", name
//	Print "List of waves used:", wlist
	//PrintMax(wlist)
	//PrintOffVsOn(wlist)
	
	if (newgraph)
		Display/k=1
	endif
	if (newaxis)
		AppendToGraph/L=tempaxis $avgname
	else
		AppendToGraph $avgname
	endif
	ModifyGraph rgb($avgname)=(r,g,b)
	ModifyGraph lsize($avgname)=3
	Variable n = ItemsInList(wlist)
	if (shadeCI)
		String CIname = "CI_"+name
		WAVE sdvw = $sdvname
		Duplicate/O sdvw $CIname
		WAVE CIw = $CIname
		// for a 95% confidence interval
		CIw = CIw * StatsInvStudentCDF(0.975, n-1) / sqrt(n)
		ErrorBars $avgname SHADE={0,2,(r,g,b,0.3*65536),(0,0,0)} wave=(CIw,CIw)
	elseif (shadeSEM)
		String semname = "Sem_"+name
		WAVE sdvw = $sdvname
		Duplicate/O sdvw $semname
		WAVE semw = $semname
		semw = semw / sqrt(n)
		ErrorBars $avgname SHADE={0,2,(r,g,b,0.3*65536),(0,0,0)} wave=(semw,semw)	
	else
		DisplayAll(wlist, 0, r=r, g=g, b=b, newaxis=newaxis, transparent=1)
	endif
End

// Parameters:
// wlist: a string list, listing a bunch of wave names
// regexp: the regular expression that was used to find this list
// returns a list of regular expressions
// each one captures all the trials for an individual fly, according to the naming convention
// where waves are name according to a code eg aay4ix, then the date, yymmdd, then the 
// experiment number for the day, eg 1r, 2l
// the length of this prefix is defined by expPrefixLength and should be set in each Igor file
// so that all waves in that file follow that convention, but users may use different codes
// for each file
Function/S getExpNumList(wlist, regexp)
	String wlist, regexp
	Variable wcnt, smth_var
	String wname, expnum
	String expnumlist = ""
	
	NVAR/Z expPrefixLength = globalExpPrefixLength
	Variable localExpPrefixLength
	if (!NVAR_Exists(expPrefixLength))
		localExpPrefixLength = 14
	else
		localExpPrefixLength = expPrefixLength
	endif
	
	// allow one character offset for the "s" prefix
	smth_var = 0
	if ((char2num(regexp) == char2num("s"))||(stringmatch(regexp,"^s*")))
		smth_var = 1
	endif
	// allow 4 character offset for "nt_s" prefix
	if (StringMatch(regexp,"^nt_s*"))
		smth_var = 4
	endif
	

	for (wcnt=0; wcnt<ItemsInList(wlist);wcnt+=1)
		wname = StringFromList(wcnt,wlist)
		expnum = "^"+wname[0,smth_var+localExpPrefixLength-1]
		if (FindListItem(expnum, expnumlist) == -1)
			expnumlist = AddListItem(expnum, expnumlist,";", Inf)
			//Print expnum
		endif
	endfor
	
	return expnumlist
End

// Mandatory parameters:
// regexp: regular expression to find all the waves you want to average
// Optional parameters:
// newgraph = 1 for new graph, 0 to append to existing graph
// name: the name you want to give to the average wave. If you pass in, e.g., "tnt", the average wave will be named
//		"Avg_tnt", the standard deviation wave will be named "Sdv_tnt"
// 	If no value is given, it will use a cleaned up version of regexp
// r, g, b: red, green and blue color values
// color = string, pick among red, green, blue, orange, yellow, purple, black. If none specified, color will be black
// If you specify color, this will override the rgb values!
// newaxis: if this is appended to an existing graph, add the new traces using a secondary axis
// shadeSEM: if 0, draw all individual traces; if 1, just draw the average trace with shading around it to indicate SEM
// NB: In Igor, optional parameters default to 0 if not specified!

//
// This function takes a regular expression, finds all waves that match it
// It then groups all the waves that belong to a single experiment (i.e. multiple trials of the same ROI), takes the average of them
// and names the average wave "Avgovtr_name" where name is the name of that experiment (i.e. the experiment prefix before the trial number)
// Then it calls DisplayGrepAvg to average these together across experiments
Function DisplayGrepAvgByExp(regexp, [newgraph, name, r, g, b, color, newaxis, shadeSEM, shadeCI])
	String regexp, name
	Variable newgraph, newaxis, r, g, b, shadeSEM, shadeCI //, normTrial
	String color
	
	String regexpnocarat
	Variable smth_var, wcnt, i
	
	String wlist, glist, wname, expnum,thisglist //, normTrialList
	String expnumlist = ""

	if (ParamIsDefault(name))
		name = CleanupName(regexp,0)
	endif
	if (ParamIsDefault(newgraph))
		newgraph = 1
	endif
	if (!ParamIsDefault(color))
		String tcRGBs = "tempcolorRGB"
		colornametoRGB(color)
		WAVE tempcolorRGB = $tcRGBs
		r = tempcolorRGB(0)
		g = tempcolorRGB(1)
		b = tempcolorRGB(2)
	endif	

	// if user has set the global variable interpFrameTime, then use that
	// otherwise, use 0.018 (~55.55 Hz)
	NVAR/Z ift = globalInterpFrameTime
	Variable interpFrameTime
	if (!NVAR_Exists(ift))
		interpFrameTime = 0.018
	else
		interpFrameTime = ift
	endif
			
	wlist = WaveList("*",";","")
	glist = GrepList(wlist, regexp)
	// glist is now a list of all waves matching the regular expression
	
	expnumlist = getExpNumList(glist, regexp)
	//print expnumlist
	
	// for each experiment in expnumlist, make the average over trials of that fly
	for (wcnt=0;wcnt<ItemsInList(expnumlist);wcnt+=1)
		expnum = StringFromList(wcnt,expnumlist)		
		thisglist = GrepList(glist,expnum)
//		if (normTrial)
//			for (i=0; i<ItemsInList(thisglist);i+=1)
//				wname = StringFromList(i,thisglist)
//				// normTrialEffect will create nt_wname that normalises for trial adaptation
//				// then add this to a new list
//				normTrialList = AddListItem(normTrialEffect(wname), normTrialList, ";", Inf)
//			endfor
//			thisglist = normTrialList
//		endif
		String avgname = CleanupName("Avgovtr"+expnum,0)
		String sdvname = CleanupName("Sdvovtr"+expnum,0)		
		interpAvg(thisglist, interpFrameTime, avgname, sdvname)
	endfor
	
	if (char2num(regexp)==char2num("^"))
		regexpnocarat = regexp[1,strlen(regexp)-1]
	else
		regexpnocarat = regexp
	endif
	
	DisplayGrepAvg("^Avgovtr_*"+regexpnocarat,newgraph=newgraph,name=name,color=color,newaxis=newaxis,shadeSEM=shadeSEM,shadeCI=shadeCI)	
End

Function GetTrialNum(wname)
	String wname
	NVAR/Z gepl = globalExpPrefixLength
	Variable expPrefixLength, smth_var
	if (!NVAR_Exists(gepl))
		expPrefixLength = 14
	else
		expPrefixLength = gepl
	endif
	// allow one character offset for the "s" prefix
	smth_var = 0
	if (char2num(wname) == char2num("s"))
		smth_var = 1
	endif

	return str2num(wname[smth_var+expPrefixLength,strlen(wname)])
End

// for a given wave, find which repetition of the odor for that fly was it 
// eg if a fly got the same odor on trials 5, 10, 12 and 20, and this wave's trial number is 12, it will return 3
// I think there might be a bug in this, if one hemisphere is unlabeled and the other is labeled!
Function GetOdorTrialNum(wname)
	String wname
	NVAR/Z gepl = globalExpPrefixLength
	Variable expPrefixLength, smth_var
	if (!NVAR_Exists(gepl))
		expPrefixLength = 14
	else
		expPrefixLength = gepl
	endif
	// allow one character offset for the "s" prefix
	smth_var = 0
	String smth_prefix = ""
	if (char2num(wname) == char2num("s"))
		smth_var = 1
		smth_prefix = "s"
	endif
	
	// remove the 'l' or 'r', and remove the lobe name
	String flynum = wname[smth_var+1,smth_var+expPrefixLength-2]
	
	// list of all movies with this fly
	String trialList = GrepList(WaveList("*",";",""),"^"+smth_prefix+"."+flynum)
	Make/O/N=(ItemsInList(trialList)) tempTrialNumsDuplicates
	
	// get the trial numbers for all these waves
	Variable i
	for (i=0; i<ItemsInList(trialList); i++)
		tempTrialNumsDuplicates[i] = getTrialNum(StringFromList(i, trialList))
	endfor
	// remove duplicates, store in a unique wave for this fly
	String trialNumsWName = "trialnums_"+flynum
	FindDuplicates/RN=$trialNumsWName tempTrialNumsDuplicates
	WAVE trialNums = $trialNumsWName
	KillWaves tempTrialNumsDuplicates
	
	// sort in ascending order
	Sort trialNums, trialNums
	
	Variable thisTrialNum = getTrialNum(wname)
	//add T for tolerance because thisTrialNum is convert to floating point and we want to search integers
	FindValue/V=(thisTrialNum)/T=.1 trialNums
	if (V_value==-1)
		print "Error in GetOdorTrialNum: couldn't find the trial number"
	endif
	return V_value+1
End

// Mandatory parameters:
// regexp: regular expression to find all the waves you want to average
// Optional parameters:
// newgraph = 1 for new graph, 0 to append to existing graph
// name: the name you want to give to the average wave. If you pass in, e.g., "tnt", the average wave will be named
//		"Avg_tnt", the standard deviation wave will be named "Sdv_tnt"
// 	If no value is given, it will use a cleaned up version of regexp
// r, g, b: red, green and blue color values
// color = string, pick among red, green, blue, orange, yellow, purple, black. If none specified, color will be black
// If you specify color, this will override the rgb values!
// newaxis: if this is appended to an existing graph, add the new traces using a secondary axis
// shadeSEM: if 0, draw all individual traces; if 1, just draw the average trace with shading around it to indicate SEM
// NB: In Igor, optional parameters default to 0 if not specified!
//
// This function takes a regular expression, finds all waves that match it
// It then groups all the waves that belong to a single experiment (i.e. multiple trials of the same ROI), takes the FIRST TRIAL of that type
// and names the average wave "Firsttr_name" where name is the name of that experiment (i.e. the experiment prefix before the trial number)
// Then it calls DisplayGrepAvg to average these together across experiments
Function DisplayGrepFirstTrialByExp(regexp, [newgraph, name, r, g, b, color, newaxis, shadeSEM, shadeCI])
	String regexp, name
	Variable newgraph, newaxis, r, g, b, shadeSEM, shadeCI
	String color
	
	Variable smth_var, wcnt, i, trialnum, mintrialnum, indexMinTrialNum
	
	String wlist, glist, wname, expnum,thisglist, firstTrialWName
	String expnumlist = ""
	String firstTrialList = ""

	if (ParamIsDefault(name))
		name = CleanupName(regexp,0)
	endif
	if (ParamIsDefault(newgraph))
		newgraph = 1
	endif
	if (!ParamIsDefault(color))
		String tcRGBs = "tempcolorRGB"
		WAVE tempcolorRGB = $tcRGBs
		colornametoRGB(color)
		r = tempcolorRGB(0)
		g = tempcolorRGB(1)
		b = tempcolorRGB(2)
	endif	

	wlist = WaveList("*",";","")
	glist = GrepList(wlist, regexp)
	// glist is now a list of all waves matching the regular expression
	
	expnumlist = getExpNumList(glist, regexp)
	//print expnumlist
	
	// for each experiment in expnumlist, find the first trial (ie lowest trial number) of that fly
	for (wcnt=0;wcnt<ItemsInList(expnumlist);wcnt+=1)
		expnum = StringFromList(wcnt,expnumlist)
		thisglist = GrepList(glist,expnum)
		mintrialnum = Inf
		indexMinTrialNum = 0
		for (i=0; i<ItemsInList(thisglist);i+=1)
			trialnum = getTrialNum(StringFromList(i,thisglist))
			if (trialnum<mintrialnum)
				mintrialnum = trialnum
				indexMinTrialNum = i
			endif
		endfor
		firstTrialList = AddListItem(StringFromList(indexMinTrialNum,thisglist), firstTrialList,";", Inf)
	endfor
	
	DisplayListAvg(firstTrialList,newgraph,name,newaxis,shadeSEM,shadeCI,r=r,g=g,b=b)	
End
	
// Mandatory parameters:
// regexp: regular expression to find all the waves you want to average
// odorTrial: 1, 2, 3, etc. Only display the trials where the fly experienced the odor for the 1st, 2nd, 3rd, etc time
// Optional parameters:
// newgraph = 1 for new graph, 0 to append to existing graph
// name: the name you want to give to the average wave. If you pass in, e.g., "tnt", the average wave will be named
//		"Avg_tnt", the standard deviation wave will be named "Sdv_tnt"
// 	If no value is given, it will use a cleaned up version of regexp
// r, g, b: red, green and blue color values
// color = string, pick among red, green, blue, orange, yellow, purple, black. If none specified, color will be black
// If you specify color, this will override the rgb values!
// newaxis: if this is appended to an existing graph, add the new traces using a secondary axis
// shadeSEM: if 0, draw all individual traces; if 1, just draw the average trace with shading around it to indicate SEM
// NB: In Igor, optional parameters default to 0 if not specified!
//
// This function takes a regular expression, finds all waves that match it
// It then groups all the waves that belong to a single experiment (i.e. multiple trials of the same ROI), takes the FIRST TRIAL of that type
// and names the average wave "Firsttr_name" where name is the name of that experiment (i.e. the experiment prefix before the trial number)
// Then it calls DisplayGrepAvg to average these together across experiments
Function DisplayGrepSelectOdorTrial(regexp, odorTrial, [newgraph, name, r, g, b, color, newaxis, shadeSEM, shadeCI])
	String regexp, name
	Variable odorTrial, newgraph, newaxis, r, g, b, shadeSEM, shadeCI
	String color
	
	Variable smth_var, wcnt, i, mintrialnum, indexMinTrialNum, thisOdorTrial
	
	String wlist, glist, wname, expnum,thisglist, firstTrialWName
	String expnumlist = ""
	String firstTrialList = ""

	if (ParamIsDefault(name))
		name = CleanupName(regexp,0)+"odorTrial"+num2str(odorTrial)
	endif
	if (ParamIsDefault(newgraph))
		newgraph = 1
	endif
	if (!ParamIsDefault(color))
		String tcRGBs = "tempcolorRGB"
		WAVE tempcolorRGB = $tcRGBs
		colornametoRGB(color)
		r = tempcolorRGB(0)
		g = tempcolorRGB(1)
		b = tempcolorRGB(2)
	endif	

	wlist = WaveList("*",";","")
	glist = GrepList(wlist, regexp)
	// glist is now a list of all waves matching the regular expression
	
	expnumlist = getExpNumList(glist, regexp)
	//print expnumlist
	
	// for each experiment in expnumlist, find the trial that matches odorTrial. If there's no such trial, then don't include this experiment
	for (wcnt=0;wcnt<ItemsInList(expnumlist);wcnt+=1)
		expnum = StringFromList(wcnt,expnumlist)
		thisglist = GrepList(glist,expnum)
		for (i=0; i<ItemsInList(thisglist);i+=1)
			thisOdorTrial = getOdorTrialNum(StringFromList(i,thisglist))
			if (thisOdorTrial==odorTrial)
				firstTrialList = AddListItem(StringFromList(i,thisglist), firstTrialList,";", Inf)
				break
			endif
		endfor
	endfor
	
	DisplayListAvg(firstTrialList,newgraph,name,newaxis,shadeSEM,shadeCI,r=r,g=g,b=b)	
End


// Mandatory parameters:
// regexpList: a list of regular expressions like "^saay4ex;^saay4ix"
// Optional parameters:
// nameList: a list of names like "ethylacetate;isoamylacetate" to name the average wave for each condition
// colors: list of colors to display the waves in (default is blue, red, green, orange, yellow, purple, black)
// catname: a list of labels to for each condition for the bar graph
// This calls DisplayGrepAvgByExp multiple times for each condition specified by the regular expressions
// So that you can compare multiple conditions on one graph (e.g. compare 2 genotypes, 3 odors, etc.)
// also calls BarAndScatterPlot to make bar graphs but this is legacy code - better to paste the data into Prism for nicer graphs
// firstTrial: if you set this to 1, instead of taking the average of all trials with that lobe/odor, you take the first trial of that lobe/odor
// odorTrial: set this to 1, 2, 3, etc. Select only data where for that lobe/odor, it is the 1st, 2nd, 3rd etc time that the fly experienced that odor
// [NB firstTrial refers to trials for that lobe/odor. odorTrial counts trials by the entire fly.
// so one trace might be the first time we recorded the gamma lobe with IA, but the 3rd time overall the fly experienced IA
Function CompareConditionsGrep(regexpList, [firstTrial, odorTrial, firstPulseOnly, nameList, colors, catnames,shadeSEM, shadeCI, whatValue, t1, t2])
	String regexpList, nameList, colors, catnames, whatValue
	Variable firstTrial, odorTrial, shadeSEM, shadeCI, firstPulseOnly, t1, t2
	Variable wcnt
	Variable items = ItemsInList(regexpList)
	String regexp, name
	
	if (ParamIsDefault(whatValue))
		whatValue = "max"
	endif
	if ((ParamIsDefault(t1))||(ParamIsDefault(t2)))
		t1 = 20
		t2 = 25
	endif
	if (ParamIsDefault(colors))
		colors = "blue;red;green;orange;yellow;purple;black"
	endif
	if (ParamIsDefault(shadeSEM))
		shadeSEM = 0
	endif
	
	String AvgovtrList = ""
	Variable UseAvgovtr = 0
	// display average traces
	Display/k=1 as StringFromList(0,regexpList)
	for (wcnt=0; wcnt<items; wcnt+=1)
		regexp = StringFromList(wcnt,regexpList)
		if (!ParamIsDefault(nameList))
			name = StringFromList(wcnt,nameList)
		else
			name = CleanUpName(regexp,0)
		endif
		if (odorTrial)
			DisplayGrepSelectOdorTrial(regexp, odorTrial, newgraph=0, color=StringFromList(wcnt,colors),shadeSEM=shadeSEM,shadeCI=shadeCI)
		elseif (firstTrial)
			DisplayGrepFirstTrialByExp(regexp, newgraph=0, name=name, color=StringFromList(wcnt,colors),shadeSEM=shadeSEM,shadeCI=shadeCI)
		else
			// this will create "Avgovtr_" waves that average over the trials for each experiment
			DisplayGrepAvgByExp(regexp, newgraph=0, name=name, color=StringFromList(wcnt,colors),shadeSEM=shadeSEM,shadeCI=shadeCI)
			AvgovtrList = AddListItem("^Avgovtr_"+decarat(regexp),AvgovtrList,";",Inf)
			UseAvgovtr = 1
		endif
	endfor
	if (firstPulseOnly)
		formatGraphFirstOdorPulse()
	endif

	if (UseAvgovtr)
		regexplist = AvgovtrList
	endif
	// display bar graphs
	BarAndScatterPlot(regexplist, colors=colors, whatValue=whatValue, t1=t1, t2=t2)
	CollectDataFromRegexpsIntoTable(regexplist, whatValue=whatValue, t1=t1, t2=t2)
End

// set a window to a standard format for displaying the first odor pulse
Function formatGraphFirstOdorPulse()
	SetAxis bottom 15, 35
	ModifyGraph height=150, width=100
	ModifyGraph lsize=1
End

// add ^MxAvgovtr in front of a regexp, while removing any ^ in front of the regexp
Function/S addMxAvgovtr(regexp)
	String regexp
	return "^MxAvgovtr_"+decarat(regexp)
End	

// if there is a ^ in front of a regexp, remove it
Function/S decarat(regexp)
	String regexp
	String regexpnocarat
	if (char2num(regexp)==char2num("^"))
		regexpnocarat = regexp[1,strlen(regexp)-1]
	else
		regexpnocarat = regexp
	endif
	return regexpnocarat
End



// take a regular expression that defines a group of waves
// measure some attribute of each wave (eg max, avg etc), given by whatValue, between timepoints t1 and t2
// default is max between 20 and 25 s
// put these individual attributes into a wave called: whatValue+"_values_"+X, where X is a cleaned up version of the regular expression
// the matching names of the waves
Function/S CollectDataFromRegexp(regexp, [whatValue, t1, t2])
	String regexp, whatValue
	Variable t1, t2
	if (ParamIsDefault(whatValue))
		whatValue = "max"
	endif
	if ((ParamIsDefault(t1))||(ParamIsDefault(t2)))
		t1 = 20
		t2 = 25
	endif
	String glist = GrepList(WaveList("*",";",""),regexp)
	CollectDataFromList(glist, regexp, whatValue=whatValue, t1=t1, t2=t2)
	return CleanupName(regexp,0)
	
End

Function CollectDataFromList(glist, regexp, [whatValue, t1, t2])
	String glist, regexp, whatValue
	Variable t1, t2
	if (ParamIsDefault(whatValue))
		whatValue = "max"
	endif
	if ((ParamIsDefault(t1))||(ParamIsDefault(t2)))
		t1 = 20
		t2 = 25
	endif	
	// sort the list (this is so that similar lists are more likely to be in matching order ignoring the order of data entry)
	// option 16 is Case-insensitive alphanumeric sort that sorts wave0 and wave9 before wave10
	glist = SortList(glist,";",16)
	
	// make a wave to collect all the __ attributes of the waves (eg max, avg, etc)
	String collectionWaveName = whatValue + "_" + CleanupName(regexp,0)
	// truncate the wave name to keep to 31-byte limit
	collectionWaveName = collectionWaveName[0,min(strlen(collectionWaveName),30)]
	Make/O/N=(ItemsInList(glist)) $collectionWaveName
	WAVE collectionWave = $collectionWaveName
	
	// make a wave to collect the original source wave names
	String collectionWaveStrName = "names_" + CleanupName(regexp,0)
	// truncate the wave name to keep to 31-byte limit
	collectionWaveStrName = collectionWaveStrName[0,min(strlen(collectionWaveStrName),30)]
	Make/O/T/	N=(ItemsInList(glist)) $collectionWaveStrName
	WAVE/T collectionWaveStr = $collectionWaveStrName
	
	Variable i
	String wname
	for (i=0; i<ItemsInList(glist); i+=1)
		wname = StringFromList(i, glist)
		WAVE w = $wname
		strswitch(whatValue)
			case "max":
				WaveStats/Q/R=(t1,t2) $wname
				collectionWave[i] = V_max
				break
			case "timeOfMax":
				WaveStats/Q/R=(t1,t2) $wname
				collectionWave[i] = V_maxloc
				break				
			case "min":
				WaveStats/Q/R=(t1,t2) $wname
				collectionWave[i] = V_min
				break
			case "extreme":
				WaveStats/Q/R=(t1,t2) $wname
				if (abs(V_min) > abs(V_max))
					collectionWave[i] = V_min
				else
					collectionWave[i] = V_max
				endif
				break
			case "avg":
				WaveStats/Q/R=(t1,t2) $wname
				collectionWave[i] = V_avg
				break
			case "ratio1vs0":
				collectionWave[i] = w[1]/w[0]
				break
			case "diff1vs0":
				collectionWave[i] = w[1]-w[0]
				break
			case "OffOn":
				WaveStats/Q/R=(26,32) $wname
				Variable off = V_avg
				WaveStats/Q/R=(20,25) $wname
				Variable on = V_avg
				collectionWave[i] = off/on
				break
			case "sdv":
				WaveStats/Q/R=(t1,t2) $wname
				collectionWave[i] = V_sdev
				break
			default:
				Print "error, unknown value for 'whatValue' in function CollectDataFromRegexp\r"
				break
		endswitch
		collectionWaveStr[i] = wname
	endfor
	
End

Function FixTimeTraces(regexp)
	String regexp
	String glist = GrepList(WaveList("*",";",""),regexp)
	Variable i
	String wname
	for (i=0; i<ItemsInList(glist); i+=1)
		wname = StringFromList(i, glist)
		WAVE w = $wname
		Variable subtractBy = w[0]
		w -= subtractBy
	endfor
	
End

// call CollectDataFromRegexp with multiple regular expressions
// collect the data into one table and save it as a tab-delimited text file
Function CollectDataFromRegexpsIntoTable(regexplist, [whatValue, t1, t2])
	String regexplist, whatValue
	Variable t1, t2
	if (ParamIsDefault(whatValue))
		whatValue = "max"
	endif
	if ((ParamIsDefault(t1))||(ParamIsDefault(t2)))
		t1 = 20
		t2 = 25
	endif
	
	Variable i
	String regexp, thisCategory
	Edit/k=1 as regexplist
	for (i=0; i<ItemsInList(regexplist); i+=1)
		regexp = StringFromList(i, regexplist)
		// this will create the wave holding the data we will add to the table
		thisCategory = CollectDataFromRegexp(regexp, whatValue=whatValue, t1=t1, t2=t2)
		String data = whatValue + "_" + thisCategory
		String originalWaveNames = "names_" + thisCategory
		AppendToTable $originalWaveNames, $data
	endfor
	
	//check if outputPath exists
	PathInfo outputPath
	if (V_flag==0)
		print "no output path specified - did not save table to disk"
	else
		SaveTableCopy/P=outputPath/T=1/A=0/O as whatValue+"_"+regexplist
	endif
	
End

// call CollectDataFromRegexp with multiple regular expressions
// plot them on one graph
Function BarAndScatterPlot(regexplist, [whatValue, t1, t2, colors, wildcardIndex, wildcardValues])
	String regexplist, whatValue, colors, wildcardValues
	Variable t1, t2, wildcardIndex
	if (ParamIsDefault(whatValue))
		whatValue = "max"
	endif
	if ((ParamIsDefault(t1))||(ParamIsDefault(t2)))
		t1 = 20
		t2 = 25
	endif
	if (ParamIsDefault(colors))
		colors = "blue;red;green;orange;yellow;purple;black"
	endif
	
	Variable i,j,r,g,b
	String regexp
	String categoryList = ""
	String thisCategory
	String categoryListWaveName = CleanUpName(regexplist,0)
	categoryListWaveName = categoryListWaveName[0,30] // truncate name to match Igor's 32-character limit
	Make/O/T/N=(ItemsInList(regexplist)) $categoryListWaveName
	WAVE/T categoryListWave = $categoryListWaveName
	for (i=0; i<ItemsInList(regexplist); i+=1)
		regexp = StringFromList(i, regexplist)
		// this will create the wave holding the data we will plot
		thisCategory = CollectDataFromRegexp(regexp, whatValue=whatValue, t1=t1, t2=t2)
		// add to our list of categories
		categoryListWave[i] = thisCategory
	endfor
	
	Display/k=1 as regexplist
	
	for (i=0; i<numpnts(categoryListWave); i+=1)
		thisCategory = categoryListWave[i]
		String wname = whatValue + "_" + thisCategory
		WAVE w = $wname
		String XpositionName = "Xpos_" + thisCategory
		XpositionName = XpositionName[0,min(strlen(XpositionName),30)]
		Make/O/N=(numpnts(w)) $XpositionName
		WAVE xpos = $XpositionName
		// the 0.5 is to put the scatter points in the middle of the bars
		xpos = i+0.5
		
		// get the avg of wname
		WaveStats/Q $wname
		String avgwname = CleanupName("Avg_" + wname, 0)
		Make/O/N=1 $avgwname
		WAVE avgw = $avgwname
		avgw = V_avg
		
		if (i>0)
			InsertPoints 0, i, avgw
			for (j=0;j<i;j+=1)
				avgw[j] = nan
			endfor
		endif
		
		// plot the bar on the graph
		AppendToGraph avgw vs categoryListWave
		ModifyGraph toMode=-1	, height=150, width=100
		ModifyGraph hbFill($avgwname)=2
		String color = StringFromList(i, colors)
		colornametoRGB(color)
		String tlcRGBs = "templightcolorRGB"
		WAVE templightcolorRGB = $tlcRGBs
		r = templightcolorRGB(0)
		g = templightcolorRGB(1)
		b = templightcolorRGB(2)
		modifygraph rgb($avgwname)=(r,g,b)

		// plot the scatter dots
		AppendToGraph/NCAT w vs xpos
		ModifyGraph mode($wname)=3, toMode($wname)=-1, marker($wname)=19, rgb($wname)=(0,0,0), msize($wname)=3
		
		//ReorderTraces $wname, {$avgmaxname}
		SetAxis left 0,*
		ModifyGraph msize=2, marker=8, standoff(bottom)=0, axisontop(bottom)=1, tick(bottom)=3, tkLblRot(bottom)=45 //,nolabel(bottom)=2
		ModifyGraph catGap(bottom)=0.35//0.3
		if (i==2)
			modifygraph catGap(bottom)=0.1
		endif
		Label left whatValue
	
		ModifyGraph fSize=14
		// allow user to change graph size
		//ModifyGraph height=0,width=0
			
	endfor	

End

//for max, start regexp with ^Max_ etc.
Function ratio2232(regexp)
    String regexp
    String wlist, wname, rationame
    String prefix = "Ratiohx_"
    Variable wcnt, ratio
    
    wlist = GrepList(WaveList("*",";",""),regexp)
    
    for (wcnt=0; wcnt<ItemsInList(wlist);wcnt+=1)
        wname =  StringFromList(wcnt, wlist)
        WAVE w = $wname
        rationame = prefix+wname
        ratio = w[1]/w[0]
        // numtype returns 1 if Inf, 2 if NaN
        if (!numtype(ratio))
            Make/N=1/O $rationame = w[1]/w[0]
            print rationame, w[1]/w[0]
        endif
    endfor
End

// Take all waves matching the regular expression regexp and make a table with them
Function editall(regexp)
	String regexp
	String wlist, wname
	Variable wcnt
	Edit/k=1
	wlist = GrepList(Wavelist("*",";",""),regexp)
	for (wcnt=0; wcnt<ItemsInList(wlist);wcnt+=1)
		wname = StringFromList(wcnt,wlist)
		AppendToTable $wname
		modifytable autosize={0,4,-1,0,0}
	endfor
End
	
// Print the average of each grepped trace from t1 to t2
Function GrepAvgOverTime(regexp, t1, t2)
	String regexp
	Variable t1, t2
	
	Variable wcnt
	String wlist, glist, wname
				
	wlist = WaveList("*",";","")
	glist = GrepList(wlist, regexp)
	
	for  (wcnt = 0; wcnt<ItemsInList(glist); wcnt += 1)
		wname = StringFromList(wcnt, glist)
		WaveStats /Q/R=(t1,t2) $wname
		Print V_avg
	endfor
End

// Displays every wave name in the string list wlist
// Mandatory parameters:
// wlist = string list of waves
// newgraph = 1 to make new graph, 0 to append to existing
// Optional parameters:
// r, g, b: specify color. If none specified, will display in graph
// newaxis = 1 to add on the graph with a secondary axis
// transparent: display the traces with 20% opacity
Function DisplayAll(wlist, newgraph, [r, g, b, newaxis, transparent])
	String wlist
	Variable newgraph, r, g, b, newaxis, transparent
	String wname
	Variable wcnt, items
	items = ItemsInList(wlist)
	
	if (newgraph)
		Display/k=1
	endif	
	if (ParamIsDefault(r)||ParamIsDefault(g)||ParamIsDefault(b))
		r=0
		g=0
		b=0
	endif	
	if (ParamIsDefault(transparent))
		transparent = 0
	endif
	
	for (wcnt = 0; wcnt < items; wcnt+=1)
		wname = StringFromList(wcnt,wlist)
		AppendToGraph $wname
		if (transparent==1)
			ModifyGraph rgb($wname)=(r,g,b,65535*0.2)
		else
			ModifyGraph rgb($wname)=(r,g,b)
		endif
	endfor	
End

// print the maximum of every wave in wlist between 20 and 25 seconds
// in the format: 
// wave max
Function PrintMax(wlist)
	String wlist
	Variable wcnt, items
	String wname, maxname
	
	items = ItemsInList(wlist)
	for (wcnt = 0; wcnt < items; wcnt+=1)
		wname = StringFromList(wcnt,wlist)
		
		//*******to print max of all waves **************//
		WaveStats/Q/R=(20,25) $wname
		maxname="Mx"+wname
		Make/O/N=1 $maxname
		WAVE wmaxname=$maxname
		wmaxname = V_max
		printf "%s %g\r",wname,V_max
	endfor	
	
End


// print the avg of every wave in wlist between 20 and 25 seconds
// in the format: 
// wave avg
Function PrintAvg(wlist)
	String wlist
	Variable wcnt, items
	String wname, maxname
	
	items = ItemsInList(wlist)
	for (wcnt = 0; wcnt < items; wcnt+=1)
		wname = StringFromList(wcnt,wlist)
		
		//*******to print max of all waves **************//
		WaveStats/Q/R=(20,25) $wname
		printf "%s %g\r",wname,V_avg
	endfor	
	
End

Function PrintOffVsOn(wlist)
	String wlist
	Variable wcnt, items
	String wname, rationame
	Variable AvgOn, AvgOff
	
	items = ItemsInList(wlist)
	for (wcnt = 0; wcnt < items; wcnt+=1)
		wname = StringFromList(wcnt,wlist)
		
		WaveStats/Q/R=(20,25) $wname
		AvgOn = V_avg
		WaveStats/Q/R=(26,32) $wname
		AvgOff = V_avg
		rationame="OffOn"+wname
		Make/O/N=1 $rationame
		WAVE wrationame=$rationame
		wrationame = (AvgOff/AvgOn)
		printf "%s %g\r",wname,(AvgOff/AvgOn)
	endfor	
	
End

Function plotOdorTrials(regexp)
	String regexp
	Variable n
	String colors = "blue;red;green;orange;yellow;purple;black"
	Variable i
	Display/k=1
	for (i=1; i<=4; i+=1)
		print "Odor trial ", i
		displaygrepselectodortrial(regexp, i, color=StringFromList(i-1,colors), newgraph=0)
	endfor
End

Function/S waveMaxByOdorTrials(expnum)
	String expnum // regular expression
	Variable n
	
	String wlist = WaveList("*",";","")
	String glist = GrepList(wlist,expnum)
	String odorTrialMaxValuesName = "odorTrialMx"+CleanupName(expnum,0)
	
	// get the largest odorTrial number
	Variable lastOdorTrial = 0
	Variable i, thisOdorTrialNum
	for (i=0; i<ItemsInList(glist); i+=1)
		thisOdorTrialNum = getOdorTrialNum(StringFromList(i,glist))
		if (thisOdorTrialNum > lastOdorTrial)
			lastOdorTrial = thisOdorTrialNum
		endif
	endfor
	Make/O/N=(lastOdorTrial) $odorTrialMaxValuesName
	SetScale/P x 1, 1, "", $odorTrialMaxValuesName
	WAVE odorTrialMaxValues = $odorTrialMaxValuesName
	odorTrialMaxValues = NaN
	
	// fill the wave with the max values of each wave
	String wname
	for (i=0; i<ItemsInList(glist); i+=1)
		wname = StringFromList(i,glist)
		WaveStats/Q/R=(20,25) $wname
		odorTrialMaxValues[getOdorTrialNum(StringFromList(i,glist))-1] = V_max
	endfor
	
	return odorTrialMaxValuesName
End

Function plotMaxByOdorTrials(regexp)
	String regexp
	String wlist = WaveList("*",";","")
	String glist = GrepList(wlist,regexp)
	String expnumlist = getexpnumlist(glist,regexp)
	Variable i
	String expnum, wname
	String maxByOdorTrialsList = ""
	Display/k=1
	for (i=0; i<ItemsInList(expnumlist); i+=1)
		expnum = StringFromList(i,expnumlist)
		wname = waveMaxByOdorTrials(expnum)
		// add this name to a list to keep it for creating a table
		maxByOdorTrialsList = AddListItem(wname, maxByOdorTrialsList, ";", Inf)
		AppendToGraph $wname
		// gaps=0: draw a line through gaps where there is no data
		// mode=4: lines + markers
		// marker=8: empty circle
		ModifyGraph gaps($wname)=0, mode($wname)=4,marker($wname)=8
	endfor
	SetAxis left 0,*
	Edit/k=1
	for (i=0; i<ItemsInList(maxByOdorTrialsList); i+=1)
		wname = StringFromList(i,maxByOdorTrialsList)
		AppendToTable $wname
	endfor
	SaveTableCopy/P=odorTrialsPath/T=1/A=0/O as regexp
End

Function/S normTrialEffect(wname, trialNormFactorWaveName)
	String wname
	String trialNormFactorWaveName
	WAVE w = $wname
	// for this wave, find which repetition of this odor it is for the fly
	Variable odorTrialNum = getOdorTrialNum(wname)
	String normTrialName = "nt_"+wname
	Duplicate/O w, $normTrialName
	WAVE normTrialWave = $normTrialName
	WAVE trialNormFactorWave = $trialNormFactorWaveName
	// normalize the wave according to TrialNormFactors
	if (odorTrialNum > numpnts($trialNormFactorWaveName))
		odorTrialNum = numpnts($trialNormFactorWaveName)
	endif
	normTrialWave = normTrialWave / trialNormFactorWave[odorTrialNum-1]
	return normTrialName
End

Function CreateAllNormTrial(regexp, trialNormFactorWaveName)
	String regexp
	String trialNormFactorWaveName
	String wlist = WaveList("*",";","")
	String glist = GrepList(wlist,regexp)
	Variable i
	String wname
	for (i=0; i<ItemsInList(glist); i+=1)
		wname = StringFromList(i,glist)
		print wname
		normTrialEffect(wname, trialNormFactorWaveName)
	endfor

End


// Looks for waves matching pattern (Igor matching, not grep), where the rightmost point is
// not 50 seconds
// in case you put the wrong scale on one of the waves
Function checkscale(pattern)
	String pattern
	String wname, wlist
	Variable wcnt
	Variable rightmost

	wlist = Wavelist(pattern,";","")
	for (wcnt=0;wcnt<ItemsInList(wlist);wcnt+=1)
		wname = StringFromList(wcnt,wlist)
		WAVE w = $wname
		rightmost = rightx(w)
		if ((rightmost>(50+deltax(w)))||(rightmost<(50-deltax(x))))
			Print wname, rightx(w), deltax(w)
		endif
	endfor
End

// equalize all the axis limits of all the open graph windows
Function equalizeAxisLimits()
	String winname_pattern
	String window_list, window_name
	Variable wcnt
	Variable min_axismin = 0
	Variable max_axismax = 0
	
	window_list = GrepList(WinList("Graph*",";",""), "^Graph[0-9]")
	print window_list
	for (wcnt = 0; wcnt<ItemsInList(window_list);wcnt += 1)
		window_name = StringFromList(wcnt, window_list)

		// get the axis limits of that window
		SetAxis/W=$window_name left *,*
		GetAxis/W=$window_name/Q left
		if (V_min < min_axismin)
			min_axismin = V_min
		endif
		if (V_max > max_axismax)
			max_axismax = V_max
		endif
			
	endfor
	//min_axismin = 0
	for (wcnt = 0; wcnt<ItemsInList(window_list);wcnt += 1)
		window_name = StringFromList(wcnt, window_list)
		SetAxis/W=$window_name left min_axismin,max_axismax
	endfor
End	

// Set x axis limits of all open graphs to that of the selected graph
Function SetxAxisLimits()
	String winname_pattern
	String window_list, window_name
	Variable wcnt
	
	window_list = GrepList(WinList("Graph*",";",""), "^Graph[0-9]")
	GetAxis bottom
	
	for (wcnt = 0; wcnt<ItemsInList(window_list);wcnt += 1)
		window_name = StringFromList(wcnt, window_list)
		SetAxis/W=$window_name bottom V_min,V_max
	endfor
End	

// set all axis limits in all the open graph windows to auto (*,*)
// useful to run this before running equalize_axislimits()
Function autoAxisLimits()
	String window_list, window_name
	Variable wcnt
	window_list = GrepList(WinList("Graph*",";",""), "^Graph[0-9]")
	for (wcnt = 0; wcnt<ItemsInList(window_list);wcnt += 1)
		window_name = StringFromList(wcnt, window_list)

		SetAxis/W=$window_name left *,*
	endfor
End

Function changeTempTrace(suffix)
    String suffix
    String tempTimeName = "m"+suffix
    String tempTraceName = "t"+suffix
    redimension/s wave0
    redimension/s wave1
    rename wave0 $tempTimeName
    rename wave1 $tempTraceName
End

// This function requires that the DF/F signal trace, the temperature trace, and the temperature timestamps all
// have the same suffix
// eg saayxhx1610071r1 (signal), tayxhx1610071r1 (temperature), mayxhx1610071r1 (timestamps)
// in this case, the prefix would be "sa" and the suffix would be "ayxhx1610071r1"
Function displayTRPA(prefix, suffix)
    String prefix, suffix
    String dffName = prefix+suffix
    // use . to ignore the r/l (right vs left) indicator in the name code - just keep the genotype, date, fly# and trial number
    String tempSuffixRegexp = suffix[0,11]+"."+suffix[13,strlen(suffix)]
	 // pickOneMatching will find all the wave names that match the given regular expression and just use the first one
	 // because they should all have the same data if they're from the same fly and trial number
	 // this means for the temperature and time traces, you can put any character you want in the space where r/l goes
    String tempTraceName = pickOneMatching("t"+tempSuffixRegexp)
    String tempTimeName = pickOneMatching("m"+tempSuffixRegexp)
   
    Display/k=1

	// plot temperature on y axis using the temperature timestamps in tempTimeName on x axis
    appendtograph/l=newaxis $tempTraceName vs $tempTimeName
    appendtograph $dffName
    ModifyGraph rgb($tempTraceName)=(0,0,0)
    
    Label left "ÆF/F"
    Label newaxis "Temp (¼C)"
    Label bottom "Time (s)"
    ModifyGraph freePos(newaxis)={1,kwFraction}
    ModifyGraph fSize(newaxis)=14
    
    // for publication:
    //ModifyGraph axThick(left)=0
    //ModifyGraph axThick(bottom)=0
//    ModifyGraph noLabel(bottom)=2, noLabel(left)=2
//    ModifyGraph axRGB(bottom)=(65535,65535,65535), axRGB(left)=(65535,65535,65535)
//    ModifyGraph freePos(newaxis)={0,kwFraction}
//    ModifyGraph axRGB(newaxis)=(0,0,0)
//    ModifyGraph width=130, height=150
//    SetAxis bottom 0, rightx($dffName)
        
End

// of all the waves whose names match the regular expression regexp, just return the first one because we assume they are all the same
Function/S pickOneMatching(regexp)
	String regexp
	String glist = GrepList(WaveList("*",";",""),regexp)
	return StringFromList(0,glist)
End


Function interpolateTempTrace(prefix, suffix, [timeCode, tempCode])
	String prefix,suffix, timeCode, tempCode
	if (ParamIsDefault(timeCode))
		timeCode="m"
	endif
	if (ParamIsDefault(tempCode))
		tempCode="t"
	endif
	String tempTraceName = tempCode+suffix
	String tempTimeName = timeCode+suffix
	String interpTempTraceName = "i"+tempCode+suffix
	String dffName = prefix+suffix
	
	Variable frameTime = deltax($dffName)
   //Get the maximum time of the time wave
   WaveStats/Q $tempTimeName
   Variable maxtime=V_max        
   // Interpolate frame rate of temperature trace reading to the DFF trace
	XYToWave2($tempTimeName,$tempTraceName,interpTempTraceName,maxtime/frameTime)
	
End

// Match the frame rates of the DFF trace and the temperature trace
// then plot the 2 waves against each other, ie temp on X axis, DFF on Y axis
// also print the max value of DFF during the period from when temp reaches 30¼C to when temp reaches max
Function matchTRPATraceToTemp(prefix, suffix, [newgraph, color])
    String prefix, suffix
    Variable newgraph
    String color
    String dffName = prefix+suffix
    // use . to ignore the r/l (right vs left) indicator in the name code - just keep the genotype, date, fly# and trial number
    String tempSuffixRegexp = suffix[0,11]+"."+suffix[13,strlen(suffix)]
	 // pickOneMatching will find all the wave names that match the given regular expression and just use the first one
	 // because they should all have the same data if they're from the same fly and trial number
	 // this means for the temperature and time traces, you can put any character you want in the space where r/l goes
    String tempTraceName = pickOneMatching("t"+tempSuffixRegexp)
    String tempTimeName = pickOneMatching("m"+tempSuffixRegexp)
    // the interpolated wave will have the name "i"+tempTraceName, or interpTempTraceName
    String interpTempTraceName = "i"+tempTraceName
    Variable frameTime, timeofmaxtemp, reach30, r, g, b, maxtime
    WAVE templightcolorRGB
    WAVE tempcolorRGB
    WAVE/T constrrise, constrfall
    
    if (ParamIsDefault(newgraph))
    	newgraph = 1
    endif
        
    // set frame rate to match that of the ÆF/F wave
    frameTime = deltax($dffName)

    //Get the maximum time of the time wave
    WaveStats/Q $tempTimeName
    maxtime=V_max        
    // Interpolate frame rate of temperature trace reading to the DFF trace
	 XYToWave2($tempTimeName,$tempTraceName,interpTempTraceName,maxtime/frameTime)

    //Get the time of the maximum temperature
    WaveStats/Q $tempTraceName
    timeofmaxtemp = V_maxloc
    
    if (newgraph)
        Display/k=1
    endif
        
    AppendToGraph $dffName vs $interpTempTraceName
    
    if  (!ParamIsDefault(color))
        colornametoRGB(color)
        r = tempcolorRGB(0)
        g = tempcolorRGB(1)
        b = tempcolorRGB(2)
        ModifyGraph rgb($dffname)=(r,g,b)
    endif
    
    // find when the temperature crosses 30 ¼C
    FindLevel $interpTempTraceName, 30
    if (V_flag)
    	print "temperature never crossed 30 ¼C"
    endif
    reach30 = V_LevelX
    
    // find the max value of the DFF wave between when temp reaches 30¼C and when temp is at max
    WaveStats/Q/R=(reach30,timeofmaxtemp) $dffName
    print V_max
    
    // save this max value as Max_dffName
    String max_dffname = "Max_"+dffName
    Make/O/N=1 $max_dffname = V_max
    
End

Function modifyTRPAGraphForPaper()
    modifygraph height=150,width=150, gfsize=14
    Label bottom "Temp. (¼C)"
    Label left "ÆF/F"
end

Function normalizetoRed(greenName, redName)
    String greenName, redName
    String normGreen = "n"+greenName
    WAVE greenw = $greenName
    WAVE redw = $redName
    
    Make/O/N=(numpnts(greenw)) $normGreen
    WAVE normw = $normGreen
    
    SetScale/P x (leftx(greenw)), (deltax(greenw)),"",normw
    normw = (1+greenw) / (1+redw) - 1
    
    Display/k=1 greenw, redw, normw
End

//avgTrials will take in a wave w (NB: a wave, not a string with the name of a wave), and an interval of time,
// interval. It will cut up w into segments that are interval seconds long, then average them together. 
//If the last segment is not the full length of interval (in your data, the last trial is 11 s, not 12 s), 
//it will throw away the time points where it doesn't have every repetition. The new wave will be the name of 
//the old wave with an "a" in front. SoÊs190820f5r10VR becomes as190820f5r10VR.
// note this uses "ceil" to count the number of reps
// could result in odd behavior if the starting movie is only slightly longer than
// an even multiple of "interval"
Function avgTrials(w, interval)
	WAVE w
	Variable interval
	
	String wname = NameOfWave(w)
	String avgwname = "a"+wname
	Variable numPoints = ceil(interval/deltax(w))
	Variable numReps = ceil(rightx(w)/interval)
	Make/O/N=(numPoints) $avgwname
	WAVE aw = $avgwname
	
	Variable i
	// becauase numReps is the ceil of rightx(w)/interval, the last interval may not be complete
	// so here we sum up the first n-1 intervals
	for (i=0; i<(numReps-1); i++)
		aw += w[x+numPoints*i]
	endfor
	// here we add on the last interval
	for (i=0; i<numPoints; i++)
		// if we haven't reached the end of w yet, add that to the average
		if ((i+(numReps-1)*numPoints)<numpnts(w))
			aw[i] += w[i+(numReps-1)*numPoints]
			aw[i] /= numReps
		// but if we have reached the end, then this time point has no valid data
		else
			aw[i] = NaN
		endif
	endfor
	SetScale/P x leftx(w), deltax(w), "", aw
end