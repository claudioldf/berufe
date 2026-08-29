# LGPD operations runbook

## Scope and owners

Rising Consultoria de Software LTDA., CNPJ 36.443.360/0001-05, is the controller for
Berufe. Registered professionals can request account erasure in the authenticated product.
The Support Team receives other privacy requests and self-service exceptions at
`suporte@berufe.com.br`. Only an authorized operator with production Rails access may run
the fallback procedures below.

The product owner confirmed the production provider register, processing regions,
contractual safeguards, and privacy settings on 23 August 2026. Recheck that evidence before
adding a provider or changing a region, purpose, data category, or subprocessor.

## Rights-request intake

1. Direct a registered professional who can access the account to the **Excluir minha conta**
   link at the bottom of **Meu perfil**, which opens **Conta e privacidade** for irreversible
   account erasure. Do not open a support ticket merely to operate that self-service flow.
2. For a request that requires Support, open a ticket with a non-personal reference containing only letters, numbers,
   `.`, `_`, `/`, or `-`. Keep the original message in the controlled support mailbox.
3. Identify the request type and the affected data. Do not request an identity document when
   control of the registered phone or author e-mail is sufficient.
4. For a professional account or referred profile handled through the Support fallback below,
   ask the claimant to complete an SMS login. That workflow accepts only an SMS-authenticated
   session created in the prior 30 minutes. The self-service flow inside the authenticated
   workspace does not require a fresh SMS login — the signed-in session and an explicit
   acknowledgement are the confirmation.
5. For a recommendation withdrawal, require the request from, or a verification sent to, the
   same e-mail used for the recommendation. Match it with the profile slug; the application
   compares only the keyed e-mail fingerprint.
6. Acknowledge the request and record the decision in the support ticket. Provide simplified
   access promptly when possible and a complete access declaration within the applicable
   LGPD period of up to 15 days.

Correction is normally completed by the professional after SMS login. If disputed public
data cannot be corrected immediately, suspend it through the existing admin moderation flow
while the request is assessed. Never edit database content manually to bypass validation or
audit records.

## Withdraw recommendation publication consent

After verifying the author e-mail as described above, run from an authenticated production
Rails shell:

```bash
bin/rake privacy:withdraw_recommendation
```

Enter the professional profile slug and author e-mail only at the interactive prompts. The
task records `publication_withdrawn_at`; public serializers exclude the recommendation and
its evidence count immediately. Keep the original consent version and timestamps for the
five-year minimal legal record when an account is later erased.

## Unpublish and erase a professional account

Explain before proceeding that erasure is irreversible, public content and shared links stop
working immediately, eligible application data is erased by a retry-safe job, and only the
minimal pseudonymous records described below remain for five years.

### Registered-professional self-service

The professional opens **Conta e privacidade** from the **Excluir minha conta** link at the
bottom of **Meu perfil**. The confirmation screen explains immediate unpublication,
irreversibility, the 30-day maximum, and the five-year minimal retention exception. Submission
requires only the signed-in session and an explicit acknowledgement checkbox — there is no
SMS re-confirmation step and no typed confirmation phrase.

The product clears the browser session after acceptance and provides an opaque status link.
That status exposes only a non-personal request reference, public processing state, and
timestamps. Treat the status token as bearer material: do not copy it into tickets, logs,
analytics, or monitoring metadata.

### Support fallback

Use the fallback for an unclaimed referred profile, a verified accessibility/availability
exception, or operational recovery. After a fresh SMS login and explicit confirmation, run:

```bash
bin/rake privacy:request_professional_erasure
```

Enter the phone and support ticket reference only at the interactive prompts. Both the
self-service endpoint and this task invoke `ProfessionalDataErasureRequester`; the task:

- verifies a successful SMS authentication in the previous 30 minutes;
- suspends the account and profile immediately;
- revokes every application session and replaces quote bearer-token digests;
- expires open recommendation invitations;
- queues deletion of public and private R2 objects, profile data, customer records, quotes,
  service history, relationships, moderation content, metrics, sessions, and the account;
