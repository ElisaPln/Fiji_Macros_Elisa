// Macro by Elisa
// Isolate Mother/Daughter centrioles and save them in different folders
// Adapted for images names taken at the confocal

//			───▄▀▀▀▄▄▄▄▄▄▄▀▀▀▄───
//			───█▒▒░░░░░░░░░▒▒█───
//			────█░░█░░░░░█░░█────
//			─▄▄──█░░░▀█▀░░░█──▄▄─
//			█░░█─▀▄░░░░░░░▄▀─█░░█

extension = ".lif";  // enter the extension of your file
deconv_extension = "_Lng_LVCC"; // enter the extensions that are added in the name of your deconvoluted image
deconv_extension2 = "_Lng_SVCC";


deconv_ext_size = lengthOf(deconv_extension);


run("Close All");

// Get the direction of the .lif files
dirdata = getDir("Chose the folder containing the lif files to analyze");   /// choix des dossier contenant les images a analyser

// Make new folders to save the data
dirMother=dirdata+"Mother"+File.separator();
File.makeDirectory(dirMother); 
dirMother_resized=dirMother+"Mother_resized"+File.separator();
File.makeDirectory(dirMother_resized); 
dirDaughter=dirdata+"Daughter"+File.separator();
File.makeDirectory(dirDaughter); 
dirDaughter_resized=dirDaughter+"Daughter_resized"+File.separator();
File.makeDirectory(dirDaughter_resized); 


ext_size = lengthOf(extension);

// Get .lif File list --> we will treat all .lif in the file at once
FilesNames=getFileList(dirdata); /// Array containing the names of all files in dirdata
nbfiles=lengthOf(FilesNames); /// lenght of the array = nb of files

// Get a list to be able to open 100 series in a .lif file
nbSerieMax=100; // max number of series in a lif file. Increase if more
series="";
for(i=1;i<nbSerieMax;i=i+1) {
	series=series+"series_"+i+" ";
}

// Start the loop on all .lif files

for (i=0; i<lengthOf(FilesNames); i++) { /// boucle sur les images contenues dans dirdata
	
	if (endsWith(FilesNames[i], ".lif")) {
		name_size = lengthOf(FilesNames[i]) - 4;
		LifName=substring(FilesNames[i],0 ,name_size);
		run("Bio-Formats", "open=["+dirdata+FilesNames[i]+"] color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT use_virtual_stack "+series);
		NamesList = getList("image.titles");

	// Browse all open images (to close the unwanted one)
	for(image=0;image<lengthOf(NamesList);image++) {
		Name = NamesList[image];
		//print(Name);
		
		// Add condition in the if under the format "||endsWith(Name,deconv_extension3)" if more than 2 extension possible
		if(endsWith(Name,deconv_extension)||endsWith(Name,deconv_extension2)) {
			selectWindow(Name);
			
			Sub_Name = substring(Name,0,lengthOf(Name)-deconv_ext_size); //Get the name without the extension
			
			if(isOpen(Sub_Name)) { // If the image without the extension exist = if the non deconvoluted image exist
				selectWindow(Sub_Name);
				run("Close"); // close the non deconvoluted image
			}
			
			
			// uncomment if you want to rename the images without extensions
//			selectWindow(Name);
//			rename(Sub_Name); 
			}}
			
		NamesList2 = getList("image.titles"); // new list of names of retained images
		Array.show(NamesList2); // To check that only the wanted files are opened
	

				
// For all images:			
		for(image=0;image<lengthOf(NamesList2);image++) {		
			Name = NamesList2[image];
			selectWindow(Name);
			Serie_nb = substring(Name,lengthOf(Name)-12,lengthOf(Name)-9);
			
			Stack.setDisplayMode("composite");
			run("In [+]");
			run("In [+]");
			
			waitForUser("Count the number of centrioles you will analyze");
			centriole_nb = getNumber("How many centrioles will you analyse on this image ?", 3);
		
			mother_nb = 0;
			daughter_nb = 0;
			
			for(j=0 ;j<centriole_nb; j++) {
				
				// save the ROI in an empty manager
				if(isOpen("ROI Manager")) {
				roiManager("reset");}
				
				// Select the centriole you want at the right plane
				selectWindow(Name);
				setTool("rectangle");
				waitForUser("select a centriole at the wanted plane");
				roiManager("add");
				slice = round(getSliceNumber()/2); // have to divide by two for two channels
			//	print(slice);
				run("Duplicate...", "duplicate slices="+slice);
				rename("centriole"); // new window with the wanted centriole
				
				// Choose the mother / Daughter category
				Dialog.create("Centriole Origin");
				Dialog.addCheckbox("Mother", false);
				Dialog.addCheckbox("Daughter", false);
				Dialog.show();
				mother=  Dialog.getCheckbox();
				daughter=  Dialog.getCheckbox();
				
				if(mother==true) {
					mother_nb = mother_nb+1;
					selectWindow("centriole");
					saveAs("Tiff", dirMother + "MotherCentriole_serie" + Serie_nb +"_centriole"+ mother_nb +".tif");
					
					// Crop and resize part (modified to remove the crop part)
					getDimensions(width, height, channels, slices, frames);
	   				run("Canvas Size...", "width=" + width*6 +" height=" + width*6 +" position=Center zero");
	    			run("Scale...", "x=6 y=6 z=1.0 interpolation=Bilinear average" );
	    			run("Set Scale...", "known=" + 1/6 +" pixel=1");
	    			// Save in the wanted file as .tif
	    			save(dirMother_resized+"resized_MotherCentriole_serie" + Serie_nb +"_centriole"+ mother_nb + ".tif");
					
					run("Close");
				}
				
				if(daughter==true) {
					daughter_nb = daughter_nb+1;
					selectWindow("centriole");
					saveAs("Tiff", dirDaughter + "DaughterCentriole_serie" + Serie_nb +"_centriole"+ daughter_nb +".tif");
					
					// Crop and resize part (modified to remove the crop part)
					getDimensions(width, height, channels, slices, frames);
	   				run("Canvas Size...", "width=" + width*6 +" height=" + width*6 +" position=Center zero");
	    			run("Scale...", "x=6 y=6 z=1.0 interpolation=Bilinear average" );
	    			run("Set Scale...", "known=" + 1/6 +" pixel=1");
	    			// Save in the wanted file as .tif
	    			save(dirDaughter_resized+"resized_DaughterCentriole_serie" + Serie_nb +"_centriole"+ daughter_nb + ".tif");
					
					run("Close");
				}
				
				
				}
				selectWindow(Name);
				run("Close");
		}}}
	

			
			
		
			
