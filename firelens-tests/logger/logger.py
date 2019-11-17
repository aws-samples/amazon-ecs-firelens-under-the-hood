import time
import sys
import json

steady_rate = int(sys.argv[1])
burst = int(sys.argv[2])

AWS_LOGS = False

if sys.argv[3] == "awslogs":
    AWS_LOGS = True

# we want the log events to be the same size, whether they come from FireLens or awslogs
# awslogs driver will not add metadata, so we add some
fake_metadata = {
    "container_id": "9e9e860842d0cb178c07632e9dbbdf4f33411ce9831adce75e85cd419e779d3a",
    "container_name": "/ecs-firelens-log-loss-test-2-app-bcd0aabcddbdb68ade01",
    "ecs_cluster": "arn:aws:ecs:ap-south-1:144718711470:cluster/firelens-testing",
    "ecs_task_arn": "arn:aws:ecs:ap-south-1:144718711470:task/88d913a3-9d3f-4e3c-aebb-aa4214f9ca62",
    "ecs_task_definition": "firelens-log-loss-test:2",
    "log": "1",
    "source": "stdout",
}

def print_event(i):
    if AWS_LOGS:
        fake_metadata["log"] = str(i)
        print(json.dumps(fake_metadata))
    else:
        print(i)

for i in range(1, 60 * steady_rate):
    print_event(i)
    if i % steady_rate == 0:
        time.sleep(1)


so_far = 60 * steady_rate

for i in range(so_far, so_far + burst + 1):
    print_event(i)
