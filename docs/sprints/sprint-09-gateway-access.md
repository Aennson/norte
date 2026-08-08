# Sprint 09 — Reaching a Jira behind a corporate gateway

**Objective:** make the Jira integration usable on a site that sits behind a network access control — first by honouring the proxy the machine already uses, and where only a browser session gets through, by holding one.

**Mandatory references:** `docs/architecture.md` §4.2, §10, §12 · BR-05, BR-08 · `docs/reports/decisions.md` DEC-012 · `docs/reports/sprint-02-report.md` §6

> **Post-v1.0.** Sprint 08 closes v1.0; this is the first sprint of v1.1. It is
> scheduled last deliberately: nothing in Sprints 03–08 depends on it, and it is
> the only sprint whose acceptance cannot be fully demonstrated without a
> particular corporate network.

---

## Why this sprint exists

Sprint 02 delivered the Jira integration and it works — against Jira Cloud, and
against a Data Center site the machine can reach. The Developer's own site
cannot be reached. The evidence, recorded in `docs/reports/sprint-02-report.md`
§6 and reproduced by `curl`:

```
GET /rest/api/2/issue/<KEY>
→ 200  text/html   (an HTML sign-in page, not the API)
→ 303  Location: https://p.zpa-auth.net/…/doauth?origurl=…
       Server: ZBA/1.0
```

A Zscaler Browser Access gateway answers before Jira does. It does not read the
`Authorization` header at all, so **no authentication scheme the app can choose
makes any difference** — Bearer, Basic, PAT and password all stop at the same
redirect. Two things could get through, and this sprint does both, cheapest
first:

1. **The proxy the machine already uses.** Dart's `HttpClient` ignores the
   Windows system proxy; a browser on the same machine does not. If a tunnel
   client is running, routing through it is the whole fix — no session, no
   WebView, and the existing token path keeps working unchanged.
2. **A browser session.** Where the gateway genuinely requires an interactive
   sign-in, the user performs one *in the app*, and the app keeps the resulting
   session alongside the token.

The order matters. (1) is a setting and a few dozen lines; (2) is a dependency,
a lifecycle and a new class of stored credential. Delivering (2) without trying
(1) would be paying the larger price for the smaller reason.

## Entry criteria

- [ ] Sprints 00–08 with DoD complete; v1.0 released.
- [ ] All S00–S08 tests green in CI.
- [ ] A site that reproduces the interception is available to the Developer, and
      the `curl` transcript above is attached to the sprint report — without
      which the exit criteria of S09-MT-01 cannot be judged.
- [ ] The Developer has confirmed with their organisation that an app-held
      session is acceptable use. **The gateway exists to control which clients
      reach the application; this sprint does not start until that question has
      an answer.**

## Scope

**In:**

*Proxy*
- `JiraNetworkSettings` (part of the stored connection, not a separate store):
  proxy mode `direct` | `system` | `manual(host, port)`.
- A dio `HttpClientAdapter` that applies it; `system` reads the platform proxy
  (Windows registry / `http_proxy` and `https_proxy` elsewhere).
- Settings UI for the mode, and a **Test connection** action that reports which
  route was used and what came back.

*Session*
- `JiraSession` — opaque session material plus the instant it expires and the
  origin it belongs to. A credential, stored exactly like the token (BR-08).
- `JiraSessionStore` port + secure-storage adapter.
- A **Sign in to Jira** flow in Settings: an embedded browser opened at the
  user's configured site URL, in which the user completes the organisation's own
  sign-in; the app then keeps the session cookies for that origin.
- `JiraRestAdapter` sends the session when there is one, alongside the token.
- `JiraSessionExpiredFailure`: the gateway interception Sprint 02 already
  detects (`200` with HTML, or a redirect to another origin) is classified as an
  expired session rather than as an unreadable response, **when and only when a
  session is configured**.
- Outbox: a session-expired failure **parks** the operation — no attempt spent,
  no backoff started — and the sync indicator offers *Sign in again*.

