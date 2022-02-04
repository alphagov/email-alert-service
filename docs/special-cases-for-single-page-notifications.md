Special cases for single-page notifications
===========================================

Given a publishing event, we can see if there is an associated
single-page subscriber-list for it with:

```ruby
def find_subscriber_list(payload)
  return if payload.fetch("content_id", "").empty?
  return unless payload.fetch("locale", "en") == "en"

  Services.email_api_client.find_subscriber_list(content_id: payload["content_id"])
rescue GdsApi::HTTPNotFound
  nil
end
```

The locale check is because the email system excludes non-English
content elsewhere, so we should only act on a publishing event if it's
also for English content.

This lets us implement some special-case behaviour for these
subscriber-lists.

Note that email-alert-**api** doesn't need to treat these
subscriber-lists any differently to topic-based subscriber-lists.  Nor
does it need to know anything about the publishing workflow.
email-alert-api just exposes generic API endpoints which work for all
subscriber-lists, meaning we could potentially extend the
functionality described here to topic-based subscriber-lists in the
future, without any changes to email-alert-api.

We currently have no plans to do that, but keeping the possibility
open ensures that we avoid building special cases in email-alert-api.


Unsubscribing users when a page is unpublished
----------------------------------------------

When a publisher unpublishes a page, it triggers either a
`gone.unpublish` or `redirect.unpublish` event on the message queue.
The `EmailUnpublishingProcessor` monitors these `*.unpublish#` events.

When receiving an event it:

1. Determines which unpublishing scenario it is: "published in error"
   (with or without an alternative URL) or "consolidated".
2. Checks if there is a single-page subscriber-list for the page.
3. Calls the email-alert-api bulk-unsubscribe endpoint for that
   subscriber-list, sending a message to users based on the
   unpublishing scenario.

email-alert-api used to handle unpublishing of topic-based
subscriptions, but that feature was removed.  We reinstated the
handling of unpublishing events for single-page subscriptions only.

Notably, our feature is implemented by adding a generic "bulk
unsubscribe from this specific subscriber-list" endpoint to
email-alert-api, and keep the logic of *which* subscriber-list to
unsubscribe from isolated to email-alert-service (in the
`UnpublishingAlert` class).

See [ADR 10 in email-alert-api][] for more information on how this
feature differs from the previous one.

[ADR 10 in email-alert-api]: https://github.com/alphagov/email-alert-api/blob/main/docs/adr/adr-010-send-unpublish-emails-for-single-pages.md


Keeping subscriber-list metadata up-to-date
-------------------------------------------

When a page has its title or description changed, it triggers a
`*.major.#` or `*.minor.#` event on the message queue.  The
`SubscriberListDetailsUpdateProcessor` monitors these events.

When receiving an event it:

1. Checks if there is a single-page subscriber-list for the page.
2. Checks if the publishing event has changed the title or
   description.
3. Calls the email-alert-api patch subscriber-list endpoint to set the
   new details.

We do not have anything comparable for topic-based subscriptions: for
example, if the "Money" taxon is renamed, existing subscriber-lists
will still use the name "Money".
