//learn file name, prepare file and Fiji for analysis
name=File.nameWithoutExtension;
run("Set Measurements...", "area mean integrated display redirect=None decimal=3");
run("Z Project...", "projection=[Max Intensity]");
rename("A");
Stack.setChannel(2);
run("Enhance Contrast", "saturated=0.35");

//Close unnecessary windows from last analysis
if (isOpen("Results")) { 
         selectWindow("Results"); 
         run("Close"); 
    } 
if (isOpen("Summary")) { 
         selectWindow("Summary"); 
         run("Close"); 
    } 
if (isOpen("ROI Manager")) { 
         selectWindow("ROI Manager"); 
         run("Close"); 
    } 

//Input ROI File:
//roi=File.openDialog("Select ROI file");
//roiManager("Open",roi);


//Define ROIs
makeOval(0, 0, 120, 120); // 98.64 µm ROI = 60 pxl in 5x image, 120 pxl in 10x
waitForUser("Drag ROI over Control Otic, then press ok");
roiManager("Add");
roiManager("Select",0);
roiManager("Rename","Cntl");
roiManager("Show All");
makeOval(0, 0, 120, 120);
waitForUser("Drag ROI over Experimental Otic, then press ok");
roiManager("Add");
roiManager("Select",1);
roiManager("Rename","Expt");
roiManager("Show All");

//Save out ROIs
waitForUser("Choose a directory to save ROIs and overlay images, then press ok");
roi_dir = getDirectory("Choose a directory to save ROI sets.");
roiManager("Save", roi_dir+name+".zip");

// ============================
// Split channels and prepare loop
// ============================
original_title = getTitle();
run("Split Channels");

// Channels to measure and labels
channels = newArray(2, 5);
labels   = newArray("SOX10", "PAX2");

// Ask once where to save CSVs
waitForUser("Choose directory to save measurement CSVs");
csv_dir = getDirectory("Choose a directory to save measurement results.");

// ============================
// Loop over channels
// ============================
for (i = 0; i < channels.length; i++) {

    chNum = channels[i];
    label = labels[i];

    // Activate split channel image
    selectWindow("C" + chNum + "-" + original_title);
    rename(label);
    resetMinAndMax();
    run("Enhance Contrast", "saturated=0.35");

    // Show ROIs
    roiManager("Show All");
    roiManager("Deselect");

    // Clear old results
    if (isOpen("Results")) { selectWindow("Results"); run("Clear Results"); }

    // Measure all ROIs
    roiManager("Select", 0); run("Measure");
    roiManager("Select", 1); run("Measure");

    // Save CSV
    saveAs("Results", csv_dir + name + "_" + label + ".csv");

    // Save ROI overlay
    roiManager("Show All");
    run("Flatten", "slice");
    saveAs("JPEG", roi_dir + name + "_ROIOverlay_" + label + ".jpg");

    // Close flattened overlay and channel image
    run("Close");
}

// ============================
// Clean up
// ============================
run("Close All");