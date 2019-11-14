### FireLens Generated Fluentd Configuration

[See the full configuration file](generated_by_firelens.conf).

```
<source>
    @type unix
    path /var/run/fluent.sock
</source>
```

Above, we see a config for the Fluent forward protocol over a unix socket.
With FireLens for Amazon ECS, container standard out logs are sent over this socket from the Fluentd Docker Log Driver.

```
<source>
    @type forward
    bind 0.0.0.0
    port 24224
</source>
```

FireLens add a configuration for the Forward protocol over TCP. This allows you to use the [Fluent Logger Libraries](https://github.com/fluent/fluent-logger-golang) to send data directly from your application code to Fluentd.

```
<filter **>
    @type record_transformer
    <record>
        ec2_instance_id i-01dce3798d7c17a58
        ecs_cluster furrlens
        ecs_task_arn arn:aws:ecs:ap-south-1:144718711470:task/9502495b-5eed-4951-9fd0-188da645658c
        ecs_task_definition firelens-example-fluentd:1
    </record>
</filter>
```

Next, there is the record transformer that adds ECS Metadata to your logs.

```
@include /fluentd/etc/external.conf
```

The include directive is used to tell Fluentd to import configuration from your external configuration file. In this example, the external config came from S3, and ECS downloaded it, mounted it into the Fluentd container at `/fluentd/etc/external.conf`.

```
<match app-firelens**>
    @type kinesis_firehose
    delivery_stream_name demo-stream
    region ap-south-1
</match>
```

Finally, the output for the logs. Outputs created by FireLens will have the match pattern `{container name}-firelens**`. In this case, the container whose logs will be sent to this output was named `app`, so the match pattern is `app-firelens**`. Logs from a container's standard out/error stream will be tagged with `{container name}-firelens-{task ID}`.