**Out:** storing the user's password or any SSO factor; completing a sign-in
without the user (scripted, headless or replayed); presenting the app as a
browser to evade a client check; OAuth 2.0 3LO, which remains the Jira Cloud
evolution path (`docs/architecture.md` §4.2); Android/iOS session capture, if
the platform's WebView denies cookie access — record it and defer rather than
work around the platform.

## Sprint validation rules

- **BR-08 covers session material.** It is a credential: secure storage only,
  never Drift, never a preference file, never a log. `RedactingLogInterceptor`
  already redacts `Cookie` and `Set-Cookie`; a test asserts it for the session
  path specifically.
- **The embedded browser is only ever pointed at the site URL the user
  configured.** Never at an address taken from a response — a redirect target is
  followed by the browser itself, not chosen by the app.
- **Nothing is read out of the browser except the session cookies for that
  origin.** No page content, no form values, no other site's cookies.
- **A session expiry must not produce a duplicate write.** A parked operation
  keeps its `operationId` and its place in the queue (BR-05); re-signing in
  resumes it, it does not re-create it.
- **The token path is not weakened.** A site that works today with a PAT and no
  proxy must still work, with no session and no browser involved. The S02
  contract suite runs unchanged.
- **The proxy is tried and reported before the session is offered.** The
  settings screen states which route reached the site, so a user is never asked
  to sign in to solve a problem a proxy setting already solved.
- A session that has expired is treated as absent, not as a failure to hide: the
  UI says so plainly and the queue waits.

## Tests

#### S09-UT-01 — Proxy mode selection
- **What it validates:** the connection uses the route the user chose.
- **Entry criteria:** `JiraNetworkSettings` in each of the three modes; a fake
  platform-proxy source reporting `proxy.example:8080`.
- **Action:** build the client adapter for each mode.
- **Exit criteria:** `direct` sets no proxy; `system` sets `proxy.example:8080`;
  `manual('other.example', 3128)` sets that and ignores the platform value. A
  `system` mode with no platform proxy configured behaves as `direct`.

#### S09-UT-02 — A gateway interception is an expired session
- **What it validates:** the classification that drives the whole re-auth flow.
- **Entry criteria:** two adapters, one with a stored session and one without;
  a response of `200` with `text/html`, and a `303` to a different origin.
- **Action:** perform a read against each.
- **Exit criteria:** with a session configured, both produce
  `JiraSessionExpiredFailure`; with none configured, both produce
  `JiraUnreadableResponseFailure` exactly as in Sprint 02 — the Sprint 02
  behaviour is unchanged for a user who never signed in.

#### S09-UT-03 — A session is a credential
- **What it validates:** BR-08 extended to session material.
- **Entry criteria:** a `JiraSession` carrying a recognisable value.
- **Action:** interpolate it into a string; store and re-read it; dump the Drift
  database.
- **Exit criteria:** `toString` contains `[REDACTED]` and not the value; the
  value round-trips through the secure store; **no table in Drift contains it**.

#### S09-UT-04 — Expiry is honoured before it is used
- **What it validates:** an expired session is absent, not a failure.
- **Entry criteria:** a stored session whose expiry is before `clock.now`.
- **Action:** ask for the session.
- **Exit criteria:** `null`; the stored material is cleared; nothing is sent.

#### S09-IT-01 — The session and the token travel together
- **What it validates:** signing in does not replace the API credential.
- **Entry criteria:** the fake server, configured to require **both** a session
  cookie and an `Authorization` header.
- **Action:** a read, a transition and a comment.
- **Exit criteria:** every request carries both; removing either produces a
  failure, so neither is decorative.

#### S09-IT-02 — An expired session parks the operation
- **What it validates:** BR-05 across a re-authentication.
- **Entry criteria:** an outbox holding one transition; a server that responds
  with the interception; `FakeClock`.
- **Action:** dispatch; then supply a valid session and dispatch again.
- **Exit criteria:** after the first dispatch `attempts == 0`, state is not
  `failed`, and no backoff window was opened; after the second, the operation is
  `completed`, applied **once**, with the same `operationId` it was created
  with.

#### S09-IT-03 — Session material never reaches a log
- **What it validates:** BR-08.
- **Entry criteria:** the adapter with its log captured in memory, a session
  configured, and a server that sets a `Set-Cookie` on the response.
