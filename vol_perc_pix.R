# Plotting heatmaps of volume data (could be extended to x, a etc)

#SETUP

library(dplyr)
library(tidyr)
library(ggplot2)
library(colorBlindness)
library(svglite)

# A. converting to vol%

calculate_vol_percentages <- function(df) {
  # Modify the volume percentages calculation
  df_volperc <- df %>%
   mutate(across(.cols = everything(),
      #= !c("Index", "solids"),
      .fns = ~ ifelse(is.na(.), 0, . / solids * 100),
      .names = "perc_{.col}"
    ))
  
  return(df_volperc)
}

# Example usage:
#ZBE017_dry_aligned_volperc = calculate_vol_percentages(ZBE017_dry_aligned)

# E. Multiple phases: 4

one_plot <- function(pix_dim, df_volperc, phase_array, save_path = NULL, autoscale = FALSE, scale_min = 0, scale_max = 100, alpha = FALSE, call = TRUE) { #user should not really be interacting with call, its just there to prevent mult plots from causing 2 prints every for iteration
  if (call) { print("Working...") }

  #clean for non existant phases, check there are actually some phases
  existing_phases <- select(df_volperc, any_of(phase_array))
  if (length(existing_phases) == 0) {
    return(NULL) #kill function before crash
  }

  cleanPhaseArray <- colnames(existing_phases)
  percPhaseArray <- paste0("perc_", cleanPhaseArray) #add perc to the inputted phase names (if we only ever work with the % why not just make a new df that has just those instead?)

  #setup columns for plotting
  df_plot <- df_volperc %>%
    select(Index, all_of(percPhaseArray)) %>%
    mutate(x = rep(1:pix_dim, times = pix_dim),
           y = rep(1:pix_dim, each = pix_dim)) %>%

    # Remove NA or non-finite values from the dataset
    drop_na() %>% #this is supposedly more performant than filter
    filter(if_any(everything(), is.finite)) %>%

    #create a sum column
    rowwise() %>% mutate(sum = sum(c_across(any_of(percPhaseArray)))) %>% ungroup()
    #rowwise to allow use of c_across, ungroup to remove effect of rowwise c_across selects columns to rowwise sum over, any_of checks for the first instance of each col name in percPhaseArray

  #setup limits, containing in a vector because it just feels right
  if (autoscale) {
    valMax <- max(df_plot$sum)
    valMin <- min(df_plot$sum)
    buckets <- 10 #edit this to change the number of buckets the data are split into when determining size of steps

    step <- (ceiling(valMax) - floor(valMin)) / buckets #range / buckets for bucket width to determine best value to round max to
    scalingFactor <- 1 / step #DONT CHANGE THIS VALUE! #step of 0.5 needs the value multiplied by 2 before its floored to get to nearest half int

    scaleLims <- c(min = floor(valMin * scalingFactor) / scalingFactor, max = ceiling(valMax * scalingFactor) / scalingFactor)
  }
  else {  #use user limits or default
    scaleLims <- c(min = scale_min, max = scale_max) #naming them min max in tuple for ease of use later
  }

  # Scale the vol_percent_sum data to the user-defined range
  df_plot$sum <- pmin(pmax(df_plot$sum, scaleLims["min"]), scaleLims["max"])  # Clip values to the range [scalemin, scalemax]

  # Add an alpha value, setting it to 0 for vol_percent < 0.001, and 1 for others
  df_plot$alpha_value <- if (alpha) ifelse(df_plot$sum < 0.001, 0, 1) else 1

  midpoint <- (scaleLims[["max"]] + scaleLims[["min"]]) / 2
  breakIntervals <- c(scaleLims[["min"]], midpoint/2, midpoint, midpoint*3/2, scaleLims[["max"]]) #defining specific points for legend labels
  #sometimes the top label wouldn't show and is important when autoscaled so this forces it

  # Choose color scale based on 'scalemin' and 'scalemax' (scaleLims)
  colour_palette <- colorBlindness::Blue2DarkRed18Steps
  colour_scale <- scale_fill_gradientn(colors = colour_palette, breaks = breakIntervals, limits = scaleLims)
  scale_alpha

  plot <- ggplot(df_plot, aes(x, y, fill = sum, alpha = alpha_value)) +
    scale_alpha_identity() + #this for some bizarre reason makes alpha_value work when its all the same value
    geom_raster() + # i am trying this out afresh
    colour_scale +
    theme_minimal() + # i am trying this out afresh
    labs(title = paste(cleanPhaseArray, "vol%   ", collapse = ""), x = "T", y = "Y", fill = "Vol%") + #Using cleanPhaseArray bc I don't want perc_ in front but thats preference I guess
    theme(panel.background = element_rect(fill = "transparent", color = NA),  # Transparency
          plot.background = element_rect(fill = "transparent", color = NA),  # Transparency
          axis.title = element_blank(),  # Remove axis titles
          axis.text = element_blank(),   # Remove axis labels
          axis.ticks = element_blank())  # Remove axis ticks
  
  # Save plot if save_path is provided
  if (!is.null(save_path)) {
    # Ensure the directory exists
    dir.create(dirname(save_path), recursive = TRUE, showWarnings = FALSE)
    
    # Set width and height to match aspect ratio of grid
    ggsave(save_path, plot, width = 10, height = 10, units = "in", dpi = 600)
  }

  if (call) { print(sprintf("Plot of %s is finished.", paste(cleanPhaseArray, collapse = " "))) } #probably the most inappropriate use of paste but street toughs like me don't give an f B)
  return(plot)  # Return the plot for further use or display
}

mult_plots <- function(pix_dim, df_volperc, phase_array, folder_path = NULL, autoscale = FALSE, scale_min = 0, scale_max = 100, alpha = FALSE) { #no call as call is for multi_plot to override prints in one_plot
  #DO NOT DISABLE AUTOSCALE IF HANDING THIS A LIST TO PLOT MULTIPLE SUM PLOTS IT WILL CRASH AND ITS TOO MUCH EFFFORT TO FIX IT FOR NICHE USAGE
  print("Working...")

  if (is.list(phase_array)) { #for multiple sum plots I need a named list otherwise theres no way to know what to call the file.
    for (mineral in names(phase_array)) { #ierating names as iterating components loses the name which I need for the filepath
      filePath <- paste0(folder_path, "/", mineral, "_plot_scaled.svg") # paste0 for empty seperator, custom name based on column name

      ran <- one_plot(pix_dim, df_volperc, phase_array[[mineral]], filePath, autoscale = autoscale, scale_min, scale_max, alpha = alpha, call = FALSE)
      if (is.null(ran)) {
        print(paste(mineral, "not present."))
        phase_array[[mineral]] <- NULL
      }

    }

    print(sprintf("%s plots finished.", paste(names(phase_array), collapse = " ")))
  }
  else {
    for (phase in phase_array) { #interating names as iterating components loses the name which I need for the filepath

      filePath <- paste0(folder_path, "/", phase, "_plot_scaled.svg") # paste0 for empty seperator, custom name based on column name

      one_plot(pix_dim, df_volperc, phase, filePath, autoscale = autoscale, scale_min, scale_max, alpha = alpha, call = FALSE)
    }

    print(sprintf("%s plots finished.", paste(phase_array, collapse = " ")))
  }
}