## TD-PixPlotR
An R program created alongside Stanley Upton to produce vol% phase maps from Theriak-Domino's pixmap data. All credit to Stanley for the original implementation and idea, I've simply improved the codebase.

Maps are produced without axes as they're intended to supplement a psuedosection. The files should be exactly the same dimensions as a T-D psuedosection, but some slight scaling may be necessary. If you'd like to make them with axes you can adjust that yourself in one_plot in vol_perc_pix.R if you're familiar with using ggplot. The pixmap files don't contain any P/T information, so it will all need manual entering (hence not supporting it already, it would require a lot of parameters being passed!).
Following the style of pixmaps from T-D, they will give a broad overview of phase vol%. If you want to pick specific values out of the map, consider using the isolines built into T-D. 

## Dependencies
You'll need a copy of R: https://www.r-project.org/ , as well as the dplyr, tidyr, ggplot2, svglite, and colorBlindness libraries:

https://cran.r-project.org/package=dplyr

https://cran.r-project.org/package=tidyr

https://cran.r-project.org/package=ggplot2

https://cran.r-project.org/package=svglite

https://cran.r-project.org/package=colorBlindness

Tested on R 4.4.3 in PyCharm.

## Use:
The user should work wholly within main.R, vol_write.R and vol_perc_pix.R just serve to hold functions. Make sure they're all in the same folder when you run it otherwise main won't be able to find the other files!

1. Once your T-D pixmap has been generated copy and paste all of the files beginning with vol_ (e.g. vol_[gr], vol_tot, vol_solids etc.) into a seperate folder. While the program shouldn't accept anything else (currently only vol is accepted but it could easily be modified to do other plots if you like), this just ensures there are no erroneous data going into the plot. To avoid causing problems in T-D it's best to do this outside of the original map folder.
  
2. At the top of main.R you'll find:

```r
PS1_aligned <- align_phase_volumes("E:\\2024_MESc_Matthew_Leonard\\pseudosections\\PS1\\_DomMap100\\vol")
write.csv(PS1_aligned, "PS1_aligned.csv", row.names = FALSE)
```

  Edit that code to point to the file location of your vol_ folder, change the variable name to something suitable, and adjust the csv name as needed. A nice side effect of this is you now have a handy csv        with all your vol data per phase, that you can import into excel if you wish. Write this out as many times as you have samples.

3. Adjust the next line to then read in the csvs like so:

```r
yourSample_volperc <- calculate_vol_percentages(read.csv("YourFileLocation"))
```

4. Then adjust pixmap_size to be whatever size you've generated them in T-D.
  
5. What follows are some lines of code to produce some useful inputs. You'll need to adjust (and duplicate as necessary) these two lines to match your samples:

```r
PS1_column_names <- colnames(PS1_volperc)
PS1all_phases <- PS1column_names[!grepl("Index|solids|tot|^perc", PS1column_names)]
```

  They are just setting up a list of every single phase within the sample, which I find extremely handy. The others don't need to be changed, unless you're using a T-D database with some weird phases -            you may want to add those to the mineral groups.

6. Included also are some example usages of the program. There are two functions - one_plot and mult_plots which will produce one plot or multiple plots respectively. Comment out or delete these examples before you run it!

## one_plot
In the backend, one_plot looks like this:
```r
one_plot <- function(pix_dim, df_volperc, phase_array, save_path = NULL, autoscale = FALSE, scale_min = 0, scale_max = 100, alpha = FALSE)
```
The first four parameters are essential, and the rest are optional. Everything passed to one_plot through phase_array will be summed and plotted on one plot! 
### pix_dim
This should always be input as the pixmap_size variable you defined earlier.
### df_volperc
Pass this the variable you read your sample csv into earlier in step 3 (yourSample_volperc). In the example code that is PS1_volperc.
### phase_array
Give a single phase name as a string, or an array of phase names as strings (e.g. "ab", or c("ab", "an")). The mineral presets are useful here too, e.g. grt. No quotes, its a variable not a string.
### save_path
A string containing the filepath. Be careful with \\ or / here, it will depend on your OS. If you're on mac use /, if on windows use \\ or /. Windows users, when copy pasting a file-path please ensure you change **all** instances of \ to \\ or / (single \ is a special character in R strings). When using one_plot you must include a filename at the end of the filepath, including .svg.
### autoscale
This is a simple TRUE or FALSE variable. If you don't enter a value it will default to FALSE, write autoscale = TRUE to enable it. Enabling autoscale will cause the scale of the plot to be clipped to the minimum and maximum values on the plot which will give the best resolution in the colour scale. I don't recommend using this if you want to compare one phase to another as the scales will be different!
### scale_min
Takes a value to set the minimum point of the scale, with autoscale enabled this value is ignored. By default it is set to 0 (%), write scale_min = X where X = some number less than scale_max.
### scale_max
Takes a value to set the maximum point of the scale, with autoscale enabled this value is ignored. By default it is set to 100 (%), write scale_max = X where X = some number greater than scale_min.
### alpha
Enabling alpha will cause 0 values to be set to transparent. By default it is set to FALSE, write alpha = TRUE to enable. I find enabling alpha makes the plots much more readable.

