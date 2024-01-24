// Macro by Elisa
// Get the intensity on a few individual MT for future normalization of MT analysis
//
//──────▄▀▄─────▄▀▄
//─────▄█░░▀▀▀▀▀░░█▄
//─▄▄──█░░░░░░░░░░░█──▄▄
//█▄▄█─█░░▀░░┬░░▀░░█─█▄▄█

// TO CHANGE ACCORDING TO YOUR IMAGES/ANALYSIS
extension = "_Lng_LVCC"; // Extension at the end of your deconvolved files
fraction_indivMT = 2; // // Set the number of individual MT we want for normalization (ex: 2 = analyse MT every 2 images)
nbserieMax = 50; // Maximum number of series possible in your .lif files

run("Close All");

// Ask the user for the wanted files
dirdata = getDirectory("Choisir le dossier contenant les stacks a analyser");   /// choix des dossier contenant les images a analyser
dir_roi = dirdata+"Segmented"+File.separator();
dir_result = dirdata+"Quantifications"+File.separator();
File.makeDirectory(dir_result);

// Select the good MT channel
Dialog.create("What is the MT channel?");
Dialog.addNumber("MT_channel:", 3);
Dialog.show();
MT_channel = Dialog.getNumber();

// Get only the files names in the folder
ImageNames=getFileList(dirdata); /// tableau contenant le nom des fichier contenus dans le dossier dirdata
ext_size = lengthOf(extension);

run("Set Measurements...", "area mean integrated redirect=None decimal=3");

if(isOpen("Results")) {
	selectWindow("Results");
	run("Close");}

if(isOpen("ROI Manager")) {
	roiManager("reset");}


// Initialize our data arrays
IndivMT = newArray(0);
Img = newArray(0);
cell_ID = newArray(0);


// Get List of series to open images in the .lif
series="";
for (i=0; i<nbserieMax; i++) {
	series=series+"series_"+i+" ";
}
MT_nb = -1;

// Loop on all the files of the folder
for (i=0; i<lengthOf(ImageNames); i++) { 
	// Open all images and Roi
	 if (endsWith(ImageNames[i], ".lif")) {
		name_size = lengthOf(ImageNames[i]) - 4;
		LifName=substring(ImageNames[i],0 ,name_size);
		
		// Open all images
		run("Bio-Formats", "open=["+dirdata+ImageNames[i]+"] color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT use_virtual_stack "+series);
		Names = getList("image.titles");
		Array.show(Names);
		
		// Close non deconvolved images for analysis on deconvolved files
		for(image=0;image<lengthOf(Names);image++) {
			Name = Names[image];
			
			if (endsWith(Name, extension)) {
				Serie_nb = substring(Name,lengthOf(Name)-12,lengthOf(Name)-9);
				Name_raw = substring(Name,0,lengthOf(Name)-9);
				
				selectWindow(Name_raw);
				close(Name_raw); // close raw if we can analyse intensities on LVCC data
			}}
		
		Names2 = getList("image.titles");
		Array.show(Names2);
		
	// Analysis on one images every fracrion_indivMT (here one every 2)
		for(image=0;image<lengthOf(Names2)/fraction_indivMT;image++) {
			Name = Names2[image*fraction_indivMT];
			Serie_nb = substring(Name,lengthOf(Name)-12,lengthOf(Name)-9);
			MT_nb ++;
			
			roiManager("reset")
			roiManager("Open", dir_roi+LifName+"_serie"+Serie_nb+"RoiSet.zip");

		// For expansion we generally have 1-2 cells per image. We analyse the first one
			selectWindow(Name);
			roiManager("select", 0);
			cell = Serie_nb+"_cell0";
	
			run("Duplicate...", "duplicate title=MT channels="+MT_channel);
			run("Enhance Contrast", "saturated=0.35");
			run("In [+]");
			run("In [+]");
			
		// user draw a line on an individual MT and we mean intensity along the line
			run("Select None");
			setTool("polyline");
			waitForUser("select one individual MT with a line");
			run("Measure");
	
			IndivMT[MT_nb] = getResult("Mean",0);
			Img[MT_nb] = LifName;
			cell_ID[MT_nb] = cell;
	
			close("MT");
			close(Name);
			roiManager("reset");
			run("Clear Results");
	}
	run("Close All");
	}


// SET THE RESULT TABLE

if(isOpen("Results")) {
    selectWindow("Results");
    run("Close");
}

// Save individual MT values
for(i=0; i<lengthOf(Img); i++) {
	setResult("Image Name",i,Img[i]);
	setResult("Cell Number",i,cell_ID[i]);
	setResult("Mean Gray value",i,IndivMT[i]);
	updateResults();
}

selectWindow("Results");
saveAs("Results",dir_result+"Results_individual_MT.csv");
run("Close");
