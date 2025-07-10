# Converting separate pixel documents into one spreadsheet
# Here for volume

library(dplyr)

# Function to merge all volume files by Index
# (might be worth doing for all parts, not just Vol?)
align_phase_volumes <- function(directory){
  file_list <- list.files(directory, pattern = "^vol_.*", full.names = TRUE)
  # Initialise an emptry list to store dataframes
  df_list <- list()
  for (file in file_list){
    # Extract phase name from filename
    phase_name <- gsub("vol_\\[?|\\]?", "", basename(file)) # Remove "vol_" and brackets
    # Read file
    df <- read.table(file, header = FALSE, col.names = c("Index", phase_name))
    # Store dataframe in list
    df_list[[phase_name]] <- df
  }
  # Merge all dataframes using full_join to keep all indices
  merged_df <- Reduce(function(x, y) full_join(x, y, by = "Index"), df_list)
  # Sort by Index
  merged_df <- arrange(merged_df, Index)
  return(merged_df)
}