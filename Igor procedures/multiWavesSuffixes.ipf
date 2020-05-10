#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// Does the same thing as multiWaves except it also takes a list of suffixes
// e.g., if prefixes = "q;b;g"
// and suffixes = "l1;r1"
// the waves will be renamed as follows:
// wave0 --> q ... l1
// wave1 --> b ... l1
// wave2 --> g ... l1
// wave3 --> q ... r1
// wave4 --> b ... r1
// wave5 --> g ... r1

Function MultiWavesSuffixes(frameTime, name, prefixes, suffixes, [startTime])
	Variable frameTime, startTime
	String name, prefixes,suffixes
	
	if (ParamIsDefault(startTime))
		startTime = 0
	endif

	Variable wcnt
	String startName, newName, sNewName
	for (wcnt=0;wcnt<ItemsInList(prefixes)*ItemsInList(suffixes);wcnt+=1)
		startName = "wave"+num2str(wcnt)
		if (!exists(startname))
			printf "error: %s does not exist", startname
			return NaN
		endif
	endfor		
	Variable i,j
	for (i=0;i<ItemsInList(suffixes);i+=1)
		for (j=0;j<ItemsInList(prefixes);j+=1)
			startName = "wave"+num2str(j+(ItemsInList(prefixes))*i)
			newName = StringFromList(j,prefixes)+name+StringFromList(i,suffixes)
			sNewName = "s"+newName
			Redimension/S $startName
			SetScale/P x startTime,frameTime,"",$startName
			Rename $startName, $newName
			Duplicate/O $newName, $sNewName
			mySmooth(sNewName)
		endfor
	endfor
End

// Does the same thing as multiWavesSuffixes except the suffixes and prefixes are all specified
// individually, not nested
// e.g., if prefixes = "qa;ba;ga;qd;bd;gd"
// and suffixes = "l1;l1;l1;r1;r1;r1"
// the waves will be renamed as follows:
// wave0 --> qa ... l1
// wave1 --> ba ... l1
// wave2 --> ga ... l1
// wave3 --> qd ... r1
// wave4 --> bd ... r1
// wave5 --> gd ... r1

Function MultiWavesSepPrefixSuffix(frameTime, name, prefixes, suffixes, [startTime])
	Variable frameTime, startTime
	String name, prefixes,suffixes
	
	if (ParamIsDefault(startTime))
		startTime = 0
	endif
	
	if (ItemsInList(prefixes)!=ItemsInList(suffixes))
		printf "error: number of prefixes doesn't match number of suffixes"
		return NaN
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
	Variable i,j
	for (i=0;i<ItemsInList(suffixes);i+=1)
		startName = "wave"+num2str(i)
		newName = StringFromList(i,prefixes)+name+StringFromList(i,suffixes)
		sNewName = "s"+newName
		Redimension/S $startName
		SetScale/P x startTime,frameTime,"",$startName
		Rename $startName, $newName
		Duplicate/O $newName, $sNewName
		mySmooth(sNewName)
	endfor
End