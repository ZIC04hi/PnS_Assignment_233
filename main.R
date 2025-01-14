# INSTALL PACKAGE
# install.packages("tidyr")
# install.packages("dplyr")
# install.packages("stringr")

# ---------------------------
# Includes
library(tidyr)
library(stringr)
library(dplyr)

# ---------------------------
# User Function
# ---------------------------
### CLEAN FUNCTIONS ###
# Brief: Remove "empty" rows from the table
# Arguments: data - table data; column_names - working column
# e.g: new_data <- CleanData_rm(new_data, Product_Collection)
CleanData_rm <- function(data, column_name) {
  data %>% filter( # Loc tat ca cac dong thoa man dieu kien
    # {{ vec }} acts as a placeholder
    # for any column name as arg
    {{ column_name }} %in% c(NA, "N/A", "")
  )
}
# Brief: Fill the missing values by same Sample_Vector name
# Arguments: data - table data; column_names - working column;
#             sample_column_name - column to fill based on same value
# e.g: new_data <- CleanData_f_name(new_data, Cache, Product_Collection)
CleanData_f_name <- function(data, column_name, sample_column_name) {
  data %>%
    # groups the data frame by the sample column.
    group_by({{ sample_column_name }}) %>%
    mutate({{ column_name }} := ifelse(
      {{ column_name }} %in% c(NA, "N/A", ""),
      # Replace NA values with the first non-NA value from
      # the sample column.
      first({{ column_name }}[{{ column_name }} %in% c(NA, "N/A", "")]),
      # else just keep its value
      {{ column_name }}
    ))
}
# Brief: Fill the missing values by average values
# Arguments: data - table data; column_name - working column
# e.g: new_data <- CleanData_f_avr(new_data, Product_Collection)
CleanData_f_avr <- function(data, column_name) {
  data %>%
    mutate({{ column_name }} := ifelse(
      {{ column_name }} %in% c(NA, "N/A", ""),
      # na.rm: Skip the NA value in column_name
      {{ column_name }} %>%
        get_num() %>%
        mean(na.rm = TRUE),
      # else do nothing
      {{ column_name }}
    ))
}
#-----------------
### CONVERT FUNCTIONS ###
# Brief: Convert data into number
# Arguments: x - data to convert
# e.g: new_data$col_to_convert <- sapply(new_data$col_to_convert, get_num)
get_num <- function(x) {
  x %>%
    str_extract("[\\d]*[.]?[\\d]+") %>% # Get the first number
    as.numeric(na.rm = TRUE) # covert into number
}
#-----------------
# Brief: Convert data into number
# Arguments: x - data to convert
# e.g: new_data$col_to_convert <- sapply(new_data$col_to_convert, get_num)
freq_to_mhz <- function(x) {
  # Check if the input is numeric (who knows what is it unit)
  if (is.numeric(x)) {
    return(x)
  }
  num <- get_num(x)
  # Determine the conversion factor based on the unit
  unit <- x %>%
    gsub("[0-9. ]", "", .) %>% # remove all number digits
    substr(1, 1) %>% # get the first letter
    toupper() # uppercase the unit
  fac <- switch(unit,
    K = 1 / 1000, # kHz to MHz
    M = 1, # MHz to MHz
    G = 1000, # GHz to MHz
    T = 1000000, # THz to MHz
    1 # Default: MHz
  )
  return(num * fac)
}
#-----------------
### PLOT ###
# Brief: Create histogram for a given column
# Arguments:  - column_name: working column
#             - name: Name of the column
#             - xlabel: unit of working column
#             - max: maximum value of y axis
# e.g: hist_plot("Bo nho Cache", new_data$Cache, MB, 512)
hist_plot <- function(name, column_name, xlabel, max) {
  hist(column_name,
    main = name,
    xlab = xlabel,
    ylab = "Frequency",
    ylim = c(0, max),
    labels = TRUE,
    breaks = 15,
    col = "lightgreen"
  )
}

