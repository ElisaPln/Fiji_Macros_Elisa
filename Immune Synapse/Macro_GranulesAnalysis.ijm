// Macro by Elisa
// Analyze Granules from the segmented .lif files and the associated ROI extracted with the Segmentation program

//			╭━┳━╭━╭━╮╮
//			┃┈┈┈┣▅╋▅┫┃
//			┃┈┃┈╰━╰━━━━━━╮
//			╰┳╯┈┈┈┈┈┈┈┈┈◢▉◣
//			╲┃┈┈┈┈┈┈┈┈┈▉▉▉
//			╲┃┈┈┈┈┈┈┈┈┈◥▉◤
//			╲┃┈┈┈┈╭━┳━━━━╯
//			╲┣━━━━━━┫﻿

// TO CHANGE ACCORDING TO YOUR IMAGES/ANALYSIS
extension = "_Lng_LVCC"; // extension of the deconvolved files
nbSerieMax=50; // Maximum number of series possible in a .lif file


run("Close All");

dirdata = getDirectory("Choisir le dossier contenant les stacks a analyser");   /// choix des dossier contenant les images a analyser
dir_roi = dirdata+"Segmented"+File.separator();
dir_result = dirdata+"Quantifications"+File.separator();
File.makeDirectory(dir_result); 

// Extension of the files
ext_size = lengthOf(extension);

// Select the good granules channel
Dialog.create("Channel Information");
Dialog.addString("Granules marker:", "GrzmB");
Dialog.addNumber("Channel Granzyme:", 1);
Dialog.addNumber("Channel NHS:", 3);
Dialog.show();
staining = Dialog.getString();
Granules_channel = Dialog.getNumber();
NHS_channel = Dialog.getNumber();


// Open individual cells extracted
ImageNames=getFileList(dirdata); /// tableau contenant le nom des fichier contenus dans le dossier dirdata
cell_nb = -1;

// Initialize the Result tables
Cell_size = newArray(0);
Granules_staining = newArray(0);
GranulesTotalIntensity = newArray(0);
GranulesNormalizedIntensity = newArray(0);
GranulesNb = newArray(0);
GranulesMeanVolume = newArray(0);
GranulesSDVolume = newArray(0);
GranulesMeanIntensity = newArray(0);
GranulesSDIntensity = newArray(0);
GranulesMeanDistToSurf = newArray(0);
GranulesSDDistToSurf = newArray(0);
Img = newArray(0);
cell = newArray(0);

run("Set Measurements...", "area mean min integrated redirect=None decimal=3");


if(isOpen("Results")) {
selectWindow("Results");
run("Close");
}
	
if(isOpen("ROI Manager")) {
	roiManager("reset");}
	
series="";
for(i=1;i<nbSerieMax;i=i+1) {
	series=series+"series_"+i+" ";
}

