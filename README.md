# Email alert service

This is a message queue consumer that triggers email alerts when documents are published with a major change.

## Running the service

The main daemon is run via `./bin/email_alert_service`.
It connects to RabbitMQ, reading configs from `./config`.
Messages are read from the `published_documents` exchange which carries documents
published from Whitehall or Publisher via the Content Store, soon to be all publishing applications.

## Running the worker

When the service detects a published document which was tagged to one or more
topics, it kicks off a Sidekiq job to notify the `email-alert-api`.

This is run via `sidekiq -C ./config/sidekiq.yml -r ./email_alert_service/sidekiq_environment.rb`
which provides the Sidekiq workers with the needed requires and configs.

## System dependencies

- RabbitMQ
- Redis

## In the future

This service will eventually be used to trigger alerts for more than just topics,
and can be extended as needed.
