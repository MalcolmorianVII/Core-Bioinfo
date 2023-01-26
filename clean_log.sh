#! /usr/bin/bash
# Cleans the workspace dir after sometime i.e maybe after a week????

cur_dir=/data/fast/core/covid_pipeline

# Check how long work has lived or the cron job will do that????
if [ -d ${cur_dir}/"work" ]
then
    echo "Removing work"
    rm -r ${cur_dir}/"work"
fi

exit 0