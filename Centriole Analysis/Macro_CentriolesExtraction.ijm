// Macro by Elisa
// Isolate Mother/Daughter centrioles and save them in different folders
// Adapted for images names taken at the confocal

//			───▄▀▀▀▄▄▄▄▄▄▄▀▀▀▄───
//			───█▒▒░░░░░░░░░▒▒█───
//			────█░░█░░░░░█░░█────
//			─▄▄──█░░░▀█▀░░░█──▄▄─
//			█░░█─▀▄░░░░░░░▄▀─█░░█



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



extension = ".lif";
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
	
// Open images in .lif files
	 if (endsWith(FilesNames[i], extension)) {
		
		name_size = lengthOf(FilesNames[i]) - ext_size;
		LifName=substring(FilesNames[i],0 ,name_size);
		run("Bio-Formats", "open=["+dirdata+FilesNames[i]+"] color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT use_virtual_stack "+series);
		NamesList = getList("image.titles");

// Get only the wanted images: Lng or Lng_001 images when they exist
		for(image=0;image<lengthOf(NamesList);image++) {
			Name = NamesList[image];
			//print(Name);
			
			if(endsWith(Name,"Series001")) {
				selectWindow(Name);
				run("Close");
			}
			else {

				if(endsWith(Name,"Lng_001")) {
				Sub_Name = substring(Name,0,lengthOf(Name)-4);
				
				if(isOpen(Sub_Name)) {
					selectWindow(Sub_Name);
					run("Close");
				}
				selectWindow(Name);
				rename(Sub_Name); // rename to get all the files with the same name pattern
				
				}}
				
			NamesList2 = getList("image.titles"); // new list of names of retained files
		//	Array.show(NamesList2);
		}
				
// For all images:			
		for(image=0;image<lengthOf(NamesList2);image++) {		
			Name = NamesList2[image];
			selectWindow(Name);
			Serie_nb = substring(Name,lengthOf(Name)-17,lengthOf(Name)-14);
			
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
	

			
			
		
			
