// Macro by Elisa
// Analyze mitochondria from the .lif files and the ROI actracted form the segmentation program
// For elongated mitochondria you can also use the "Ridge detection" pluging go get width and length of the filaments

//			──▒▒▒▒▒▒───▄████▄
//			─▒─▄▒─▄▒──███▄█▀
//			─▒▒▒▒▒▒▒─▐████──█─█
//			─▒▒▒▒▒▒▒──█████▄
//			─▒─▒─▒─▒───▀████▀

// TO CHANGE ACCORDING TO YOUR IMAGES/ANALYSIS
extension = "_Lng_LVCC"; // extension of the deconvolved files
nbSerieMax=50; // Maximum number of series possible in a .lif file
selection_value = 45; // Intensity minimal to detect a granule as a mitochondria

run("Close All");

dirdata = getDirectory("Choisir le dossier contenant les stacks a analyser");   /// choix des dossier contenant les images a analyser
dir_roi = dirdata+"Segmented"+File.separator();
dir_result = dirdata+"Quantifications"+File.separator();
File.makeDirectory(dir_result); 

// Extension of the files
ext_size = lengthOf(extension);

// Select the good mitochondria channel
Dialog.create("Channel Information");
Dialog.addString("Mitochondria marker:", "TOM20");
Dialog.addNumber("Channel mitochondria:", 3);
Dialog.addNumber("Channel NHS:", 1);
Dialog.show();
staining = Dialog.getString();
Mito_channel = Dialog.getNumber();
NHS_channel = Dialog.getNumber();


// Open individual cells extracted
ImageNames=getFileList(dirdata); /// tableau contenant le nom des fichier contenus dans le dossier dirdata
cell_nb = -1;

// Initialize the Result tables
Cell_size = newArray(0);
Mito_staining = newArray(0);
MitoTotalIntensity = newArray(0);
MitoNormalizedIntensity = newArray(0);
GranulesArea = newArray(0);
PositiveGranulesArea = newArray(0);
Img = newArray(0);
cell = newArray(0);



run("Set Measurements...", "area mean min integrated redirect=None decimal=3");

if(isOpen("Results")) {
	run("Clear Results");
	}

if(isOpen("Indiv Mito Measurement")) {
	close("Indiv Mito Measurement");
	}

if(isOpen("ROI Manager")) {
	roiManager("reset");
	}

series="";
for(i=1;i<nbSerieMax;i=i+1) {
	series=series+"series_"+i+" ";
}

Table.create("Indiv Mito Measurement");


//---------------------  MITOCHONDRIA ANALYSIS  -----------------------------------------
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
		  			run("Duplicate...", "title=deconv_cell_mito duplicate channels="+Mito_channel);
		  			run("Clear Outside", "stack");
		  			
		  			selectWindow("Total_Image");
				    roiManager("select", object);
		  			run("Duplicate...", "title=deconv_cell_NHS duplicate channels="+NHS_channel);
		  			run("Clear Outside", "stack");
		
			
//---------------- Total Mitochondria staining intensity  ---------------------------------------
					selectWindow("deconv_cell_mito");
					// selectWindow("raw_cell"); to analyse on raw data
					run("Z Project...", "projection=[Sum Slices]");
					roiManager("select", object);
					run("Clear Results");
				    run("Measure");
				    
				    Cell_size[cell_nb] = getResult("Area", 0);
				    Mito_staining[cell_nb] = staining;
					MitoTotalIntensity[cell_nb] = getResult("RawIntDen", 0);
					MitoNormalizedIntensity[cell_nb] = getResult("RawIntDen", 0)-getResult("Min", 0); // we remove by the minimal value which is considered to be the background
				    run("Clear Results");
			
			
