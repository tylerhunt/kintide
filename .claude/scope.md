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
    Modeled as the `invited` state of a subscription; the invite link is
    the subscription link.
  - **Subscription** — determines who receives updates. Lifecycle states:
    invited → active → deactivated. Subscribers do not have accounts.
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
  - Invitation links do not expire; the owner can remove a pending
    invitation instead (which also frees the phone number for
    re-inviting).
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

## Technical Decisions

  - **Rails 8** on the latest stable Ruby, with **PostgreSQL**. All runtime
    versions pinned in `.tool-versions` and managed with asdf.
  - **Hotwire** (Turbo + Stimulus) with server-rendered pages. No separate
    frontend application.
  - **Tailwind CSS** via the `tailwindcss-rails` gem.
  - **RSpec** for tests.
  - Authentication via the **Rails 8 built-in authentication generator**
    (sessions, password reset, bcrypt), extended with a signup flow.
  - **Active Storage** for photo and avatar uploads, with libvips for
    resizing variants. Local disk in development; production backend chosen
    alongside deployment.
  - **Solid Queue** for background jobs (SMS fan-out on publish). Runs on
    PostgreSQL; no Redis.
  - **Twilio** for SMS, using its built-in STOP handling and A2P 10DLC
    registration path.
  - **phonelib** for validating and normalizing phone numbers to E.164
    before storage.
  - Subscriber link tokens generated with `has_secure_token` — random opaque
    tokens, revocable per subscription.
  - **Deployment target: deliberately undecided.** Active Storage and Solid
    Queue keep VPS/Kamal, Heroku, and Fly.io all open; revisit when v1
    nears shippable.

## Open Questions

  - Photo limits per post (count and file size).
  - Whether the web view needs any owner-facing analytics (e.g. delivery
    status), or delivery is fire-and-forget in v1.
