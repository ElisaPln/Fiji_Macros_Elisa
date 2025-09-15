// Fiji Macro by Elisa
// Macro to isolate synapses on coverslips and save the associated ROI
//        .       .
//                             / `.   .' "
//                     .---.  <    > <    >  .---.
//                     |    \  \ - ~ ~ - /  /    |
//         _____          ..-~             ~-..-~
//        |     |   \~~~\.'                    `./~~~/
//       ---------   \__/                        \__/
//      .'  O    \     /               /       \  "
//     (_____,    `._.'               |         }  \/~~~/
//      `----.          /       }     |        /    \__/
//            `-.      |       /      |       /      `. ,~~|
//                ~-.__|      /_ - ~ ^|      /- _      `..-'   
//                     |     /        |     /     ~-.     `-. _  _  _
//                     |_____|        |_____|         ~ - . _ _ _ _ _>
//

run("Close All")
//dirdata = getArgument();
dirdata = getDirectory("Choose the folder you would like to analyze");
dir=dirdata+"Segmented"+File.separator();
File.makeDirectory(dir);


extension = ".nd";
ext_size = lengthOf(extension);

method = "watershed"; // choose between "watershed or "nucleus segmentation"
run("Set Measurements...", "area mean center shape redirect=None decimal=3");
				
Actin_channel = 3;
DAPI_channel = 4;
cell_nb = -1;

// File list
ImageNames=getFileList(dirdata); /// tableau contenant le nom des fichier contenus dans le dossier dirdata
nbimages=lengthOf(ImageNames); /// longueur du tableau == nombre de fichier dans le dossier

// Initialize Result table
if (isOpen("Synapse_Measure")==false) {
	Table.create("Synapse_Measure");
}

nbSerieMax=50;
series="";
for(i=1;i<nbSerieMax;i=i+1) {
	series=series+"series_"+i+" ";
}



// Open all the lif files
for (i=0; i<lengthOf(ImageNames); i++) { /// boucle sur les images contenues dans dirdata

	// Select only the MT images
	 if (endsWith(ImageNames[i], extension)) {
		name_size = lengthOf(ImageNames[i]) - ext_size;
		LifName=substring(ImageNames[i],0 ,name_size);
		run("Bio-Formats", "open=["+dirdata+ImageNames[i]+"] color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT use_virtual_stack "+series);
		wait(500); 
		Names = getList("image.titles");

		for(image=0;image<lengthOf(Names);image++) {
			Name = Names[image];
			selectWindow(Name);
			
			Serie_nb = substring(Name,lengthOf(Name)-3,lengthOf(Name)-1);
			
			// Remove empty files
			getStatistics(area, mean, min, max);
			if (max == 0) {
			    close(); // This image is empty
			} 
			else {
			    // Process your image if not empty
			
		// Adjust colors and channels
			Stack.setPosition(3,13,1);
			Stack.setChannel(1);
			run("Enhance Contrast", "saturated=0.35");
			Stack.setChannel(2);
			run("Enhance Contrast", "saturated=0.35");
			Stack.setChannel(3);
			run("Enhance Contrast", "saturated=0.35");
			Stack.setChannel(4);
			run("Enhance Contrast", "saturated=0.35");

			if(isOpen("ROI Manager")) {
				roiManager("reset");}
			run("Clear Results");
			Stack.setPosition(3,13,1);
	
			// segmentation on actin zproj and watershed
			if (method == "watershed") {
				run("Duplicate...", "title=duplic duplicate channels="+Actin_channel);
				run("Z Project...", "projection=[Max Intensity]");
				rename("Mask_Actin");
				run("Gaussian Blur...", "sigma=1");
				run("Enhance Contrast", "saturated=0.35");
				setAutoThreshold("Huang dark no-reset"); // Change threshold method according to image quality
				run("Convert to Mask");
				run("Fill Holes");
				run("Watershed");

				// Get particles excluding the edge
				run("Analyze Particles...", "size=20-Infinity exclude overlay add");
				
				if (roiManager("count")==0) {
					run("Analyze Particles...", "size=10-Infinity overlay add");
				}
				
				roiManager("Select All");
				roiManager("Measure");

				
				close("Mask_Actin");
				close("duplic");
			}

			selectWindow(Name);
			roiManager("Show All");
			roiManager("Save", dir + LifName+"_serie"+Serie_nb+"RoiSet.zip");
			
// ----------------------------SAVE SYNAPSE AREA -------------------------------------			
			n= roiManager("count"); // number of cells selected
			roiManager("reset");
			if (n>0) { // Continue analysis only if cells are detected

				for (object = 0; object < n; object++) { // loop on all cells of the image
					cell_nb = cell_nb +1;
					cell_ID = "pos"+Serie_nb+"_cell"+object;
					selectWindow(Name);
			  	
					// Save results:
					selectWindow("Synapse_Measure");
					Table.set("Image Name",cell_nb,LifName);
					Table.set("Cell_ID",cell_nb,cell_ID);
					Table.set("Area",cell_nb,getResult("Area", object));
					Table.set("Mean intensity",cell_nb,getResult("Mean", object));
					Table.set("AR",cell_nb,getResult("AR", object));
					Table.set("Solidity",cell_nb,getResult("Solidity", object));
					Table.update;
				}}
				close(Name);
				}}}}

// III - SAVE RESULTS ---------------------------------------------------------------------------
if (isOpen("Synapse_Measure")==true) {
	selectWindow("Synapse_Measure");
	saveAs("Results",dirdata+"Synapse_Measure.csv");
			}	
