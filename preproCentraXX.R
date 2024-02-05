# Load packages 
library(tidyverse)

# Clear global environment
rm(list=ls())
setwd("/home/emba/Documents/PESI/BVET")

# load raw data
# columns of Interest: internalStudyMemberID, name2, code, value, section, (valueIndex), numericValue
df = read_csv("PEMA_20240201.csv", show_col_types = F, locale = locale(encoding = "ISO-8859-1")) %>%
  select(internalStudyMemberID, date, name2, code, value, section, numericValue) %>%
  filter(internalStudyMemberID != "NEVIA_test" & 
           !is.na(name2)) %>%
  rename("questionnaire" = "name2", 
         "item" = "code", 
         "subID" = "internalStudyMemberID") %>%
  mutate(
    value = str_replace(value, ",", ";")
  ) %>% 
  filter(substr(subID,1,4) != "PESI") %>%                                      # filter out pilots
  group_by(subID)

## date of testing
df.date = df %>%
  group_by(subID) %>%
  summarise(
    date = min(date, na.rm = T)
  )

## preprocess each questionnaire separately:

# PSY_NEVIA_BDI 
# (10 bis 19: leichtes depressives Syndrom, 20 bis 29: mittelgradiges, >= 30: schweres)
df.bdi = df %>% filter(questionnaire == "PSY_NEVIA_BDI_v2")  %>%
  select(questionnaire, subID, numericValue) %>%
  group_by(subID) %>%
  summarise(
    BDI_total = sum(numericValue, na.rm = T)
  )

# PSY_NEVIA_CFT
df.cft = df %>% filter(questionnaire == "PSY_NEVIA_CFT") %>% 
  group_by(subID) %>%
  select(-c(questionnaire, section, numericValue)) %>%
  rename("raw" = `value`) %>%
  mutate(
    item = gsub("^PSY_PIPS_", "", item), 
    score = case_when(
      raw == 'd' & item == 'CFT_1_1' ~ 1, raw == 'b' & item == 'CFT_1_2' ~ 1,raw == 'e' & item == 'CFT_1_3' ~ 1,
      raw == 'a' & item == 'CFT_1_4' ~ 1, raw == 'e' & item == 'CFT_1_5' ~ 1, raw == 'b' & item == 'CFT_1_6' ~ 1, 
      raw == 'c' & item == 'CFT_1_7' ~ 1, raw == 'c' & item == 'CFT_1_8' ~ 1, raw == 'd' & item == 'CFT_1_9' ~ 1, 
      raw == 'a' & item == 'CFT_1_10' ~ 1, raw == 'b' & item == 'CFT_1_11' ~ 1, raw == 'a' & item == 'CFT_1_12' ~ 1, 
      raw == 'c' & item == 'CFT_1_13' ~ 1, raw == 'd' & item == 'CFT_1_14' ~ 1, raw == 'e' & item == 'CFT_1_15' ~ 1, 
      raw == 'd' & item == 'CFT_2_1' ~ 1, raw == 'a' & item == 'CFT_2_2' ~ 1, raw == 'b' & item == 'CFT_2_3' ~ 1, 
      raw == 'a' & item == 'CFT_2_4' ~ 1, raw == 'e' & item == 'CFT_2_5' ~ 1, raw == 'c' & item == 'CFT_2_6' ~ 1, 
      raw == 'b' & item == 'CFT_2_7' ~ 1, raw == 'a' & item == 'CFT_2_8' ~ 1, raw == 'c' & item == 'CFT_2_9' ~ 1, 
      raw == 'e' & item == 'CFT_2_10' ~ 1, raw == 'c' & item == 'CFT_2_11' ~ 1, raw == 'e' & item == 'CFT_2_12' ~ 1, 
      raw == 'd' & item == 'CFT_2_13' ~ 1, raw == 'd' & item == 'CFT_2_14' ~ 1, raw == 'b' & item == 'CFT_2_15' ~ 1, 
      raw == 'b' & item == 'CFT_3_1' ~ 1, raw == 'c' & item == 'CFT_3_2' ~ 1, raw == 'b' & item == 'CFT_3_3' ~ 1, 
      raw == 'd' & item == 'CFT_3_4' ~ 1, raw == 'b' & item == 'CFT_3_5' ~ 1, raw == 'a' & item == 'CFT_3_6' ~ 1, 
      raw == 'e' & item == 'CFT_3_7' ~ 1, raw == 'd' & item == 'CFT_3_8' ~ 1, raw == 'c' & item == 'CFT_3_9' ~ 1, 
      raw == 'a' & item == 'CFT_3_10' ~ 1, raw == 'e' & item == 'CFT_3_11' ~ 1, raw == 'c' & item == 'CFT_3_12' ~ 1, 
      raw == 'd' & item == 'CFT_3_13' ~ 1, raw == 'e' & item == 'CFT_3_14' ~ 1, raw == 'a' & item == 'CFT_3_15' ~ 1, 
      raw == 'd' & item == 'CFT_4_1' ~ 1, raw == 'b' & item == 'CFT_4_2' ~ 1, raw == 'e' & item == 'CFT_4_3' ~ 1, 
      raw == 'b' & item == 'CFT_4_4' ~ 1, raw == 'c' & item == 'CFT_4_5' ~ 1, raw == 'a' & item == 'CFT_4_6' ~ 1, 
      raw == 'd' & item == 'CFT_4_7' ~ 1, raw == 'a' & item == 'CFT_4_8' ~ 1, raw == 'a' & item == 'CFT_4_9' ~ 1, 
      raw == 'c' & item == 'CFT_4_10' ~ 1, raw == 'e' & item == 'CFT_4_11' ~ 1, TRUE ~ 0
    )
  ) %>% summarise(
    CFT_total = sum(score)
  )

