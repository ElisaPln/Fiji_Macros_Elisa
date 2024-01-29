Fiji_Macros by Elisa

# SUMMARY
- GENERAL MACROS:
    - **run-different-macro.ijm** = apply different macros on different files at once
    - **Macro_OpenDeconvFiles.ijm** = Open all the images in a .lif and keep opened only the wanted one
 
- CENTRIOLE ANALYSIS (Guichard Hamel Lab)
    - **Macro_CentriolesExtraction.ijm** = Extract Mother/Dauther centrioles form your .lif file, crop/resize them and save them separately
    - **Macro_CentrioleAnalysis.ijm** = Plot profile analysis on centrioles, derived from the "PickCentriole" plugin
  
- IMMUNE SYNAPSE
    - **Macro_SynapseSegmentation.ijm** = Isolate the coated-glass synapses from the .lif files and save the ROIs
    - **Macro_ActivationState.ijm** = Open segmented synapses *[from Macro_SynapseSegmentation]* and ask the user the activation state according to actin
    - **Macro_SynapseAnalysis.ijm** = Open segmented synapses *[from Macro_SynapseSegmentation]* and analyse MTOC polarization AND/OR protein repartition at the synapse
    - **MT Analysis**:
        - **Macro1_MT-Analysis_Normalization.ijm** = Open segmented synapses *[from Macro_SynapseSegmentation]* and get the mean value of a few individual MT selected by the user
        - **Macro2_MT-Analysis.ijm** = Open segmented synapses *[from Macro_SynapseSegmentation]* and measure MT network area, total intensity normalized, and integration of an intensity profile
    - **Macro_GranulesAnalysis.ijm** = Open segmented synapses *[from Macro_SynapseSegmentation]* and analyse Mitochondrial signal in granules indentified by NHS staining (on Z projection)
    - **Macro_MitochondriaAnalysis.ijm** = Open segmented synapses *[from Macro_SynapseSegmentation]* and analyse Granules in 3D
