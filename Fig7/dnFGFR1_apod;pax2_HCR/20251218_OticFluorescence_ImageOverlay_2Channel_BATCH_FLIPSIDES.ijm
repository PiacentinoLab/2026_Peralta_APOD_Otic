// ============================
// Batch setup
// ============================

// Input directory
waitForUser("Select the input directory with images to process");
input_dir = getDirectory("Select input directory");

// Output directories
waitForUser("Select the directory to save ROIs and overlay images");
roi_dir = getDirectory("Select ROI/overlay save directory");

waitForUser("Select the directory to save measurement CSVs");
csv_dir = getDirectory("Select CSV save directory");

// Channels to measure and labels
channels = newArray(1, 4);
labels   = newArray("PAX2", "APOD");

// Get list of image files in input directory
fileList = getFileList(input_dir);

// ============================
// Loop over all images
// ============================
for (f = 0; f < fileList.length; f++) {

    fileName = fileList[f];

    // Only process image files (adjust extensions if needed)
    if (!endsWith(fileName, ".tif") && !endsWith(fileName, ".czi") && !endsWith(fileName, ".nd2") && !endsWith(fileName, ".lif"))
        continue;

    print("Processing: " + fileName);

    // Open image
    open(input_dir + fileName);
    name = File.nameWithoutExtension;
    rename("A");

    // ============================
    // Prepare image
    // ============================
    run("Set Measurements...", "area mean integrated display redirect=None decimal=3");
    run("Z Project...", "projection=[Max Intensity]");
    run("Flip Horizontally", "stack");
    rename("A");
    Stack.setChannel(4);
    run("Enhance Contrast", "saturated=0.35");

    // Close leftover windows
    if (isOpen("Results")) { selectWindow("Results"); run("Close"); }
    if (isOpen("Summary")) { selectWindow("Summary"); run("Close"); }
    if (isOpen("ROI Manager")) { selectWindow("ROI Manager"); run("Close"); }

    // ============================
    // Define ROIs // 98.64 µm ROI = 60 pxl in 5x image, 120 pxl in 10x
    // ============================
    makeOval(0, 0, 120, 120); 
    waitForUser("Drag ROI over Control Otic, then press OK for image: " + name);
    roiManager("Add");
    roiManager("Select",0);
    roiManager("Rename","Cntl");
    roiManager("Show All");

    makeOval(0, 0, 120, 120);
    waitForUser("Drag ROI over Experimental Otic, then press OK for image: " + name);
    roiManager("Add");
    roiManager("Select",1);
    roiManager("Rename","Expt");
    roiManager("Show All");

    // Save ROI set
    roiManager("Save", roi_dir + name + ".zip");

    // ============================
    // Split channels and measure
    // ============================
    original_title = getTitle();
    run("Split Channels");

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

    // Close all remaining windows for this image
    run("Close All");
}

print("Batch processing complete!");