# PSY_NEVIA_DEMO_PESI

df.demo = df %>% filter(questionnaire == "PSY_NEVIA_DEMO_PESI") %>%
  mutate(
    item = recode(item, 
                  `PSY_PIPS_Demo_Alter/age` = "age",
                  `PSY_NEVIA_DEMO_gender` = "gender",
                  `PSY_NEVIA_DEMO_Geschlechtsidentität` = "cis",
                  `PSY_PIPS_Demo_Diagnose/diagnosis` = "ASD",
                  `PSY_PIPS_Demo_seit/since` = "since",
                  `PSY_NEVIA_DEMO_code` = "ASDcode",
                  `PSY_NEVIA_DEMO_familyASD` = "ASDfamily",
                  `PSY_NEVIA_DEMO_diagnoseADHD` = "ADHD",
                  `PSY_NEVIA_DEMO_seit2` = "ADHDsince",
                  `PSY_NEVIA_DEMO_familyADHD` = "ADHDfamily",
                  `PSY_NEVIA_DEMO_diagcode2` = "ADHDcode",
                  `PSY_PIPS_DEMO_DISEASES_1` = "physDisease",
                  `PSY_PIPS_DEMO_DISEASES_2` = "psychDisease",
                  `PSY_PIPS_DEMO_MEDICATION` = "meds", 
                  `PSY_PIPS_Demo_Rauchen/smoking` = "smoking",
                  `PSY_PIPS_DEMO_NIKOTIN_1` = "smoking_quantity",
                  `PSY_PIPS_Demo_Alkohol/alcohol` = "alcohol",
                  `PSY_PIPS_DEMO_ALKOHOL_1` = "alcohol_quantity",
                  `PSY_NEVIA_DEMO_edu` = "edu",
                  `PSY_PIPS_Demo_Sehhilfe/glasses` = "vision", 
                  `PSY_NEVIA_DEMO_handedness` = "handedness"),
    value = gsub("^(Keine|Nein|keine).*", "0", value),
    value = gsub("^Ja", "1", value)
  )

df.demo[!is.na(df.demo$numericValue),]$value = as.character(df.demo[!is.na(df.demo$numericValue),]$numericValue)

df.demo = df.demo %>%
  group_by(subID) %>% select(subID, item, value) %>%
  pivot_wider(names_from = item, values_from = value)

# PSY_NEVIA_Ishihara_Landolt
df.ish = df %>% filter(questionnaire == "PSY_NEVIA_Ishihara_Landolt") %>%
  filter(!grepl("text", item, fixed = TRUE)) %>%
  group_by(subID) %>% select(subID, numericValue) %>%
  summarise(
    ISH_total = sum(numericValue, na.rm = T)
  )

# PSY_NEVIA_RAADS-14
df.raads = df %>% filter(questionnaire == "PSY_NEVIA_RAADS-14") %>%
  mutate(
    numericValue = recode(value, 
           `Nur wahr als ich < 16 J. alt war` = 1,
           `Nur jetzt wahr` = 2,
           `Wahr jetzt und als ich jung war` = 3,
           `Nicht wahr` = 0),
    section = gsub("^Abschnitt ", "", section),
    item = gsub("^PSY_NEVIA_RAADS_", "", item)
  ) %>% group_by(subID) %>% 
  select(subID, item, section, numericValue)

