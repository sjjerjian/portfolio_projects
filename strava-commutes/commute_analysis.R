library(tidyverse)
library(data.table)
library(lubridate)

# data cleaning ----------------------------------------------------------------

activities <- fread("activities.csv", stringsAsFactors=FALSE)
setnames(activities, sub(" ", "_", names(activities)))

# Convert datetime column to proper datetime format
activities$Activity_Date <- as.POSIXct(activities$Activity_Date, tz = "UTC",
                                       format = "%b %d, %Y, %I:%M:%S %p")

# Tidy the data
tidy_data <- activities %>%
        filter(Commute == TRUE) %>%
        rename(
               datetime = Activity_Date,
               elapsed_time_mins = Elapsed_Time,
               moving_time_mins = Moving_Time,
               distance_km = Distance,
               max_speed = Max_Speed,
               avg_speed = Average_Speed,
        ) %>%
        mutate(
                datetime_est = with_tz(datetime, tzone="America/New_York"),
                elapsed_time_mins = elapsed_time_mins/60,
                moving_time_mins = moving_time_mins/60,
                distance_km = distance_km/1000,
                
        ) %>%
        select(
                datetime_est, 
                elapsed_time_mins, moving_time_mins, distance_km,
                max_speed, avg_speed
                
        ) 

head(tidy_data)

summary(tidy_data)

# remove a few outliers
# Filter out outliers
filtered_data <- tidy_data %>%
         filter(elapsed_time_mins >= 20,
                elapsed_time_mins <= 35,
                moving_time_mins > 20,
                )

fwrite(filtered_data, "commute_rides.csv")


# analysis ----------------------------------------------------------------

library(tidyverse)
library(data.table)
library(lubridate)
library(ggplot2)

commutes <- fread("commute_rides.csv", stringsAsFactors = FALSE)

# why do I need to do this again??
commutes$datetime_est = with_tz(commutes$datetime_est, tzone="America/New_York")

commutes <- commutes %>%
        mutate(t_win = floor_date(datetime_est, "30 minutes"),
               t_win = format(t_win, format = "%H:%M"))
head(commutes)

time_to_int <- function(time_str) {
        time_str <- gsub(":", "", time_str)  # Remove colon
        return(as.integer(time_str))
}
commutes$t_win <- sapply(commutes$t_win, time_to_int) 

hourly_avg <- commutes %>%
        group_by(t_win) %>%
        summarize(count_rides = n(),
                avg_mt = mean(moving_time_mins),
                avg_et = mean(elapsed_time_mins),
                std_mt = sd(moving_time_mins),
                std_et = sd(elapsed_time_mins))
        
ggplot(data = hourly_avg) +
        geom_line(mapping = aes(x = t_win, y = avg_mt), color = 'red') +
        geom_line(mapping = aes(x = t_win, y = avg_et), color = 'blue') +
        geom_line(mapping = aes(x = t_win, y = count_rides), color = "purple") +
        geom_ribbon(mapping = aes(x = t_win, ymin = avg_mt - std_mt, ymax = avg_mt + std_mt),
                    fill = 'red', alpha = 0.3) +
        geom_ribbon(mapping = aes(x = t_win, ymin = avg_et - std_et, ymax = avg_et + std_et),
                    fill = 'blue', alpha = 0.3) +
        labs(x = "Time Window", y = "Values") +
        theme_minimal() +
        scale_y_continuous(sec.axis = sec_axis(~., name = "Count of Rides"))



