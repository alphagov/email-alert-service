# Decision record: reinstate unpublish emails for single page subscriptions

Date: 2021-12-03

## Context

We have just launched a new email notifications feature that allows users to subscribe to updates on a single page.
Currently this feature is only enabled on a few selected pages (eg. [Open standards for government][open-standards-for-government]),
but it is expected to roll out to the majority of pages and content types by early 2022.
There is a user need to let subscribers know when a page they are subscribed to has been withdrawn or redirected.

The email alert API used to send emails when a page in a taxon subscription was unpublished.
This feature was [removed in Jan 2021][remove-previous-unpublish-emails] for good reasons.

[open-standards-for-government]: https://www.gov.uk/government/publications/open-standards-for-government
[remove-previous-unpublish-emails]: https://github.com/alphagov/email-alert-api/issues/1572

## Decision

We will reinstate emails when a page is unpublished, but only to users with a single page subscription to that page.
We will also remove the subscriber list for a single page when it is unpublished to reduce the build up of empty lists in Email Alert API.

### Addressing the concerns from the previous version

The previous version of this feature was removed for several good reasons. We believe readding the unpublish emails only for single page subscriptions addresses these concerns:

#### It only worked for topic taxons

The new unpublished emails will only apply to single page subscriptions. This is a deliberate decision to keep the scope small and allow us to address the other concerns about handling an unpublished page in a taxon.

#### It only worked if the unpublished page was redirected

The new unpublished emails will handle pages that are redirected published in error with or without an alternative URL. This covers the publisher-facing [unpublishing types][unpublishing-types].

#### It wasn't monitored so we didn't know if it was working

Because the new emails will only be for single page subscriptions, it will be easier to test the whole system. We will also use existing methods for templating and sending emails so we can benefit from the monitoring that's already in place.

#### It rendered email using ERB, unlike the rest of the system

The new unpublished emails will use the same method to render emails as the content changes.

#### It removed any subscriber lists that included the page, even those for a different taxon

There's only one single page subscriber list for each page, so it's much easier to know which list to remove when a page is unpublished.

#### There was no evidence it met user needs

Single page notifications are an answer to the user need to stay up to date with specific pieces of government guidance. Especially when the area might be subject to frequent updates or changes.

Our hypothesis is that some users will subscribe to taxons that are broader than their actual area of interest. So they will receive updates about areas they are not interested in, in order to get the few relevant updates to them.

Our hypothesis is that users who subscribe to be notified for major updates, will also want to know if the guidance is unpublished as part of staying up-to-date, and will find it unexpected if guidance they have been monitoring disappears from their account subscriptions without warning.

### Other related issues

The email alert API has subscriber lists that will never send an email. This is documented as [GOV.UK Tech Debt][email-alert-api-dead-lists].
This proposal does not directly address this Tech Debt, but by removing the single page subscriber lists as a page is unpublished we can try to prevent the impact of the tech debt from increasing.

[unpublishing-types]: https://github.com/alphagov/publishing-api/blob/a33292a3002d722a5b5840aaea751ebe10304c28/app/commands/v2/unpublish.rb#L37
[email-alert-api-dead-lists]: https://trello.com/c/PjRE1A0G/200-email-alert-api-has-dead-lists-that-will-never-send-any-email

## Status

Proposed

## Consequences
