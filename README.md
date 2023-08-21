# Prediction of Prediabetes
<div style="text-align: right"> Author: Vassil Dimitrov </div>
<div style="text-align: right"> Date: 2023-08-04 </div>
<br>  

*Look at script **0_prereq_env.ipynb** for required modules, libraries and environments.*
  
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

*Look at scripts **1_data_upload_allergies.sql**, **1_data_upload_conditions.sql**, **1_data_upload_careplans.sql**, **1_data_upload_immunizations.sql**, **1_data_upload_medications.sql**, **1_data_upload_patients.sql**, **1_data_upload_procedures.sql**, **2_read_sql_transform_clean.ipynb**, **3_consolid_data_1.ipynb** and later **6_add_observ_tidy.ipynb**.*
    
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
3. Ensure that the features corresponding to the significant coefficients with the highest magnitude (most important predictors) are congruent with observations associated with diabetes based on the literature.
   
   Hyperparameters such as scaling, regularization types and penalty values, dimension reduction and the type of solver were optimized on training subset. And the model was trained using the full training set. Values that are not significant or with very small coefficients were excluded from downstream analysis as they bring little to no information explaining presence/absence of prediabetes. At this point, more features were added to the model from the *observations* table.

*Look at scripts **5_LogReg_1.ipynb**, **6_add_observ_tidy.ipynb** and **7_EDA_test_split.ipynb**.*

#### Logistic Regression
Logistic regression was performed after all the hyperparameters were optimized on a validation subset of the training set. The model was then trained on the entire training dataset and its performance was tested on the test set:
- TRAIN:
  - accuracy: 0.89
  - precision: 0.96
  - recall: 0.80
- TEST:
  - accuracy: 0.89
  - precision: 0.96
  - recall: 0.80

There does not appear to be any overtraining as the train and test metrics are virtually identical. Accuracy here is a valid and important metric as the classes are evenly split. We have a high precision implying that 96% of patients predicted to develop prediabetes actually develop it. The recall for this model is a bit lower and signifies that only 80% of all patients with prediabetes are captured by the model. Since our main goal is a CALL-TO-ACTION to prevent prediabetes development, trading precision for recall may be a good idea: we would rather have more false positives than miss true positives as there is no/small associated intervention cost.

*Look at script **8_Logistic_Regression.ipynb**.*

#### Decision Tree Classifier and Random Forests
A very simple classifier was constructed and was favoured due to its high interpretability. There was a significant overlap for the top and most important nodes of the tree classifier and the features with the highest coefficient magnitude of the logistic regression model. In an effort to improve performance at the expense of interpretability, random forest models were optimized and tested. They barely outperformed the decision tree classifier, but due to the latter's interpretability, it may be more advantages to keep the decision tree classifier model especially in the context of healthcare where communication with the patient is very important.

*Look at scripts **10_Trees.ipynb** and **10_1_Random_Forests.ipynb**.*

#### KNN Classifier
This model was chosen as it is non-parametric and could be quite flexible. It is approriate for use with data that does not exhibit linear relationship and is multi-dimensional.

*Look at script **11_KNN_model.ipynb**.*

#### Deep Neural Networks


  