- **Action:** perform a read.
- **Exit criteria:** the transcript contains neither the request cookie nor the
  response one; `[REDACTED]` appears in their place; no response body is logged.

#### S09-CT-01 — The gateway contract
- **What it validates:** a session-bearing adapter obeys the same `JiraGateway`
  contract as the others.
- **Entry criteria:** the S02-CT-01 suite, with a fourth subject: the REST
  adapter with a session against a gateway-protected fake server.
- **Action:** run the existing S02-CT-01 cases unchanged.
- **Exit criteria:** the same return types and failures for the same stimuli as
  the other three subjects. **No S02 case is modified to accommodate this.**

#### S09-GT-01 — The connection panel in its four states
- **What it validates:** `docs/design-system.md` §6 for the new panel.
- **Entry criteria:** not configured · token only · token + valid session ·
  session expired.
- **Action:** render the settings panel in dark and light.
- **Exit criteria:** stable goldens; the expired state names the problem and
  offers *Sign in again*; the token-only state offers no sign-in at all, because
  nothing has yet said one is needed.

#### S09-E2E-01 — Signing in through the app
- **What it validates:** the capture flow end to end, with no real gateway.
- **Entry criteria:** a fake sign-in page served by the local fake server, which
  sets a session cookie on submit; the embedded browser pointed at it.
- **Action:** through the UI: Settings → Sign in to Jira → complete the fake
  page → return.
- **Exit criteria:** the panel reports a valid session with its expiry; the
  session is in the secure store and **not** in Drift; a subsequent read
  succeeds; signing out clears it and the next read fails with
  `JiraSessionExpiredFailure`.

#### S09-E2E-02 — A queued write survives a sign-out and back in
- **What it validates:** BR-05 and the parking rule, through the UI.
- **Entry criteria:** a linked task; a valid session; the gateway set to
  intercept.
- **Action:** through the UI, comment on the issue → observe the indicator →
  sign in again → wait for the dispatcher.
- **Exit criteria:** while intercepted the indicator says a sign-in is needed
  (not "failed"), the operation has spent no attempts, and nothing reached the
  site; after signing in the comment is applied exactly once, with the
  `operationId` it was queued with.

#### S09-MT-01 — Manual, against the real gateway
- **What it validates:** the only thing no fake can — that this actually works
  on the network it was built for.
- **Entry criteria:** the Developer's machine on the corporate network; the site
  from the entry criteria; the organisation's confirmation on record.
- **Action:**
  1. Settings → Jira → **Test connection** with proxy mode `system`. Record the
     route and the result.
  2. If that reaches the API, stop: the session path is not needed, and the
     report says so.
  3. Otherwise → **Sign in to Jira**, complete the organisation's sign-in, and
     repeat **Test connection**.
  4. Link an issue, comment, transition, refresh.
  5. Leave the app until the session expires; repeat step 4.
- **Exit criteria:** step 1 or 3 reaches the REST API; steps 4 behave exactly as
  in S02-E2E-01; after expiry the app asks for a sign-in rather than failing
  silently, and the queued work completes once signed in. **No credential and no
  session value appears in any log or in the report.**

## Definition of Done

- [ ] Gates G1–G6 green; domain+application coverage ≥ 90%, project ≥ 80%.
- [ ] All S09-* tests passing; S02-CT-01 runs unchanged with its fourth subject.
- [ ] The Sprint 02 token path demonstrably unaffected: the full S02 suite green
      with no session and no proxy configured.
- [ ] S09-MT-01 executed and recorded, including which of the two routes was the
      one that worked.
- [ ] **Inherited from Sprint 02 (DEC-014):** S09-MT-01 steps 4–5 *are* the
      Sprint 02 §6 manual script against the real site. Sprint 02's Definition
      of Done was closed on the promise of this line. Recording it here as
      passed also discharges that box; leaving it open leaves both open. This
      sprint does not close on the automated suite alone.
- [ ] A decision record for the WebView dependency (`docs/architecture.md` §2.1)
      and for session material as a stored credential (§10).
- [ ] Report `docs/reports/sprint-09-report.md`.
