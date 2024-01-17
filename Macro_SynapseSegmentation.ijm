// Fiji Macro by Elisa
// Macro to isolate synapses on aCD3/CD28 coverslips and save the associated ROI and Files
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

run("Close All")

dirdata = getDirectory("Choose the folder you would like to analyze");
dir=dirdata+"Segmented"+File.separator();
File.makeDirectory(dir);

// Do we keep the non deconvolved for intensity measurement?
Dialog.create("Do you want to extract the non deconvolved files too?");
Dialog.addCheckbox("Keep raw data", true);
Dialog.show();
raw_data = Dialog.getCheckbox();

if (raw_data == true) {
	dir_raw=dir+"Raw_Data"+File.separator();
	File.makeDirectory(dir_raw);
}


extension = ".lif";
ext_size = lengthOf(extension);

method = "watershed"; // choose between "watershed or "nucleus segmentation"

// What colors in the staining?
// Dialog Box to choose the colors
//channel_color = newArray("Red", "Green", "Blue", "Magenta","Cyan","Yellow","Grays");
//Dialog.create("Select the parameters of your images");
//Dialog.addChoice("channel_1:", channel_color);
//Dialog.addChoice("channel_2:", channel_color);
//Dialog.addChoice("channel_3:", channel_color);
//Dialog.addChoice("channel_4:", channel_color);
//Dialog.show();
//channel_1 = Dialog.getChoice();
//channel_2 = Dialog.getChoice();
//channel_3 = Dialog.getChoice();
//channel_4 = Dialog.getChoice();


// Select the Actin and DAPI channels
Dialog.create("What is the Actin channel?");
Dialog.addNumber("Actin_channel:", 3);
Dialog.show();
Actin_channel = Dialog.getNumber();

Dialog.create("What is the DAPI channel?");
Dialog.addNumber("DAPI_channel:", 4);
Dialog.show();
DAPI_channel = Dialog.getNumber();


// File list
ImageNames=getFileList(dirdata); /// tableau contenant le nom des fichier contenus dans le dossier dirdata
nbimages=lengthOf(ImageNames); /// longueur du tableau == nombre de fichier dans le dossier

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
		Names = getList("image.titles");

		for(image=0;image<lengthOf(Names);image++) {
			Name = Names[image];
			
			if(endsWith(Name,"LVCC")) {
				selectWindow(Name);
				Serie_nb = substring(Name,lengthOf(Name)-12,lengthOf(Name)-9);

			// Adjust colors and channels
				Stack.setPosition(3,13,1);
				Stack.setChannel(1);
				run("Enhance Contrast", "saturated=0.35");
				//run(channel_1);

				Stack.setChannel(2);
				run("Enhance Contrast", "saturated=0.35");
				//run(channel_2);

				Stack.setChannel(3);
				run("Enhance Contrast", "saturated=0.35");
				//run(channel_3);

				Stack.setChannel(4);
				run("Enhance Contrast", "saturated=0.35");
				//run(channel_4);


				if(isOpen("ROI Manager")) {
					roiManager("reset");}

				Stack.setPosition(3,13,1);
				
			//	method = "watershed";
		
				// segmentation on actin zproj and watershed
				if (method == "watershed") {
					run("Duplicate...", "title=duplic duplicate channels="+Actin_channel);
					run("Z Project...", "projection=[Max Intensity]");
					rename("Mask_Actin");
					run("Gaussian Blur...", "sigma=2");
					setAutoThreshold("Huang dark no-reset");
					run("Convert to Mask");
					run("Fill Holes");
					run("Watershed");

					// Get particles excluding the edge
					run("Analyze Particles...", "size=50-Infinity exclude overlay add");
					
					if (roiManager("count")==0) {
						run("Analyze Particles...", "size=10-Infinity overlay add");
					}
					
					close("Mask_Actin");
					close("duplic");
				}



			// For segmentation with nucleus
				else {
					run("Z Project...", "projection=[Max Intensity]");
					rename("Zproj");

					// segmentation via DAPI channel
					run("Duplicate...", "title=DAPI duplicate channels="+DAPI_channel);
			//		run("Z Project...", "projection=[Max Intensity]");
					run("Mean...", "radius=50");
					run("Find Maxima...", "noise=20 output=[Segmented Particles] exclude");
					rename("Mask_DAPI");
					
					/// Make Cell Mask
					selectWindow("Zproj");
					run("Duplicate...", "title=Mask_Actin duplicate channels="+Actin_channel);
				//	run("Z Project...", "projection=[Max Intensity]");
					run("Gaussian Blur...", "sigma=2");
					setAutoThreshold("Huang dark no-reset");
					run("Convert to Mask");
					run("Fill Holes");

					/// Combine Masks
					imageCalculator("AND create", "Mask_DAPI","Mask_Actin");
					selectWindow("Result of Mask_DAPI");
					run("Analyze Particles...", "size=50-Infinity exclude overlay add");
					
					close("Result of Mask_DAPI");
					close("Mask_Actin");
					close("Mask_DAPI");
					close("DAPI");
					close("Zproj");
				}
				
				selectWindow(Name);
				roiManager("Show All");
				// Uncomment to save the .tif files
			//	run("8-bit");
			//	saveAs("Tiff", dir + LifName+"_serie"+Serie_nb+"_LVCC.tif");
				roiManager("Save", dir + LifName+"_serie"+Serie_nb+"RoiSet.zip");
				
				
				run("Close");
}
			else {
				if (raw_data == true) {
					selectWindow(Name);
					Serie_nb = substring(Name,lengthOf(Name)-3,lengthOf(Name));
					// Uncomment to save the .tif files
			//		run("8-bit");
			//		saveAs("Tiff", dir_raw + LifName+"_serie"+Serie_nb+".tif");	
					run("Close");
				}
				else {
					selectWindow(Name);
					run("Close");
				}

}
}}}
