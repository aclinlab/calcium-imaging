#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// This function will find all waves that match the regular expression regexp, and combine the trials from a single experiment number
// (ie waves that have identical for the first globalExpPrefixLength characters)
// Then it will attempt to pair all experiments that differ only by a single character
// Usage:
// Option 1:
// e.g., pairedGraphs("^sgay4i.","xs")
// Here, the regular expression has only a single wildcard (.). pairedGraphs will find the waves that match this regular expression
// with the wildcard replaced by either "x" or "s", and it will pair up the experiments that have the same code but differ only in
// whether they are marked "x" or "s". Experiments that lack a matching partner will be excluded.
// Option 2:
// e.g., pairedGraphs("^sg.c..yo","01",wildcardIndex=6)
// Here, the regular expression has multiple wildcards (.). Use the optional parameter wildcardIndex to specify which character in
// the regular expression is the one that you want to replace with the wildcardValues (in this example, "0" or "1).
// NOTE: wildcardIndex is ZERO-INDEXED!! i.e. start counting characters from 0, not 1.
// Option 3:
// e.g., pairedGraphs("^sg[ca]tnm.","xm",wildcardIndex=10,extraChars=3)
// Here, the regular expression has 3 extra characters that won't exist in the final wave name that come BEFORE the wildcard
// NOTE: wildcardValues should be a string of wildcard characters eg "abc" (not a list eg "a;b;c")
// Therefore it's not possible to have multi-character wildcards at the moment. If there is a need for this we can change the function.
//
// optional parameter waveSum: if set to 1, then, the function will calculate a composite wave summing up all the waves specified by the wildcard for each set
// and display the new composite waves
// then you must set optional parameter sumLabel which is the label for the new composite wave (in the same code position as the wildcards)
//
// optional parameter waveDiff: if set to 1, then, the function will do the same as with waveSum except it will take the
// *negative* of the first wave!!
// e.g. if your wildcards are "xy", for every pair, it will take the wave matching wildcard "y" and subtract from that the wave matching wildcard "x"
// i.e., it will do y - x
// if you have multiple waves in the set, e.g. your wildcards are "xyz", it will do y + z - x
// You still need to use the optional parameter sumLabel to make the label for the new composite wave
//
// optional parameter waveDiffNorm: if set to 1, normalize to the peak of first wave
// thus for wildcards "xy" it will do (y-x)/(x_max)
//
// optional parameter waveDiffNormSum: if set to 1, normalize to the sum of the peaks of each wave
// thus for wildcards "xy" it will do (y-x)/(x_max+y_max)
// 
Function pairedGraphs(regexp, wildcardValues, [wildcardIndex, extraChars, whatValue, t1, t2, shadeSEM, shadeCI, firstPulseOnly, colors, waveSum, waveDiff, waveDiffNorm, waveDiffNormSum, sumLabel])
	String regexp, wildcardValues, whatValue, colors, sumLabel
	Variable wildcardIndex, extraChars, t1, t2, shadeSEM, shadeCI, firstPulseOnly, waveSum, waveDiff, waveDiffNorm, waveDiffNormSum
	if (ParamIsDefault(whatValue))
		whatValue = "max"
	endif
	if ((ParamIsDefault(t1))||(ParamIsDefault(t2)))
		t1 = 20
		t2 = 25
	endif	
	if ((waveSum)||(waveDiff)||(waveDiffNorm)||(waveDiffNormSum))
		if (ParamIsDefault(sumLabel))
			print "error: you did not define sumLabel"
			return -1
		endif
	endif
	if ((waveSum + waveDiff + waveDiffNorm + waveDiffNormSum) > 1)
		print "error: only one of waveSum, waveDiff, waveDiffNorm, and waveDiffNormSum can be set to 1"
		return -1
	endif
	
	if (ParamIsDefault(colors))
		colors = "blue;red;green;orange;yellow;purple;black"
	endif
	// find where in the regexp is there a wildcard (.) - this is needed below
	if (ParamIsDefault(wildcardIndex))
		wildcardIndex = strsearch(regexp, ".", 0)
	endif
	String regexpWithWildcardValues = regexp[0,wildcardIndex-1]+"["+wildcardValues+"]"+regexp[wildcardIndex+1,strlen(regexp)]
	//print regexpWithWildcardValues

	// list all waves that match regexpWithWildcardValues
	String glist = GrepList(WaveList("*",";",""),regexpWithWildcardValues)

	// sort the list (this is so that similar lists are more likely to be in matching order ignoring the order of data entry)
	// option 16 is Case-insensitive alphanumeric sort that sorts wave0 and wave9 before wave10
	glist = SortList(glist,";",16)

	//print glist

	// get list of regular expressions to capture every experiment from that glist
	// it will be something like "^sgmxxmx1802271l;^sgmxxmx1802271r;^sgmxxmm1802271l;^sgmxxmm1802271r"etc
	String expnumlist = getExpNumList(glist, regexpWithWildcardValues)
	//print expnumlist

	// split into lists for each wildcard value
	Variable iw // means "i-wildcard"
	// make a wave to hold the lists for each wildcard value
	String wildcardExpnumsName = CleanupName(regexp+"_"+wildcardValues+"_"+num2str(wildcardIndex),0)
	//print wildcardExpnumsName
	Make/O/T/N=(strlen(wildcardValues)) $wildcardExpnumsName
	WAVE/T wildcardExpnumsWave = $wildcardExpnumsName
	for (iw=0;iw<strlen(wildcardValues);iw+=1)
		wildcardExpnumsWave[iw] = GrepList(expnumlist,decarat(regexp[0,wildcardIndex-1]+wildcardValues[iw]+regexp[wildcardIndex+1,strlen(regexp)]))
	endfor	
	//print wildcardExpnumsWave

	// keep only the ones that have matching expnum apart from the wildcard
	// we'll use the first wildcardValue as the anchor
	Variable jw, ie // ie means "i-expnum" - iterating over the expnums in each list in wildcardExpnumsWave
	// loop over wildcardValues
	for (iw=0;iw<strlen(wildcardValues);iw+=1)
		// loop over the other wildcardValues
		for (jw=0;jw<strlen(wildcardValues);jw+=1)
			// skip the diagonals
			if (iw!=jw)
				// loop over the expnums for the iw-th wildcard, see if there is matching expnum in the jw-th wildcard
				for (ie=0;ie<ItemsInList(wildcardExpnumsWave[iw]);ie+=1)
					String currentExpnum = StringFromList(ie, wildcardExpnumsWave[iw])
					//print ReplaceString(".",regexp,wildcardValues[iw])
					//Variable position = strsearch(currentExpnum, ReplaceString(".",regexp,wildcardValues[iw]),0)
					//print position
					String matchingExpnum = currentExpnum[0, wildcardIndex-1-extraChars]+wildcardValues[jw]+currentExpnum[wildcardIndex+1-extraChars,Inf]
					print matchingExpnum
					//String matchingExpnum = currentExpnum[0, position+wildcardIndex-1]+wildcardValues[jw]+currentExpnum[position+wildcardIndex+1,Inf]
					//print currentExpnum, matchingExpnum
					// if matchingExpnum is not in the matching expnum list, remove the current expnum from the current list
					if (FindListItem(matchingExpnum, wildcardExpnumsWave[jw])==-1)
						wildcardExpnumsWave[iw] = RemoveFromList(currentExpnum, wildcardExpnumsWave[iw])
						ie-=1
					endif
				endfor
			endif
		endfor
	endfor
	//print wildcardExpnumsWave
		
	
	for (iw=0;iw<strlen(wildcardValues);iw+=1)
		for (jw=0;jw<strlen(wildcardValues);jw+=1)
			if (ItemsInList(wildcardExpnumsWave[iw])!=ItemsInList(wildcardExpnumsWave[iw]))
				print "error: non-matching number of exp nums"
			endif
		endfor
	endfor
	
	
	// if user has set the global variable interpFrameTime, then use that
	// otherwise, use 0.018 (~55.55 Hz)
	NVAR/Z ift = globalInterpFrameTime
	Variable interpFrameTime
	if (!NVAR_Exists(ift))
		interpFrameTime = 0.018
	else
		interpFrameTime = ift
	endif
	
	String expnum, thisglist, avgname, sdvname
	String toKill = "toKill"
	Variable normToThisValue
	if ((waveSum)||(waveDiff)||(waveDiffNorm)||(waveDiffNormSum))
		for (ie=0;ie<ItemsInList(wildcardExpnumsWave[0]);ie+=1)
			String listToComposite = ""
			expnum = StringFromList(ie,wildcardExpnumsWave[0])
			String compositeWaveName = decarat(expnum[0, wildcardIndex-1-extraChars] + sumLabel + expnum[wildcardIndex+1-extraChars,Inf])
			//print compositeWaveName
