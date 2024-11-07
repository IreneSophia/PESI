ls.packages = c("knitr",            # kable
                "brms",             # Bayesian lmms
                "tidyverse",        # tibble stuff
                "SBC"               # plots for checking computational faithfulness
)

lapply(ls.packages, library, character.only=TRUE)

# set cores
options(mc.cores = parallel::detectCores())

setwd('..')

# settings for the SBC package
use_cmdstanr = getOption("SBC.vignettes_cmdstanr", TRUE) # Set to false to use rst
options(brms.backend = "cmdstanr")
cache_dir = "./_brms_SBC_cache"
if(!dir.exists(cache_dir)) {
  dir.create(cache_dir)
}

# Using parallel processing
library(future)

# get demographic information
load("PESI_data.RData")

# aggregate
df.fix.agg = df.fix %>% 
  group_by(subID, diagnosis, dyad, sync, dyad.type, AOI) %>%
  summarise(
    fix.dur   = median(fix.dur, na.rm = T),
    fix.total = median(fix.total),
    fix.prop  = fix.dur*100/fix.total
  ) %>% ungroup() %>%
  mutate_if(is.character, as.factor)
  
# set the contrasts
contrasts(df.fix.agg$dyad.type) = contr.sum(2)
contrasts(df.fix.agg$diagnosis) = contr.sum(2)
contrasts(df.fix.agg$sync)      = contr.sum(2)
contrasts(df.fix.agg$AOI)       = contr.sum(3)[c(3,2,1),]

# number of simulations
nsim = 500

# set number of iterations and warmup for models
iter = 4500
warm = 1500

# set formula considering all combinations
code   = "PESI_fix"
f.fix = brms::bf(fix.prop ~ diagnosis * sync * dyad.type * AOI
                 + (dyad.type * sync * AOI | subID) 
                 + (diagnosis * sync * AOI | dyad))

# check whether the slopes are set correctly
df.fix.agg %>% count(subID, dyad.type, sync, AOI)
df.fix.agg %>% count(dyad, diagnosis, sync, AOI)

# set weakly informed priors
priors = c(
  # three AOIs, therefore, intercept expected to be around 33%
  prior(normal(33, 11), class = Intercept), 
  prior(normal(11, 11), class = sigma), # 1/3 of the Intercept
  prior(normal(5,   5), class = sd),
  prior(lkj(2)        , class = cor),
  prior(normal(0,  10), class = b)
)

# get number which have been created already
ls.files = list.files(path = cache_dir, pattern = sprintf("res_%s_.*", code))
if (is_empty(ls.files)) {
  i = 1
} else {
  i = max(readr::parse_number(ls.files)) + 1
}

m = 10

# create the data and the results
gen  = SBC_generator_brms(f.fix, data = df.fix.agg, prior = priors,
                          thin = 50, warmup = 20000, refresh = 2000)
if (!file.exists(file.path(cache_dir, paste0("dat_", code, ".rds")))){
  set.seed(2469)
  dat = generate_datasets(gen, nsim) 
  saveRDS(dat, file = file.path(cache_dir, paste0("dat_", code, ".rds")))
} else {
  dat = readRDS(file = file.path(cache_dir, paste0("dat_", code, ".rds")))
}

# set seed
set.seed(248+i) 

write(sprintf('%s: %s %d', lubridate::now(), code, i), sprintf("%slog_%s.txt", 
                                                               "/home/emba/Insync/10planki@gmail.com/Google Drive/NEVIA/logfiles/",
                                                               code), append = TRUE)

bck = SBC_backend_brms_from_generator(gen, chains = 4, thin = 1,
                                      init = 0.1, warmup = warm, iter = iter)
plan(multisession)
print("start res")
res = compute_SBC(SBC_datasets(dat$variables[((i-1)*m + 1):(i*m),], 
                               dat$generated[((i-1)*m + 1):(i*m)]), 
                  bck,
                  cache_mode     = "results", 
                  cache_location = file.path(cache_dir, sprintf("res_%s_%02d", code, i)))
                  
write(sprintf('%s: DONE %d', lubridate::now(), i), sprintf("%slog_%s.txt", 
                                                           "/home/emba/Insync/10planki@gmail.com/Google Drive/NEVIA/logfiles/",
                                                           code), append = TRUE)

if ((i*m) == nsim) {
   installr::os.shutdown(m = 15)
}
