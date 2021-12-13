library(dplyr)
library(ggplot2)
library(gdata)

films <- read.csv("DF_1999movies.csv")

# reduce the number of columns excluding those that are meaningless for further analysis or mostly filled with NA
new_films <- select(films, imdbID, Title, Year, Rated, Released, Runtime, Genre, Director, Writer, Actors, Language, Country, Awards, imdbRating, imdbVotes, BoxOffice)

# overall check of selected columns
summary(new_films)


# quite strangely in the csv file "not available" are codified with the string "NaN":  we replace this "NaN" value with the more standard NA  
new_films[new_films == "NaN"] <- NA

# Let's check the NA presence on all non-categorical variables and on the most significant categorical ones
sum(is.na(new_films))             # there are 23.012 NA values in total: some columns are more affected than others
sum(is.na(new_films$Genre))       # only 913
sum(is.na(new_films$imdbRating))  # only 1900
sum(is.na(new_films$imdbVotes))   # only 1885
sum(is.na(new_films$Year))        # 0 ok
sum(is.na(new_films$Released))    # 1875

# Quite complex topic if retain NA or omit. Some NA can be tolerated but other could be excluded: for example if we want to delete the 913 rows having Genre==NA just run the below line
# new_films <- new_films[complete.cases(new_films[ , 7]),]


# the csv should contains the films released in 1999 but looking bettere there are a few exceptions
new_films %>%
  group_by(Year) %>%
  summarise( count = n()   )

# let's delete the few exceptions where Year is not 1999 
new_films <- new_films[!new_films$Year!=1999,]

glimpse(new_films)     

# complexity of this Task2 is related to:
#    1)  there are only a vey few non-categorical variables:  Year (fixed to 1999) , Released, imdbRating, imdbVotes, BoxOffice
#    2)  many variables are badly formatted in a way that makes it complex to use them, for example:    
#           - runtime (duration of the film): is not an integer but a string (it contains values like "94 min" or "1 h 46 min"  or "1 h" )
#           - imdbVotes: is not an integer but a string (it contains values likes "12,345" whose right value is 12345 )
#           - released: is not formatted as a date but as a string
#           - BoxOffice: is not formatted as currency but as a string
#    3)  most of categorical variables (e.g. Genre, Director, Writer, Actors, Language, Country) contains multiple values comma-separated (e.g. for Genre the value "Action, Crime, Drama").


# cleaning 1: field imdbVotes  in the csv is uncorrectly formatted as string
new_films$imdbVotes <- as.numeric(as.character(gsub(",", "", new_films$imdbVotes)))


# cleaning 2: field Released  is formatted as date
lct <- Sys.getlocale("LC_TIME") 
Sys.setlocale("LC_TIME", "C")
new_films$Released <- as.Date(new_films$Released, "%d %b %Y")
Sys.setlocale("LC_TIME", lct)


# if we want to do some analysis based on the duration of the films we need a simple user defined function to convert in minutes the IMDB field "runtime" (whose values are formatted as "56 min" or "1 h 46 min"  or "1 h")

# cleaning 3: film duration in minutes as integer
calc_duration <- function(par_runtime){
  if (is.na(par_runtime))
    return(NA)
  
  # delete the ending " min" if present
  if (grepl("min", par_runtime)) 
    s1 = substr(par_runtime,1,nchar(par_runtime)-4)
  else
    s1 = par_runtime
  
  if (grepl("h", s1)) 
  {
    # we need to split hours and minutes 
    s2 <- unlist(trim(strsplit(s1, "h")))  
    
    return(60 * as.integer(s2[1]) + ifelse(is.na(s2[2]), 0, as.integer(s2[2])) )
  } 
  else 
    return(as.integer(as.character(s1)))
}

# add a new column Duration with initial default value at 0
new_films["Duration"] <- 0

# small cycle to set the new columns (honestly I tried to avoid the cycle and instead using apply o cbind but unsuccesfully)
for(i in 1:length(new_films$Runtime)){
  new_films$Duration[i] <- calc_duration(toString(new_films$Runtime[i]))
  }  

# cleaning 4: field BoxOffice  in the csv is uncorrectly formatted as string
new_films$BoxOffice <- as.numeric(as.character(substr(gsub(",", "", new_films$BoxOffice),2,99)))


# cleaning 5: for a geographical analysis would it be useful to have a new column MainCountry (it has been verified is the first one in the list if more than one is present)
new_films["MainCountry"] <- NA
for(i in 1:length(new_films$MainCountry)){
  new_films$MainCountry[i] <- ifelse(grepl(",", new_films$Country[i]) , as.character(unlist(trim(strsplit(as.character(new_films$Country[i]), ",")))[1]) , as.character(new_films$Country[i]) )
}  
new_films$MainCountry[new_films$MainCountry=="USA"] <- "United States"

