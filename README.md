# Email alert service

This is a message queue consumer that triggers email alerts when documents are published with a major change.

## Running the service

The main daemon is run via `./bin/email_alert_service`.
It connects to RabbitMQ, reading configs from `./config`.
Messages are read from the `published_documents` exchange which carries documents
published from Whitehall or Publisher via the Content Store, soon to be all publishing applications.

When the service detects a published document which was tagged to one or more
topics, it builds an email message, and passes it to email-alert-api.

## System dependencies

- RabbitMQ
- Redis

## In the future

This service will eventually be used to trigger alerts for more than just topics,
and can be extended as needed.
