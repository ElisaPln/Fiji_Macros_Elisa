// Macro by Elisa
// Analyze individual resized centrioles ispired from commands from the PickCentrioles Plungins

//		_________________§§§§§§§§__________§§_____§§
//		_______________§§________§§_______§§§§___§§§§
//		_____________§§__§§§§§§§§__§§______§§_____§§
//		____________§§__§§______§§__§§______§§___§§
//		___________§§__§§___§§§__§§__§§_____§§§§§
//		___________§§__§§__§__§__§§__§§_____ §§§§§
//		___________§§__§§__§§___§§§__§§_____§§§§§
//		___________§§__§§___§§§§§§__§§_____§§§§§§
//		____________§§__§§_________§§_____§§§§§§
//		_______§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
//		___§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
//		___§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§

run("Close All");

// Choose your analysis method. In "manual" you select the two 50% points by hand
method = "auto" // Choose between "manual" or "auto"

// Trajectory of the data and of the output
dirdata = getDirectory("Choisir le dossier contenant les stacks a analyser");  

// Select output file name
Dialog.create("Filename");
Dialog.addString("Name of your result file", "output.csv");
Dialog.show();
filename = Dialog.getString();

// Extension of the files
extension = ".tif";
ext_size = lengthOf(extension);

// Select the nb of channels to analyze
Dialog.create("How many channels?");
Dialog.addNumber("Channel nb:", 2);
Dialog.show();
channel_nb = Dialog.getNumber();

// Which channel?
channel_list=newArray(channel_nb);
for(channel=0 ;channel<channel_nb; channel++) {
	Dialog.create("How many channels?");
	Dialog.addNumber("Channel "+channel+1+":", 1);
	Dialog.show();
	channel_list[channel] = Dialog.getNumber();
}
//Array.print(channel_list);



ImageNames=getFileList(dirdata); /// tableau contenant le nom des fichier contenus dans le dossier dirdata
centriole_nb = -1; 


if(isOpen("Results")) {
	selectWindow("Results");
	run("Close");}

if(isOpen("ROI Manager")) {
	roiManager("reset");}


// Analysis function: plot profile according to your selected line and measure the maxima and 50% points
function getPointsFromChannel(channel) {
	roiManager("reset");
	Stack.setChannel(channel);
    // Open the "Plot Profile" window
    run("Plot Profile");
    rename("Plot");
    run(col[channel]);
    
    // The user get select the max points
    selectWindow("Plot");
    setTool("multipoint");
    waitForUser("Select the 2 maximums");
    roiManager("Add");
    roiManager("Select", 0);
    run("Measure");
    x1 = getResult("X", 0);
    y1 = getResult("Y", 0);
    x2 = getResult("X", 1);
    y2 = getResult("Y", 1);
    run("Clear Results");
	
	// for manual selection of 50% points
	if (method == "manual") {
		// Draw new graph with 50% lines
	    selectWindow("Plot");
	    Plot.getValues(x, y);
	    Plot.create("Plot Values", "X", "Y", x, y);
	    Plot.setLineWidth(2);
	    Plot.drawLine(0, y1 / 2, x1, y1 / 2);
	    Plot.drawLine(x2, y2 / 2, 1.5, y2 / 2);
	    run(col[channel]);
	    Plot.show();
	    close("Plot");
	
	    // Get 50% points
	    setTool("multipoint");
	    waitForUser("Select the 2 50% points");
	    roiManager("Add");
	    roiManager("Select",0 );
	    run("Measure");
	    x1_50 = getResult("X", 0);
	    x2_50 = getResult("X", 1);
	    run("Clear Results");
	    roiManager("Reset");
	   
	    close("Plot Value");
	}
	
	else { // if method is "auto": automatically calculate the 50% points from your selected max points
		selectWindow("Plot");
	    Plot.getValues(x, y);
	   	val_y1 = newArray(0);
	   	val_y2 = newArray(0);
		for(k=0 ;k<lengthOf(y)-1; k++) {
			if ((y[k]<=y1/2 && y1/2<=y[k+1]) || (y[k+1]<=y1/2 && y1/2<=y[k])) {
				print(x[k]);
				val=newArray(0);
				val[0]=x[k];
				val_y1=Array.concat(val_y1, val);
			}
			if ((y[k]<=y2/2 && y2/2<=y[k+1]) || (y[k+1]<=y2/2 && y2/2<=y[k])) {
				val=newArray(0);
				val[0]=x[k];
				val_y2=Array.concat(val_y2, val);
			}}
		Array.print(val_y1);
		Array.print(val_y2);
		Array.getStatistics(val_y1, min, max, mean, stdDev);
		x1_50 = min;
		Array.getStatistics(val_y2, min, max, mean, stdDev);
		x2_50 = max;
		
		close("Plot");
		}
    // Return the x value of the 2 50% points
    return newArray(x1_50, x2_50);
}

// colors for the different channels graphs
col = newArray("Magenta","Cyan","Green");

// loop on all centriole images
for(i=0 ;i<lengthOf(ImageNames); i++) {
	if (endsWith(ImageNames[i], ".tif")) {

	open(dirdata+ImageNames[i]);
	centriole_nb = centriole_nb+1; 
	centriole_ID = substring(ImageNames[i],lengthOf(ImageNames[i])-23,lengthOf(ImageNames[i])-4);

	rename("cell");
	Stack.setDisplayMode("color");
	setTool("line");
	run("Line Width... ");
	waitForUser("select a profile");
	
	// to get the measurement on all channels
	for(j=0 ;j<channel_nb; j++) {
		selectWindow("cell");
		channel = channel_list[j];
		print(channel);
		label = "prot"+(channel);
		resultPoints = getPointsFromChannel(channel);
		
		// Create the result table if not already opened
		if (isOpen("Prot Measurement")==false) {
			Table.create("Prot Measurement");
		}

		// result window update
		selectWindow("Prot Measurement");
		Table.set("Centriole_ID",centriole_nb,centriole_ID);
		Table.set(label+"pk1",centriole_nb,resultPoints[0]);
		Table.set(label+"pk2",centriole_nb,resultPoints[1]);
		Table.update;
	}
		run("Close All");
	}}

// Result window saving
selectWindow("Prot Measurement");
saveAs("Results", dirdata+filename);