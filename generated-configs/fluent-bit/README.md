### FireLens Generated Fluent Bit Configuration

[See the full configuration file](generated_by_firelens.conf).

```
[INPUT]
    Name forward
    unix_path /var/run/fluent.sock
```

Above, we see a config for the Fluent forward protocol over a unix socket.
With FireLens for Amazon ECS, container standard out logs are sent over this socket from the Fluentd Docker Log Driver.

```
[INPUT]
    Name forward
    Listen 0.0.0.0
    Port 24224
```

FireLens add a configuration for the Forward protocol over TCP. This allows you to use the [Fluent Logger Libraries](https://github.com/fluent/fluent-logger-golang) to send data directly from your application code to Fluent Bit.

**NOTE:** An earlier version of this README noted that FireLens has built-in support for a health-check for Fluent Bit. Please see our [updated health check guidance for FireLens](https://github.com/aws-samples/amazon-ecs-firelens-examples/tree/mainline/examples/fluent-bit/health-check). 

In the example [task definition](task-definition.json), the `include-pattern` field was used to filter the container's logs. That field leads to the creation of this filter.

```
[FILTER]
    Name record_modifier
    Match *
    Record ec2_instance_id i-01dce3798d7c17a58
    Record ecs_cluster furrlens
    Record ecs_task_arn arn:aws:ecs:ap-south-1:144718711470:task/737d73bf-8c6e-44f1-aa86-7b3ae3922011
    Record ecs_task_definition firelens-example-twitch-session:5
```

Next, there is the record transformer that adds ECS Metadata to your logs.

```
@INCLUDE /fluent-bit.conf
```

The include directive is used to tell Fluent Bit to import configuration from your external configuration file. In this example, the external/custom config is within the log routing image. The path here is the same as the path specified by `config-file-value` in the Task Definition.

```
[OUTPUT]
    Name null
    Match firelens-healthcheck
```

Logs used for the container health check are not sent anywhere.

```
[OUTPUT]
    Name firehose
    Match app-firelens*
    delivery_stream demo-stream
    region ap-south-1
```

Finally, the output for the logs. Outputs created by FireLens will have the match pattern `{container name}-firelens*`. In this case, the container whose logs will be sent to this output was named `app`, so the match pattern is `app-firelens*`. Logs from a container's standard out/error stream will be tagged with `{container name}-firelens-{task ID}`.
