#!/bin/bash
#Author : Leegin Bernads T.S
# Script to fetch the s3 metrices.

#Get all the s3 buckets in aws
aws s3api list-buckets --query "Buckets[].Name" | grep "\"" | tr -d ' ' | cut -d',' -f1 | sed -e 's/^"//' -e 's/"$//' >> buckets.txt

#Find the size of the s3 buckets and store them in the file "size.txt".
function bucket_size()
{
	for i in `cat buckets.txt`
	do 
		aws cloudwatch get-metric-statistics --namespace AWS/S3 --metric-name BucketSizeBytes --start-time 2018-12-12T00:00:00Z --end-time 2018-12-13T00:00:00Z --period 3600 --statistics Average --unit Bytes --dimensions Name=BucketName,Value=$i Name=StorageType,Value=StandardStorage | grep Average | cut -d":" -f2| cut -d"," -f1 | tr -d ' ' | awk -v var="$i" 'BEGIN {total=0}{total+=$1}END{print total/1024/1024/1024 "GB" "  :  " var}' >> size.txt
	done
}


#check if lifecycle is enabled or disabled for the s3 buckets
function lifecycle()
{
	for i in `cat buckets.txt`
    do
    	command=`aws s3api get-bucket-lifecycle --bucket $i 2> /dev/null | grep -i status | cut -d':' -f2  | tr -d ' ' | cut -d',' -f1 |sed -e 's/^"//' -e 's/"$//'`

		if [[ "$command" == "Enabled" ]]
        then
        	echo "$i : Enabled" >> Lifecycle.txt
        else
        	echo "$i : Diabled" >> Lifecycle.txt
        fi
    done
}

#Find the type of storage class of the s3 buckets
function storageclass()
{
	aws cloudwatch list-metrics --namespace "AWS/S3" --region ap-southeast-1 --dimensions Name=StorageType,Value=$1 --output json | grep -A 8 $1 | grep  -i value | grep -v $1 | cut -d ":" -f2 |tr -d ' ' | sed -e 's/^"//' -e 's/"$//'  | awk -v var="$1" '{print $1 "  :  "  var}' >> storageclass.txt
}

#Get the last modified time of the s3 bucket.
function modifiedtime()
{
	for in in `cat buckets.txt`
	do
		aws s3 ls $i --recursive | sort -r | awk '{print $1"  " $2}' | head -n 1 >> modifiedtime.txt
	done
}


if [[ -e buckets.txt ]]
then
	bucket_size
	lifecycle
	storageclass StandardStorage
	storageclass IntelligentTieringStorage
	storageclass StandardIAStorage
	storageclass ReducedRedundancyStorage
	storageclass GlacierStorage
	modifiedtime
else
	echo "The file which contains the list of the buckets does not exist"
fi
