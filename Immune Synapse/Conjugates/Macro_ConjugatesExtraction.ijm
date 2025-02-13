// Macro by Elisa - Adapted from Noémie's synapse extraction
// Open raw images from .lif or.nd files and save individual image for manually selected conjugates

//		˚∧＿∧  　+        —̳͟͞͞✩
//		(  •‿• )つ  —̳͟͞͞ ✩         —̳͟͞͞✩ +
//		(つ　 <                —̳͟͞͞✩
//		｜　 _つ      +  —✩         —̳͟͞͞✩ ˚
//		`し´

// PARAMETERS TO CHANGE BEFORE LAUNCHING
extension = ".lif"; // extension of your files
nbSerieMax=50; // maximum number of series in your multiposition files

// _________MACRO_____________________________________________________________________________________________
run("Close All");
// Get the folder we want to analyse --> this macro will analyse ALL lif or nd files in the folder at the same time.
dirdata = getDirectory("Choisir le dossier contenant les stacks a analyser");   /// choix des dossier contenant les images a analyser
dir=dirdata+"Synapses"+File.separator();
File.makeDirectory(dir); 

ext_size = lengthOf(extension);

// Dialog Box to choose the colors in your images
channel_color = newArray("Red", "Green", "Blue", "Magenta","Cyan","Yellow","Grays");
Dialog.create("Select the colors of your images");
Dialog.addChoice("channel_1:", channel_color);
Dialog.addChoice("channel_2:", channel_color);
Dialog.addChoice("channel_3:", channel_color);
Dialog.addChoice("channel_4:", channel_color);
Dialog.show();
channel_1 = Dialog.getChoice();
channel_2 = Dialog.getChoice();
channel_3 = Dialog.getChoice();
channel_4 = Dialog.getChoice();

// File list
ImageNames=getFileList(dirdata); // Array containing all files names in dirdata
nbimages=lengthOf(ImageNames); //

// To open all series in one lif file
series="";
for(i=1;i<nbSerieMax;i=i+1) {
	series=series+"series_"+i+" ";
}

// LOOP ON ALL FILES
for (i=0; i<lengthOf(ImageNames); i++) {
	 // Only analyse image files .lif or .nd
	 if (endsWith(ImageNames[i], extension)) {
		name_size = lengthOf(ImageNames[i]) - ext_size;
		LifName=substring(ImageNames[i],0 ,name_size);
		run("Bio-Formats", "open=["+dirdata+ImageNames[i]+"] color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT use_virtual_stack "+series);
		Names = getList("image.titles"); // All open images = all series/position of 1 .lif/.nd file
		
		 // Loop on all opened images = on all series of the .lif/.nd file
		for(image=0;image<lengthOf(Names);image++) {
			Name = Names[image];
			Serie_nb = substring(Name,lengthOf(Name)-3,lengthOf(Name)); // nb of the serie/position

			selectWindow(Name);
			setSlice(15);	
		
		// Adjust colors and brightness
			Stack.setChannel(1);
			run("Enhance Contrast", "saturated=0.35");
			run(channel_1);
			
			Stack.setChannel(2);
			run("Enhance Contrast", "saturated=0.35");
			run(channel_2);
			
			Stack.setChannel(3);
			run("Enhance Contrast", "saturated=0.35");
			run(channel_3);
			
			Stack.setChannel(4);
			run("Enhance Contrast", "saturated=0.35");
			run(channel_4);
			
			Stack.setDisplayMode("composite");
			
			// Ask the user to select wanted cells
			waitForUser("do you see the cells");
			cell_nb = getNumber("How many synapse will you analyse on this image ?", 3);
		
			if(isOpen("ROI Manager")) {
				roiManager("reset");
				}

			if(cell_nb==0) { // If no cells selected on the image
				print("Go to the next image");
				close();
				}
				
			else { // if at least 1 cell selected by the user
	
	//------------ 1. SELECT ALL CELLS AND SAVE POSITIONS ------------------------------------------------------
				for(j=0 ;j<cell_nb; j++) {
					setTool("rectangle");
					waitForUser("select a synapse");
					roiManager("add");
					roiManager("show all");
				}
				roiManager("Save", dirdata+LifName+"_"+Serie_nb+"_ROI_Selection.zip");
	
	//------------ 2. ORIENTATE AND SAVE INDIVIDUAL CELLS AS .tif FILES ------------------------------------------------------
				
				for(cell=0 ;cell<cell_nb; cell++) {
					roiManager("reset");
					roiManager("Open", dirdata+LifName+"_"+Serie_nb+"_ROI_Selection.zip");
					cell_ID = Serie_nb+"_cell"+cell;
					
					// Zoom on a cell
		  			selectWindow(Name);
				    roiManager("select", cell);
					run("Duplicate...", "duplicate");
					rename("cell");
					
					// Orientate the conjugate according to the synapse
					Stack.getDimensions(width, height, channels, slices, frames);
					setTool("line");
					waitForUser("choisis le plan de la synapse et trace la ligne");
					roiManager("reset");
					roiManager("add");
					run("Measure");
					anglesynapse=getResult("Angle", 0)-90;
					Stack.getPosition(channel1, slice1, frame1);
					run("Clear Results");
					run("Duplicate...", "title=temp.tif duplicate");
					run("Rotate... ", "angle="+anglesynapse+" grid=1 interpolation=Bilinear stack");
			
					selectWindow("temp.tif");
				
					/// ask for flip or not
					yesno=newArray("yes", "no");
					Dialog.create("Turn the cell");
					Dialog.addCheckbox("Turn the cell", false);
					Dialog.show();
					turn=  Dialog.getCheckbox();
		
					if(turn==true) {
					selectWindow("temp.tif");
					run("Flip Horizontally");
					}
	
					// Save individual images in separated folder
					selectWindow("temp.tif");
					saveAs("Tiff", dir + LifName+"_"+cell_ID+".tif");
					run("Close");
					selectWindow("cell");
					run("Close");
				}
	selectWindow(Name); // close total image at the end and go to the next serie/position
	run("Close");
	}
}}}
