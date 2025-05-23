# ===============================================
# Makefile: DNAm Pipeline
# ===============================================

# Directories
LOGS_DIR = logs
DATA_DIR = data
RDATA_DIR = rData
RESULTS_DIR = results
FIGURES_DIR = figures

# Default target
all:	rData/preprocessingMinfi/metrics/m_NomFilt_MSetF_Flt_Rxy_Ds_Rc.RData \
	rData/preprocessingMinfi/metrics/beta_NomFilt_MSetF_Flt_Rxy_Ds_Rc.RData \
	rData/preprocessingMinfi/metrics/cn_NomFilt_MSetF_Flt_Rxy_Ds_Rc.RData \
	data/preprocessingEwastools/pheno_ewasQC.csv \
	data/preprocessingPheno/phenoEWAS.csv \
	data/methylationGLM_T1/annotatedGLM.csv \
     	data/methylationGLMM_T1T2/annotatedLME.csv \
     	rData/epigeneticAge_T1T2/models/phenoDNAmAgeLM_T1.RData \
     	rData/epigeneticAge_T1T2/models/phenoDNAmAgeLM_T2.RData 

# ----------------------------------------------------
# Step 1: Minfi Preprocessing
# ----------------------------------------------------
rData/preprocessingMinfi/metrics/m_NomFilt_MSetF_Flt_Rxy_Ds_Rc.RData \
rData/preprocessingMinfi/metrics/beta_NomFilt_MSetF_Flt_Rxy_Ds_Rc.RData \
rData/preprocessingMinfi/metrics/cn_NomFilt_MSetF_Flt_Rxy_Ds_Rc.RData: preprocessingMinfi.R
	Rscript preprocessingMinfi.R \
	  --phenoFile data/preprocessingMinfi/pheno.csv \
	  --idatFolder data/preprocessingMinfi/idats/ \
	  --outputLogs logs/preprocessingMinfi/ \
	  --nSamples NA \
	  --idColumns SID,Timepoint \
	  --arrayType IlluminaHumanMethylationEPICv2 \
	  --annotationVersion 20a1.hg38 \
	  --scriptLabel preprocessingMinfi \
	  --baseDataFolder rData \
	  --qcTiffPath figures/preprocessingMinfi/quality_control_MSet.tiff \
	  --tiffWidth 2000 --tiffHeight 1000 --tiffRes 150 \
	  --qcCutoff 10.5 --detPtype m+u \
	  --densityTiffPath figures/preprocessingMinfi/densityBeta_MSet.tiff \
	  --pdfReportPath reports/qc_report_RGSet.pdf \
	  --funnormSeed 123 --normMethods 'funnorm' \
	  --pvalThreshold 0.01 \
	  --chrToRemove chrX,chrY --snpsToRemove SBE,CpG --mafThreshold 0.1 \
	  --crossReactivePath data/preprocessingMinfi/12864_2024_10027_MOESM8_ESM.csv \
	  --plotGroupVar Sex \
	  --betaMPlotPath figures/preprocessingMinfi/densityBetaM_MSetF_Flt_Rxy_Ds_Rc.tiff

# ----------------------------------------------------
# Step 2: Ewastools Preprocessing
# ----------------------------------------------------
data/preprocessingEwastools/pheno_ewasQC.csv: preprocessingEwastools.R rData/preprocessingMinfi/metrics/cn_NomFilt_MSetF_Flt_Rxy_Ds_Rc.RData
	Rscript preprocessingEwastools.R \
	  --phenoFile data/preprocessingMinfi/pheno.csv \
	  --idatFolder data/preprocessingMinfi/idats/ \
	  --outputLogs logs/preprocessingEwastools/ \
	  --sampleIdCols Basename \
	  --matchColumn Basename \
	  --detectionPcutoff 0.01 \
	  --lcReference salivaEPIC \
	  --snpProbeType rs \
	  --outlierThreshold -4 \
	  --outPhenoQC data/preprocessingEwastools/pheno_ewasQC.csv

# ----------------------------------------------------
# Step 3: Merge Phenotype
# ----------------------------------------------------
data/preprocessingPheno/phenoEWAS.csv: preprocessingPheno.R data/preprocessingEwastools/pheno_ewasQC.csv
	Rscript preprocessingPheno.R \
	  --phenoFile data/preprocessingMinfi/pheno.csv \
	  --phenoEWAS data/preprocessingEwastools/pheno_ewasQC.csv \
	  --betaPath rData/preprocessingMinfi/metrics/beta_NomFilt_MSetF_Flt_Rxy_Ds_Rc.RData \
	  --mPath rData/preprocessingMinfi/metrics/m_NomFilt_MSetF_Flt_Rxy_Ds_Rc.RData \
	  --cnPath rData/preprocessingMinfi/metrics/cn_NomFilt_MSetF_Flt_Rxy_Ds_Rc.RData \
	  --dropColumnsPhenoEWAS SampleID \
	  --colsToRenamePhenoEWAS failed,Leukocytes,Epithelial.cells,outlier,outlierYN,donor_id,n \
	  --mergeKey SID \
	  --factorVars Sex,Ethnicity,TraumaDefinition \
	  --factorPrefixes Sex,Ethn,TraD \
	  --timepoints 1,2 \
	  --combineTimepoints 1,2 \
	  --outputPheno data/preprocessingPheno/merge \
	  --outputRData rData/preprocessingPheno/metrics \
	  --outputLogs logs/preprocessingPheno

