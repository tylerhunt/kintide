# Kintide

Kintide is a private alternative to social networking apps for sharing life
updates with the people closest to you. Authors write occasional posts —
typically weekly — with text and photos, and a hand-picked circle of friends
and family receives them directly. Content is private by default and only
ever visible to the circle.

The name comes from "kin" (your people) and the Old English root *tīd* ("that
which happens"), shared by both "tide" (season) and "tidings" (news).

## Concepts

  - **Account** — an author. Has email/password credentials, a name, and an
    avatar image.
  - **Circle** — a named group owned by an account (e.g. "The Hunts"). Holds
    the account's posts and subscribers. One circle per account in v1.
  - **Invitation** — an offer to join a circle, sent to a phone number.
  - **Subscription** — created when an invitation is accepted. Determines who
    receives updates. Subscribers do not have accounts.
  - **Post** — text plus one or more photos, published to a circle.

## v1 Scope

### Accounts

  - Email/password signup and login.
  - Profile with a name and an uploadable avatar image.

### Circle

  - Each account owns exactly one circle, created during onboarding.
  - The circle has a name.

### Invitations

  - The owner invites subscribers by entering phone numbers.
  - Each invitee receives an SMS with a link to accept.
  - Accepting creates a subscription — no account or password required.
  - Email invitations are deferred until email delivery exists (see
    Deferred).

### Posts

  - A post has text and supports multiple photo uploads.
  - Publishing immediately fans out an SMS to every active subscriber with a
    short message and a link to the web view. No drafts or scheduling in v1.

### Subscriber Web View

  - The SMS link opens a mobile-friendly web page showing the circle's posts
    (full archive, not just the newest post).
  - Links carry a per-subscriber token rather than a per-post token, so one
    person's access can be revoked without breaking anyone else's links.
  - Tokens are bearer credentials: forwarding a link shares access. This is
    an accepted v1 tradeoff of account-less subscribers.

### Opt-Out and Compliance

  - Subscribers can opt out by replying STOP (standard carrier handling) or
    via an unsubscribe link in the web view. Either path deactivates the
    subscription.
  - Sending application SMS in the US requires A2P 10DLC brand and campaign
    registration with carriers. Registration takes days to weeks and must
    happen before delivery works reliably.
  - Budget roughly one cent per SMS sent.

## Deferred Beyond v1

  - Email delivery of posts, and email invitations along with it.
  - Multiple circles per account.
  - Subscriber accounts (optional claimed accounts on top of tokens).
  - Comments and reactions.
  - Scheduled posts and weekly digests.

## Open Questions

  - Photo limits per post (count and file size).
  - Whether the web view needs any owner-facing analytics (e.g. delivery
    status), or delivery is fire-and-forget in v1.
  - SMS provider choice (Twilio is the default assumption for STOP handling
    and 10DLC registration).
