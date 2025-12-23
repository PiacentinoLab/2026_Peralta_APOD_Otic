//Define channels to measure and their names
measure_channel_1 = 2
measure_channel_1_name = "FOXI3"

//learn file name, prepare file and Fiji for analysis
name=File.nameWithoutExtension;
run("Set Measurements...", "area mean integrated display redirect=None decimal=3");
run("Z Project...", "projection=[Max Intensity]");
run("Flip Horizontally", "stack"); //activate this line if imaged on the confocal
rename("A");
Stack.setChannel(measure_channel_1);
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
makeOval(0, 0, 225, 225);
waitForUser("Drag ROI over Control Trigem, then press ok");
roiManager("Add");
roiManager("Select",0);
roiManager("Rename","Cntl");
roiManager("Show All");
makeOval(0, 0, 225, 225);
waitForUser("Drag ROI over Experimental Trigem, then press ok");
roiManager("Add");
roiManager("Select",1);
roiManager("Rename","Expt");
roiManager("Show All");

//Save out ROIs
waitForUser("Choose a directory to save ROIs and overlay images, then press ok");
roi_dir = getDirectory("Choose a directory to save ROI sets.");
roiManager("Save", roi_dir+name+".zip");

// Split channels then measure each channel defined above
run("Split Channels");

//First channel
selectWindow("C" + toString(measure_channel_1) + "-A");
rename(measure_channel_1_name);
run("Enhance Contrast", "saturated=0.35");
//run("Subtract Background...", "rolling=200");
roiManager("Show All");
roiManager("Deselect");
roiManager("Measure");
selectWindow(measure_channel_1_name);
//Save out ROI/Image Overlay
roiManager("Show All");
run("Flatten", "slice");
saveAs("JPEG", roi_dir+name+"_"+measure_channel_1_name+"_ROIOverlay.jpg");

//Save out Measurements as csv
waitForUser("Choose a directory to save measurements, then press ok");
csv_dir = getDirectory("Choose a directory to save measurement results.");
saveAs("Results", csv_dir+name+".csv");

//Close image windows
run("Close All");