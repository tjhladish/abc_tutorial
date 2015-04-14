# You probably don't want to change these lines
rm(list=ls())
library("RSQLite")
drv = dbDriver("SQLite")
db = dbConnect(drv, "./dice.sqlite")
par_df = dbGetQuery(db, "select P.* from parameters P, jobs J where P.serial = 
                         J.serial and status = 'Q'")
update_jobs = "update jobs set status='D' where serial = ?";

# Edit this line to agree with your simulator function and abc_config.json file.
# List the metrics your function returns, in the order it returns them, using
# the short_name (or name, if you didn't provide a short_name) for each metric
# that you included in the JSON file, E.g., "met1=?, met2=?, met3=?" instead of
# "dice_sum=?, dice_stdev=?".
#                                         edit this part
#                                    vvvvvvvvvvvvvvvvvvvvvvvv
update_metrics = "update metrics set dice_sum=?, dice_stdev=? where serial = ?";

# Replace this dice game simulator with your own simulator that takes parameter 
# values from the database, does some kind of simulation, and returns metrics 
# named as explained above.
simulator = function(ndice, nsides) { 
    vals = sample(nsides, ndice, replace=T)
    data.frame(dice_sum=sum(vals), dice_stdev=sd(vals))
}

# Replace ndice and sides with the parameters your simulator takes
run_simulator = function(serial, ndice, nsides) { # Here
    metrics = simulator(ndice, nsides)            # and here.
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
mapply(run_simulator, par_df$serial, par_df$ndice, par_df$nsides)
