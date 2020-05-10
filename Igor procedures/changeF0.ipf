#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// wname is a string with the name of a wave containing a dF/F trace
// t1 and t2 are time points in that wave
// this function will recalculate the dF/F taking a new time window as the period 
// for calculating the F0
// For example say you initially set the F0 period as t=(5,10) but upon inspection it looks like
// the object moved a lot during that period, so it would be more appropriate to take
// t=(10,15) as the period in which the object is at "baseline".
// then call:
// changeF0("examplewave", 10, 15)
Function changeF0(wname, t1, t2)
	String wname
	Variable t1, t2
	
	WAVE w = $wname
	WaveStats/Q/R=(t1,t2) $wname
	
	Variable i
	// V_avg is the average value of the wave between time points t1 and t2
	for (i=0;i<numpnts(w);i+=1)
		w[i] = (w[i] + 1)/(V_avg + 1) - 1
	endfor

End

// call changeF0 for all waves matching a regular expression
Function changeAllF0(regexp, t1, t2)
	String regexp
	Variable t1, t2
	String glist = GrepList(WaveList("*",";",""), regexp)
	Variable i
	String wname
	for (i=0;i<ItemsInList(glist);i+=1)
		wname = StringFromList(i, glist)
		changeF0(wname, t1, t2)
	endfor

End