//---------------------  GRANULES ANALYSIS  -----------------------------------------
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
				
				roiManager("reset");
				roiManager("Open", dir_roi+LifName+"_serie"+Serie_nb+"RoiSet.zip");
				n= roiManager("count");
				roiManager("reset");
				
			// Get each cell of the image from the ROI
				for (object = 0; object < n; object++) {
					cell_nb = cell_nb + 1;
					cell_ID = Serie_nb+"_cell"+object;
					
					Img[cell_nb] = LifName;
					cell[cell_nb] = cell_ID;
					
					roiManager("reset");
					roiManager("Open", dir_roi+LifName+"_serie"+Serie_nb+"RoiSet.zip");

				// To analyse Raw image
//					selectWindow(Total_Image_raw);
//				    roiManager("select", object);		   
//		  			run("Duplicate...", "title=raw_cell duplicate");
//		  			run("Clear Outside", "stack"); // Remove surrounding signal
//		  			run("Select None");
		  			
		  			selectWindow("Total_Image");
				    roiManager("select", object);
		  			run("Duplicate...", "title=deconv_cell_granules duplicate channels="+Granules_channel);
		  			run("Clear Outside", "stack");
		  			
		  			selectWindow("Total_Image");
				    roiManager("select", object);
		  			run("Duplicate...", "title=deconv_cell_NHS duplicate channels="+NHS_channel);
		  			run("Clear Outside", "stack");
  			
  			
//---------------- Total Granules staining intensity  ---------------------------------------

  			// To get mask on NHS:
//  			selectWindow(name+"_LVCC.tif");
//		    roiManager("select", object);
//  			run("Duplicate...", "title=deconv_NHS duplicate channels="+NHS_channel);
//  			run("Clear Outside", "stack");
			
	
					selectWindow("deconv_cell_granules");
					run("Z Project...", "projection=[Sum Slices]");
					roiManager("select", object);
				    run("Measure");
				    
				    Cell_size[cell_nb] = getResult("Area", 0);
				    Granules_staining[cell_nb] = staining;
					GranulesTotalIntensity[cell_nb] = getResult("RawIntDen", 0);
					GranulesNormalizedIntensity[cell_nb] = getResult("RawIntDen", 0)/getResult("Min", 0); // we divide by the minimal value which is considered the background
				    run("Clear Results");
				    close("SUM deconv_cell_granules");
			
			
//--------------- Granules identification (with no Z-projection because granules could overlap) ----------------------------------------------
						// Pre-cleaning
					selectWindow("deconv_cell_granules");
					run("Select None");
					run("Duplicate...", "title=Mask duplicate");
					run("Subtract Background...", "rolling=50 stack");
					run("Unsharp Mask...", "radius=2 mask=0.60 stack");
					run("Gaussian Blur...", "sigma=2 stack");
					run("Gamma...", "value=1 stack");
					
						// Find 3D Object
					run("3D Objects Counter", "threshold=205 slice=33 min.=50 max.=20799109 exclude_objects_on_edges objects statistics summary");	
					Table.rename("Statistics for Mask", "Results");
				
						// If the program cannot find the granules automatically: adjust the threshold by hand until it works
					if (getValue("results.count")==0) { // Add the wanted selective parameters if you want to manually select the threshold
						selectWindow("Mask");
						run("3D Objects Counter");
						waitForUser("play with the threshold value for granules identification");
						Table.rename("Statistics for Mask", "Results");
					}

						// Save the object image
					selectWindow("Objects map of Mask");
					saveAs("Tiff", dir_result + LifName + cell_ID +"_GranulesMap.tif");
					close("Objects map of Mask");

//---------------- Get the nb of granules detected --------------------------------------------------------------------
					granules_nb=getValue("results.count");
					GranulesNb[cell_nb] = granules_nb;

//--------------- To get a nice table with all individual granules referenced -------------------------------------------
				// If too heavy just add a command to save the separated tables per cells
					headings = String.getResultsHeadings;
					headingsArray = split(headings, "\t");
					Array.print(headingsArray);
					if (isOpen("Granules Analysis")==false) {
						Table.create("Granules Analysis");
					}
					selectWindow("Granules Analysis");
					size = Table.size;
					for (granule= 0; granule < granules_nb; granule++) {
						selectWindow("Granules Analysis");
						Table.set("Image Name",granule+size,LifName);
						Table.set("Cell_ID",granule+size,cell_ID);
						Table.set("Granule_ID",granule+size,granule);
							
						for (j=1; j<headingsArray.length; j++){
							data = getResult(headingsArray[j], granule);
							selectWindow("Granules Analysis");
							Table.set(headingsArray[j], granule+size, data);
							Table.update;
					}}
					
//---------------- Get Intensity/Size parameters Summary for this cell ---------------------------------------------------
					run("Summarize"); // Summarize add 3 rows at the end of the table for Mean-SD-Min-Max
					GranulesMeanVolume[cell_nb] = getResult("Volume (micron^3)", granules_nb);
					GranulesSDVolume[cell_nb] = getResult("Volume (micron^3)", granules_nb+1);
					GranulesMeanIntensity[cell_nb] = getResult("Mean", granules_nb);
					GranulesSDIntensity[cell_nb] = getResult("Mean", granules_nb+1);
					GranulesMeanDistToSurf[cell_nb] = getResult("Mean dist. to surf. (micron)", granules_nb);
					GranulesSDDistToSurf[cell_nb] = getResult("Mean dist. to surf. (micron", granules_nb+1);
					
					
					run("Clear Results");	
					roiManager("reset");
					
					close("deconv_cell_granules");
					close("deconv_cell_NHS");
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
	setResult("Granules staining",i,Granules_staining[i]);
	setResult("Cell Size",i,Cell_size[i]);
	setResult("Granules Total Intensity",i, GranulesTotalIntensity[i]);
	setResult("Granules Normalized Intensity",i, GranulesNormalizedIntensity[i]);
	setResult("Granules Nb",i, GranulesNb[i]);
	setResult("Granules Mean Volume",i, GranulesMeanVolume[i]);
	setResult("Granules SD Volume",i, GranulesSDVolume[i]);
	setResult("Granules Mean Intensity",i, GranulesMeanIntensity[i]);
	setResult("Granules SD Intensit",i, GranulesSDIntensity[i]);
	setResult("Granules Mean Dist To Surf",i, GranulesMeanDistToSurf[i]);
	setResult("Granules SD Dist To Surf",i, GranulesSDDistToSurf[i]);

	updateResults();
}


selectWindow("Results");
saveAs("Results",dir_result+"Summary_Granules.csv");


selectWindow("Granules Analysis");
saveAs("Results",dir_result+"IndivGranulesAnalysis.csv");
