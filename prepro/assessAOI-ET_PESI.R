# Load packages 
library(tidyverse)
library(readODS)

# Clear global environment
setwd('..')
rm(list=ls())

# set file paths
fl.path = '/media/emba/emba-2/PESI'
dt.path = paste(fl.path, 'BVET', sep = "/")

# Fixations ---------------------------------------------------------------

# radius of AOIs
r_head = 60*1.75
r_hand = 40*1.75

# create a function to convert pixels from pictures to pixels of presentation
# on screen during experiment
convertX2screen = function(x){
  # pictures were presented 1.75 times the original size, 
  # starting 288 pixels to the right of the left screen border
  screenX = x*1.75 + 288
  return(screenX)
}
convertY2screen = function(y){
  # pictures were presented 1.75 times the original size, 
  # starting 164 pixels above the upper screen border
  screenY = y * 1.75 - 164
  return(screenY)
}

# read in all the AOI information for heads and hands
df.AOIs = list.files(path = './AOIs', pattern = "PESI.*0.csv", full.names = T) %>%
  setNames(nm = .) %>%
  map_df(~read_csv(., show_col_types = F), .id = "fln") %>%
  # rename so that it fits the fixation data frames
  mutate(
    on_trialPic = frame + 1,
    on_trialVid = gsub(".*AOIs/(.+).csv", "\\1", fln)
  ) %>%
  # only keep relevant columns for the AOIs
  select(on_trialVid, on_trialPic, 
         indiv1.Face_x, indiv1.Face_y, 
         indiv1.HandL_x, indiv1.HandL_y, indiv1.HandR_x, indiv1.HandR_y, 
         indiv2.Face_x, indiv2.Face_y, 
         indiv2.HandL_x, indiv2.HandL_y, indiv2.HandR_x, indiv2.HandR_y) %>%
  # calculate pixels with respect to actual presentation on screen
  mutate(
    across(
      .cols = starts_with("indiv") & ends_with("x"),
      .fns  = convertX2screen
    )
  ) %>%
  mutate(
    across(
      .cols = starts_with("indiv") & ends_with("y"),
      .fns  = convertY2screen
    )
  ) 

# read in all the AOI information for bodies
ls.files = list.files(path = './AOIs', pattern = "PESI.*body.csv", full.names = T) 
ls.bodyAOIs = vector(mode='list', length = length(ls.files))
for (i in 1:length(ls.files)) {
  ls.bodyAOIs[[i]] = as.matrix(read_csv(ls.files[i], show_col_types = F, col_names = F))
  names(ls.bodyAOIs)[i] = gsub(".*AOIs/(.+)_body.csv", "\\1", ls.files[i])
}

# get the preprocessed fixation data
df.fix = list.files(path = dt.path, pattern = "PESI.*_fixations.csv", full.names = T) %>%
  setNames(nm = .) %>%
  map_df(~read_csv(., show_col_types = F), .id = "fln") %>%
  # get the subID from the filename 
  mutate(
    subID = gsub(".*PESI-ET-(.+)_fixations.csv", "\\1", fln)
  ) 

# get the original subIDs
subIDs = unique(df.fix$subID)

