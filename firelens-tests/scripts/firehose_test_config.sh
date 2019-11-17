# $1 = runtask JSON file
# $2 = S3 object prefix
# $3 = total events

task_definitions=(
"firehose-log-loss-test-config-c5-fixed:1"
"firehose-log-loss-test-config-c5-fixed:2"
"firehose-log-loss-test-config-c5-fixed:3"
"firehose-log-loss-test-config-c5-fixed:4"
"firehose-log-loss-test-config-c5-fixed:5"
"firehose-log-loss-test-config-c5-fixed:6"
"firehose-log-loss-test-config-c5-fixed:7"
"firehose-log-loss-test-config-c5-fixed:8"
"firehose-log-loss-test-config-c5-fixed:9"
"firehose-log-loss-test-config-c5-fixed:10"
"firehose-log-loss-test-config-c5-fixed:11"
"firehose-log-loss-test-config-c5-fixed:12"
"firehose-log-loss-test-config-c5-fixed:13"
"firehose-log-loss-test-config-c5-fixed:14"
"firehose-log-loss-test-config-c5-fixed:15"
)

total_logs=(
60000
120000
180000
240000
300000
360000
420000
480000
540000
600000
660000
720000
780000
840000
900000
)

export REGION="ap-south-1"
export AWS_REGION="ap-south-1"

test_case() {
	for i in {1..5}
	do
		echo "_____________________________________"
		aws ecs run-task --cli-input-json file://run_task.json --task-definition $1 --region ap-south-1 >> runtask_results.txt
		sleep 600
		echo "Validation Attempt 1:"
		AWS_REGION="ap-south-1" S3_BUCKET_NAME="deepika-pudakone" OBJECT_PREFIX="log-loss-test" TOTAL_EVENTS="${2}" go run validate_s3/validator.go
		echo "Validation Attempt 1: Double check for correctness"
		sleep 10
		AWS_REGION="ap-south-1" S3_BUCKET_NAME="deepika-pudakone" OBJECT_PREFIX="log-loss-test" TOTAL_EVENTS="${2}" go run validate_s3/validator.go
		sleep 10
		echo "Cleaning Bucket:"
		AWS_REGION="ap-south-1" S3_BUCKET_NAME="deepika-pudakone" S3_ACTION="clean" go run clean_s3/clean_s3.go
		echo "Cleaning Bucket:"
		AWS_REGION="ap-south-1" S3_BUCKET_NAME="deepika-pudakone" S3_ACTION="clean" go run clean_s3/clean_s3.go
		echo "_____________________________________"
	done
}

for i in {0..14}
do
	echo "Test Case: $i"
	echo "Task Definition: ${task_definitions[$i]}"
	echo "Total Events: ${total_logs[$i]}"
	test_case "${task_definitions[$i]}" "${total_logs[$i]}"
done
