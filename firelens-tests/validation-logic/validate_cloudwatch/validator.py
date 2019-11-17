import boto3
import json
import sys
import os


client = boto3.client('logs', region_name=os.environ.get('REGION'))
TOTAL_EVENTS = int(os.environ.get('TOTAL_EVENTS'))

def get_all_log_events(log_group, log_stream):
    events = []
    response = client.get_log_events(logGroupName=log_group,logStreamName=log_stream, startFromHead=True)
    token = ''
    events = response['events']
    forwardToken = response.get('nextForwardToken')
    while response.get('nextBackwardToken') != token:
        print('iterating backward')
        token = response.get('nextBackwardToken')
        response = client.get_log_events(logGroupName=log_group,logStreamName=log_stream, startFromHead=True, nextToken=token)
        events.extend(response['events'])
    token = forwardToken
    response = client.get_log_events(logGroupName=log_group,logStreamName=log_stream, nextToken=token)
    events.extend(response['events'])
    while response.get('nextForwardToken') != token:
        print('iterating forward')
        token = response.get('nextForwardToken')
        response = client.get_log_events(logGroupName=log_group,logStreamName=log_stream, nextToken=token)
        events.extend(response['events'])
    return sorted(events, key=lambda event: int(json.loads(event['message'])['log']))

def validate_test_case(test_name, log_group, log_stream, validator_func):
    print('RUNNING: ' + test_name)
    print('Checking: '+log_group+':'+log_stream)
    events = get_all_log_events(log_group, log_stream)
    # test length
    if len(events) != TOTAL_EVENTS:
        print(str(len(events)) + ' events found in CloudWatch')
        print('TEST_FAILURE: incorrect number of log events found')

    counter = 1
    for log in events:
        validator_func(counter, log)
        counter += 1

    print('SUCCESS: ' + test_name)

def vanilla_validator(counter, log):
    event = json.loads(log['message'])
    val = int(event['log'])
    if val != counter:
        print('Expected: ' + str(counter) + '; Found: ' + str(val))
        sys.exit('TEST_FAILURE: found out of order log message')


validate_test_case('Log Loss Validator', os.environ.get('GROUP'), os.environ.get('STREAM'), vanilla_validator)
