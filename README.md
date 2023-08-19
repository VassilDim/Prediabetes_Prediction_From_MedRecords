# Prediction of Prediabetes
<div style="text-align: right"> Author: Vassil Dimitrov </div>
<div style="text-align: right"> Date: 2023-08-04 </div>
<br>  
  
## Problem statement
The overarching goal of this project is to leverage medical records (synthetic medical records in this case, obtained from [here](https://synthea.mitre.org/downloads)) and build models that can predict the incidence of prediabetes.
  <br>
    
## Why prediabetes?
- The main reason is that at this point the development of diabetes can be slowed down and even prevented by relatively cheap and easy behavioral changes.
- This can significantly reduce socio-economic burden, improve patient quality of life and lower the healthcare infrastructure overload.
- The prevalence of prediabetes and diabetes in Canada as of 2023 is 11 million people.
- There is an upward trend with $14 billion spent in 2008 and $30 billion in 2019 to treat prediabetes, diabetes and its complications.
- The out-of-pocket cost per patient can go up to $18,306 per year.
  <br>
    
## Data
Due to ethical considerations, all models were build using [synthetic data](https://synthea.mitre.org/downloads). The data was obtained in *csv* format pre-parsed from *json* files following the FHIR convetion such that information for over 1 million patients with chronic diseases is spread across 12 output directories each containing the following tables:
- allergies
- careplans
- conditions
- encounters
- immunizations
- medications
- observations
- patients
- procedures

Note that due to the large amount of data, MySQL database was used to load, transform, consolidate and clean up the data. In the *Prediabetes_Prediction_From_MedRecords* repository, the scripts performing these tasks are *sql* scripts with the prefix 1 indicating the expected order of execution of the scripts for the analysis.

The tables in the SQL database were loaded directly as pandas dataframe to complete data consolidation and transform values for all features to a numerical representation.
  <br>
    
## Analysis
  <br>

### EXPLORATORY DATA ANALYSIS

First, the diabetic patients were excluded from downstream analysis as well as patients receiving medications or care associated with diabetes (e.g. metformin or dialysis due to renal disease).
The correlation between features was assessed an highly correlated features were used to engineer a new aggregate feature OR one of the features was dropped entirely.
The number of prediabetic patients were less than the non-prediabetic patients. The latter group was therefore downsampled to obtain balanced target feature labels. Dimensionality reduction followed by visualization was employed to gain insight about which scaling method works best and whether there are any clusters of patients:
- PCA
- tSNE
- UMAP
- no scaling
- standard scaling
- MinMax scaling
Unsurprisingly, MinMax scaling produced the best results since most of the features are represented by dummy variables.

*Look at scripts **4_train_split_EDA.ipynb** and **later 7_EDA_test_split.ipynb***

### MODEL BUILDING

#### Base Model (logistic regression)
This model was first trained in order to:
1. Obtain baseline performance metrics.
2. Identify variables that are not important for explaining the variation in the response variable and can therefore be eliminated from downstream analysis.
Hyperparameters such as scaling, regularization types and penalty values, dimension reduction and the type of solver were optimized on training
  