# some need to be turned around: [!ADD]
idx = c(1, 6, 11, 23, 26, 33, 37, 43, 47, 48, 53, 58, 62, 68, 72, 77)
df.raads[df.raads$item %in% idx,]$numericValue = abs(df.raads[df.raads$item %in% idx,]$numericValue - max(df.raads$numericValue, na.rm = T) + min(df.raads$numericValue, na.rm = T))

df.raads = df.raads %>% group_by(subID) %>%
  summarise(
    RAADS_total = sum(numericValue, na.rm = T)
  )

# PSY_NEVIA_STAI_trait 
df.stait = df %>% filter(questionnaire == "PSY_NEVIA_STAI_trait") %>% 
  mutate(item = as.numeric(gsub("\\D", "", item)),
         value = as.numeric(value))

# some need to be turned around [!ADD: recode some of the questions?]
idx = c(3, 4, 7)
df.stait[df.stait$item %in% idx,]$value = abs(df.stait[df.stait$item %in% idx,]$value - (max(df.stait$value, na.rm = T) + min(df.stait$value, na.rm = T)))

df.stait = df.stait %>% group_by(subID) %>%
  summarise(
    STAITT_total = sum(value, na.rm = T)
  )

# PSY_NEVIA_UI 
df.ui = df %>% filter(questionnaire == "PSY_NEVIA_UI") %>% 
  group_by(subID) %>%
  summarise(
    UI_total = sum(as.numeric(value))
  )

# PSY_NEVIA_d2 
df.d2 = df %>% filter(questionnaire == "PSY_NEVIA_d2") %>% 
  group_by(subID) %>%
  summarise(
    D2_total = sum(as.numeric(value))
  )

# merge all together
ls.df = list(df.date, df.demo, df.cft, df.bdi, df.stait, df.raads, df.ish, df.ui, df.d2)
df.sub = ls.df %>% reduce(full_join, by = "subID") %>% 
  mutate(
    age = case_when(
      nchar(age) > 5 ~ 26, # hard code age of one person
      T ~ as.numeric(gsub("\\D", "", age))
    ),
    ASD = if_else(is.na(ASD), 0, as.numeric(ASD))
  )

# add iq scores
cft = read_delim("CFT-norms.csv", show_col_types = F, delim = ";")
df.sub$CFT_iq = NA
for (i in 1:nrow(df.sub)) {
  if (df.sub$CFT_total[i] >= 9 & !is.na(df.sub$CFT_total[i]) & !is.na(df.sub$age[i]) & df.sub$age[i] >= 16 & df.sub$age[i] <= 60) {
    df.sub$CFT_iq[i] = cft[(df.sub$age[i] >= cft$lower & df.sub$age[i] <= cft$upper & df.sub$CFT_total[i] == cft$raw),]$iq
  }
}

# load csv with subIDs and IQs from other studies [!MISSING]
#df.iqs = read_delim(file = paste("subID_iq.csv", sep = "/"), show_col_types = F) %>%
#  select(subID, MWT_iq, CFT_iq) %>% drop_na()

# update our df.sub with these values
#df.sub = rows_update(df.sub, df.iqs) 

# check if there are still IQ values missing
if (nrow(df.sub %>% filter(is.na(CFT_iq))) > 0) {
  warning('There are still IQ values missing!')
  # save csv with subIDs where we need the iq values from other studies
  write_csv(df.sub %>% filter(is.na(CFT_iq)) %>% select(subID), file = "subID_iq_missing.csv")
}

# categorise the groups and gender
df.sub = df.sub %>%
  mutate(
    diagnosis = as.factor(case_when(
      ASD  == 1 ~ "ASD",
      ADHD == 1 ~ "ADHD",
      TRUE ~ "CTR"
    )),
    gender_desc = gender,
    gender = as.factor(case_when(
      grepl("männlich|male|m", gender_desc, ignore.case = TRUE) ~ "mal",
      grepl("weiblich|female|w|f", gender_desc, ignore.case = TRUE) ~"fem",
      TRUE ~ "dan")
    )
  ) %>%
  relocate(subID, diagnosis, gender) %>%
  rename("subID" = "subID")

# check if someone has to be excluded
nrow(df.sub %>% filter(CFT_iq <= 70))

# save everything
write_csv(df.sub, file = "PESI_centraXX.csv")
