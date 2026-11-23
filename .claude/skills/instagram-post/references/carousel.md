# Carousel

Reference implementation: `arts/src/posts/profissional_post_001.mjs` (five slides, rendered in seconds).

## Specs

- 1080×1350 (4:5), PNG, named `slide-0N-<slug>.png`.
- The profile grid crops the centre 3:4, so keep text 84px from the side edges.
- 5 to 7 slides: a cover that holds the whole hook, one idea per middle slide, and a closing slide
  with the CTA.

## Template

Copy the file to `arts/src/posts/<name>.mjs` and change:

- the header comment (audience, voice swaps, claims);
- the output folder in `dir()`;
- the slides, built from the shared helpers in `arts/src/lib.mjs` (`page`, `cta`, `chips`, `icon`,
  brand tokens `C`);
- the exported jobs array, named after the post (`profissionalPost001Jobs` is the pattern).

Reuse the frame (wordmark top, swipe arrow bottom) and the `.copy` block for the headline: an eyebrow, a
Newsreader headline whose italic `<em>` carries the accent, a Manrope sub line.

## Review

Render with `node arts/src/build.mjs <name>`, view each slide with Read, and check the grid crop: the
cover must still read when cut to 3:4. When slides look right, also look at them side by side
(`magick montage`) to confirm the series feels like one system.

Alt text: one sentence per slide in `post.md`, ready to paste into Instagram's alternative-text field.
