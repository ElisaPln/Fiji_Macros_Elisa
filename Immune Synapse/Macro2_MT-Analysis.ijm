// Macro by Elisa
// Analyze total MT integrated intensity, Area and the number of MT crossing an inner area
// Use normalization result table from the previous macro on individual MT
//
//┊┊┊┊┊┊┊┊┊┊┊┊┊╭╭╭╮╮╮┊┊┊┊┊┊┊┊┊
//┊┊┊┊┊┊┊┊┊┊┊┊╰╰╲╱╯╯┊┊┊┊┊┊┊┊
//┊┊┊┊┊┊┊┊┏╮╭┓╭━━━━━━╮┊┊┊┊┊┊┊┊
//┊┊┊┊┊┊┊┊╰╮╭╯┃┈┈┈┈┈┈┃┊┊┊┊┊┊┊┊
//┊┊┊┊┊┊┊┊┊┃╰━╯┈┈╰╯┈┈┃┊┊┊┊┊┊┊┊
//┊┊┊┊┊┊┊┊┊┃┈┈┈┈┈┈┈╰━┫┊┊┊┊┊┊┊┊
//        ╲╱╲╱╲╱╲╱╲╱╲╱╲╱


// TO CHANGE ACCORDING TO YOUR IMAGES/ANALYSIS
extension = "_Lng_LVCC"; // extension of the deconvolved files
nbSerieMax=50; // Maximum number of series possible in a .lif file
scale = 0.6; // scaling factor of the cell-ROI that is used to get the MT intensity profile

run("Close All");

dirdata = getDirectory("Choisir le dossier contenant les stacks a analyser");   /// choix des dossier contenant les images a analyser
dir_roi = dirdata+"Segmented"+File.separator();
dir_result = dirdata+"Quantifications"+File.separator();

// Extension of the files
ext_size = lengthOf(extension);

// Select the good MT channel
Dialog.create("What is the MT channel?");
Dialog.addNumber("MT_channel:", 3);
Dialog.show();
MT_channel = Dialog.getNumber();

// Open normalization table and get the mean MT value
open(dir_result+"Results_individual_MT.csv");
Table.rename("Results_individual_MT.csv", "Results");
run("Summarize");
mean_indiv_MT = getResult("Mean Gray value", nResults()-4);
sd_indiv_MT = getResult("Mean", nResults()-3);

// Open individual cells extracted
ImageNames=getFileList(dirdata); /// tableau contenant le nom des fichier contenus dans le dossier dirdata
cell_nb = -1;

// Initialize the Result tables
Network_Total_Area = newArray(0);
NetworkIntensity = newArray(0);
NormalizedIntensity = newArray(0);
Img = newArray(0);
cell = newArray(0);
Intensity_profile = newArray(0);
NormalizedIntensity_profile = newArray(0);
					

run("Set Measurements...", "area mean integrated redirect=None decimal=3");

if(isOpen("Results")) {
selectWindow("Results");
run("Close");
}
	
if(isOpen("ROI Manager")) {
	roiManager("reset");}

// Function that calculate the area under a curve by the trapezoid method
function trapezoidal_rule(xValues,yValues) {
    n = lengthOf(xValues);
    area = 0;
    for (i = 0; i < n-1; i++) {
    	area +=  (xValues[i+1]-xValues[i])/2*(yValues[i+1]+yValues[i]) ;
    }
    return area;
}


// List of series to open the .lif
series="";
for(i=1;i<nbSerieMax;i=i+1) {
	series=series+"series_"+i+" ";
}

run("Set Measurements...", "area mean min integrated redirect=None decimal=3");


