// Macro by Elisa
// Open conjugates files (.tif) from MACRO_ConjugatesExtraction
// Calculate Solidity and deformation of the synapse with actin/CD45 channel through maual or auto means

//	          ☆ ° ✧　 
//			   ★*
//			/\︵-︵/\
//			|(◉)(◉)|
//			\ ︶V︶ /
//			/↺↺↺↺\
//			↺↺↺↺↺|
//			\↺↺↺↺/
//                ¯¯¯¯¯¯¯¯/\¯/\¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
//	          ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯		⠀⠀

// PARAMETERS TO CHANGE BEFORE LAUNCHING
method_threshold="manual"; // Method used for the threshold of the cell: "manual" or "auto"
distance_manual = true // method used to calculate the distance to the synapse
distance_auto = true
Contour_channel = 2; // Channel used for contouring od the cell (usually Actin or CD45)

// _________MACRO_____________________________________________________________________________________________

run("Close All");

// Ask the user the file with conjugates to analyse
dirdata = getDirectory("Choose the folder you would like to analyze");
dir_result = dirdata+"Quantifications"+File.separator();
File.makeDirectory(dir_result);

// Get all files names in the folder
ImageNames=getFileList(dirdata); // array containing all files name in dirdata
cell_nb = -1;

// Initialize Results and ROI Manager
if(isOpen("Results")) {
		selectWindow("Results");
		run("Close");
		}
		
if(isOpen("ROI Manager")) {
	roiManager("reset");
	}

// Initialize wanted measurements
run("Set Measurements...", "area mean standard min centroid center shape integrated redirect=None decimal=3");

// Create the result table
if (isOpen("Synapse Shape")==false) {
Table.create("Synapse Shape");
}