new_films %>%
  group_by(MainCountry) %>%
  summarise( count = n())   %>%
  arrange(desc(count))

# keep the top 9 values and force Other on the other ones
new_films$MainCountry[new_films$MainCountry!="United States" & 
                      new_films$MainCountry!="India" &  
                      new_films$MainCountry!="Japan" &  
                      new_films$MainCountry!="Canada" &  
                      new_films$MainCountry!="France" &  
                      new_films$MainCountry!="Germany" &  
                      new_films$MainCountry!="Italy" &  
                      new_films$MainCountry!="Philippines" ] <- "Other"


#   ===================================== trend analysis =================================

# this kind of analysis would have been significant at yearly basis
# unfortunately having only 1 year in the csv (1999) it has been adpated on a monthly basis (but not particularly meaningful also considering that there are many NA)
# trend confirm that during summer break less films are released
ggplot(new_films, aes(format(Released, "%m"))) + 
  geom_bar(fill="blue") +
  labs(title="number of film released in 1999 by month", x="month", y="number of films")

# more sophisticated version excluding rows where release date is NA and splitted by MainCountry
ggplot(new_films[ !is.na(new_films$Released) & !is.na(new_films$MainCountry),], aes(format(Released, "%m"))) + 
  geom_bar(fill="blue") +
  labs(title="number of film released in 1999 by month and country", x="month", y="number of films") +
  facet_wrap(~ MainCountry, nrow = 3)


# check if average rating is changing over time (in our case monthly)
# nothing meaningful on a monthly basis: yearly could be more interesting
ggplot(new_films, aes(x = factor(format(Released, "%m")), y = imdbRating)) +
  geom_boxplot(color="blue") +
  labs(title="boxplot of film released in 1999 by month", x="month", y="imdbRating")

#   ===================================== relationship between vote and rating =================================

# we want to check if there is a relationshp between number of votes and rating (people votes more the good films)
# we filter out the record where votes is NA or below a treshold (5000 votes)

# relationship between number of votes and rating: not meaningful on this small dataset but potentially meaningful on the entire database
ggplot(new_films[ !is.na(new_films$imdbVotes) & new_films$imdbVotes > 5000,], aes(x = imdbVotes, y = imdbRating)) +
  geom_point(mapping = aes(color = MainCountry))  +
  geom_smooth() +
  labs(title="Relationship between votes and rating", x="Votes", y="Rating")

#   ===================================== best director analysis =================================

# in the analysis we want to avoid that a director with one film, one vote and a rating of 10 looks as the best director
# for this reason we restrict the ranking to the directors with an mean of votes > 5K
best_director <- new_films %>% 
  group_by(Director) %>%
  summarise( count = n() , avg_votes=mean(imdbVotes, na.rm=TRUE) , mean = mean(imdbRating, na.rm=TRUE) ) %>%
  filter(avg_votes > 5000) %>%
  arrange(desc(mean))  %>%
  top_n(10) 
  
ggplot(best_director, aes(x = Director, y = mean, alpha = avg_votes))+
  geom_bar(stat = "identity",fill = "blue") + 
  labs(x = "Best 10 Directors", y = "Avg Imdb Score") + 
  ggtitle("Top 10 Directors") + 
  coord_flip(ylim=c(6,10))


# we want to perform the same analysys but restrcting the scope to the only films that have been nominated for an Oscar or have won an Oscar
best_director <- new_films %>% 
  filter(grepl("Oscar", new_films$Awards)) %>%
  group_by(Director) %>%
  summarise( count = n() , avg_votes=mean(imdbVotes, na.rm=TRUE) , mean = mean(imdbRating, na.rm=TRUE) ) %>%
  arrange(desc(mean))  %>%
  top_n(10) 


ggplot(best_director, aes(x = Director, y = mean, alpha = avg_votes))+
  geom_bar(stat = "identity",fill = "blue") + 
  labs(x = "Best 10 Directors", y = "Avg Imdb Score") + 
  ggtitle("Top 10 Directors (with Oscar nominations or Oscar wins)") + 
  coord_flip(ylim=c(6,10))


#   ===================================== best genre analysis =================================

best_Genre <- new_films %>%
  filter( ! is.na(Genre)) %>%
  group_by(Genre) %>%
  summarise(count = n() , avg_votes=mean(imdbVotes, na.rm=TRUE) , mean = mean(imdbRating, na.rm=TRUE) ) %>%
  arrange(desc(mean))  %>%
  top_n(5)
  

ggplot(best_Genre, aes(x = Genre, y = mean, alpha = avg_votes)) +
    geom_bar(stat = "identity",fill = "blue") + 
    labs(x = "Top movie genre", y = "Average Imdb Score") + 
    ggtitle("Top movie genre with average score") + 
    coord_flip(ylim=c(6,9))