- preserves only pseudonymous acceptance, consent, referral-attestation, quote-acceptance,
  and moderation-event facts needed for audit or defense.

Check operational results using the non-personal ticket reference or request UUID in
`data_erasure_requests`. A
`completed` status is final. A `failed` status leaves the account/profile suspended and is
retried automatically by the job and the ten-minute recovery sweep; inspect the error by
request UUID, resolve the storage or database cause, and retry the GoodJob entry if needed.
Do not reactivate the account while erasure is pending. The maximum operational deadline is
30 days from the verified request.

## Retention matrix

| Record or object                                           | Production rule                                                                    | Enforcement                                   |
| ---------------------------------------------------------- | ---------------------------------------------------------------------------------- | --------------------------------------------- |
| OTP challenge                                              | Until its configured expiry, at most 10 minutes                                    | Hourly authentication cleanup                 |
| OTP anti-abuse counter                                     | Until its 24-hour window expires                                                   | Hourly authentication cleanup                 |
| Professional session                                       | 7 idle days, 30 absolute days                                                      | Authentication and hourly cleanup             |
| Admin session                                              | 30 idle minutes, 12 absolute hours                                                 | Authentication and hourly cleanup             |
| Successful GoodJob record                                  | 14 days                                                                            | GoodJob preserved-record cleanup              |
| Unresolved failed GoodJob record                           | Until operational review                                                           | Manual review; never blind deletion           |
| Anonymous non-audit search event                           | 90 days                                                                            | Daily rollup and purge                        |
| Expression prompt, raw LLM output, and controlled parse    | 6 calendar months                                                                  | Daily deletion of the complete audit event    |
| Pseudonymous search-event deduplication claim              | 24 hours                                                                           | Daily expiry cleanup and replacement on reuse |
| Temporary LLM search analysis and sanitized contact draft  | 24 hours                                                                           | Daily search-reporting retention cleanup      |
| Daily aggregate/activity                                   | 730 days                                                                           | Daily reporting cleanup                       |
| Abandoned upload authorization                             | 10 minutes                                                                         | Ten-minute cleanup                            |
| Rejected, replaced, removed, or unattached media           | 30 days                                                                            | Daily media retention cleanup                 |
| Identity evidence after a decision                         | 30 days                                                                            | Daily identity-file cleanup                   |
| Recommendation invitation                                  | 14-day validity; operational row removed within 30 days after completion or expiry | Daily recommendation cleanup                  |
| Published recommendation                                   | Until publication consent is withdrawn                                             | Timestamped withdrawal and public query scope |
| Active account, profile, customer, quote, and service data | While required for the relationship; eligible data erased after a verified request | Shared self-service/Support erasure workflow  |
| Minimal pseudonymous legal/audit records                   | Five years                                                                         | Daily LGPD audit cleanup                      |
| Support correspondence                                     | Only while required to answer, evidence, or defend the request                     | Controlled mailbox review                     |
| Database backups                                           | Provider's verified production backup cycle                                        | Railway configuration and restore tests       |

Review the matrix quarterly and after every material feature or provider change. A longer
retention requires a recorded legal basis, necessity assessment, and updated public notice
when material.

## International transfers and processors

Maintain account evidence for Railway/PostgreSQL, Infobip, Cloudflare R2, Resend, and
Bugsnag/SmartBear: service purpose, data categories, processing countries, current
subprocessor list, contract/DPA, applicable ANPD transfer mechanism, retention controls,
security configuration, and last review date. Evidence and signed agreements belong in the
company's controlled repository, not this source repository.

The public notice must be updated before a new provider or materially different destination
receives production personal data. WhatsApp, Instagram, and YouTube are independent services
opened only by the visitor's action and are not Berufe processors for the in-platform flow.

## Incident minimum

Contain access, preserve only necessary evidence, rotate exposed credentials, identify data
and people affected, and record the timeline and decision. Assess risk and damage using the
current ANPD incident regulation. Notify the ANPD and affected people when legally required,
using the applicable content and deadline. Do not place personal data or identity evidence in
GitHub issues, pull requests, Railway deployment notes, or Bugsnag metadata.
