renv::init()
library(tidyverse)
library(flightplot)

flightplot::sample_trips

plot_flights(sample_trips)

# see if this data can be combined with the 'airports' dataset
# make an inner join with the 'airports' IATA column
flights <- Combined_Flights_2022 %>% select(,1:16, -11, -12, -14)

# check if 'origin' & 'dest' airports can be joined with 'airports'
df1 <- flights %>% select(,3:4)
df1 <- as.vector(as.matrix(df1))
df1 <- as.data.frame(unique(df1)) 
print(df1)
df1 <- df1 %>% rename(code = 'unique(df1)')

# pull the ariport code, lat & lon columns
df2 <- airports %>% select(,5, 7, 8)
df2 <- df2 %>% rename(code = 'IATA')

df1 <- df2 %>% inner_join(df1)
# re-join with the main 'flights' dataset
df1 <- df1 %>% rename(Dest = 'code')
flights <- df1 %>% inner_join(flights)

# re-position the columns
flights <- flights %>% relocate(Dest, Latitude, Longtitude, .after = Origin)
# optional - write the dataset containing lat & lon 
setwd("~/Documents/R/Datasets")
write.csv(flights, "flights.csv")

# EDA
# add day & month
flights <- flights %>% mutate(day = wday(FlightDate, label = TRUE))
flights <- flights %>% mutate(month = month(FlightDate, label = TRUE))

flights %>% group_by(Airline, day) %>% summarise(n = n()) %>% 
  ggplot(aes(day, n)) + geom_boxplot() + 
  theme(panel.background = element_rect(color = 'black', fill = 'white'),
        panel.grid.major = element_blank(),legend.title = element_blank(),
        panel.grid.minor = element_blank()) + 
  xlab('') + ylab('')

summary(flights$DepDelayMinutes)
# remove NA's & outliers
flights <- flights %>% filter(DepDelayMinutes != 'NA')
flights <- flights %>% filter(between(DepDelayMinutes, 0,3000))

# find unique combinations for each Airline (Origin & Dest)
unique(flights[,c('Airline','Origin','Dest')])


# duplicate 'flights' for model building
model <- flights[,2:18]

# EDA 

# Airlines with most distance 
library(stringr)

top_airlines <- model %>% group_by(Airline) %>% summarise(sum(Distance)) %>% 
  arrange(desc(`sum(Distance)`)) %>% top_n(10)

top_airlines <- top_airlines %>% rename(Distance = `sum(Distance)`)

# visuals 
miles <- ggplot(top_airlines) + geom_hline(
  aes(yintercept = y), 
  data.frame(y = c(0:3) * 1000),
  color = "lightgrey"
) + geom_col(
  aes(
    x = reorder(str_wrap(Airline, 3), Distance),
    y = Distance, fill = Distance
  ),
  position = "dodge2",
  show.legend = TRUE,
  alpha = .9
) + geom_point(
  aes(
    x = reorder(str_wrap(Airline, 3),Distance),
    y = Distance
  ),
  size = 3,
  color = "gray12"
) + geom_segment(
  aes(
    x = reorder(str_wrap(Airline, 3), Distance),
    y = 0,
    xend = reorder(str_wrap(Airline, 3), Distance),
    yend = 3000
  ), linetype = "dashed", color = "gray12"
) + coord_polar() +
  scale_y_continuous(labels = scales::unit_format(unit = "M", scale = 1e-6)) + 
  scale_fill_continuous(labels = scales::unit_format(unit = "M", scale = 1e-6)) + 
  theme(plot.title = element_text(face = "bold", size = 12)
        ,axis.text.y = element_blank(),
        axis.ticks = element_blank()) + ylab('') + xlab('') + 
  ggtitle(label = 'Top 10 Airlines with the most airmiles')

miles

