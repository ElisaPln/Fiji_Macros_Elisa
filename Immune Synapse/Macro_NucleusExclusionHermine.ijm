// Fiji Macro by Elisa
//	   	♡  ∩__∩ 
//		  („•֊•„)♡ 
//		|￣U   U￣￣￣￣￣￣￣￣￣                            ￣|
//		|     Macro to isolate cells from BrightField         |
//		|	  or Phallo staining and compare fluorescence    |
//		|	  in the nucleus VS in the whole cell!           |   
//		￣￣￣￣￣￣￣￣￣￣￣￣


// PARAMETERS TO CHANGE BEFORE LAUNCHING
extension = ".lif"; // extension of your analysis file
method = "BF"; // choose between "BF" or "Actin" = channel used to identify your cells
nb_plane = 2; // nb of stzck you want to measure --> Ex: "2" means 2 before and 2 after middle plane
Actin_channel = 4; // Channels repartition of your experiment
DAPI_channel = 1;
BF_channel = 2;
CCR2_channel = 3;
// Please put your files in separate folder per condition to avoid analysing everything at the same time

// MACRO__________________________________________________________________________________________________________________________
run("Close All")
dirdata = getDirectory("Choose the folder you would like to analyze");
dir_roi=dirdata+"Segmentation"+File.separator();
File.makeDirectory(dir_roi);

ext_size = lengthOf(extension);

// File list
ImageNames=getFileList(dirdata); // table with each names of the files in dirdata
nbimages=lengthOf(ImageNames); /// length of the table = nb of files in the folder
cell_nb = -1;
nbSerieMax=50; // max nb of position in your images. Increase if necessary
series="";
for(i=1;i<nbSerieMax;i=i+1) {
	series=series+"series_"+i+" ";
}

// Initialize Result table
if (isOpen("CCR2_Measure")==false) {
	Table.create("CCR2_Measure");
}
							
