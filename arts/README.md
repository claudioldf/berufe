# Berufe brand arts

Marketing assets for Instagram and Google Ads. Everything is rendered from HTML templates in
`src/build.mjs`, so a copy or colour change is one edit and one command:

```bash
node arts/src/build.mjs            # re-render every asset
node arts/src/build.mjs banner     # only assets whose path contains "banner"
```

It needs the Playwright install from `apps/web` (`pnpm install` there) and ImageMagick (`magick`);
videos also need `ffmpeg` with x264 and AAC (set `FFMPEG=/path/to/ffmpeg` if the one on your PATH is
broken; a failed encode keeps the rendered frames so you only re-encode).
Colours, wordmark, and fonts come from the product (`#12625d` teal, `#f8755d` coral, Georgia
wordmark, Newsreader headlines, Manrope body). The illustration is the site's hero art
(`apps/web/public/images/hero-home-care-illustration.webp`), which is synthetic.

## Instagram

| File                                           | Size      | Use                                                                                                                        |
| ---------------------------------------------- | --------- | -------------------------------------------------------------------------------------------------------------------------- |
| `instagram/instagram-profile-icon-2048x2048.png` | 2048×2048 | Profile picture. Full-bleed square because Instagram applies its own circle; the mark sits well inside the circular crop. |
| `instagram/instagram-banner-1500x500.png`        | 1500×500  | Wide 3:1 banner. Instagram profiles have no cover slot, so use it for the link-in-bio page, Facebook page cover, etc.      |

### Posts (`instagram/posts/`)

One folder per post, named `<audience>_post_NNN` (`profissional_…` for professionals, `cliente_…` for
people searching for one). Each holds the media, `caption.txt` to paste as the caption, and `post.md`
with the angle, on-screen text, accessibility text and a pre-publish checklist. Templates live in
`src/posts/<name>.mjs`; render one with `node arts/src/build.mjs <name>`.

To make a new post, ask Claude Code for one (`/instagram-post reel sobre orçamento`). The skill in
`.claude/skills/instagram-post/` carries the voice, the claims policy and the workflow below.

- **Carousels:** slide PNGs, 1080×1350 (4:5).
- **Reels:** `reel.mp4` (1080×1920, 9:16, 30 fps, H.264 + silent AAC) and a `cover.png`. Videos are
  built frame by frame (a CSS animation timeline is seeked and screenshotted, then ffmpeg encodes it),
  so they only render when named explicitly and take a few minutes. For a quick design check, render
  stills instead: `VIDEO_PREVIEW=0,2.7,5 VIDEO_PREVIEW_DIR=/some/dir node arts/src/build.mjs <name>`.

| Post                       | Audience      | Angle                                                                                                  |
| -------------------------- | ------------- | ------------------------------------------------------------------------------------------------------ |
| `profissional_post_001/`   | Professionals | "Serviço bem feito tem que aparecer": everyday pains (photos lost in the phone, re-explaining, a customer who does not know you) answered by the free profile, WhatsApp contact with no fees and quotes, in the professionals' own words. Promises no customers. |
| `profissional_post_002/`   | Professionals | Reel, "Chamou cliente novo no WhatsApp? Ele vai perguntar 3 coisas": the three questions a new customer asks (have you done this before? can I trust you? how much?) answered by photos of past services, the identity label and indications, and the phone quote. Silent: add licensed audio in the Instagram app. |

## Google Ads

**Logos** (`google-ads/logos/`)

| File                         | Size      | Google Ads slot                                     |
| ---------------------------- | --------- | --------------------------------------------------- |
| `logo-square-1200x1200.png`  | 1200×1200 | Square logo (1:1)                                   |
| `logo-landscape-1200x300.png` | 1200×300  | Landscape logo (4:1), transparent, for light backgrounds |

**Creatives** (`google-ads/creatives/`), two audiences, same layouts:

- `clientes/` — teal, "Sua casa em boas mãos." → CTA _Buscar profissionais_ (visitors looking for a professional).
- `profissionais/` — cream, "Mostre seu trabalho. Fortaleça sua reputação." → CTA _Criar perfil grátis_ (professionals joining).

| Size      | Format                        | Notes                                                    |
| --------- | ----------------------------- | -------------------------------------------------------- |
| 1200×628  | Landscape 1.91:1              | Responsive display / Demand Gen                          |
| 1200×1200 | Square 1:1                    | Responsive display / Demand Gen                          |
| 960×1200  | Portrait 4:5                  | Responsive display / Demand Gen                          |
| 300×250   | Medium rectangle              | Standard display image ad, under the 150 KB limit        |
| 728×90    | Leaderboard                   | Standard display image ad, under the 150 KB limit        |
| 300×600   | Half page                     | Standard display image ad, under the 150 KB limit        |

`sem-texto/` holds image-only versions (1200×628, 1200×1200, 960×1200). Use these for Responsive
Display and Performance Max, where Google adds your headlines and CTA itself and discourages text
baked into images.

## Notes

- Copy is pt-BR and reuses the site's own lines so ads match the landing pages. Claims are limited
  to what the product does today (free profile, direct WhatsApp contact, no fee per contact, no commission).
- No WhatsApp logo is used; "WhatsApp" appears as text only.
- The URL shown is `berufe.com.br`. Point each ad's final URL at the matching page
  (`/encontrar` for `clientes`, `/para-profissionais` for `profissionais`).