#   =====================================  analysis based on the duration =================================
  
# the analysis of the distribtion of the Duration shows the highest values in the ranges 80-90 and 90-100 minutes   
ggplot(data=new_films, aes(Duration)) + 
  geom_histogram(breaks=seq(30, 250, by=10),
                 fill="blue", 
                 alpha = .5) +
  labs(title="Histogram for Duration", x="Duration", y="Count") +
  xlim(c(30,250))

# let's check if there ar differences between the main countries ->  as expected films in India last much more (peak between 140 and 150 minutes)
ggplot(data=new_films[ !is.na(new_films$Duration) & !is.na(new_films$MainCountry),], aes(Duration)) + 
  geom_histogram(breaks=seq(30, 250, by=10),
                 fill="blue", 
                 alpha = .5) +
  labs(title="Histogram for Duration", x="Duration", y="Count") +
  xlim(c(30,250)) +
  facet_wrap(~ MainCountry, nrow = 3)

# check relationship between Duration and Rating: as expected no relationship  
ggplot(data = new_films, mapping = aes(x = Duration, y = imdbRating)) +
  geom_point(color="blue")  


#   =====================================  analysis based on the country =================================

new_films$Country[new_films$Country=="USA"] <- "United States"

top_countries <- new_films %>% 
  filter( ! is.na(MainCountry) & ! is.na(imdbVotes)) %>%
  group_by(MainCountry) %>%
  summarise(mean = mean(imdbRating, na.rm=TRUE), avg_votes=mean(imdbVotes, na.rm=TRUE), count = n() ) %>%
  arrange(desc(count))  %>%
  top_n(10) 

ggplot(top_countries, aes(x = MainCountry, y = count))+
  geom_bar(stat = "identity",fill = "blue") + 
  labs(x = "Top 10 Countries", y = "Number of films") + 
  ggtitle("Top 10 Countries for number of film") 

ggplot(top_countries, aes(x = MainCountry, y = mean, alpha = avg_votes))+
  geom_bar(stat = "identity",fill = "blue") + 
  labs(x = "Top 10 Countries", y = "Avg Imdb Score") + 
  ggtitle("Top 10 Countries") + 
  coord_flip(ylim=c(5,7))

ggplot(new_films, aes(x = factor(MainCountry), y = imdbRating)) +
  geom_boxplot(color="blue") +
  labs(title="Avg Rating of film released in 1999 by MainCountry", x="Country", y="imdbRating")

#   ===================================== relationship between boxoffice revenues and rating =================================

# let's check if there is a relationship between boxoffice revenues and rating: result -> not fully clear, to be verified with the larger dataset
ggplot(new_films[ !is.na(new_films$BoxOffice) & !is.na(new_films$imdbRating) ,], aes(x = BoxOffice, y = imdbRating)) +
  geom_point(mapping = aes(color = MainCountry))  +
  geom_smooth() +
  labs(title="Relationship between BoxOffice Revenues and Rating", x="BoxOffice", y="Rating")


#   ===================================== relationship between boxoffice revenues and number of votes =================================

# let's check if there is a relationship between boxoffice revenues and number of votes: here the result is much more clear
ggplot(new_films[ !is.na(new_films$BoxOffice) & !is.na(new_films$imdbVotes) ,], aes(x = BoxOffice, y = imdbVotes)) +
  geom_point(mapping = aes(color = MainCountry))  +
  geom_smooth() +
  labs(title="Relationship between BoxOffice Revenues and imdbVotes", x="BoxOffice", y="imdbVotes")

ggplot(new_films[ !is.na(new_films$BoxOffice) & !is.na(new_films$imdbVotes) ,], aes(x = BoxOffice, y = imdbVotes)) +
  geom_point()  +
  geom_smooth() +
  labs(title="Relationship between BoxOffice Revenues and imdbVotes", x="BoxOffice", y="imdbVotes") +
  facet_wrap(~ MainCountry, nrow = 3)

#   ===================================== more sophisticated best genre analysis =================================

Genre_clean <- gsub('[{}"]', '', new_films$Genre) # remove unwanted stuff 
Genre_split <- trim(strsplit(Genre_clean, ",")) # split rows into individual genre
Genre_unique <- sort(unique(unlist(Genre_split))) # get a list of unique genre 

films_extended <- cbind(new_films, t(sapply(Genre_split, function(x)  table(factor(x, levels = Genre_unique)))))

# most voted films in 1999
top_n(arrange(filter( new_films, ! is.na(imdbVotes)), desc(imdbVotes)), 10, imdbVotes)[,c(2,5,6,7,14,15)]