# start selecting relevant fixations
df.fix = df.fix %>%
  # only keep saccades within screen area
  filter(meanX_pix <= 1920 & meanY_pix <= 1080) %>%
  # only keep saccades starting and ending during trials
  filter(!is.na(on_trialNo) & !is.na(off_trialNo)) %>%
  # only keep relevant columns
  select(subID, run, eye, duration, meanX_pix, meanY_pix, on_trialNo, on_trialPic, on_trialVid, 
         off_trialNo, off_trialPic, off_trialVid) %>%
  # merge with AOI information
  merge(., df.AOIs, all.x = T) %>%
  arrange(on_trialVid, on_trialPic) %>%
  # create boolean values whether this fixation is in head and/or hand AOI
  mutate(
    # fixation in radius of head of left individual
    on_headAOI1 = if_else(
      sqrt((meanX_pix - indiv1.Face_x)**2 + (meanY_pix - indiv1.Face_y)**2) <= r_head, 
      TRUE, FALSE
    ),
    # fixation in radius of head of right individual
    on_headAOI2 = if_else(
      sqrt((meanX_pix - indiv2.Face_x)**2 + (meanY_pix - indiv2.Face_y)**2) <= r_head, 
      TRUE, FALSE
    ),
    # fixation in radius of head of any of the two individuals
    on_headAOI = if_else(on_headAOI1 | on_headAOI2, TRUE, FALSE),
    # fixation in radius of hands of left individual
    on_handAOI1 = case_when(
      sqrt((meanX_pix - indiv1.HandL_x)**2 + (meanY_pix - indiv1.HandL_y)**2) <= r_hand ~ TRUE, 
      sqrt((meanX_pix - indiv1.HandR_x)**2 + (meanY_pix - indiv1.HandR_y)**2) <= r_hand ~ TRUE, 
      T ~ FALSE
    ),
    # fixation in radius of hands of right individual
    on_handAOI2 = case_when(
      sqrt((meanX_pix - indiv2.HandL_x)**2 + (meanY_pix - indiv2.HandL_y)**2) <= r_hand ~ TRUE, 
      sqrt((meanX_pix - indiv2.HandR_x)**2 + (meanY_pix - indiv2.HandR_y)**2) <= r_hand ~ TRUE, 
      T ~ FALSE
    ),
    # fixation in radius of hands of any of the two individuals
    on_handAOI = if_else(on_handAOI1 | on_handAOI2, TRUE, FALSE),
    # fixation on any of the AOIs
    on_eitherAOI = if_else(on_handAOI | on_headAOI, TRUE, FALSE),
    # get dyad of the videos
    dyad = gsub("_0.*", "", on_trialVid)
  )

# check which subjects do not have any relevant saccades
setdiff(subIDs, unique(df.fix$subID))

# now, we loop through the remaining fixations and check
# whether they are in the body AOI
idx = which(!df.fix$on_eitherAOI)
df.fix$on_bodyAOI = F
for (i in idx) {
  xPic = round((df.fix$meanX_pix[i]-288)/1.75)
  yPic = round((df.fix$meanY_pix[i]+164)/1.75)
  if (xPic > 0 & xPic <=  768 & yPic > 0 & yPic <= 576) {
    df.fix$on_bodyAOI[i]  = ls.bodyAOIs[[df.fix$dyad[i]]][yPic,xPic] == 255
  }
}
  
# aggregate the fixations 
df.fix.dur = df.fix %>% 
  group_by(subID, on_trialVid, run, eye, on_trialNo) %>%
  summarise(
    fix.total     = sum(duration),
    head  = sum(duration[on_headAOI == TRUE]),
    hand  = sum(duration[on_handAOI == TRUE]),
    body  = sum(duration[on_bodyAOI == TRUE])
  ) %>% pivot_longer(cols = c(head, hand, body), values_to = "fix.dur", names_to = "AOI")

df.fix = df.fix %>% 
  group_by(subID, on_trialVid, run, eye, on_trialNo) %>%
  summarise(
    n.total = n(),
    head  = sum(on_headAOI == TRUE),
    hand  = sum(on_handAOI == TRUE),
    body  = sum(on_bodyAOI == TRUE)
  ) %>% pivot_longer(cols = c(head, hand, body), values_to = "count", names_to = "AOI") %>%
  merge(., df.fix.dur)

# save the data
saveRDS(df.fix, file.path(dt.path, "PESI-ET_fix.rds"))

# Saccades ----------------------------------------------------------------     

# get the preprocessed fixation data
df.sac = list.files(path = dt.path, pattern = "PESI.*_saccades.csv", full.names = T) %>%
  setNames(nm = .) %>%
  map_df(~read_csv(., show_col_types = F), .id = "fln") %>%
  # get the subID from the filename 
  mutate(
    subID = gsub(".*PESI-ET-(.+)_saccades.csv", "\\1", fln)
  ) %>%
  # only keep saccades starting during trials
  filter(!is.na(on_trialNo)) %>%
  select(subID, on_trialNo, on_trialVid, run, eye)

# aggregate the number of saccades
df.sac.agg = df.sac %>%
  group_by(subID, on_trialNo, on_trialVid) %>%
  summarise(
    n.sac = n()
  )

# save the data
saveRDS(df.sac.agg, file.path(dt.path, "PESI-ET_sac.rds"))
