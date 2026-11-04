# Execute the authors' unchanged loader and verify it against independent input checks.
root <- normalizePath("reproduction")
out <- file.path(root,"results/phase2-smoke-20261104")
dir.create(out,recursive=TRUE,showWarnings=FALSE)
stopifnot(!file.exists(file.path(out,"preprocessing.rds")))
work <- file.path(root,"work/475c7dcdadc12987033d332b101f025625074301")
setwd(file.path(work,"script"))
source("script_data.R")
raw <- read.csv("../data/japan_rsv.csv")
stopifnot(nrow(raw)==26978, length(unique(raw$prefecture))==47,
          !anyNA(raw),all(raw$cases>=0),all(raw$cases==as.integer(raw$cases)))
raw$week <- pmin(raw$week,52)
keys <- paste(raw$prefecture,raw$year,raw$week)
stopifnot(sum(table(keys)==2)==94)
reference <- aggregate(cases~prefecture+year+week,raw,function(x) round(mean(x)))
actual <- as.data.frame(japan_rsv_prefecture)
joined <- merge(reference,actual,by=c("prefecture","year","week"))
stopifnot(nrow(actual)==26884,nrow(joined)==26884,
          identical(joined$cases.x,joined$cases.y),
          all(table(actual$prefecture)==572))
pop_reference <- c(Hokkaido=5140354,Honshu=102077895,Shikoku=3620103,
                   Kyushu=12640119,Ryukyu=1468318)
stopifnot(all(japan_pop_island$pop==pop_reference[japan_pop_island$island]))
islands <- names(pop_reference)
standata <- setNames(lapply(islands,function(ii) {
  d <- as.data.frame(japan_rsv_island[japan_rsv_island$island==ii,])
  stopifnot(nrow(d)==572,identical(as.integer(d$year),rep(2013:2023,each=52)),
            identical(as.integer(d$week),rep(1:52,11)),!anyNA(d),
            all(d$cases>=0),all(d$cases==as.integer(d$cases)))
  n <- switch(ii,Hokkaido=208L,Ryukyu=312L,364L)
  list(N=572L,Nnonpi=n,week=as.integer(d$week),cases=as.integer(d$cases),
       mu=1/80/52,pop=unname(pop_reference[ii]),gamma=1)
}),islands)
for (object in c("japan_rsv_prefecture","japan_rsv_island","japan_pop_island",
                 "japan_humidity_island","japan_temperature_island")) {
  d <- as.data.frame(get(object))
  stopifnot(!anyNA(d))
  write.csv(d,file.path(out,paste0(object,".csv")),row.names=FALSE)
}
for (name in c("humidity","temperature")) {
  d <- get(paste0("japan_",name,"_island"))
  stopifnot(nrow(d)==1865,all(is.finite(d[[name]])))
}
saveRDS(standata,file.path(out,"standata.rds"))
saveRDS(list(reference_matches=TRUE,duplicate_groups=94,prefecture_weeks=nrow(actual),
             island_weeks=table(japan_rsv_island$island),population=pop_reference,
             source_loader="unchanged",climate_start="supplied weekly tables"),
        file.path(out,"preprocessing.rds"))
cat("PREPROCESS_PASS: original loader; 5 islands x 572 weeks; independent case aggregation matches.\n")