//-----------------   MT NETWORK ANLYSIS  ------------------------------------------------------------
// Open all the lif files
for (i=0; i<lengthOf(ImageNames); i++) { 
	// Open all images and Roi
	 if (endsWith(ImageNames[i], ".lif")) {
		name_size = lengthOf(ImageNames[i]) - 4;
		LifName=substring(ImageNames[i],0 ,name_size);
		run("Bio-Formats", "open=["+dirdata+ImageNames[i]+"] color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT use_virtual_stack "+series);
		Names = getList("image.titles");

		for(image=0;image<lengthOf(Names);image++) {
			Name = Names[image];
			if (endsWith(Name, extension)) {
				Serie_nb = substring(Name,lengthOf(Name)-12,lengthOf(Name)-9);
				Name_raw = substring(Name,0,lengthOf(Name)-9);
				
				selectWindow(Name);
				run("Duplicate...", "title=Total_Image duplicate");
				
				selectWindow(Name_raw);
//				run("Duplicate...", "title=Total_Image_raw duplicate"); // if we want to analyse on raw files
				close(Name_raw); // close raw if we can analyse intensities on LVCC data
				
				roiManager("Open", dir_roi+LifName+"_serie"+Serie_nb+"RoiSet.zip");
				n= roiManager("count");
				roiManager("reset");
				
			// Get each cell of the image from the ROI
				for (object = 0; object < n; object++) {
					cell_nb = cell_nb + 1;
					cell_ID = Serie_nb+"_cell"+object;
					
			// Create cell images deconv and raw
				
					roiManager("Open", dir_roi+LifName+"_serie"+Serie_nb+"RoiSet.zip");

//					selectWindow(Total_Image_raw);
//				    roiManager("select", object);		   
//		  			run("Duplicate...", "title=raw_cell duplicate");
//		  			run("Clear Outside", "stack"); // Remove surrounding signal
//		  			run("Select None");
		  			
		  			selectWindow("Total_Image");
				    roiManager("select", object);
		  			run("Duplicate...", "title=deconv_cell duplicate channels="+MT_channel);
		  			run("Clear Outside", "stack");
		
		
		//---------   Microtubule Mask (without projection)  -------------------
						// Pre-cleaning
					selectWindow("deconv_cell");
					run("Select None");
					setSlice(20);
					run("Duplicate...", "duplicate");
					run("Subtract Background...", "rolling=50 stack");
					run("Unsharp Mask...", "radius=2 mask=0.60 stack");
					run("Gaussian Blur...", "sigma=1 stack");
					run("Gamma...", "value=0.75 stack");
					
						// Thresholding (auto)
					setAutoThreshold("Otsu dark no-reset");
					setOption("BlackBackground", true);
					run("Convert to Mask", "method=Otsu background=Dark black stack");
					   // Thresholding Manual
				//	run("Threshold...");
				//	setAutoThreshold("Default dark");
				//	waitForUser("Play with threshold"); // Set a low threshold to keep only somas
				//	run("Convert to Mask", "stack");
					run("Despeckle", "stack");
					rename("MT_mask");
					
					nb_stack = nSlices();
					Area_MT = 0;
					
						// Get overall area per slice
					for (slice = 1; slice <= nb_stack; slice++) {
						selectWindow("MT_mask");
						//run("Duplicate...", "duplicate range="+slice+"-"+slice);
						setSlice(slice);
				//		run("Select All");
						run("Create Selection");
						run("Measure");
						if (getResult("Mean",0)==0) {
							Area_MT = Area_MT+ 0;}
						else{
							Area_MT = Area_MT+ getResult("Area",0);}
							print(getResult("Area",0));
						//close();
						run("Clear Results");
						}
					//	print(Area_MT);
					
				
		// -------- Intensity analysis -------------------------------------
						// Multiply Mask by original intensity
					imageCalculator("Multiply create 32-bit stack", "deconv_cell","MT_mask");
					run("Divide...", "value=255 stack");
					run("Z Project...", "projection=[Sum Slices]");
					run("Select None");
					run("Measure"); // Raw integrated density = sum of intensity of pixels in the defined MT network ~ MT quantity
					run("Close");
					
						// Fill data tables
					Img[cell_nb] = LifName;
					cell[cell_nb] = cell_ID;
					Network_Total_Area[cell_nb] = Area_MT;
					NetworkIntensity[cell_nb] = getResult("RawIntDen",0);
					NormalizedIntensity[cell_nb] = NetworkIntensity[cell_nb]/(mean_indiv_MT); // divide Raw integrated density by individual MT intensity
					
					
		// -------- Get "number" of MT crossing an inner area --------------------------------
					selectWindow("Total_Image");
					roiManager("select", object);
					run("Duplicate...", "title=deconv_cell2 duplicate channels="+MT_channel);
						// We shrink the ROI with a scale fzctor decided at the beginning of the macro
					run("Scale... ", "x="+scale+" y="+scale+" centered");
					roiManager("reset");
					roiManager("Add");
					
					run("Clear Results");
					run("Measure");
					min=getResult("Min", 0);
					run("Select None");
					run("Subtract...", "value="+min);
					
					roiManager("select", 0);
					run("SegmentedLine Conversion");
					run("Plot Profile");
					
					// get the area under the intensity plot-profile curve
					Plot.getValues(x, y);
					Intensity_profile[cell_nb] = trapezoidal_rule(x,y);
					NormalizedIntensity_profile[cell_nb] = Intensity_profile[cell_nb]/(mean_indiv_MT);
					
		// --------- CLOSE ALL IMAGES ----------------------------
					close("MT_mask");
					//close("raw_cell");
					close("deconv_cell");
					close("deconv_cell2");
					close("Plot of deconv_cell2");
					roiManager("reset");
					run("Clear Results");
				}
				
					close("Total_Image");
					close(Name);
					roiManager("reset");
				}}}
	 	run("Close All");
	 }


// SET THE RESULT TABLE
if(isOpen("Results")) {
    selectWindow("Results");
    run("Close");
}


// Save Intensity network values
for(i=0;i<cell_nb;i++) {
	setResult("Image Name",i,Img[i]);
	setResult("Cell",i,cell[i]);
	setResult("Network Total Area",i,Network_Total_Area[i]);
	setResult("Network Total Intensity",i,NetworkIntensity[i]);
	setResult("Network Normalized Intensity",i, NormalizedIntensity[i]);
	setResult("Intensity along Inner Curve",i, Intensity_profile[i]);
	setResult("Intensity along Inner Curve normalized",i, NormalizedIntensity_profile[i]);
	updateResults();

}


selectWindow("Results");
saveAs("Results",dir_result+"Results_MT_Network.csv");
