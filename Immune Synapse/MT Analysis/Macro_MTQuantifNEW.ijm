// Macro by Elisa
// Goal: get MT global intensity of a cell normalized by the of the BG
// Images need to be pre-segmented using the "Macro_SynapseSegmentation.ijm" macro
//                                             (░(¯`:´¯)░)
//			.....(░(¯`:´¯)░)               (░(¯ `·.\|/.·´¯)░)
//		....(░(¯ `·.\|/.·´¯)░)             (░(¯ `·.(█).·´¯)░░
//		....(░(¯ `·.(█).·´¯)░░  (¯`:´¯)░)   (░(_.·´/|\`·._)
//		.....(░(_.·´/|\`·._)(¯ `·.\|/.·´¯)░)...(░(_.:._).░
//		........(░(_.:._).░ (¯ `·.(█).·´¯)░)
//		              .....(░(_.·´/|\`·._)
//		                  ...(░░(_.:._)░)...

dirdata = getDirectory("Choisir le dossier contenant les stacks a analyser");   /// choix des dossier contenant les images a analyser
dir_result = dirdata+"Quantifications"+File.separator();
dir_roi = dirdata+"Segmented"+File.separator();
File.makeDirectory(dir_result);

// Select the good MT channel
Dialog.create("What is the MT channel?");
Dialog.addNumber("MT_channel:", 1);
Dialog.show();
MT_channel = Dialog.getNumber();

// Get only the .nd files
ImageNames=getFileList(dirdata); /// tableau contenant le nom des fichier contenus dans le dossier dirdata
ImageNb=0; /// longueur du tableau == nombre de fichier dans le dossier

// Set the number of individual MT we want for normalization in this condition
nb_cells = lengthOf(ImageNames);
nb_indivMT = nb_cells/3;


extension = ".nd";
ext_size = lengthOf(extension);
run("Set Measurements...", "area mean integrated redirect=None decimal=3");

ImageNames=getFileList(dirdata); /// tableau contenant le nom des fichier contenus dans le dossier dirdata
cell_nb = -1;

run("Close All");

if(isOpen("Results")) {
		selectWindow("Results");
		run("Close");
		}
		
if(isOpen("ROI Manager")) {
	roiManager("reset");
	}
	
// Initialize Result table
if (isOpen("MT_Quantif")==false) {
	Table.create("MT_Quantif");
}

// Change maximum number of series you have in your .nd/.lif files
nbSerieMax=50;
series="";
for(i=1;i<nbSerieMax;i=i+1) {
	series=series+"series_"+i+" ";
}

// Open all the files
for (i=0; i<lengthOf(ImageNames); i++) { /// boucle sur les images contenues dans dirdata

	// Open all images and Roi
	 if (endsWith(ImageNames[i], extension)) {
		name_size = lengthOf(ImageNames[i]) - ext_size;
		LifName=substring(ImageNames[i],0 ,name_size);
		run("Bio-Formats", "open=["+dirdata+ImageNames[i]+"] color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT use_virtual_stack "+series);
		Names = getList("image.titles");

		for(image=0;image<lengthOf(Names);image++) {
			Name = Names[image];
			Serie_nb = substring(Name,lengthOf(Name)-3,lengthOf(Name)-1);

			selectWindow(Name);
			
			wait(500); 
			getStatistics(area, mean, min, max);
			if (max == 0) {
			    close(); // This image is empty
			} 
			else {
			
			run("Duplicate...", "title=Total_Image duplicate");
			wait(500); 
			Stack.setPosition(3,15,1);
			Stack.setChannel(MT_channel);
			run("Enhance Contrast", "saturated=0.35");
	
			roiManager("Open", dir_roi+LifName+"_serie"+Serie_nb+"RoiSet.zip");
			n= roiManager("count");
			roiManager("reset");
			
			// Get each cell of the image from the ROI
			for (object = 0; object < n; object++) {
				cell_nb = cell_nb + 1;
				cell_ID = Serie_nb+"_cell"+object;
				
				// Create cell images deconv and raw
				roiManager("reset");
				roiManager("Open", dir_roi+LifName+"_serie"+Serie_nb+"RoiSet.zip"); 			
	  			selectWindow("Total_Image");
	  			
			    roiManager("select", object);
	  			run("Duplicate...", "title=total_cell duplicate");

				run("Select None");
				run("Duplicate...", "title=MT_original duplicate channels="+MT_channel);
				setSlice(15);
				
	  			makeRectangle(0, 0, 15, 15);
	  			run("Clear Results");
	  			run("Measure");
	  			mean_bg = getResult("Mean", 0);
	  			run("Clear Results");
	  			
	  			run("Select None");
	  			run("Subtract...", "value="+mean_bg+" stack");
	  			
			// Microtubule Mask (without projection)
					// Pre-cleaning
				run("Duplicate...", "duplicate");
				rename("MT_mask");
				run("Unsharp Mask...", "radius=2 mask=0.60 stack");
				run("Gaussian Blur...", "sigma=1 stack");
				run("Gamma...", "value=0.75 stack");
				
					// Thresholding (auto)
				setOption("BlackBackground", true);
				run("Convert to Mask", "method=Otsu background=Dark black stack");
				
			
					// Multiply Mask by original intensity
				imageCalculator("Multiply create 32-bit stack", "MT_original","MT_mask");
				run("Divide...", "value=255 stack");
				run("Z Project...", "projection=[Sum Slices]");
				run("Clear Results");
				run("Measure"); // Raw integrated density = sum of intensity of pixels in the defined MT network ~ MT quantity
				
			 // Add the image and cell ID in the result table
		  		selectWindow("MT_Quantif");
				Table.set("Image Name",cell_nb,LifName);
				Table.set("Cell_ID",cell_nb,cell_ID);
				Table.set("mean_bg",cell_nb,mean_bg);
				Table.set("Normalized intensity",cell_nb,getResult("IntDen",0));
				Table.set("Normalized intensity by px",cell_nb,getResult("RawIntDen",0));
				Table.update;
				
				close("MT_original");
				close("MT_mask");
				close("Result of MT_original");
				close("SUM_Result of MT_original");
				close("total_cell");
}}}}}


if (isOpen("MT_Quantif")==true) {
	selectWindow("MT_Quantif");
	saveAs("Results", dir_result+"Results_MTQuantif.csv");	
}																	
