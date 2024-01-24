// Macro by Elisa
// Open segmentation files (.tif and corresponding ROI) and calculate the polarization index AND/OR synaptic actin/tubulin repartition

//           \\\||||||////
//            \\  ~ ~  //
//             (  @ @  )
//    ______ oOOo-(_)-oOOo___________
//    .......
//    .......
//    .......
//    _____________Oooo._____________
//       .oooO     (   )
//        (   )     ) /
//         \ (     (_/
//          \_)

run("Close All");


dirdata = getDirectory("Choose the folder you would like to analyze");
//dirdata = getArgument()
dir_raw = dirdata+"Raw_Data"+File.separator();
dir_result = dirdata+"Quantifications"+File.separator();
dir_roi = dirdata+"Segmented"+File.separator();
File.makeDirectory(dir_result); 

// Extension of the files
extension = "Lng_LVCC";
ext_size = lengthOf(extension);

// Method used to determine the bottom and top plane of the cell: "auto" or "manual"
method="auto"

// Do you want to get centrosome polarization results
MTOC_pol = false

// Do you want to perform the Protein repartition analysis at the synapse?
//How many synaptic planes and circles do you want to use
Concentric_circle = true
syn_planes = 5;
circles_nb =5;

// Select the good channels
Dialog.create("Choose the corresponding channels");
Dialog.addNumber("Actin:", 3);
Dialog.addNumber("Tubulin:", 2);
Dialog.addNumber("MTOC", 1);
Dialog.show();
Actin_channel = Dialog.getNumber();
MT_channel = Dialog.getNumber();
MTOC_channel = Dialog.getNumber();
//Actin_channel = 3;
//MT_channel = 2;
//MTOC_channel = 1;

// Distance between each stack
voxel_depth = 0.21

// Get all files names in the folder
ImageNames=getFileList(dirdata); /// tableau contenant le nom des fichier contenus dans le dossier dirdata
cell_nb = -1;

// Initialize Results and ROI Manager
if(isOpen("Results")) {
		selectWindow("Results");
		run("Close");
		}
		
if(isOpen("ROI Manager")) {
	roiManager("reset");
	}


nbSerieMax=50;
series="";
for(i=1;i<nbSerieMax;i=i+1) {
	series=series+"series_"+i+" ";
}

