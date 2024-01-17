// Macro by Elisa
// Open all images from a lif file and close all non-deconvoluted files. 


//		───────────────────────────────────────
//		───▐▀▄───────▄▀▌───▄▄▄▄▄▄▄─────────────
//		───▌▒▒▀▄▄▄▄▄▀▒▒▐▄▀▀▒██▒██▒▀▀▄──────────
//		──▐▒▒▒▒▀▒▀▒▀▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▀▄────────
//		──▌▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▄▒▒▒▒▒▒▒▒▒▒▒▒▒▒▀▄──────
//		▀█▒▒▒█▌▒▒█▒▒▐█▒▒▒▀▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▌─────
//		▀▌▒▒▒▒▒▒▀▒▀▒▒▒▒▒▒▀▀▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▐───▄▄
//		▐▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▌▄█▒█
//		▐▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒█▒█▀─
//		▐▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒█▀───
//		▐▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▌────
//		─▌▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▐─────
//		─▐▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▌─────
//		──▌▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▐──────
//		──▐▄▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▄▌──────
//		────▀▄▄▀▀▀▀▀▄▄▀▀▀▀▀▀▀▄▄▀▀▀▀▀▄▄▀────────


// TO CHANGE ACCORDING TO YOUR DATA
extension = ".lif";  // enter the extension of your file
deconv_extension = "_Lng_LVCC"; // enter the extensions that are added in the name of your deconvoluted image
deconv_extension2 = "_Lng_SVCC";

// CODE
run("Close All"); // close all previously opened files

FilePath = File.openDialog("Chose the lif files to analyze"); // Ask the user the direction of the .lif files
ext_size = lengthOf(extension);
deconv_ext_size = lengthOf(deconv_extension);

// Create a list ["serie1","serie2",..."serie100"] to be able to open 100 series in a .lif file
nbSerieMax=100; // max number of series in a lif file. Increase if more series in your file
series="";
for(i=1;i<nbSerieMax;i=i+1) {
	series=series+"series_"+i+" ";
}

// Opening of your file if it is the right format
if (endsWith(FilePath, extension)) {
		
	name_size = lengthOf(FilePath) - ext_size;
	LifName=substring(FilePath,0 ,name_size); // Get the name of the file without the extension
	
	// Open the 100 first series of the .lif
	run("Bio-Formats", "open=["+FilePath+"] color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT use_virtual_stack "+series);
	
	NamesList = getList("image.titles"); //Get the names of all images opened

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
	}




// To create a new macro that work on all the remaining opened image you can complete this loop					
//		for(image=0;image<lengthOf(NamesList2);image++) {		
//			Name = NamesList2[image];
//			selectWindow(Name);
//			...
//			}
	

			
			
		
			