#!/bin/bash

##        #######   ######   ####  ######  ##     ##  #######  ##    ## #### ########  #######  ########         ###    ########  ##     ##
##       ##     ## ##    ##   ##  ##    ## ###   ### ##     ## ###   ##  ##     ##    ##     ## ##     ##       ## ##   ##     ## ###   ###
##       ##     ## ##         ##  ##       #### #### ##     ## ####  ##  ##     ##    ##     ## ##     ##      ##   ##  ##     ## #### ####
##       ##     ## ##   ####  ##  ##       ## ### ## ##     ## ## ## ##  ##     ##    ##     ## ########      ##     ## ########  ## ### ##
##       ##     ## ##    ##   ##  ##       ##     ## ##     ## ##  ####  ##     ##    ##     ## ##   ##       ######### ##        ##     ##
##       ##     ## ##    ##   ##  ##    ## ##     ## ##     ## ##   ###  ##     ##    ##     ## ##    ##      ##     ## ##        ##     ##
########  #######   ######   ####  ######  ##     ##  #######  ##    ## ####    ##     #######  ##     ##     ##     ## ##        ##     ##

# Ticket - https://jira.logicmonitor.com/browse/DEV-111402

# Date - 22-09-2022
# Copyright - LogicMonitor LLP - 2022
# Team APM Tracing
# Author - girish.mahajan@logicmonitor.com


# Default Legends - this can be overrides by adding in .env.sh file
S3_BUCKET_NAME="lm-apm-traces"
LAMBDA_FUNCTION_NAME="topology-generator"
AWS_REGION="us-west-2"

# values are 0 and 1. 0 being no cold start on next run
IS_FORCE_COLD_START=0

HOME_DIR="/Users/$(id -u -n)/Desktop/DEV-111402/"

# add your aws creds to the env

# Overrides legends
[ -f .env.sh ]  && . .env.sh

# inform aws cli about the aws cloud
. ~/.aws_creds_qauattraces02

debug=$#
secure=0

[ ! -d logs ] && mkdir logs

logfile="$HOME_DIR/logs/logrun_$(date +%F_%s).log"
log "LogicMonitor APM Topology Lambda Test Launch - secure=$secure debug=$debug"
log "S3 Bucket Name: $S3_BUCKET_NAME - Region - $AWS_REGION - Topology APM Lambda Function Name - $LAMBDA_FUNCTION_NAME"

echo "||Sr No||File Name||Is Lambda code start||Is Topology generated||Anomaly Observed||Topology Filename||Took (ms)||Remarks||" > logs/kpi.csv

function log {
 echo "$(date +%F" "%H:%M:%S","%s) | $1" | tee -a $logfile
}

function kpi {
 echo "|$1|$2|$3|$4|$5|$6|$7|$8|" | tee -a logs/kpi.csv
}

function forcecoldstart(){
 log "Making configuration alter for lambda $LAMBDA_FUNCTION_NAME so it goes cold start on next run"
 aws lambda update-function-configuration --function-name $LAMBDA_FUNCTION_NAME --description "forcing to go cold start $(date +%F%s)"
}


function getpayloadjson {

local srcFile=$1

payload="{  \"srcFileName\": \"##S3_FILE##\",  \"srcBucketName\": \"##BUCKET_NAME##\",  \"accessKey\":\"##ACCESS_KEY_LAMBDA_PAYLOAD##\",  \"secretKey\":\"##SECRET_KEY_LAMBDA_PAYLOAD##\",  \"destBucketName\":\"##BUCKET_NAME##\",  \"region\": \"##AWS_REGION##\",  \"ingestTime\": ##INGEST_TIME##, \"generateAggregation\" : true}"

payload=$(echo $payload | sed -e "s/"##S3_FILE##"/"$(echo "$(echo $srcFile | sed -e 's/\//vuu/g')")"/g" | sed -e 's/vuu/\//g')

payload=$(echo $payload | sed -e "s/"##BUCKET_NAME##"/"$(echo $S3_BUCKET_NAME)"/g" | sed -e "s/"##AWS_REGION##"/"$(echo $AWS_REGION)"/g"| sed -e "s/##INGEST_TIME##/$(date +%s%3)/g")
payload=$(echo $payload | sed -e "s/"##ACCESS_KEY_LAMBDA_PAYLOAD##"/"$(echo $ACCESS_KEY_LAMBDA_PAYLOAD)"/g" | sed -e "s/"##SECRET_KEY_LAMBDA_PAYLOAD##"/"$(echo $SECRET_KEY_LAMBDA_PAYLOAD)"/g")
echo $payload | sed -e "s/\"/\\\"/g"

}

function getpayload {

   local payload="$(getpayloadjson $1)"

   raw=$(echo $1 | sed -e "s/\//-/g" | sed -e "s/\.parquet/-$(date +%F_%s)-request.json/g")
   input=$(echo $1 | sed -e "s/\//-/g" | sed -e "s/\.parquet/-$(date +%F_%s)-request.fileb/g")
   
   echo $payload > tmp/$raw
   cat $raw | base64 > $input

   if [ $secure -eq 1 ]; then  
    echo "fileb://$input"  
   else
    echo $payload
   fi;
   
}

function invokeLambdaAWS {

   [ ! $# -eq 2 ] && echo "unable to invoke, required s3 file for invoking lambda" && return -1 || echo "Invoking src=$1"

   payload="$(getpayload $1)"
   output="$2"

   log "output=$output payload => $payload"

   # see if we can go cold start forcefully
   [ $IS_FORCE_COLD_START -eq 1 ] && forcecoldstart on next run || log "force cold start has been disabled it is as per the aws to respond to the invoke lambda request"

   if [ $debug -eq 1 ] ; then
    time aws lambda invoke --function-name $LAMBDA_FUNCTION_NAME --debug --payload "$payload" --cli-binary-format raw-in-base64-out response.txt | tee -a $logfile
   else
    time aws lambda invoke --function-name $LAMBDA_FUNCTION_NAME --payload "$payload" --cli-binary-format raw-in-base64-out response.txt | tee -a $logfile
   fi
   [ ! -d tmp ] && mkdir tmp
   mv response.txt tmp/$output
}

function main {

 echo "There are total $(cat s3fileset.txt | wc -l) files given for the observation"
 #template="||Sr No||File Name||Is Lambda code start||Is Topology generated||Anomaly Observed||Topology Filename||Took (ms)||Remarks||"
 count=0
 for s3File in $(cat s3fileset.txt); do 
   local begin=$(date +%s)   
   response=$(echo $s3File | sed -e "s/\//-/g" | sed -e "s/\.parquet/-$(date +%F_%s)-response.json/g")
   invokeLambdaAWS $s3File "$response"; 
   end=$(date +%s)
   #topologyFileName=$(cat tmp/$response |  sed -e 's/.*topologyFileName":"//g' | sed -e 's/".*//g' | grep topology.txt)
   topologyFileName="NA"
   took=$((($end - $begin)/1)) #fixme
   count=$((count + 1 ))
  
   # log the kpi metrics for the operation
   kpi $count $s3File "NA" "NA" "NA" $topologyFile $took "NA" ; 
  done
  
  rm -rf $HOME_DIR/*.fileb
}

main