// Open all the lif files
for (i=0; i<lengthOf(ImageNames); i++) { /// boucle sur les images contenues dans dirdata
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
				Stack.setPosition(3,20,1);
				Stack.setChannel(Actin_channel);
				run("Enhance Contrast", "saturated=0.35");
				selectWindow(Name_raw);
				close(Name_raw); // if we can analyse intensities on LVCC data
				
				roiManager("Open", dir_roi+LifName+"_serie"+Serie_nb+"RoiSet.zip");
				n= roiManager("count");
				roiManager("reset");
				// Get each cell of the image from the ROI
				for (object = 0; object < n; object++) {
					cell_nb = cell_nb + 1;
					cell_ID = Serie_nb+"_cell"+object;
					
					// Create cell images deconv and raw
				//	selectWindow(Name_raw);
					roiManager("Open", dir_roi+LifName+"_serie"+Serie_nb+"RoiSet.zip");
//				    roiManager("select", object);		   
//		  			run("Duplicate...", "title=raw_cell duplicate");
//		  			run("Clear Outside", "stack"); // Remove surrounding signal
//		  			run("Select None");
		  			
		  			selectWindow("Total_Image");
		  			
				    roiManager("select", object);
		  			run("Duplicate...", "title=deconv_cell duplicate");
		  			run("Clear Outside", "stack");
				
				
				// ---------------------- GET CELL MASK ----------------------------------------------------------------
			    // Get the Mask of the cell using the Actin (or NHS) channel on deconv image-------------------------------------------	
		
					selectWindow("deconv_cell");
					run("Select None");
					run("Duplicate...", "title=MaskCell duplicate channels="+Actin_channel);
					setSlice(20);
					run("Enhance Contrast", "saturated=0.35");
					
					run("Gaussian Blur...", "sigma=1 stack");
					run("Subtract Background...", "rolling=250 stack");
					setOption("BlackBackground", true);
			//		run("Threshold...");
			//		waitForUser("play with the threshold value");
					run("Convert to Mask", "method=Huang background=Dark black");
					run("Fill Holes", "stack");
					
					// Create the result table
					if (isOpen("Polarization Results")==false) {
					Table.create("Polarization Results");
					}
					 // Add the image and cell ID in the result table
			  		selectWindow("Polarization Results");
					Table.set("Image Name",cell_nb,LifName);
					Table.set("Cell_ID",cell_nb,cell_ID);
					Table.update;
					
					// -------- GET CELL SIZE AND SYNAPSE PLANE ----------------------------------------------------------------
					// Get the top and the bottom of the cell auto or manually -------------------------------------------	
			
					if (method=="manual") { // The user choose the planes by hand
						selectWindow("deconv_cell");
						run("Select None");
						waitForUser("Select the synaptic plane");
						Z0 = getSliceNumber();
						print(Z0);
						waitForUser("Select the upper plane");
						Z1 = getSliceNumber();
						print(Z1);
						CellSize = (Z1-Z0)*voxel_depth;
					}
			
					
					if (method=="auto") { // Find automatically the planes of apparition/disparition of the actin signal
						selectWindow("MaskCell");
						nbZ=nSlices();
						firstZ=false;
						lastZ=false;
						CentrosomeMaxPosition = 0;
						for(slice=1; slice<=nbZ; slice++) {
							selectWindow("MaskCell");
							setSlice(slice);
							getStatistics(area, mean, min, max, std, histogram);
						
							if(mean>0 && firstZ==false) {
								Z0=slice+2; //first slice with signal --> bottom of the cell 5 slice above
								firstZ=true;
							}
							
							if(mean==0 && firstZ==true) {
								Z1=slice-1;
								slice=nbZ;
								lastZ=true;
							}}
						
							if(lastZ==false) {
								Z1=nbZ;
								lastZ=true;
							}
						CellSize = (Z1-Z0)*voxel_depth;
					}
				
						
					// -------------- CENTROSOME POLARIZATION ANALYSIS ----------------------------------------------------------------
					// Find centrosome center of mass through 3D object finder and calculate polarization index and centering------------------------
					if (MTOC_pol == true) {
						
						selectWindow("deconv_cell");
						run("Select None");
						run("Duplicate...", "title=MaskCentrosome duplicate channels="+MTOC_channel);
						run("Gaussian Blur...", "sigma=1 stack");
						run("Subtract Background...", "rolling=250 stack");
				
						
						// Get the center of mass of the centrosome automatically
						setSlice(15);
						getStatistics(area, mean, min, max, std, histogram);
						if (max < 18000) {
							threshold = max-200;
						}
				  		else {
				  			threshold = 18000;
				  		}
						run("3D Objects Counter", "threshold=" + threshold +" slice=10 min.=200 max.=2093364 exclude_objects_on_edges statistics summary");
						Table.rename("Statistics for MaskCentrosome", "Results");
						
						// If the program cannot find the centrosome automatically: adjust the threshold by hand until it works
						if (getValue("results.count")==0 || getValue("results.count")>1) { 
						// Correct the threshold
//							run("3D Objects Counter");
//							waitForUser("play with the threshold value for centrosome identification");
//							Table.rename("Statistics for MaskCentrosome", "Results");
							
						// Choose the centrosome by hand
							selectWindow("MaskCentrosome");
							setTool("point");
							waitForUser("point the centrosome by hand");
							run("Set Measurements...", "area mean min center integrated redirect=None decimal=3");
							run("Measure");
							
							centrosome_plane = getSliceNumber(); //Z coordinate of the center of mass of the centrosome IN PIXEL SIZE
							centrosome_x = getResult("XM",0); //X coordinate of the center of mass of the centrosome IN PIXEL SIZE
							centrosome_y = getResult("YM",0); //Y coordinate of the center of mass of the centrosome IN PIXEL SIZE
							run("Clear Results");
							run("Select None");
						
						}
						else {
							centrosome_plane = getResult("ZM",0); //Z coordinate of the center of mass of the centrosome IN PIXEL SIZE
							centrosome_x = getResult("XM",0); //X coordinate of the center of mass of the centrosome IN PIXEL SIZE
							centrosome_y = getResult("YM",0); //Y coordinate of the center of mass of the centrosome IN PIXEL SIZE
							run("Clear Results");
						}
						CentrosomeToSynapse= (centrosome_plane-Z0)*voxel_depth;
			
						// Get the centrosome distance to the cortex center (at the centrosome_plane)
						selectWindow("MaskCell");
						run("Duplicate...", "ignore duplicate range="+centrosome_plane+"-"+centrosome_plane+" use");
						roiManager("reset");
						run("Analyze Particles...", "size=2-Infinity show=Overlay include overlay add");
						run("Set Measurements...", "area mean centroid redirect=None decimal=3");
						
						if (roiManager("count")!=0) { 
							roiManager("select", 0);
							run("Measure");
						
							getPixelSize(unit, pixelWidth, pixelHeight);
							// Conversion of these points in pixel size
							x_cortex = getResult("X", 0)/pixelWidth;
							y_cortex = getResult("Y", 0)/pixelHeight;
							
							run("Clear Results");
							roiManager("reset");
							
							// Create a distance Map according to the cortex center:
							run("Select All");
							run("Clear", "slice");
							makePoint(x_cortex, y_cortex, "small yellow hybrid");
							run("Draw");
							run("Analyze Particles...", "size=0-Infinity show=Overlay include overlay add");
							run("Convert to Mask");
							run("Invert");
							roiManager("select", 0);
							run("Distance Map");
							rename("Distance-to-the-center");
							roiManager("reset");
							
							// Centrosome distance to the center = intensity of the point in the distance map
							makePoint(centrosome_x, centrosome_y, "small yellow hybrid");
							run("Measure");
							centrosome_distance = getResult("Mean", 0)*pixelWidth;
						}
						else {
							centrosome_distance = "NA";
						}
						
						// Fill the result table
			  			selectWindow("Polarization Results");
						Table.set("CentrosomeToSynapse",cell_nb,CentrosomeToSynapse);
						Table.set("Cell_Size",cell_nb,CellSize);
						Table.set("Polarization_index",cell_nb,CentrosomeToSynapse/CellSize);	
						Table.set("CentrosomeToCenter",cell_nb,centrosome_distance);
						Table.update;
						
						close("MaskCentrosome");
						close("Distance-to-the-center");
					}	
						
					// -------------- CONCENTRIC CIRCLES ANALYSIS AT THE SYNAPSE ----------------------------------------------------------------
					// Z-Project the selected synapse planes or full cell and ------------------------
					if (Concentric_circle == true) {
						
						if (isOpen("Prot Repartition")==false) {
						Table.create("Prot Repartition");
					}
						selectWindow("Prot Repartition");
						Table.set("Image Name",cell_nb,LifName);
						Table.set("Cell_ID",cell_nb,cell_ID);
						Table.update;
						
						
					// if we want a projection on the whole cell
						roiManager("Open", dir_roi+LifName+"_serie"+Serie_nb+"RoiSet.zip");
						selectWindow("Total_Image");
					    roiManager("select", object);
		  				run("Duplicate...", "title=deconv_cell2 duplicate");
		  				roiManager("reset");
		  				roiManager("Add");
						
						stop_plane = Z0 + syn_planes;
	
					// if we want a few planes above the first detected plane 
//						run("Z Project...", "start="+Z0+" stop="+stop_plane+" projection=[Max Intensity]"); 
//						run("Set Measurements...", "area mean shape redirect=None decimal=3");
//						run("Fill Holes");
//						rename("Synapse");
//						run("Analyze Particles...", "size=10-Infinity show=Overlay clear overlay add");
//						if (roiManager("count")==0) { // Select by hand ? projetc all cell?
//							run("Analyze Particles...", "size=0-Infinity show=Overlay clear overlay add");
//						}
						run("Clear Results");
						roiManager("Measure");
						
						// Get Synapse Size-Roundness
						SynapseArea=getResult("Area", 0);
						SynapseAspect = getResult("AR", 0);
						
						// Main result window update
						selectWindow("Polarization Results");
						Table.set("Synapse_Area",cell_nb,SynapseArea);
						Table.set("Synapse_AR",cell_nb,SynapseAspect);
						Table.update;
				
						// Draw concentric circles
						for (circle = 1; circle < circles_nb; circle++){
							roiManager("Select", 0);
							scale = 1-(circle*0.2);
							run("Scale... ", "x="+scale+" y="+scale+" centered");
							roiManager("Add");
						}
						
						// Superpose the few synapse plan
						selectWindow("deconv_cell"); // if LVCC is linear we can use the LVCC files
						//	selectWindow("raw_cell");
						run("Z Project...", "start="+Z0+" stop="+stop_plane+" projection=[Sum Slices]"); // if we want a few planes above the first detected plane 
						rename("Synapse_proj");
						
						// Measure RawIntDen and Area in each zone on raw image
						run("Set Measurements...", "area mean min integrated redirect=None decimal=3");
						for (circle = 1; circle < circles_nb; circle++){
							roiManager("Select", newArray(circle-1,circle));
							roiManager("XOR");
							
							run("Clear Results");
						
							selectWindow("Synapse_proj");
							Stack.setChannel(Actin_channel);
							run("Measure");
							zone_area = getResult("Area", 0);
							Actin_value = getResult("RawIntDen", 0);
							
							run("Clear Results");
							selectWindow("Synapse_proj"); 
							Stack.setChannel(MT_channel);
							run("Measure");
							Tub_value = getResult("RawIntDen", 0);
							
							// Repartition result window update
							selectWindow("Prot Repartition");
							Table.set("Image Name",cell_nb,LifName);
							Table.set("Cell_ID",cell_nb,cell_ID);
							Table.set("Zone"+circle+"_area",cell_nb,zone_area);
							Table.set("Actin_zone"+circle+"_value",cell_nb,Actin_value);
							Table.set("Tub_zone"+circle+"_value",cell_nb,Tub_value);
							Table.update;
		
					}
					close("Synapse");
					close("Synapse_proj");
					}
					roiManager("reset");
					close("deconv_cell");
				//	close("raw_cell");
					close("MaskCell");
					
					
			}
			close(Name);
			close("Total_Image");
			//	close(Name_raw);
			}}
			}}


if (isOpen("Polarization Results")==true) {
	selectWindow("Polarization Results");
	saveAs("Results",dir_result+"Results_Polarization.csv");
			}


if (isOpen("Prot Repartition")==true) {
	selectWindow("Prot Repartition");
	saveAs("Results", dir_result+"Results_ProtRepartition.csv");	
}																	
