# Predicting-flight-delays-
Building a custom ML model to predict whether a flight will be delayed or not

Dataset:
https://www.kaggle.com/datasets/robikscube/flight-delay-dataset-20182022/data?select=Combined_Flights_2022.csv

**Context:**
For this project, I used a large flights dataset to build a custom machine learing model using **Support Vector Machines (SVMs)** to predict
whether a flight will be delayed or not.

To imporve our model and visuals, we would need coordinates (lat/long) to visualise the flight paths. 

'Combined_Flights_2022' doesn't contain coordinates for the visualisation, and therefore, I used a separate dataset contained in the package 'flightplot'to extract lat & long. 

# Model
To predict whether a flight will be delayed, our training dataset needs to contain as much information about a flight as possible. 
The 'Combined_Flights_2022' is a rich dataset with millions of entries contianing key information on 'Airtime', 'Delay', 'Distance', 'Ariports'.
Additionally, I added coordinates information to add to the training dataset. 

# Limitations 
As this is a custom ML model on my local machine, I could only train 1% of the dataset due to the low processing power of my macbook.
Despite the high volume of 'Combined_Flights_2022' it still lacks key information like 'Weather', 'Wind speed' which could prove useful in our training dataset. 

'Combined_Flights_2022' also contains only 7-months of data, so the training dataset won't be able to pick any key seasonal patterns. 

# Model summary
Call:
svm(formula = Delayed ~ ., data = train, cost = 100, gamma = 0.1)


Parameters:
   SVM-Type:  C-classification 
 SVM-Kernel:  radial 
       cost:  100 

Number of Support Vectors:  7148

 ( 2513 4635 )


Number of Classes:  2 

Levels: 
 No Yes
 
# Model results
Despite training the model on only 1% of the total 'Combined_Flights_2022', the model accuracy from the confusion matrix was 53%. 
Other Classification matrics like 'Recall' & 'Precision' can also be calculated from the confusion matrix to assess the overall model performance. 

# Model improvements
1. Increase the training dataset
2. Apply 'tuning' to identify the best values for cost & gamma
3. Additional sources of data such as 'weather' could've yielded much better results

# Visualising flight paths of the flights delayed by >3 hours