//---------------- Mitochondria Mask (with Z-projection) ------------------------------------
				// Pre-cleaning
					selectWindow("deconv_cell_NHS"); // On NHS channel
					run("Select None");
					run("Z Project...", "projection=[Max Intensity]");
					run("Subtract Background...", "rolling=50 stack");
					run("Unsharp Mask...", "radius=2 mask=0.60 stack");
					run("Gaussian Blur...", "sigma=2 stack");
					run("Gamma...", "value=1 stack");
			
				// Thresholding (auto)
					setAutoThreshold("RenyiEntropy dark no-reset");
					setOption("BlackBackground", true);
					run("Convert to Mask", "method=Otsu background=Dark black stack");
			    // Thresholding Manual
				//	run("Threshold...");
				//	waitForUser("Play with threshold"); // Set a low threshold to keep only somas
				//	run("Convert to Mask", "stack");
					run("Despeckle", "stack");
					rename("Mito_mask");
			

//---------------- Get overall area of the granular network -------------------------------------
					selectWindow("Mito_mask");
					run("Create Selection");
					run("Measure");
					GranulesArea[cell_nb] = getResult("Area", 0);
					run("Clear Results");
			
//---------------- Get individual measurement for each mitochondria and remove those below a certain value of staining intensity -----------------------------------
					roiManager("reset");
					selectWindow("Mito_mask");
					run("Select None");
					run("Analyze Particles...", "size=0.50-Infinity exclude clear overlay add");
					mito_nb = roiManager("count");
					roiManager("Save", dirdata + cell_ID+"_Mitochondria_RoiSet.zip"); // Save the Roi of the detected granules
					
					Table.rename("Indiv Mito Measurement", "Results");
					mito_neg_count=0;
					mito_neg=newArray(0);
					row=getValue("results.count");
		
					for (mito=0; mito<mito_nb; mito++) {
						selectWindow("deconv_cell_mito");
						roiManager("select", mito);
						run("Measure");
						setResult("Image Name",mito+row,Name);
						setResult("Cell_ID",mito+row,cell_ID);
						setResult("ROI_ID",mito+row,Roi.getName);
						updateResults();
						
						stain_value = getResult("Mean", mito); // selection on the mean intensity??
						
						//Select Roi depending on staining intensity (determined by the selection_value defined at the very beginning of the code)
						if (stain_value>selection_value) {
							setResult("Status",mito+row,"pos");
						}
						else {
							setResult("Status",mito+row,"neg");
							mito_neg[mito_neg_count]=mito;
							mito_neg_count++;
						}}
			
					Table.rename("Results", "Indiv Mito Measurement");
					
					
//--------------- Get total Area of pos mito ---------------------------------------------------------
					roiManager("Select", mito_neg);
					roiManager("Delete"); // We remove all negative granules = non mitochondrial roi
					roiManager("Select All"); // We select and combine the rest
					roiManager("Combine");
					roiManager("Add");
					if (roiManager("count")>0) {
						roiManager("Select", roiManager("count")-1);
						run("Clear Results");
						run("Measure");
						PositiveGranulesArea[cell_nb] = getResult("Area", 0);
					}
					else {
						PositiveGranulesArea[cell_nb] = 0;
					}
					roiManager("reset");
					
					close("Mito_mask");
					close("deconv_cell_mito");
					close("deconv_cell_NHS");
					close("SUM deconv_cell_mito");
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
	setResult("Mito staining",i,Mito_staining[i]);
	setResult("Cell Size",i,Cell_size[i]);
	setResult("Mito Total Intensity",i, MitoTotalIntensity[i]);
	setResult("Mito Normalized Intensity",i, MitoNormalizedIntensity[i]);
	setResult("Granules Area",i, GranulesArea[i]);
	setResult("Positive Granules Area",i, PositiveGranulesArea[i]);
	updateResults();

}


selectWindow("Results");
saveAs("Results",dir_result+"Results_MitoAnalysis.csv");


selectWindow("Indiv Mito Measurement");
saveAs("Results",dir_result+"Indiv_MitoMeasurement.csv");
