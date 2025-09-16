Fiji_Macros by Elisa

# SUMMARY
- GENERAL MACROS:
    - **run-different-macro.ijm** = apply different macros on different files at once
    - **Macro_OpenDeconvFiles.ijm** = Open all the images in a .lif and keep opened only the wanted one
 
- CENTRIOLE ANALYSIS (Guichard Hamel Lab)
    - **Macro_CentriolesExtraction.ijm** = Extract Mother/Dauther centrioles from your .lif file, crop/resize them and save them separately. Thunder or Stellaris versions take into account the different possible deconvoluted files names
    - **Macro_CentrioleAnalysis.ijm** = Plot profile analysis on centrioles (extracted in .tif) , derived from the "PickCentriole" plugin.
  
- IMMUNE SYNAPSE
  
      Old files = made in 2023-2024 in Geneva. Use new files to get latest versions
  
    - **Macro_SynapseSegmentation.ijm** = Isolate the coated-glass synapses from the .lif files and save the ROIs
    - **Macro_SynapseSegmentationCAR.ijm** = Same as the previous one but modified to include a rough analysis of isolated synapses (area and circularity)
    - **Macro_ActivationState.ijm** = Open segmented synapses *[from Macro_SynapseSegmentation]* and ask the user the activation state according to actin
    - **Macro_SynapseAnalysis.ijm** = Open segmented synapses *[from Macro_SynapseSegmentation]* and analyse MTOC polarization AND/OR protein repartition at the synapse
    - **MT Analysis**:
        - **Macro1_MT-Analysis_Normalization.ijm** = Open segmented synapses *[from Macro_SynapseSegmentation]* and get the mean value of a few individual MT selected by the user
        - **Macro2_MT-Analysis.ijm** = Open segmented synapses *[from Macro_SynapseSegmentation]* and measure MT network area, total intensity normalized, and integration of an intensity profile
        - **Macro_MTQuantifNEW.ijm** = Open segmented synapses *[from Macro_SynapseSegmentation]* or *[from Macro_SynapseSegmentationCAR]* and measure MT total intensity normalized by the background mean intensity (no need to define individual MT)
    - **Macro_GranulesAnalysis.ijm** = Open segmented synapses *[from Macro_SynapseSegmentation]* and analyse Mitochondrial signal in granules indentified by NHS staining (on Z projection)
    - **Macro_MitochondriaAnalysis.ijm** = Open segmented synapses *[from Macro_SynapseSegmentation]* and analyse Granules in 3D
    - **Conjugates**:
        - **Macro_ConjugatesExtraction.ijm** = Isolate the conjugates manually selected by the users from the .lif files and save the ROIs. Save each individual synapse with right orientation and colors as a .tif file in separated folder.
        - **Macro_ConjugatesShape.ijm** = Open isolated conjugates *[from Macro_ConjugatesExtraction]* and measure solidity and deformation at the synapse
    - **Macro_NucleusExclusion.ijm** = (Macro for Hermine) Segment cells and nucleus using BF/Actin and DAPI and measure 1 channel intensity in cytoplasm vs nucleus
