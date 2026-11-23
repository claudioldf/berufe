---
name: instagram-post
description: Make a new Berufe Instagram post (carousel or Reel) with art, caption and notes under arts/instagram/posts/. Use for any request to create another Instagram or social post.
---

# Instagram post

Builds one post under `arts/instagram/posts/<audience>_post_NNN/`: media, `caption.txt` and `post.md`.
The pipeline (`arts/src/`, run with `node arts/src/build.mjs <name>`) and the two existing posts are the
reference implementations; copy from them instead of starting blank.

The request may carry format, audience and angle (`/instagram-post reel sobre orçamento`).

## 1. Brief

Fix four things; take what the request states and default the rest:

- **Format**: Reel when the request says video or reel, else carousel.
- **Audience**: `profissional` (pedreiro, eletricista, pintor, encanador, diarista…). A `cliente` post
  takes the customer side of the same claims policy; no template exists for it yet.
- **Angle**: one everyday pain or question of the audience, answered by one supported feature. When
  the request names none, read the posts table in `arts/README.md` and offer three unused angles
  from `references/voice-and-claims.md` with AskUserQuestion.
- **Folder**: `<audience>_post_NNN`, NNN the next free number for that audience.

Done when format, audience, angle and folder are fixed.

## 2. Copy first

Read `references/voice-and-claims.md`. Write every on-screen line and the caption in pt-BR before any
HTML, in the audience's own words. Build a claims ledger: one row per on-screen line with the product
feature that backs it and the source file. Spot-check the sources the reference names, since the facts
there are a cache.

Done when each line is a question or pain from the audience's day, or traces to a supported feature
in the ledger.

## 3. Template

Open the format's reference and follow it: `references/carousel.md` or `references/reel.md`. Copy the
closest template to `arts/src/posts/<name>.mjs`, rewrite it, and wire it into `arts/src/build.mjs`
(import it, then `jobs.push(...)` for images or `videos.push(...)` for a Reel).

Playwright comes from `apps/web`: when `apps/web/node_modules/@playwright` is missing, run
`pnpm install` there first.

## 4. Review

Render, then view every PNG with Read (a Reel's stills and, at the end, frames decoded from the MP4).
Iterate until every slide or scene, at its final state, passes:

- Nothing overlaps; every text block sits inside its card or safe zone.
- No headline line holds a single orphan word; set breaks with explicit `<br />`.
- The profile address reads `berufe.com.br/be/seu-nome`.
- No city, no handle, no name or number the product cannot back.
- Deep text on coral buttons, coral-400 only for large italic on teal.

Then render the unfiltered images (`node arts/src/build.mjs`) and read `git status --short arts`: only
the new post's files and the intended edits appear, because the other assets re-render byte-identical.

## 5. Deliverables

In the post folder, next to the media:

- `caption.txt`: hook line first, short plain paragraphs, the profile address, "Link na bio", 5-10
  hashtags, no cities.
- `post.md`: copy the structure of the latest post of the same format (angle, on-screen text or
  storyboard with the feature each part shows, accessibility text, claims policy, publishing steps).

Add the post's row to the posts table in `arts/README.md`.

## 6. Commit

Per `CLAUDE.md`: scoped commits, a plain imperative title, no `Co-Authored-By` trailer and no AI
footer. Commit shared code changes (`lib.mjs`, `build.mjs`) apart from the post itself.

## 7. Report

Tell the user, briefly: the concept, the folder and files, specs, what the post deliberately does not
claim, and anything left for them (add licensed audio to a Reel, paste caption and alt text, choose the
bio link). Report any check that failed or was skipped.
