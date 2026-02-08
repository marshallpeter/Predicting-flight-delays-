# Predicting-flight-delays-
Building a custom ML model to predict whether a flight will be delayed or not

Dataset:
https://www.kaggle.com/datasets/robikscube/flight-delay-dataset-20182022/data?select=Combined_Flights_2022.csv

**Context:**
For this project, I used a large flights dataset to build a custom machine learing model using **Support Vector Machines (SVMs)** algorithm to predict
whether a flight will be delayed or not.

To imporve our model and visuals, we would need coordinates (lat/long) to visualise the flight paths. 

'Combined_Flights_2022' doesn't contain coordinates for the visualisation, and therefore, I used a separate dataset contained in the package 'flightplot' to extract lat & long. 

Note: we have approximately 8,000 entries missing due to combining datasets to extract lat/long. 

<img width="846" height="420" alt="image" src="https://github.com/user-attachments/assets/fa8dd333-69cf-47aa-92b2-6cf7a79061dd" />

# Exploratory Data Analysis (EDA) 
Data transformation & EDA are a crucial part of building custom ML models. Without these 2, one wouldn't know which attributes to use / exclude for training datasets and test against the model outputs. 

I wanted to visualise which airlines have the highest miles to understand whether these airlines have a pattern of delays: 

<img width="4251" height="2677" alt="miles" src="https://github.com/user-attachments/assets/512d9a50-c2c9-449c-ac4e-e87aff3e5ca3" />

I also added 'weekday' & 'month' columns to visualise delays by weekdays to understand any concrete patterns: 

<img width="4251" height="2677" alt="week" src="https://github.com/user-attachments/assets/c437da50-1db1-4de4-9587-3e3a539a87d8" />

I also wanted to capture a snapshot of the delayed flights based on distance:

<img width="4251" height="2677" alt="distance" src="https://github.com/user-attachments/assets/16aa6bf4-d835-471c-bc3b-4312e8748cea" />

# Model
To predict whether a flight will be delayed, our training dataset needs to contain as much information about a flight as possible. 
The 'Combined_Flights_2022' is a rich dataset with millions of entries contianing key information on 'Airtime', 'Departure Delay', 'Distance', 'Ariports'.
Additionally, I added coordinates information, weekday and months based on the dates to add to the training dataset. 

# Limitations 
As this is a custom ML model built on my local machine, I could only train 1% of the dataset due to the low processing power of my macbook.
Despite the high volume (~4 millions entries) of 'Combined_Flights_2022', it still lacks key information like 'Weather', 'Wind speed', 'Traffic control related information', which could prove useful in our training dataset. 

'Combined_Flights_2022' also only **7-months** of the data, so the training dataset won't be able to pick any key seasonal patterns. 

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

<img width="926" height="356" alt="image" src="https://github.com/user-attachments/assets/f0af5f89-ac12-4e68-8735-32465b02fbaa" />


# Model improvements
1. Increase the training dataset
2. Apply 'tuning' to identify the best values for cost & gamma
3. Additional sources of data such as 'weather', 'wind speed' and 'traffic control related data' could've yielded much better results

# Visualising flight paths of the flights delayed by >3 hours
<img width="992" height="744" alt="flight_path" src="https://github.com/user-attachments/assets/ff628de6-f2ad-4acf-8680-aeb86515337c" />


