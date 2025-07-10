#Don't delete these!
library(dplyr)
library(tidyr)
library(ggplot2)
library(colorBlindness)
library(svglite)
source("vol_perc_pix.R")
source("vol_write.R")

### PARAMS & SETUP ###
#use this to write your pixMap data to a cs
PS1_aligned <- align_phase_volumes("C:\\2024_MESc_Matthew_Leonard\\pseudosections\\PS1\\_DomMap100\\vol")
write.csv(PS1_aligned, "PS1_aligned.csv", row.names = FALSE)

#change these to the file location of the csv you made with vol_write for each sample.
# yourSample_volperc <- calculate_vol_percentages(read.csv("YourFileLocation"))

PS1_volperc <- calculate_vol_percentages(read.csv("C:\\2024_MESc_Matthew_Leonard\\pseudosections\\PS1_aligned.csv"))

# enter the length of your domino pixmap, eg. 50x50 or 100x100, only one of the lengths
pixmap_size <- 100

### PRE-DEFINED CONVENIENT INPUTS ###
# yourSample_ColumnNames <- colnames(yourSample_volperc)
PS1_column_names <- colnames(PS1_volperc) #pull all column names, pruned below

#Filters out non-phase columns to make easy list of every phase in a sample for mult_plots
# yourSample_all_phases <- yourSample_column_names[!grepl("Index|solids|tot|^perc", yourSample_column_names)]
PS1all_phases <- PS1_column_names[!grepl("Index|solids|tot|^perc", PS1_column_names)]

#some generic mineral groups for a plot of vol_amp, vol_bio, etc., this is all phases in the main T-D databases
#you don't need to remove the phases you don't have, it won't plot them if they're not present
AlSi <- c("and", "ky", "sill")
amp <- c("tr", "tsm", "prgm", "glm", "cumm", "grnm", "a", "b", "mrb", "kprg", "tts")
bio <- c("annm", "east", "phl", "obi", "tbi", "fbi", "mmbi")
chl <- c("ames", "daph", "clin", "afchl", "ochl1", "ochl4", "f3clin", "mmchl")
cpx <- c("acmm1", "cfm", "di", "hed", "jac", "jd", "om")
crd <- c("crd", "fcrd", "hcrd", "mncd")
epi <- c("cz", "ep", "fep")
fld <- c("ab", "an", "san")
grt <- c("py", "alm", "spss", "gr", "kho")
ilhem <- c("oilm1", "dilm1", "dhem1", "oilm", "dilm", "dhem")
all_liquid <- c("q4L", "abL", "kspL", "anL", "slL", "fo2L", "fa2L", "h2oL")
dry_liquid <- c("q4L", "abL", "kspL", "anL", "slL", "fo2L", "fa2L") #melt phases without h2o volume added.
mag <- c("imt", "dmt", "usp")
opx <- c("en", "fs", "fm", "mgts", "fopx", "mnopx", "odi")
oxides <- c("oilm1", "dilm1", "dhem1", "oilm", "dilm", "dhem", "imt", "dimt", "usp")
plg <- c("ab", "an")
st <- c("mstm", "fst", "mnstm", "msto", "mstt")
w_mica <- c("mu", "cel", "fcel", "pa", "mat", "fmu1")

#Above in a single variable for running through mult_plots. Name/key assigned to each group (on left) will be used for the filename.
all_groups <- list(cordierite = crd, plagioclase = plg, feldspar = fld, garnet = grt, all_liquid = all_liquid, dry_liquid = dry_liquid,
                chlorite = chl, AlSilicate = AlSi, amphibole = amp, biotite = bio, clinopyroxene = cpx, epidote = epi, magnetite = mag,
                ilmenite_haematite = ilhem, orthopyroxene = opx, oxides = oxides, staurolite = st, white_mica = w_mica)
#if making your own, it must be list() and not c(), c() will concatenate
#list variables need to have a name otherwise it will not work through mult_plots.

### USAGE EXAMPLES ###
#one_plot will take every phase given and plot them on a single plot. E.G:
#just a plot of ab, with a custom scale.
one_plot(pixmap_size, PS1_volperc, "ab", "C:\\Users\\Matthew\\Desktop\\TestFolder\\ab_plot.svg", scale_min = 10, scale_max = 90)
#a plot of ky + sill
one_plot(pixmap_size, PS1_volperc, c("ky", "sill"), "C:/Users/Matthew/Desktop/TestFolder/ky_sill_plot.svg", autoscale = TRUE)
# a plot of every oxide (haem, ilm, mag, usp)
one_plot(pixmap_size, PS1_volperc, oxides, "C:\\Users\\Matthew\\Desktop\\TestFolder\\oxides_plot.svg", autoscale = TRUE, alpha = TRUE)
#comment these out or delete them before you use your own!

#mult_plots is probably all you're after.
#In the back it just calls one_plot for every single item in an array it's handed (which can be an array of arrays for multiple sum plots).
#usage is essentially the same as one_plot with some small differences:
#two plots, one of an and one of ab
mult_plots(pixmap_size, PS1_volperc, c("an", "ab"), "C:/Users/Matthew/Desktop/TestFolder/mults", autoscale = TRUE, alpha = TRUE)
#one plot per bio phase, if it's asked for phases it can't find it just won't plot them.
mult_plots(pixmap_size, PS1_volperc, bio, "C:/Users/Matthew/Desktop/TestFolder/mults")
#one plot for every phase, using the predefined array (make your own, go to line 13!)
mult_plots(pixmap_size, PS1_volperc, PS1all_phases, "C:/Users/Matthew/Desktop/TestFolder/all phases")
#two plots, one of ky + sill, and another of ab + an. Must be a list and must be named. Name will be used as filename.
mult_plots(pixmap_size, PS1_volperc, list(kySil = c("ky", "sill"), plg = c("ab", "an")), "C:/Users/Matthew/Desktop/TestFolder/sums", scale_min = 0, scale_max = 70, alpha = TRUE)
#multiple plots of each mineral group
mult_plots(pixmap_size, PS1_volperc, all_groups, "C:/Users/Matthew/Desktop/TestFolder/sums", autoscale = TRUE)