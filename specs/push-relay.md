# Push relay (AV-123)

Design for push notifications when the app is not running, mostly on
mobile. **Status (2026-10-16): designed, not built; out of scope for
now.** While the app runs, local notifications cover the same events
(AV-121, `app/lib/src/notifications/`).

## Problem

AHP delivers state only over a live WebSocket (`action` notifications on
subscribed channels). There is no push, webhook or "notify me later"
command in AHP 1.0.0 or the protocol's main branch. A phone suspends a
backgrounded app within seconds, iOS never lets it keep a socket open,
and Android only does with a foreground service. So the events a user
wants to hear about ("needs input", "finished", "failed") happen while
nothing is listening.

None of the hosts we target solve this: pi-agent-host-protocol and VS
Code's agent host only serve WebSocket clients, and VS Code's own mobile
story goes through GitHub (cloud agents), not AHP.

## Options considered

1. **Keep the socket alive on the device.** An Android foreground service
   with a persistent notification works but costs battery and is
   impossible on iOS. Rejected as the main design; it may be an Android
   opt-in later.
2. **Background fetch.** iOS `BGAppRefreshTask` and Android WorkManager
   run every 15 minutes at best, at the OS's discretion. Too late for "the
   agent is waiting for you". Rejected.
3. **A relay that holds the connection.** A small always-on process
   connects to the user's hosts as an ordinary AHP client, watches the
   session catalogue, and sends a push through APNs/FCM when a session
   needs attention. **Chosen.**
4. **A host-side push extension.** A host could accept a push target
   itself (an AHP extension command or `_meta` convention). This needs
   every host to implement it and to hold push credentials. Possible
   later as an optimization; the relay works with unmodified hosts.

## Design

```
host (pi / VS Code)  ◄──AHP/WebSocket──  relay  ──APNs/FCM──►  phone
        ▲                                   ▲
        └──────────── app (when open) ──────┘ registers device + hosts
```

- **Relay process.** A Dart command-line program in this repository
  (`packages/shireitou_relay`), built on `ahp_client`, so it reuses the
  connection, reconnect and catalogue code. It subscribes only to
  `ahp-root://` and keeps the session catalogue (`listSessions` plus the
  `root/session*` notifications). It never subscribes to sessions or
  chats, so it does not appear in a session's `activeClients` and holds
  no conversation content.
- **Events.** The same pure function the app uses,
  `attentionEvents(before, after)`, turns catalogue changes into
  "needs input", "finished" and "failed" events, filtered by the
  per-event settings the device registered.
- **Where it runs.** Next to the hosts: on the developer machine or the
  box that runs pi (a `systemd --user` unit or a launchd agent), so host
  tokens never leave that machine and the relay reaches hosts that only
  listen on `127.0.0.1`. A hosted multi-user relay is out of scope.
- **Registration.** The app, when open, sends the relay its push token
  (APNs device token or FCM registration token), its platform, the host
  keys it wants watched and the event settings, over an authenticated
  HTTPS endpoint of the relay (`POST /devices`, bearer token shown by the
  relay at first start and pasted into the app once, like an AHP host
  token). Host URLs and tokens are configured on the relay, not uploaded
  from the phone.
- **Push delivery.** The relay needs push credentials: an APNs auth key
  (`.p8`) for the app's bundle ID and an FCM service account. Both belong
  to whoever builds and signs the app, which is why this is not
  self-serve: a user building from source must create their own Apple
  and Firebase projects. Payloads carry only the host key, session URI,
  event kind and session title (titles may be sensitive; the relay
  setting `includeTitles: false` sends "A session needs your input"
  instead).
- **Opening a session.** Tapping the push opens the app with the same
  payload as a local notification (`{host, session}`), which the app
  already routes through `openSessionRequestsProvider`.
- **Deduplication.** While the app is in the foreground it tells the
  relay (`PUT /devices/<id>/active`) and the relay holds pushes for that
  device, since local notifications already cover it; the flag expires
  after 60 s without a refresh, so a killed app gets pushes again.
- **Security.** The relay holds host tokens and push credentials; it
  listens on HTTPS only (or behind the same tunnel as the hosts), stores
  device registrations in a local file with mode 0600, and rejects
  requests without its bearer token. It sends no conversation content.

## Not decided

- Whether the relay should also offer an AHP endpoint itself (a
  multiplexing proxy), which would solve the web transport problems
  (TLS, CORS-free `wss://`) in the same process.
- Live Activities (AV-124) need APNs too and would reuse the relay's
  credentials.

## Why not now

It needs Apple and Google developer accounts, signing and a running
service, none of which exist for this project yet (the app is not
signed, AV-009), and no mobile build is shipped. Local notifications
cover desktop users, who are the current audience.