# flight delay based on day of the week
week <- model %>% filter(DepDelayMinutes >180) %>% 
  group_by(FlightDate, day) %>% summarise(mean(DepDelayMinutes)) %>% 
  ggplot(aes(FlightDate, `mean(DepDelayMinutes)`)) + 
  geom_line(aes(color = day)) + 
  theme(panel.background = element_rect(color = 'black', fill = 'white'),
        panel.grid.major = element_blank(),legend.title = element_blank(),
        panel.grid.minor = element_blank()) + 
  xlab('') + ylab('Average Delay (mins)')

week

# flight delay based on Airline
airline <- model %>% filter(DepDelayMinutes > 180) %>% group_by(FlightDate, Airline) %>% 
  summarise(mean(DepDelayMinutes)) %>% 
  ggplot(aes(FlightDate, `mean(DepDelayMinutes)`)) + 
  geom_line(aes(color = Airline)) +  
  theme(panel.background = element_rect(color = 'black', fill = 'white'),
        panel.grid.major = element_blank(),legend.title = element_blank(),
        panel.grid.minor = element_blank()) + 
  xlab('') + ylab('Average Delay (mins)')

airline

# flight delay based on distance
distance <-  model %>% group_by(Airline, Distance) %>% filter(DepDelayMinutes >180) %>% 
  summarise(mean(DepDelayMinutes)) %>% 
  ggplot(aes(Distance, `mean(DepDelayMinutes)`)) + 
  geom_line(aes(color = Airline)) + 
  theme(panel.background = element_rect(color = 'black', fill = 'white'),
        panel.grid.major = element_blank(),legend.title = element_blank(),
        panel.grid.minor = element_blank()) + 
  xlab('Air miles') + ylab('Average Delay (mins)')

distance

# model building
# add a column 'Delayed' --- Yes / No 
model <- model %>% mutate(Delayed = DepDelayMinutes)

# function to populate the column

delayed <- function(delay){
  delay <- as.numeric(delay)
  if(delay == '0'){
    return('No')
  }else{
    return('Yes')
  }
}

# apply the function
model$Delayed <- sapply(model$Delayed, delayed)
print(str(model))

# convert 'Delayed' into a factor
model$Delayed <- factor(model$Delayed)

# slice the data 
library(caTools)

sample <- sample.split(model$Delayed, SplitRatio = 0.01)
# training dataset
train <- subset(model, sample == TRUE)
# testting dataset
test <- subset(model, sample == FALSE)

# algorithm - support vector machine (SVMs)
library(e1071)
modelsvm <- svm(Delayed ~ ., data = train, cost = 100, gamma = 0.1)

summary(modelsvm)

# test a sample to assess how well the model predicts
airports <- train[,3:4]
airports <- as.vector(as.matrix(unique(airports)))  

test <- test %>% filter(Origin == airports) %>% 
  filter(Dest == airports)


predicted_values <- predict(modelsvm, test[,1:17])
summary(predicted_values)
predicted_values <- as.data.frame(predicted_values)

test <- test[1:593,]
# confusion matrix
table(test$Delayed, predicted_values$predicted_values)

# accuracy 
accuracy <- (226 + 145) / (226+105+117+145) 
print(accuracy)
# 62.5% 

# visualise the delayed (>3 hours) flights 

library(leaflet)
model <- model %>% filter(DepDelayMinutes > 180)
circles <- data.frame(lng = model$Longtitude, lat = model$Latitude)

map <- leaflet() %>% 
  addTiles() %>%
  addCircleMarkers(data = circles, color = "red", weight = 1, radius = 2) %>% 
  setView(lng = -94.3674, lat = 35.3366, zoom = 2.5) %>% 
  addPolylines(lng = model$Longtitude, lat=model$Latitude, weight=1, 
               opacity=0.5, color="blue")

map

library(mapview)
library(webshot)
webshot::install_phantomjs()
mapshot(map, file = "~/Documents/R/Graphics/flight_path.png")

renv::snapshot()







