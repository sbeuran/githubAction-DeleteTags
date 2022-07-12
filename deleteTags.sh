#!/bin/bash -e

#the purpose of this script is to keep the last 3 versions of the tags and delete the rest
acr='carlsshop' #define the ACR
repos=('carlsshop/hybris' ) #define the repository
latest_version='release_05.95.00-5' # "release_05.92.00-11" is the result of kubectl get deployments -A -o json | jq -r '.items[].spec.template.spec.containers[].image' | sort | uniq | grep carlsshop.azurecr.io | sed "s;carlsshop.azurecr.io/;;g" | sed "s;:; ;g" | awk '{print $1 $2}'


for repo in "${repos[@]}"; do
tags_to_delete=$(az acr repository show-tags -n ${acr} --repository ${repo} --output tsv | grep -v ${latest_version})
done
arr=($tags_to_delete) #creates array to store the tags to be deleted
printf "%s\n" "${arr[@]}" > tmp.txt #prints the array into a tmp file
rel_ver_to_del=`grep 'release' tmp.txt | cut -d. -f2 | sort | uniq | tail -n 3`
sort tmp.txt | grep 'release' > tmp1.txt
sort tmp.txt | grep 'develop'| tail -n 3 > tmp2.txt
for del in ${rel_ver_to_del}; do
  grep $del tmp1.txt >> tmp2.txt
done
sort tmp.txt | grep 'release'| tail -n 3 >> tmp2.txt
sort tmp.txt | grep 'feature_cbscps'| tail -n 3 >> tmp2.txt
sort tmp.txt | grep 'feature_csdevops'| tail -n 3 >> tmp2.txt
grep -Fvxf tmp2.txt tmp.txt > delete.txt
tags_to_delete=($(awk -F= '{print $1}' delete.txt))
for tag_to_delete in ${tags_to_delete[@]}; do
  #az acr repository delete --yes -n ${acr} --image ${repo}:${tag_to_delete} #command to delete the tags
  echo "deleting ${tag_to_delete} image" #list the tags to delete
done
rm -f tmp.txt tmp1.txt tmp2.txt delete.txt #remove temp files