//			Make/O $compositeWaveName
//			WAVE compositeWave = $compositeWaveName
//			compositeWave = 0
			normToThisValue = 0
			for (iw=0;iw<strlen(wildcardValues);iw+=1)
				expnum = StringFromList(ie,wildcardExpnumsWave[iw])		
				thisglist = GrepList(glist,expnum)
				avgname = CleanupName("Avgovtr"+expnum,0)
				sdvname = CleanupName("Sdvovtr"+expnum,0)		
				interpAvg(thisglist, interpFrameTime, avgname, sdvname)
				listToComposite = AddListItem(avgname, listToComposite)
				if ((waveDiffNorm)&&(iw==0))
					WaveStats/Q/R=(t1,t2) $avgname
					normToThisValue = V_max
					//print normToThisValue
				endif
				if (waveDiffNormSum)
					WaveStats/Q/R=(t1,t2) $avgname
					normToThisValue += V_max
					//print normToThisValue
				endif
				if (((waveDiff)||(waveDiffNorm)||(waveDiffNormSum))&&(iw==0))
					WAVE avgw = $avgname
					avgw = -avgw
				endif
			endfor
			interpAvg(listToComposite, interpFrameTime, compositeWaveName, toKill)
			KillWaves $toKill
			WAVE compositeWave = $compositeWaveName
			compositeWave *= strlen(wildcardValues)
			if ((waveDiffNorm)||(waveDiffNormSum))
				compositeWave /= normToThisValue
			endif
		endfor
	endif



	// display the traces (averaged over trials) for the selected expnums
	Display/k=1 as wildcardExpnumsName
	Variable r,g,b
	for (iw=0;iw<strlen(wildcardValues);iw+=1)
		// for each expnum, make the average over trials of that fly
		String listToDisplay = ""
		for (ie=0;ie<ItemsInList(wildcardExpnumsWave[iw]);ie+=1)
			expnum = StringFromList(ie,wildcardExpnumsWave[iw])		
			thisglist = GrepList(glist,expnum)
			avgname = CleanupName("Avgovtr"+expnum,0)
			sdvname = CleanupName("Sdvovtr"+expnum,0)		
			interpAvg(thisglist, interpFrameTime, avgname, sdvname)
			listToDisplay = AddListItem(avgname, listToDisplay)
		endfor
		String tcRGBs = "tempcolorRGB"
		colornametoRGB(StringFromList(iw,colors))
		WAVE tempcolorRGB = $tcRGBs
		r = tempcolorRGB(0)
		g = tempcolorRGB(1)
		b = tempcolorRGB(2)		
		DisplayListAvg(listToDisplay, 0, CleanupName(regexp+"_"+wildcardValues,0)+"_"+wildcardValues[iw], 0, shadeSEM, shadeCI, r=r, g=g, b=b)
	endfor
	
	if (firstPulseOnly)
		formatGraphFirstOdorPulse()
	endif


	display/k=1 as wildcardExpnumsName
	String catname = CleanupName(wildcardExpnumsName+"_categories",0)
	Make/O/T/N=(strlen(wildcardValues)) $catname
	WAVE/T categories = $catname
	
	String summaryDataName = whatvalue+wildcardExpnumsName
	Make/O/N=(strlen(wildcardValues)) $summaryDataName = 0
	WAVE summaryData = $summaryDataName
	// here assume all lists in wildcardExpnumsWave are same length - see above
	for (ie=0;ie<ItemsInList(wildcardExpnumsWave[0]);ie+=1)
		currentExpnum = StringFromList(ie, wildcardExpnumsWave[0])
		//Variable position = strsearch(currentExpnum, regexp[0,wildcardIndex-1]+wildcardValues[0]+regexp[wildcardIndex+1,Inf],0)
		String expnumWaveName = CleanupName(whatValue+currentExpnum[0, wildcardIndex-1-extraChars]+"_"+currentExpnum[wildcardIndex+1-extraChars,Inf]+"_"+wildcardValues,0)
		//String expnumWaveName = CleanupName(whatValue+currentExpnum[0, position+wildcardIndex-1]+"_"+currentExpnum[position+wildcardIndex+1,Inf]+"_"+wildcardValues,0)
		Make/O/N=(strlen(wildcardValues)) $expnumWaveName
		WAVE expnumWave = $expnumWaveName
		if (ie==0)
			String firstTrace = expnumWaveName //keep the first trace for ReorderTraces below
		endif
		for (iw=0;iw<strlen(wildcardValues);iw+=1)
			String wname = CleanupName("Avgovtr"+currentExpnum[0, wildcardIndex-1-extraChars]+wildcardValues[iw]+currentExpnum[wildcardIndex+1-extraChars,Inf],0)
			//String wname = CleanupName("Avgovtr"+currentExpnum[0, position+wildcardIndex-1]+wildcardValues[iw]+currentExpnum[position+wildcardIndex+1,Inf],0)
			WAVE w = $wname
			strswitch(whatValue)
				case "max":
					WaveStats/Q/R=(t1,t2) $wname
					expnumWave[iw] = V_max
					break
				case "avg":
					WaveStats/Q/R=(t1,t2) $wname
					expnumWave[iw] = V_avg
					break
				case "ratio1vs0":
					expnumWave[iw] = w[1]/w[0]
					break
				case "diff1vs0":
					expnumWave[iw] = w[1]-w[0]
					break
				case "OffOn":
					WaveStats/Q/R=(26,32) $wname
					Variable off = V_avg
					WaveStats/Q/R=(20,25) $wname
					Variable on = V_avg
					expnumWave[iw] = off/on
					break
				default:
					Print "error, unknown value for 'whatValue' in function pairedGraphs\r"
					break
			endswitch
		endfor
		summaryData = summaryData + expNumWave
		appendToGraph expnumWave vs categories
		ModifyGraph mode=4, marker=8, rgb=(0,0,0,19661), lsize=0.5, mrkStrokeRGB=(0,0,0,19661), gfSize = 14, height = 150, width = 100,msize=2
		SetAxis left 0,*
	endfor
	summaryData = summaryData / ItemsInList(wildcardExpnumsWave[0])
	
	// this is so the different bars of summaryData can be different colors
	// (rather than just doing appendToGraph summaryData vs categories
	for (iw=0;iw<strlen(wildcardValues);iw+=1)
	   categories[iw] = wildcardValues[iw]
		String thisSummaryDataName = whatvalue+wildcardExpnumsName+"_"+wildcardValues[iw]
		Make/O/N=(iw+1) $thisSummaryDataName = NaN
		WAVE thisSummaryData = $thisSummaryDataName		
		thisSummaryData[iw] = summaryData[iw]
		appendToGraph $thisSummaryDataName vs categories
		colornametoRGB(StringFromList(iw,colors))
		String tlcRGBs = "templightcolorRGB"
		WAVE templightcolorRGB = $tlcRGBs
		r = templightcolorRGB(0)
		g = templightcolorRGB(1)
		b = templightcolorRGB(2)

		ModifyGraph mode($thisSummaryDataName)=5, rgb($thisSummaryDataName)=(r,g,b), hbFill($thisSummaryDataName)=2, lsize($thisSummaryDataName)=0
		ReorderTraces $firstTrace, {$thisSummaryDataName} // move the bars behind the dots
	endfor
	ModifyGraph toMode=-1, catgap(bottom)=0.35, standoff(bottom)=0, tick(bottom)=3
	Label left whatValue
	
	Edit/k=1 as wildcardExpnumsName
	for (ie=0;ie<ItemsInList(wildcardExpnumsWave[0]);ie+=1)
		currentExpnum = StringFromList(ie, wildcardExpnumsWave[0])
		//position = strsearch(currentExpnum, regexp[0,wildcardIndex-1]+wildcardValues[0]+regexp[wildcardIndex+1,Inf],0)
		expnumWaveName = CleanupName(whatValue+currentExpnum[0, wildcardIndex-1-extraChars]+"_"+currentExpnum[wildcardIndex+1-extraChars,Inf]+"_"+wildcardValues,0)
		//expnumWaveName = CleanupName(whatValue+currentExpnum[0, position+wildcardIndex-1]+"_"+currentExpnum[position+wildcardIndex+1,Inf]+"_"+wildcardValues,0)
		AppendToTable $expnumWaveName
	endfor
	//check if outputPath exists
	PathInfo outputPath
	if (V_flag==0)
		print "no output path specified - did not save table to disk"
	else
		SaveTableCopy/P=outputPath/T=1/A=0/O as whatValue+"_"+wildcardExpnumsName
	endif
End