// Open all the lif files
for (image=0; image<lengthOf(ImageNames); image++) { 
	Name=ImageNames[image];   
	namelength=lengthOf(Name)-4;   // ex: remove 4 last caracters, here ".tif"
	name1=substring(Name, 0, namelength); // Remove extension from name. name1 = Name without .tif at the end
	
	if (endsWith(ImageNames[image], ".tif")) { // Only open .tif files
		open(dirdata+Name);
		cell_nb++; // Follow the number of cells we analysed
		
		selectWindow(Name);
		Stack.getDimensions(width, height, channels, slices, frames);
		getPixelSize(unit, pixelWidth, pixelHeight);
		
		// Ask the user to trace the synapse line at the wanted plane and save this line as Roi
		roiManager("reset");
		run("Line Width...", "line=1");
		setTool("line");
		waitForUser("Choose the synapse plane you want to analyse and trace the synapse line");
		roiManager("add");
		roiManager("Select", 0);
		roiManager("Rename", "synapse");
		
	// ---------------------- CELL MASK ----------------------------------------------------------------
    // Get the Mask of the whole cell using the Actin (or CD45) channel-------------------------------------------	
	
		run("Select None");
		run("Duplicate...", "title=temp");
		run("Duplicate...", "title=MaskCell duplicate channels="+Contour_channel);
		
		 // Image treatment for better thresholding
		run("Gaussian Blur...", "sigma=2 stack");
		run("Subtract Background...", "rolling=250 stack");
		 
		 // Thresholding manual or automatic (change automatic programm according to you staining quality)
		if (method_threshold == "manual") {
			setOption("BlackBackground", true);
			run("Threshold...");
			waitForUser("play with the threshold value");
			run("Convert to Mask");
		}
		
		if (method_threshold == "auto") {
			setOption("BlackBackground", true);
			run("Threshold...");
			run("Convert to Mask", "method=Yen background=Dark black");
		}
		
		run("Fill Holes");
		run("Analyze Particles...", "size=10-Infinity show=Overlay include overlay add");
		
		 // Check the mask
		selectWindow("temp");
		roiManager("Show All");
		waitForUser("Remove non cells particles");
		roiManager("Select", 1);
		roiManager("Rename", "mask");
		
		 // Add the whole cell analysis results in the table
		run("Clear Results");
		run("Measure");
		selectWindow("Synapse Shape");
		Table.set("Image Name",cell_nb,name1);
		Table.set("Area_total",cell_nb,getResult("Area", 0));
		Table.set("AR_total",cell_nb,getResult("AR", 0));
		Table.set("Solidity_total",cell_nb,getResult("Solidity", 0));
		Table.update;
		
		
	// ---------------------- DISTANCE TO SYSNAPSE MANUAL MEASUREMENT ----------------------------------------------------------------
    // Get the Distance to the synapse by manually drawing a perpendicular line between you cell and the synapse -------------------------------------------	
		if (distance_manual == true) {
			selectWindow("temp");
			roiManager("Show All");
			waitForUser("Draw the perpendicular line you want to measure");

			run("Clear Results");
			run("Measure");
			// Add the line length to the result table
			selectWindow("Synapse Shape");
			Table.set("Distance_manual",cell_nb,getResult("Length", 0));
			Table.update;
		}
		
	// ---------------------- DISTANCE TO SYSNAPSE AUTO MEASUREMENT ----------------------------------------------------------------
    // Automatically calculate the Distance to the synapse using a distance map -------------------------------------------	
	
		if (distance_auto == true) {	
			 // ---------------------- 1. SYNAPSE CONTOURING ----------------------------------------------------------------
    		 // Get the Synapse contouring from the cell mask -------------------------------------------	
			selectWindow("MaskCell");
			run("Select None");
			run("Duplicate...", "title=Synapse");
			run("Select All");
			run("Clear");
			roiManager("Select", 1); // select mask
			run("Draw");
			roiManager("Deselect All");
			run("Line Width...", "line=10");
			run("Select None");
			waitForUser("Delimitate the side of your synapse");
			run("Clear");
			waitForUser("Delimitate the side of your synapse");
			run("Clear");
			run("Analyze Particles...", "size=0-Infinity show=Overlay include overlay add");
			
			roiManager("Select", 2);
			roiManager("Rename", "cell_back");
			roiManager("Select", 3);
			roiManager("Rename", "cell_front");
			close("Synapse");
			
			 // ---------------------- 2. DISTANCE MAP ----------------------------------------------------------------
		     // Get the Distance map and measure the synapse contouring on this map -------------------------------------------	
			selectWindow("MaskCell");
			run("Select None");
			run("Duplicate...", "title=Distance_Map");
			run("Select All");
			run("Clear");
			roiManager("Select", "synapse");
			run("Line Width...", "line=1");
			run("Draw");
			run("Convert to Mask", "method=Default background=Dark black");
			
			run("Invert");
			run("Distance Map");
			
			// Measure
			run("Clear Results");
			roiManager("Select",2);
			run("Measure"); // get total size of the cell
			roiManager("Select",3);
			run("Measure"); // get mean, max and sd distance to the sysnapse line
			
			cell_size = getResult("Max", 0)*pixelWidth;
			synapse_mean = getResult("Mean", 1)*pixelWidth;
			synapse_max = getResult("Max", 1)*pixelWidth;
			synapse_sd = getResult("StdDev", 1)*pixelWidth;
			
			// Add the instensity results to the result table
			selectWindow("Synapse Shape");
			Table.set("Cell Size",cell_nb,cell_size);
			Table.set("Synapse Mean Distance",cell_nb,synapse_mean);
			Table.set("Synapse Max Distance",cell_nb,synapse_max);
			Table.set("Synapse Distance SD",cell_nb,synapse_sd);
			Table.update;
		}
		// Save ROI with synapse and cell contouring used
		roiManager("Save", dirdata+name1+"_AnalysisROI.zip");
		run("Close All");
		}}
			
//----------------  SAVE FINAL RESULTS -------------------------------------------------------------------------
if (isOpen("Synapse Shape")==true) {
	selectWindow("Synapse Shape");
	saveAs("Results", dir_result+"Results_SynapseShape.csv");	
}																	
			
			
