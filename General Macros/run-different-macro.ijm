// Macro by Elisa
// Run more than one macro automatically on different files

//		░░░░░░░░░░░░░░░░░░░░░░█████████░░░░░░░░░
//		░░███████░░░░░░░░░░███▒▒▒▒▒▒▒▒███░░░░░░░
//		░░█▒▒▒▒▒▒█░░░░░░░███▒▒▒▒▒▒▒▒▒▒▒▒▒███░░░░
//		░░░█▒▒▒▒▒▒█░░░░██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██░░
//		░░░░█▒▒▒▒▒█░░░██▒▒▒▒▒██▒▒▒▒▒▒██▒▒▒▒▒███░
//		░░░░░█▒▒▒█░░░█▒▒▒▒▒▒████▒▒▒▒████▒▒▒▒▒▒██
//		░░░█████████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██
//		░░░█▒▒▒▒▒▒▒▒▒▒▒▒█▒▒▒▒▒▒▒▒▒█▒▒▒▒▒▒▒▒▒▒▒██
//		░██▒▒▒▒▒▒▒▒▒▒▒▒▒█▒▒▒██▒▒▒▒▒▒▒▒▒▒██▒▒▒▒██
//		██▒▒▒███████████▒▒▒▒▒██▒▒▒▒▒▒▒▒██▒▒▒▒▒██
//		█▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒█▒▒▒▒▒▒████████▒▒▒▒▒▒▒██
//		██▒▒▒▒▒▒▒▒▒▒▒▒▒▒█▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██░
//		░█▒▒▒███████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██░░░
//		░██▒▒▒▒▒▒▒▒▒▒████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒█░░░░░
//		░░████████████░░░█████████████████░░░░░░

// How many macro do we want to apply ?
macro_nb = getNumber("How many macro will you use ?", 2);

// Get the wanted macro
macro_list = newArray(macro_nb);
for(j=0 ;j<macro_nb; j++) {
	path = File.openDialog("Select a File");
  //open(path); // open the file
  	dir_macro = File.getParent(path);
  //	print(dir_macro);
  //	print(path);
  	//name = File.getName(path);
	macro_list[j] = path;
	}


// How many files do we want to analyse ?
files_nb = getNumber("How many files do you want to analyse ?", 2);
files_list = newArray(files_nb);
// Get the files to analyse
for(j=0 ;j<files_nb; j++) {
	files_list[j] = getDirectory("Choisir le dossier contenant les stacks a analyser");   /// choix des dossier contenant les images a analyser
	print(files_list[j]);
	}
	
//var files_list_tot = files_list

// Run selected macro on each selected files
for(j=0 ;j<files_nb; j++) {
	dirLif = files_list[j];
	dirdata = dirLif+"Tiff"+File.separator();
	
	for(i=0 ;i<macro_nb; i++) {
		runMacro(macro_list[i],dirLif); // run the wanted macro with the file as argument
		//Be carefull to add dirLif = getArgument() in your macro file
}}


