# Email alert service

This is a message queue consumer that triggers email alerts when documents are published with a major change.

## Technical documentation

You can use the [GOV.UK Docker environment](https://github.com/alphagov/govuk-docker) to run the application and its tests with all the necessary dependencies. Follow [the usage instructions](https://github.com/alphagov/govuk-docker#usage) to get started.

**Use GOV.UK Docker to run any commands that follow.**

### Before running the app

The email-alert-service uses the [govuk_message_queue_consumer](https://github.com/alphagov/govuk_message_queue_consumer)
to connect to a message queue on the `published_documents` exchange.

There is a rake task to create the queue for this exchange:

```
bundle exec rake message_queues:create_queues
```

There is a rake task to start a processor to consume from the queue:

```
bundle exec rake message_queues:major_change_consumer
```

### Running the test suite

```
bundle exec rake
```

## Licence

[MIT License](LICENCE)