#################################
#       Data Pre-processing
#################################
# ---------------------------
# Read data
data <- read.csv("Data//Intel_CPUs.csv")
# ---------------------------
# Extract data
new_data <- data[, c(
  "Product_Collection",
  "Bus_Speed",
  "Cache",
  "Graphics_Max_Dynamic_Frequency",
  "Graphics_Video_Max_Memory",
  "Max_Memory_Bandwidth",
  "Max_nb_of_Memory_Channels",
  "Max_Memory_Size",
  "nb_of_Cores",
  "Processor_Base_Frequency",
  "Recommended_Customer_Price",
  "Secure_Key",
  "TDP"
)]
str(new_data)
# ---------------------------
### PROCESSING MISSING DATA ###
# Count missing data on new data label
missing_data <- new_data %>%
  sapply(
    function(x) {
      sum(
        x %>% is.na() | x %>% sapply(is.null) |
          x %>% sapply(function(x) (x == "" | x == "N/A"))
      )
    }
  ) %>%
  print()
# Count missing data frequency
missing_data_frequency <- missing_data %>%
  `/`(nrow(new_data)) %>%
  print()
# ---------------------------


### Paste code in here
# TO-DO:
## 1. Kiem tra dinh dang bien
## 2. Kiem tra du lieu bi khuyet, xu ly no (xoa/ die`n vao)
## 3. Xu ly bien ngoai lai
## 4. Tao them bien dinh tinh tu bien dinh luong





new_data$Cache <- sapply(new_data$Cache, freq_to_mhz)
# ---------------------------
### Max_nb_of_Memory_Channels ###
# UNIT: None
new_data <- new_data %>%
  mutate(
    Max_nb_of_Memory_Channels = sapply(Max_nb_of_Memory_Channels, get_num)
  ) # Convert into number
# ---------------------------
### Bus_Speed ###
# UNIT: MHz
# Transfer per second to MHz
# TESTING: new_data <- CleanData_rm(new_data, Bus_Speed)
tmp <- separate(new_data,
  col = Bus_Speed,
  into = c("Bus_Speed", "Speed_Unit", "Bus_Type"),
  sep = " ",
  fill = "right"
)

new_data$Bus_Speed <- ifelse(tmp$Speed_Unit == "MHz",
  as.numeric(tmp$Bus_Speed),
  as.numeric(tmp$Bus_Speed) * 100
  # Maybe change when I know wtf is tranfer type and how can convert exactly
)
rm(tmp)
# ---------------------------
### Max Memory Bandwidth ###
# UNIT: GB/s
# TESTING: new_data <- CleanData_rm(new_data, Max_Memory_Bandwidth)
new_data <- new_data %>%
  mutate(
    Max_Memory_Bandwidth = sapply(Max_Memory_Bandwidth, get_num)
  )
# ---------------------------
#################################
#       Descriptive statistics
#################################
# ---------------------------
### Summary statistics ###
#  !Add more specific
summary_stats <- new_data[, c(
  "Bus_Speed",
  "Max_Memory_Bandwidth"
)]
# !Note that not every vectors has to be summarized
# Calculate the average of each sample
mean <- apply(summary_stats, 2, mean)

# Calculate standard derive (correction)
sd <- apply(summary_stats, 2, sd)

# Calculate quartile scores
q1 <- apply(summary_stats, 2, quantile, probs = 0.25)
med <- apply(summary_stats, 2, median)
q3 <- apply(summary_stats, 2, quantile, probs = 0.75)

# Calculate min value
min <- apply(summary_stats, 2, min)

# Calculate max value
max <- apply(summary_stats, 2, max)

# Restore the features in tabular form
summary_stats <- data.frame(mean, sd, q1, med, q3, min, max)
# ---------------------------
### Cache statistics ###
hist_plot("Bo nho Cache", new_data$Cache, MB, 512)