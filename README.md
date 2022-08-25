# Steps


* Getting the todolist
* Processing the data
* Adding the data to the database
sed -i "s/([0-9]{4}.[0-9]{2}.[0-9]{2})/${day}/g" ${params.add_samples}
#sed -i "s/([0-9]{4}.[0-9]{2}.[0-9]{2})/${day}/g" ${params.add_samples} $(date +"%Y.%m.%d")
awk '{gsub(/$params.pat/,$day)}' $params.add_samples
sed -i "s/$dy/$day/" $params.add_samples