### Examples
```r
#just a plot of ab, with a custom scale.
one_plot(pixmap_size, PS1_volperc, "ab", "C:\\Users\\Matthew\\Desktop\\TestFolder\\ab_plot.svg", scaleMin = 10, scaleMax = 90)

#a plot of ky + sill using autoscaling.
one_plot(pixmap_size, PS1_volperc, c("ky", "sill"), "C:/Users/Matthew/Desktop/TestFolder/ky_sill_plot.svg", autoscale = TRUE)

#a plot using the oxides preset (haem + ilm + mag + usp) with alpha enabled.
one_plot(pixmap_size, PS1_volperc, oxides, "C:\\Users\\Matthew\\Desktop\\TestFolder\\oxides_plot.svg", autoscale = TRUE, alpha = TRUE)
```

## mult_plot
In the backend, mult_plot just calls one_plot multiple times. This means usage is pretty similar, with some differences in what data you actually hand to it:
```r
mult_plots <- function(pix_dim, df_volperc, phase_array, folder_path = NULL, autoscale = FALSE, scale_min = 0, scale_max = 100, alpha = FALSE)
```
### phase_array
mult_plots handles this input slightly differently to one_plot. If you pass it an array of phases, e.g. c("ab", "an") it will produce two plots, one of "ab" and one of "an", rather than a plot with the two summed. The phase name is used as the file name for each plot. To create multiple sum plots at once you can pass it a list of arrays, e.g. list(kySil = c("ky", "sill"), plg = c("ab", "an")). It's important a name is attached to them (the "kySil =" bit) as this is how the file name is generated for these sum plots. The yourSample_all_phases defined in step 5 comes in handy here, and can be used to create one plot per phase present in your sample. all_groups is also useful for creating a plot for each mineral, rather than each phase.
### folder_path
As multiple plots are being generated you cannot provide a file name within the path like in one_plot. Please provide **only** the path to the folder you want them saved in, with no filename. How the filenames are generated is described above.
### scale_min, scale_max, and autoscale
In mult_plots, the values for scale_min and scale_max will be applied to every single plot. Autoscaling, if enabled, will occur for each plot individually. It's not possible to assign a custom scale on a per plot basis within a single call of mult_plots.

### Examples
```r
#two plots, one of an and one of ab
mult_plots(pixmap_size, PS1_volperc, c("an", "ab"), "C:/Users/Matthew/Desktop/TestFolder/mults", autoscale = TRUE, alpha = TRUE)

#one plot per bio phase, if it's asked for phases it can't find it just won't plot them.
mult_plots(pixmap_size, PS1_volperc, bio, "C:/Users/Matthew/Desktop/TestFolder/mults")

#one plot for every phase, using the predefined array
mult_plots(pixmap_size, PS1_volperc, PS1all_phases, "C:/Users/Matthew/Desktop/TestFolder/all phases")

#two plots, one of ky + sill, and another of ab + an. Must be a list and must be named. Name will be used as filename.
mult_plots(pixmap_size, PS1_volperc, list(kySil = c("ky", "sill"), plg = c("ab", "an")), "C:/Users/Matthew/Desktop/TestFolder/sums", scale_min = 0, scale_max = 70, alpha = TRUE)

#multiple plots of each mineral group
mult_plots(pixmap_size, PS1_volperc, all_groups, "C:/Users/Matthew/Desktop/TestFolder/sums", autoscale = TRUE)
```
