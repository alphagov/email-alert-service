# Email alert service

This is a message queue consumer that triggers email alerts when documents are published with a major change.

## Technical documentation

Messages are read from the `published_documents` exchange which carries documents
published from all publishing applications via the content-store.

When the service detects a published document which was tagged to one or more
topics, it builds an email message, and passes it to email-alert-api.

### Dependencies

- redis

### Running the application

The email-alert-service uses the [govuk_message_queue_consumer](https://github.com/alphagov/govuk_message_queue_consumer)
to connect to a message queue on the `published_documents` exchange.

There is a rake task to create the queue for this exchange:

`bundle exec rake message_queues:create_queues`

There is a rake task to start a processor to consume from the queue:

`bundle exec rake message_queues:major_change_consumer`

### Running the test suite

`bundle exec rspec`

## Licence

[MIT License](LICENCE)