# ----------------------------------------------------
# Step 4: GLM for T1
# ----------------------------------------------------
data/methylationGLM_T1/annotatedGLM.csv: methylationGLM_T1.R data/preprocessingPheno/phenoEWAS.csv
	Rscript methylationGLM_T1.R \
	  --inputPheno rData/preprocessingPheno/mergeData/phenoBetaT1.RData \
	  --outputLogs logs/methylationGLM_T1 \
	  --outputRData rData/methylationGLM_T1/models \
	  --outputPlots figures/methylationGLM_T1 \
	  --phenotypes PCL_SUM,PCL5_B,PCL5_C,PCL5_D,PCL5_E,PTGIX_SUM,DASS_D,DASS_S,DASS_A,SSS8_SUM \
	  --covariates Sex,Age,Ethnicity,TraumaDefinition,Leukocytes.EWAS,Epithelial.cells.EWAS,BMI \
	  --factorVars Sex,Ethnicity,TraumaDefinition \
	  --cpgPrefix cg \
	  --cpgLimit NA \
	  --nCores 64 \
	  --plotWidth 2000 --plotHeight 1000 --plotDPI 150 \
	  --libPath ~/R/x86_64-pc-linux-gnu-library/4.4 \
	  --glmLibs glm2 \
	  --prsMap PCL_SUM:PTSD_PRS,PCL5_B:PTSD_PRS,PCL5_C:PTSD_PRS,PCL5_D:PTSD_PRS,PCL5_E:PTSD_PRS,PTGIX_SUM:PTSD_PRS,DASS_D:MDD_PRS,DASS_S:PTSD_PRS,DASS_A:GAD_PRS,SSS8_SUM:MDD_PRS \
	  --summaryPval NA \
	  --summaryResidualSD \
	  --saveSignificantCpGs \
	  --significantCpGPval 0.00001 \
	  --saveTxtSummaries \
	  --fdrThreshold  0.05 \
	  --annotationPackage IlluminaHumanMethylationEPICv2anno.20a1.hg38 \
	  --annotationCols Name,chr,pos,UCSC_RefGene_Group,UCSC_RefGene_Name,Relation_to_Island,GencodeV41_Group \
	  --annotatedGLMOut data/methylationGLM_T1

# ----------------------------------------------------
# Step 5: LME for T1 vs T2 (Longitudinal Analysis)
# ----------------------------------------------------
data/methylationGLMM_T1T2/annotatedLME.csv: methylationGLMM_T1T2.R data/preprocessingPheno/phenoEWAS.csv
	Rscript methylationGLMM_T1T2.R \
	  --inputPheno rData/preprocessingPheno/mergeData/phenoBetaT1T2.RData \
	  --outputLogs logs/methylationGLMM_T1T2 \
	  --outputRData rData/methylationGLMM_T1T2/models \
	  --outputPlots figures/methylationGLM_T1T2 \
	  --personVar person \
	  --timeVar Timepoint \
	  --phenotypes PCL_SUM,PCL5_B,PCL5_C,PCL5_D,PCL5_E,PTGIX_SUM,DASS_D,DASS_S,DASS_A,SSS8_SUM \
	  --covariates Sex,Age,Ethnicity,TraumaDefinition,Leukocytes.EWAS,Epithelial.cells.EWAS,BMI \
	  --factorVars Sex,Ethnicity,TraumaDefinition \
	  --lmeLibs lme4,lmerTest \
	  --libPath ~/R/x86_64-pc-linux-gnu-library/4.4 \
	  --prsMap PCL_SUM:PTSD_PRS,PCL5_B:PTSD_PRS,PCL5_C:PTSD_PRS,PCL5_D:PTSD_PRS,PCL5_E:PTSD_PRS,PTGIX_SUM:PTSD_PRS,DASS_D:MDD_PRS,DASS_S:PTSD_PRS,DASS_A:GAD_PRS,SSS8_SUM:MDD_PRS \
	  --cpgPrefix cg \
	  --cpgLimit NA \
	  --nCores 64 \
	  --interactionTerm Timepoint \
	  --saveSignificantInteractions \
	  --significantInteractionPval 0.00001 \
	  --saveTxtSummaries \
	  --fdrThreshold  0.05 \
	  --annotationPackage IlluminaHumanMethylationEPICv2anno.20a1.hg38 \
	  --annotationCols Name,chr,pos,UCSC_RefGene_Group,UCSC_RefGene_Name,Relation_to_Island,GencodeV41_Group \
	  --annotatedLMEOut data/methylationGLMM_T1T2