// Open all the lif files
for (i=0; i<lengthOf(ImageNames); i++) { //loop on all files from dirdata

	// Select only the .lif files
	 if (endsWith(ImageNames[i], extension)) {
		name_size = lengthOf(ImageNames[i]) - ext_size;
		LifName=substring(ImageNames[i],0 ,name_size);
		run("Bio-Formats", "open=["+dirdata+ImageNames[i]+"] color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT use_virtual_stack "+series);
		Names = getList("image.titles"); // table with the names of all images in yout .lif

		for(image=0;image<lengthOf(Names);image++) { // loop on all opened images
			Name = Names[image];
		//	print(Name);
			selectWindow(Name);
			Serie_nb = substring(Name,lengthOf(Name)-3,lengthOf(Name));
		//	print(Serie_nb);
		// Adjust colors and channels
			Stack.setPosition(3,10,1);
			Stack.setChannel(1);
			run("Enhance Contrast", "saturated=0.35");
			// run("Red"): // if you want to set specofoc colors to your channels

			Stack.setChannel(2);
			run("Enhance Contrast", "saturated=0.35");

			Stack.setChannel(3);
			run("Enhance Contrast", "saturated=0.35");

			Stack.setChannel(4);
			run("Enhance Contrast", "saturated=0.35");


			if(isOpen("ROI Manager")) {
				roiManager("reset");}

			Stack.setPosition(BF_channel,10,1);
			run("Duplicate...", "title=bf duplicate channels="+BF_channel);
			
			// Let the user choose the middle plane for the analysis
			waitForUser("Choose the middle plane");
			middle_plane = getSliceNumber();
			close("bf");
			
// I- AUTOMATIC SEGMENTATION OF CELLS --------------------------------------------------------------------------------------------------------
			// segmentation on BF channel
			if (method == "BF") {
				run("Duplicate...", "title=mask_bf duplicate channels="+BF_channel+" slices="+middle_plane-3);
				run("Gaussian Blur...", "sigma=3");
				setAutoThreshold("Yen dark no-reset");
				run("Convert to Mask");
				
				// CAREFULL, sometimes mask is inverted for BF. Here is a verification
				run("Clear Results");
				run("Select None");
				run("Measure");
				run("Create Selection");
				run("Measure");
				run("Select None");
				white_area = getResult("Area", 1);
				black_area = getResult("Area", 0)-white_area;
				if(white_area>black_area){
					run("Invert");
				}
				
				run("Fill Holes");
				//run("Watershed");

				// Get particles excluding the edge
				run("Analyze Particles...", "size=5-Infinity exclude overlay add");
				
				// If no cells detected --> threshold by hand or trash image
				if (roiManager("count")==0) {
					Dialog.create("No cells detected");
					Dialog.addCheckbox("Manual threshold", false);
					Dialog.addCheckbox("Delete image", true);
					Dialog.show();
					Manual = Dialog.getCheckbox();
					Discard=  Dialog.getCheckbox();
					
					if(Manual == true){	
						close("mask-bf");
						selectWindow(Name);
						run("Duplicate...", "title=mask_bf duplicate channels="+BF_channel+" range="+   +"-1 use");
						run("Gaussian Blur...", "sigma=3");
						run("Threshold...");
						waitForUser("Set the threshold yourself and press Apply");
						run("Fill Holes");
						run("Watershed");
					}
					
					if(Discard == true){
						close("mask-bf");
						close(Name);
				}}
				
				selectWindow(Name);
				roiManager("Show All");
				
				// Selection of good cells and removal of artefacts by hand
				waitForUser("Remove unwanted particles in the ROI manager");
				// Save ROI.zip in specific folder
				roiManager("Save", dir_roi + LifName+"_serie"+Serie_nb+"RoiSet.zip");
				
				close("mask_bf");
			}
			
			// Segmentation using phalloidin staining and Zproj
			if (method == "Actin") {
				run("Duplicate...", "title=duplic duplicate channels="+Actin_channel);
				run("Z Project...", "projection=[Max Intensity]");
				rename("mask_actin");
				run("Gaussian Blur...", "sigma=2");
				setAutoThreshold("Huang dark no-reset");
				run("Convert to Mask");
				run("Fill Holes");
				run("Watershed");
				
				run("Analyze Particles...", "size=5-Infinity exclude overlay add");
				
				// You can add here the same firewall as BF method for when ROI is empty = no cells are found
				
				selectWindow(Name);
				roiManager("Show All");
				waitForUser("Remove unwanted particles in the ROI manager");
				roiManager("Save", dir_roi + LifName+"_serie"+Serie_nb+"RoiSet.zip");
				
				close("mask_Actin");
			}
			
// II- FLUORESCENCE MEASUREMENT IN CHOSEN STACKS --------------------------------------------------------------------------------------------------------
			n= roiManager("count"); // number of cells selected
			roiManager("reset");
			if (n>0) { // Continue analysis only if cells are detected

				for (object = 0; object < n; object++) { // loop on all cells of the image
					cell_nb = cell_nb +1;
					cell_ID = "pos"+Serie_nb+"_cell"+object;
					selectWindow(Name);
			  		
			  		// Reopen ROI.zip each time to avoid errors
			  		roiManager("reset");
			  		roiManager("Open", dir_roi+LifName+"_serie"+Serie_nb+"RoiSet.zip");
					roiManager("select", object);
			  		run("Duplicate...", "title=cell duplicate"); // Zoom on the cell
			  		run("In [+]");
			  		run("In [+]");
			  		run("Clear Outside", "stack");
			  		roiManager("reset");
			  		roiManager("add");
			  			
			  		// Distance between each stack --> if we want to work in volume
					getVoxelSize(width, height, depth, unit);
					voxel_depth = depth;
					
					// Select working stacks
					selectWindow("cell");
					run("Select None");
					low_plane = middle_plane - nb_plane ;
					upper_plane = middle_plane + nb_plane ;
					
					// Initialize values:
					zone_area =0;
					CCR2_value_tot=0;
					dapi_area=0;
					CCR2_value_nucleus=0;
					Cyto_area=0;
					CCR2_value_cyto=0;
					
					// Measure fluorescence in each stack selected
					for (plane = low_plane; plane < upper_plane+1; plane++) {
						// 1) Fluorescence in the whole cell
						Stack.setPosition(CCR2_channel, plane, 1);
						roiManager("select", 0);
						run("Clear Results");
						run("Measure");
						zone_area = zone_area + getResult("Area", 0); // *voxel_depth if we want to work in volume
						CCR2_value_tot = CCR2_value_tot + getResult("RawIntDen", 0);

						// 2) Fluorescence in the nucleus
						run("Select None");
						run("Duplicate...", "title=mask_dapi duplicate channels="+DAPI_channel+" slices="+plane+"-"+plane);
						run("Gaussian Blur...", "sigma=2 stack");
						setAutoThreshold("Default dark no-reset");
						setOption("BlackBackground", true);
						run("Convert to Mask");
						run("Fill Holes", "stack");
					
						run("Analyze Particles...", "size=0-Infinity overlay add");
						close("mask_dapi");
						
						// if no DAPI found
						if (roiManager("count")<=1) {
							print(LifName + cell_ID+" = Not DAPI found");
							waitForUser;

							dapi_area = 0;
							CCR2_value_nucleus = 0;
							Cyto_area = 0;
							CCR2_value_cyto = 0;
						}
						
						else{
						selectWindow("cell");
						Stack.setPosition(CCR2_channel, plane, 1);
						roiManager("Select", 1); // last object added is the DAPI particle
						run("Clear Results");
						run("Measure");
						dapi_area = dapi_area + getResult("Area", 0);
						CCR2_value_nucleus = CCR2_value_nucleus + getResult("RawIntDen", 0);
						
						// 3) Fluorescence in the cytoplasm area
						roiManager("Select", newArray(0,1));
						roiManager("XOR");	
						run("Clear Results");
						run("Measure");
						Cyto_area = Cyto_area + getResult("Area", 0);
						CCR2_value_cyto = CCR2_value_cyto + getResult("RawIntDen", 0);
						}}
					close("cell"); // we are done with this cell
					
					// Save results:
					selectWindow("CCR2_Measure");
					Table.set("Image Name",cell_nb,LifName);
					Table.set("Cell_ID",cell_nb,cell_ID);
					Table.set("middle_plane",cell_nb,middle_plane);
					Table.set("nb_plane",cell_nb,nb_plane);
					Table.set("cell_area",cell_nb,zone_area);
					Table.set("dapi_area",cell_nb,dapi_area);
					Table.set("Cyto_area",cell_nb,Cyto_area);
					Table.set("CCR2_value_tot",cell_nb,CCR2_value_tot);
					Table.set("CCR2_value_nucleus",cell_nb,CCR2_value_nucleus);
					Table.set("CCR2_value_cyto",cell_nb,CCR2_value_cyto);
					Table.update;
				}}
				close(Name);
				}}}

// III - SAVE RESULTS ---------------------------------------------------------------------------
if (isOpen("CCR2_Measure")==true) {
	selectWindow("CCR2_Measure");
	saveAs("Results",dirdata+"CCR2_Measure.csv");
			}
