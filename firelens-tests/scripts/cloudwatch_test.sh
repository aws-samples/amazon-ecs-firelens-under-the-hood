# $1 = runtask JSON file
# $2 = S3 object prefix
# $3 = total events

task_definitions=(
"firelens-log-loss-test-c5-fixed:1"
"firelens-log-loss-test-c5-fixed:2"
"firelens-log-loss-test-c5-fixed:3"
"firelens-log-loss-test-c5-fixed:4"
"firelens-log-loss-test-c5-fixed:5"
"firelens-log-loss-test-c5-fixed:6"
"firelens-log-loss-test-c5-fixed:7"
"firelens-log-loss-test-c5-fixed:8"
"firelens-log-loss-test-c5-fixed:9"
"firelens-log-loss-test-c5-fixed:10"
"firelens-log-loss-test-c5-fixed:11"
"firelens-log-loss-test-c5-fixed:12"
"firelens-log-loss-test-c5-fixed:13"
"firelens-log-loss-test-c5-fixed:14"
"firelens-log-loss-test-c5-fixed:15"
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

test_case() {
	for i in {1..5}
	do
		export AWS_REGION="ap-south-1"
		export REGION="ap-south-1"
		echo "_____________________________________"
		aws ecs run-task --cli-input-json file://run_task.json --task-definition $1 --region ap-south-1 >> runtask_results.txt

		sleep 600
		echo "Validation Attempt 1:"
		GROUP="firelens-log-loss-testing" STREAM="log-loss-test" TOTAL_EVENTS="${2}" python3 validate_cloudwatch/validator.py
		echo "Validation Attempt 2: Double check for correctness"
		sleep 10
		GROUP="firelens-log-loss-testing" STREAM="log-loss-test" TOTAL_EVENTS="${2}" python3 validate_cloudwatch/validator.py
		sleep 10
		echo "Deleting Log Group:"
		LOG_GROUP_NAME="firelens-log-loss-testing" python3 clean_cloudwatch/clean.py
		echo "Deleting Log Group:"
		LOG_GROUP_NAME="firelens-log-loss-testing" python3 clean_cloudwatch/clean.py
		echo "_____________________________________"
	done
}

for i in {0..14}
do
	echo "Test Case: $i"
	echo "Task Definition: ${task_definitions[$i]}"
	echo "Total Events: ${total_logs[$i]}"
	"test_case "${task_definitions[$i]}" "${total_logs[$i]}""
done
