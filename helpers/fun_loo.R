# 3 predictors ------------------------------------------------------------

# "As a rule of thumb, it has been suggested that if the elpd difference ( elpd_diff in the loo package) is less than 4, the difference is small, and if it is larger than 4, one should compare that difference to its standard error (se_diff) (see section 16 of Vehtari 2022)." (https://bruno.nicenboim.me/bayescogsci/ch-cv.html#cross-validation-in-stan; Nicenboim, Schad & Vasisth, 2024)
# https://web.archive.org/web/20221219223947/https://avehtari.github.io/modelselection/CV-FAQ.html

loo_3int = function(m, pred1, pred2, pred3, code, loo_dir) {
  
  ls.packages = c("brms", "tidyverse")
  lapply(ls.packages, library, character.only = TRUE)
  
  # set cores
  ncores = parallel::detectCores()
  options(mc.cores = ncores)
  
  # set the seed
  set.seed(2468)
  
  # create cache if it doesn't exist yet
  if(!dir.exists(loo_dir)) {
    dir.create(loo_dir)
  }
  
  # initialise empty list
  loos = vector(mode = "list", length = 19)
  
  # get the priors
  priors = m$prior
  
  # loo for max model
  loos[[1]] = loo(m)
  names(loos)[1] = sprintf('%s * %s * %s', pred1, pred2, pred3)
  
  # extract random effects from model
  idx = min(gregexpr(pattern ='\\(', as.character(m[["formula"]][["formula"]])[3])[[1]])
  random = substr(as.character(m[["formula"]][["formula"]])[3], idx, nchar(as.character(m[["formula"]][["formula"]])[3]))
  
  # extract name of dependent variable
  dvname = as.character(m[["formula"]][["formula"]])[[2]]
  
  # intercept only model
  f0 = brms::bf(sprintf('%s ~ 1 + %s', dvname, random))
  m.0 = update(m, f0, save_pars = save_pars(all = T), newdata = m[["data"]],
               prior = priors %>% filter(class != "b"), 
               backend = "cmdstanr", threads = threading(floor(ncores/(m[["fit"]]@sim[["chains"]]))),
               file = file.path(loo_dir, sprintf("m_%s_00", code)))
  # check for divergency issues
  div = sum(subset(nuts_params(m.0), Parameter == "divergent__")$Value > 0)/length(subset(nuts_params(m.0), Parameter == "divergent__")$Value)
  if (div < 0.05) {
    # loo for intercept only model
    loos[[2]] = loo(m.0)
    names(loos)[2] = "1"
  }
  
  # create a list of all the fixed effects combinations 
  fixed = c(
    pred1,
    pred2,
    pred3,
    sprintf('%s + %s', pred1, pred2),
    sprintf('%s + %s', pred1, pred3),
    sprintf('%s + %s', pred2, pred3),
    sprintf('%s + %s + %s', pred1, pred2, pred3),
    sprintf('%s + %s + %s:%s', pred1, pred2, pred1, pred2),
    sprintf('%s + %s + %s + %s:%s', pred1, pred2, pred3, pred1, pred2),
    sprintf('%s + %s + %s:%s', pred2, pred3, pred2, pred3),
    sprintf('%s + %s + %s + %s:%s', pred1, pred2, pred3, pred2, pred3),
    sprintf('%s + %s + %s + %s:%s + %s:%s', pred1, pred2, pred3, pred1, pred2, pred2, pred3),
    sprintf('%s + %s + %s:%s', pred1, pred3, pred1, pred3),
    sprintf('%s + %s + %s + %s:%s', pred1, pred2, pred3, pred1, pred3),
    sprintf('%s + %s + %s + %s:%s + %s:%s', pred1, pred2, pred3, pred1, pred2, pred1, pred3),
    sprintf('%s + %s + %s + %s:%s + %s:%s', pred1, pred2, pred3, pred2, pred3, pred1, pred3),
    sprintf('%s + %s + %s + %s:%s + %s:%s + %s:%s', pred1, pred2, pred3, pred1, pred2, pred2, pred3, pred1, pred3)
  )
  
  # LOOP THROUGH ALL THE MODELS
  
  for (b in 1:length(fixed)) {
    # build the formula
    f = brms::bf(sprintf('%s ~ %s + %s', dvname, fixed[b], random))
    # update the priors
    preds = str_split(fixed[b], pattern = " \\+ ")[[1]]
    priors_current = priors %>% 
      filter((class == "b" & gsub('[[:digit:]]+', '', coef) %in% preds) | 
               (class == "b" & coef == "") | 
               (class != "b" ))
    # update the model
    m.up   = update(m, f, save_pars = save_pars(all = T),
                    prior = priors_current, 
                    backend = "cmdstanr", threads = threading(floor(ncores/(m[["fit"]]@sim[["chains"]]))),
                    file = file.path(loo_dir, sprintf("m_%s_%02d", code, b)))
    # check for divergency issues
    div = sum(subset(nuts_params(m.up), Parameter == "divergent__")$Value > 0)/length(subset(nuts_params(m.up), Parameter == "divergent__")$Value)
    if (div < 0.05) {
      loos[[b+2]] = loo(m.up)
      names(loos)[b+2] = fixed[b]
    }
  }
  
  # return the loos
  return(loos)
  
}