# ----------------------------------------------------
# Step 6: Epigenetic Clock Integration (T1 & T2)
# ----------------------------------------------------
rData/epigeneticAge_T1T2/models/phenoDNAmAgeLM_T1.RData: epigeneticAge_T1T2.R data/preprocessingPheno/phenoT1.csv data/preprocessingPheno/phenoT2.csv
	Rscript epigeneticAge_T1T2.R \
	  --outputLogs logs/epigeneticAge_T1T2 \
	  --betaT1 rData/preprocessingPheno/metrics/betaT1.RData \
	  --betaT2 rData/preprocessingPheno/metrics/betaT2.RData \
	  --phenoT1 data/preprocessingPheno/phenoT1.csv \
	  --phenoT2 data/preprocessingPheno/phenoT2.csv \
	  --clockDictT1 data/clockFundation/T1_DNAmAgeCalcProject_18159_DataDict.csv \
	  --clockResT1 data/clockFundation/T1_DNAmAgeCalcProject_18159_Results.csv \
	  --clockDictT2 data/clockFundation/T2_DNAmAgeCalcProject_18237_DataDict.csv \
	  --clockResT2 data/clockFundation/T2_DNAmAgeCalcProject_18237_Results.csv \
	  --minfiPheno data/preprocessingMinfi/pheno.csv \
	  --idRenameFrom SID \
	  --idRenameTo id \
	  --sexZeroValue 0 \
	  --sex0Label Female \
	  --sex1Label Male \
	  --phenotypes PCL_SUM,PCL5_B,PCL5_C,PCL5_D,PCL5_E,PTGIX_SUM,DASS_D,DASS_S,DASS_A,SSS8_SUM \
	  --covariates Sex,Age,Ethnicity,TraumaDefinition,Leukocytes.EWAS,Epithelial.cells.EWAS,BMI \
	  --factorVars Sex,Ethnicity,TraumaDefinition \
	  --clockPattern "\\.Methylclock$$|\\.DNAm_Age\\.ClockF$$" \
	  --prsMap PCL_SUM:PTSD_PRS,PCL5_B:PTSD_PRS,PCL5_C:PTSD_PRS,PCL5_D:PTSD_PRS,PCL5_E:PTSD_PRS,PTGIX_SUM:PTSD_PRS,DASS_D:MDD_PRS,DASS_S:PTSD_PRS,DASS_A:GAD_PRS,SSS8_SUM:MDD_PRS \
	  --modelOutDir rData/epigeneticAge_T1T2/models \
	  --dnAmAgeLM_T1Out rData/epigeneticAge_T1T2/models/phenoDNAmAgeLM_T1.RData \
	  --dnAmAgeLM_T2Out rData/epigeneticAge_T1T2/models/phenoDNAmAgeLM_T2.RData \
	  --outputPlots figures/epigeneticAge_T1T2 \
	  --plotWidth 2000 --plotHeight 1000 --plotDPI 150

# ----------------------------------------------------
# Clean up outputs
# ----------------------------------------------------
clean:
	rm -rf data/preprocessingPheno/* \
	       data/preprocessingEwastools/* \
	       data/methylationGLM_T1/* \
	       data/methylationGLMM_T1T2/* \
	       data/epigeneticAge_T1T2/* \
	       results/* figures/* logs/* preliminaryResults/* rData/* reports/*

# ----------------------------------------------------
# Status Check Target
# ----------------------------------------------------
status:
	@echo "===== Pipeline Status ====="
	@test -e rData/preprocessingMinfi/objects/RGSet.RData && echo "? Step 1: preprocessingMinfi done" || echo "? Step 1: preprocessingMinfi outcome file missing"
	@test -e data/preprocessingEwastools/pheno_ewasQC.csv && echo "? Step 2: preprocessingEwastools done" || echo "? Step 2: preprocessingEwastools outcome file missing"
	@test -e data/preprocessingPheno/phenoEWAS.csv && echo "? Step 3: preprocessingPheno done" || echo "? Step 3: preprocessingPheno outcome file missing"
	@test -e data/methylationGLM_T1/annotatedGLM.csv && echo "? Step 4: methylationGLM_T1 done" || echo "? Step 4: methylationGLM_T1 outcome file missing"
	@test -e data/methylationGLMM_T1T2/annotatedLME.csv && echo "? Step 5: methylationGLMM_T1T2 done" || echo "? Step 5: methylationGLMM_T1T2 outcome file missing"
	@test -e rData/epigeneticAge_T1T2/models/phenoDNAmAgeLM_T1.RData && echo "? Step 6: epigeneticAge_T1T2 (T1) done" || echo "? Step 6: epigeneticAge_T1T2 (T1) outcome file missing"
	@test -e rData/epigeneticAge_T1T2/models/phenoDNAmAgeLM_T2.RData && echo "? Step 6: epigeneticAge_T1T2 (T2) done" || echo "? Step 6: epigeneticAge_T1T2 (T2) outcome file missing"
	@echo "============================"


.PHONY: all clean
