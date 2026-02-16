renv::init()
library(tidyverse)
library(flightplot)

flightplot::sample_trips

plot_flights(sample_trips)

# see if this data can be combined with the 'airports' dataset
# make an inner join with the 'airports' IATA column
flights <- Combined_Flights_2022 %>% select(,1:16, -11, -12, -14)

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

# add coordinates for Origin & Destination ariports from the flightplot package

coord <- flightplot::airports
coord <- coord %>% select(,5,7,8)
# ORIGIN
origin_coords <- flights %>% select(,3,9)

origin_coords <- origin_coords %>% rename(IATA = Origin)
origin_coords <- origin_coords %>% inner_join(coord)
origin_coords <- origin_coords %>% rename(ori_lat = Latitude)
origin_coords <- origin_coords %>% rename(ori_lon = Longtitude)

# DESTINATION
dest_coords <- flights %>% select(,4,9)

dest_coords <- dest_coords %>% rename(IATA = Dest)
dest_coords <- dest_coords %>% inner_join(coord)

coordinates <- cbind(origin_coords, dest_coords)
coordinates <- coordinates %>% select(,1,2,3,4,7,8)

# visualise the flights paths of severely delayed flights >24 hrs

# remove NA's & outliers
coordinates <- coordinates %>% filter(DepDelayMinutes != 'NA')
coordinates <- coordinates %>% filter(between(DepDelayMinutes, 0,3000))

coordinates <- coordinates %>% filter(DepDelayMinutes > 1500)

origin <- data.frame(lng = coordinates$ori_lon, lat = coordinates$ori_lat)
dest <- data.frame(lng = coordinates$Longtitude, lat = coordinates$Latitude )

# add connecting lines between origin & destination ariports
coordinates <- coordinates %>% mutate(id = row_number())
# subsets 
df1 <- coordinates %>% select(id, ori_lat, ori_lon)
df1 <- df1 %>% rename(lat = ori_lat, lon = ori_lon)

df2 <- coordinates %>% select(id, Latitude, Longtitude)
df2 <- df2 %>% rename(lat = Latitude, lon = Longtitude)

df.sp <- bind_rows(df1, df2)

library(sp)

# convert df.sp to a spatial dataframe
coordinates(df.sp) <- c('lon', 'lat')

#create a list per id
id.list <- sp::split( df.sp, df.sp[["id"]] )

id <- 1
# FUNCTION - for each id, create a line that connects all points with that id

for ( i in id.list ) {
  event.lines <- SpatialLines( list( Lines( Line( i[1]@coords ), ID = id ) ),
                               proj4string = CRS( "+init=epsg:4326" ) )
  if ( id == 1 ) {
    sp_lines  <- event.lines
  } else {
    sp_lines <- rbind( sp_lines, event.lines )
  }
  id <- id + 1
}

library(leaflet)

map <- leaflet() %>% 
  addTiles() %>%
  addCircles(data = origin, color = "red", weight = 1.5, radius = 2) %>% 
  addCircles(data = dest, color = 'blue', weight = 1.5, radius = 2) %>% 
  addPolylines(data = sp_lines, weight = 1, opacity = 0.3,
               color = 'grey') %>%
  setView(lng = -94.3674, lat = 35.3366, zoom = 2.5)
  
map

library(mapview)
library(webshot)
webshot::install_phantomjs()
mapshot(map, file = "~/Documents/R/Graphics/flight_path.png")

renv::snapshot()







