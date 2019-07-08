#!/bin/bash

# exit script immediately if there's an error
set -e

pushd `dirname $0` > /dev/null
SCRIPT_PATH=`pwd`
popd > /dev/null

AWS_REGION=us-east-1
AWS_PROFILE=aws-scenarios-dev
STACK_NAME=aws-lb-infra
PARAMS_PATH="${SCRIPT_PATH}/../parameters"
PARAMETER_JSON="file://$PARAMS_PATH/parameters_lb_prod.json"
CFN_DIR="${SCRIPT_PATH}/../cfn"
ARTIFACT_FILENAME="deploy_lb.yml"
CFN_MAIN_FILE="${CFN_DIR}/${ARTIFACT_FILENAME}"
CHANGE_SET_NAME="aws-base-changeset"
S3_BUCKET=${AWS_PROFILE}
S3_ARTIFACT_KEY="${STACK_NAME}/${ARTIFACT_FILENAME}"
S3_ARTIFACT_URL="https://s3.amazonaws.com/${S3_BUCKET}/${S3_ARTIFACT_KEY}"
S3_ARTIFACT_PATH="s3://${S3_BUCKET}/${S3_ARTIFACT_KEY}"

echo "==== Uploading artifact to S3"
aws s3 cp ${CFN_MAIN_FILE} ${S3_ARTIFACT_PATH} --profile ${AWS_PROFILE}

echo "==== Deploying infrastructure"
if [ "$AWS_PROFILE" = "aws-scenarios-dev" ]
then
   aws cloudformation deploy --no-execute-changeset \
    --stack-name $STACK_NAME \
    --template-file $CFN_MAIN_FILE \
    --region $AWS_REGION \
    --profile $AWS_PROFILE \
    --capabilities CAPABILITY_IAM
else
   aws cloudformation create-change-set \
    --stack-name $STACK_NAME \
    --change-set-name $CHANGE_SET_NAME \
    --profile $AWS_PROFILE \
    --region $AWS_REGION \
    --template-url $S3_ARTIFACT_URL \
    --capabilities CAPABILITY_IAM \
    --parameters $PARAMETER_JSON
fi

echo "Log into the aws console for $AWS_PROFILE in order to apply the changeset"