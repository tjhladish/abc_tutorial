# You probably don't want to change these lines
rm(list=ls())
req.packages <- c("RSQLite", "rjson", "argparser")
sapply(req.packages, require, character.only = T)

a.parser <- arg.parser("Run simulations against an ABC-SMC run database.", "abc_wrapper")
a.parser <- add.argument(a.parser, "--json", "configuration data; if not provided, will attempt to locate a *.json file in the working directory", type="character")
a.parser <- add.argument(a.parser, "--database", "runs database; if not provided, will attempt to locate a *.sqlite file in the working directory", type="character")
a.parser <- add.argument(a.parser, "--src", "source file for the simulation function; if not provided, will attempt to locate a simulation.R file in the working directory", type="character")
argv <- parse.args(a.parser)

if (is.na(argv$json)) {
  tar <- list.files(pattern = "*.json")
  stopifnot(length(tar) > 0)
  argv$json <- tar[1]
}

if (is.na(argv$database)) {
  tar <- list.files(pattern = "*.sqlite")
  stopifnot(length(tar) > 0)
  argv$database <- tar[1]
}

if (is.na(argv$src)) {
  tar <- list.files(pattern = "simulation.R")
  stopifnot(length(tar) > 0)
  argv$src <- tar[1]
}

source(argv$src)

drv = dbDriver("SQLite")
db = dbConnect(drv, argv$database)
par_df = dbGetQuery(db, "select P.* from parameters P, jobs J where P.serial = 
                         J.serial and status = 'Q'")
update_jobs = "update jobs set status='D' where serial = ?";

metrics <- sapply(fromJSON(file=argv$json)$metrics, function(m) ifelse(!is.null(m$short_name), m$short_name, m$name))

update_metrics = paste("update metrics set", paste(paste0(metrics,'=?'), collapse = ", "), "where serial = ?", collapse=" ")

run_simulator = function(serial, ...) { 
    metrics = simulator(...)            
    metrics$serial = serial;
    dbBeginTransaction(db)
    dbGetPreparedQuery(db, update_metrics, bind.data = metrics)
    dbGetPreparedQuery(db, update_jobs, bind.data = data.frame(serial=serial))
    dbCommit(db)
}

# Run your simulator on the entire database.  Replace ndice and sides with
# the parameters your simulator takes, but here you must use the parameter
# short_names you provided in the JSON file, or the names if short_names were
# not used.
apply(par_df, 1, run_simulator)
