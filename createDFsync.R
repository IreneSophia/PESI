# This function extracts synchrony and synchronisation values from an MEAlist.
# This MEAlist has to be the output of a MEAccf command which calculates these
# values. The names MEA objects in the input MEAlist will be separated into 
# columns using the separator sep and the column names in desc. For example, if 
# the name structure is "task_study_dyad" you can use the separator "_" and the 
# descriptor c("task", "study", "dyad") to create three columns.
# Input: 
#     * mea_ccf (MEAlist)
#     * sep (chr)         : separator for the names of the MEA objects
#     * desc (chr)        : column names for separated names columns
#
# The function has one output: 
#     * df (data frame)   : data frame including the effect sizes and interpretations
#
# (c) Irene Sophia Plank, 10plank@gmail.com
#

createDFsync = function(mea_ccf, sep, desc, fps) {
  
  library(tidyverse)
  
  if (!is.MEAlist(mea_ccf)) {
    stop("The entered object is not a MEAlist object!")
  }
  if (length(str_split(names(mea_ccf[1]), pattern = sep)[[1]]) != length(desc)) {
    stop("Check again your separator and your descriptor, there's a mismatch!")
  }
  
  spc    = c() # name of the mea object -> specification described by desc
  s1avg  = c() # average of positive lags
  s2avg  = c() # average of negative lags
  avg    = c() # average over all lags
  peak   = c() # peak of all lags
  s1peak = c() # peak of positive lags
  s2peak = c() # peak of negative lags
  zero   = c() # value at lag zero
  win    = c() # window
  s1mot  = c() # motion s1 in percent for whole video
  s2mot  = c() # motion s2 in percent for whole video
  winst  = c() # start of the respective window
  winen  = c() # end of the respective window
  
  # loop through mea objects
  for (j in 1:length(mea_ccf)) {
    
    this   = mea_ccf[[j]]
    nwin   = nrow(this[["ccf"]])
    spc    = c(spc, rep(names(mea_ccf[j]),nwin))
    
    # loop through the windows
    for (i in 1:nwin){
      peak = c(peak, max(this[["ccf"]][i,]))
      ncol = ncol(this[["ccf"]])/2
      s1peak = c(s1peak, max(this[["ccf"]][i,1:floor(ncol)]))
      s2peak = c(s2peak, max(this[["ccf"]][i,ceiling(ncol):(ncol*2)]))
      avg = c(avg, this[["ccfRes"]][["all_lags"]][i])
      s1avg = c(s1avg, this[["ccfRes"]][["s1_lead"]][i]) 
      s2avg = c(s2avg, this[["ccfRes"]][["s2_lead"]][i])
      zero = c(zero, this[["ccfRes"]][["lag_zero"]][i])
      win = c(win, i)
      winstart = this[["ccfRes"]][["winTimes"]][["start"]][i]
      wmin     = as.numeric(substr(winstart, 4,5))
      wsec     = as.numeric(substr(winstart, 7,8))
      rstart   = (wmin*60 + wsec)*fps
      winend   = this[["ccfRes"]][["winTimes"]][["end"]][i]
      wmin     = as.numeric(substr(winend, 4,5))
      wsec     = as.numeric(substr(winend, 7,8))
      rend     = ((wmin*60 + wsec)*fps)-1
      s1mot  = c(s1mot, (sum(this[["MEA"]][[1]][rstart:rend] > 0 | is.na(this[["MEA"]][[1]][rstart:rend])))/length(this[["MEA"]][[1]][rstart:rend]))
      s2mot  = c(s2mot, (sum(this[["MEA"]][[2]][rstart:rend] > 0 | is.na(this[["MEA"]][[2]][rstart:rend])))/length(this[["MEA"]][[2]][rstart:rend]))
      winst  = c(winst, winstart)
      winen  = c(winen, winend)
    }
  }
  
  # put everything in a dataframe and separate according to sep and desc
  df = data.frame(spc,win,s1mot,s2mot,peak,s1peak,s2peak,avg,s1avg,s2avg,zero, winst, winen) %>% 
    separate(spc, desc, sep = sep)
  
  df$fps = fps
  
  return(df)
  
}