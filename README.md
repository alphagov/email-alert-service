# Email alert service

This is a message queue consumer that triggers email alerts when documents are published with a major change.

## Technical documentation

Messages are read from the `published_documents` exchange which carries documents
published from Whitehall or Publisher via the Content Store, soon to be all publishing applications.

When the service detects a published document which was tagged to one or more
topics, it builds an email message, and passes it to email-alert-api.

### Dependencies

- redis
- rabbitMQ

*(Installed by puppet on the VM for a local version the following applies)*
 * install rabbitMQ with `brew install rabbitmq` (or similar)
 * visit http://localhost:15672/cli/ and follow the instructions to install the admin CLI
  * `rabbitmqadmin declare user name=root password=CHANGEME tags=administrator`
  * `rabbitmqadmin declare permission vhost="/" user=root configure='.*' write='.*' read='.*'`
  * `rabbitmqadmin declare exchange name=published_documents type=topic durable=true`

### Running the application

The main daemon is run via `./bin/email_alert_service`.
It connects to RabbitMQ, reading configs from `./config`.

### Running the test suite

`bundle exec rspec`

## In the future

This service will eventually be used to trigger alerts for more than just topics,
and can be extended as needed.

## Licence

[MIT License](LICENCE)
