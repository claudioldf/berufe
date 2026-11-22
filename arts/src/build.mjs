// Renders every brand asset in ./arts from HTML templates.
//
//   node arts/src/build.mjs            # render everything
//   node arts/src/build.mjs banner     # render only assets whose path contains "banner"
//
// Uses ImageMagick (`magick`) for the transparent/trimmed landscape logo export.

import { execFileSync } from "node:child_process";
import path from "node:path";
import { C, artsDir, chips, cta, heroArt, openRenderer, out, page } from "./lib.mjs";
import { profissionalPost001Jobs } from "./posts/profissional_post_001.mjs";
import { profissionalPost002Videos } from "./posts/profissional_post_002.mjs";

// ---------------------------------------------------------------------------
// Copy (pt-BR, taken from the live site so ads match the landing pages)
// ---------------------------------------------------------------------------
const COPY = {
  clientes: {
    theme: "teal",
    eyebrow: "Profissionais perto de você",
    h: "Sua casa em<br /><em>boas mãos.</em>",
    hInline: "Sua casa em <em>boas mãos.</em>",
    hShort: "Sua casa em<br /><em>boas mãos.</em>",
    sub: "Conheça o trabalho e as referências de cada profissional antes de escolher.",
    subShort: "Veja o trabalho e as referências antes de escolher.",
    cta: "Buscar profissionais",
    ctaShort: "Buscar agora",
    chips: [
      ["badge-check", "Perfil verificado"],
      ["images", "Portfólio e referências"],
      ["message-circle", "WhatsApp direto"],
    ],
  },
  profissionais: {
    theme: "cream",
    eyebrow: "Você presta serviços?",
    h: "Mostre seu trabalho.<br /><em>Fortaleça sua reputação.</em>",
    hInline: "Mostre seu trabalho. <em>Fortaleça sua reputação.</em>",
    hShort: "Mostre seu trabalho. <em>Seja encontrado.</em>",
    sub: "Crie seu perfil, publique seus trabalhos e peça referências — sem pagar por contatos.",
    subShort: "Perfil grátis, sem pagar por contatos.",
    cta: "Criar perfil grátis",
    ctaShort: "Criar perfil grátis",
    chips: [
      ["badge-check", "Perfil grátis"],
      ["wallet", "Sem comissão"],
      ["message-circle", "WhatsApp direto"],
    ],
  },
};

// ---------------------------------------------------------------------------
// Ad creatives
// ---------------------------------------------------------------------------
function landscape(c) {
  const long = c.theme === "cream";
  return page(
    1200,
    628,
    c.theme,
    `
.halo{width:600px;height:600px;right:30px;top:34px}
.halo2{width:420px;height:420px;right:-90px;top:-130px}
.art{height:610px;right:34px;bottom:-6px}
.copy{position:absolute;left:68px;top:54px;bottom:54px;width:640px;display:flex;flex-direction:column}
.copy .brand{font-size:46px}
.copy .main{margin-top:auto}
.copy .eyebrow{font-size:17px;margin-bottom:16px}
.copy .h{font-size:${long ? 78 : 104}px}
.copy .sub{font-size:24px;margin-top:20px;max-width:${long ? 560 : 520}px}
.copy .row{display:flex;align-items:center;gap:26px;margin-top:28px}
.copy .url{font-size:21px}
`,
    `<div class="halo2"></div><div class="halo"></div>
<img class="art" src="${heroArt}" />
<div class="copy">
  <div class="brand">berufe<span>.</span></div>
  <div class="main">
    <div class="eyebrow">${c.eyebrow}</div>
    <div class="h">${c.h}</div>
    <div class="sub">${c.sub}</div>
    <div class="row">${cta(c.cta, 24)}<span class="url">berufe.com.br</span></div>
  </div>
</div>`,
  );
}

function square(c) {
  const long = c.theme === "cream";
  return page(
    1200,
    1200,
    c.theme,
    `
.halo{width:800px;height:800px;right:-60px;bottom:30px}
.halo2{width:560px;height:560px;left:-200px;bottom:-220px}
.art{height:700px;right:-20px;bottom:-10px}
.copy{position:absolute;left:84px;top:80px;bottom:84px;width:1032px;display:flex;flex-direction:column}
.copy .head{display:flex;align-items:center;justify-content:space-between}
.copy .brand{font-size:68px}
.copy .url{font-size:28px}
.copy .top{margin-top:${long ? 64 : 84}px}
.copy .eyebrow{font-size:25px;margin-bottom:24px}
.copy .h{font-size:${long ? 106 : 140}px}
.copy .sub{font-size:34px;margin-top:28px;max-width:${long ? 700 : 640}px}
.copy .bottom{margin-top:auto;display:flex;flex-direction:column;align-items:flex-start;gap:32px}
.copy .chips{display:flex;flex-direction:column;align-items:flex-start;gap:16px}
`,
    `<div class="halo2"></div><div class="halo"></div>
<img class="art" src="${heroArt}" />
<div class="copy">
  <div class="head"><div class="brand">berufe<span>.</span></div><span class="url">berufe.com.br</span></div>
  <div class="top">
    <div class="eyebrow">${c.eyebrow}</div>
    <div class="h">${c.h}</div>
    <div class="sub">${c.sub}</div>
  </div>
  <div class="bottom">
    <div class="chips">${chips(c.chips, 27)}</div>
    ${cta(c.cta, 32)}
  </div>
</div>`,
  );
}

function portrait(c) {
  const long = c.theme === "cream";
  return page(
    960,
    1200,
    c.theme,
    `
.halo{width:700px;height:700px;right:-120px;top:420px}
.halo2{width:460px;height:460px;right:-170px;top:-150px}
.art{height:690px;right:-34px;top:410px}
.copy{position:absolute;left:70px;top:68px;bottom:72px;width:820px;display:flex;flex-direction:column}
.copy .head{display:flex;align-items:center;justify-content:space-between}
.copy .brand{font-size:60px}
.copy .url{font-size:25px}
.copy .top{margin-top:58px}
.copy .eyebrow{font-size:22px;margin-bottom:20px}
.copy .h{font-size:${long ? 90 : 120}px}
.copy .sub{font-size:30px;margin-top:26px;max-width:${long ? 520 : 460}px}
.copy .bottom{margin-top:auto}
`,
    `<div class="halo2"></div><div class="halo"></div>
<img class="art" src="${heroArt}" />
<div class="copy">
  <div class="head"><div class="brand">berufe<span>.</span></div><span class="url">berufe.com.br</span></div>
  <div class="top">
    <div class="eyebrow">${c.eyebrow}</div>
    <div class="h">${c.h}</div>
    <div class="sub">${c.sub}</div>
  </div>
  <div class="bottom">${cta(c.cta, 32)}</div>
</div>`,
  );
}

function mpu(c) {
  const long = c.theme === "cream";
  return page(
    300,
    250,
    c.theme,
    `
.halo{width:200px;height:200px;right:-26px;bottom:-4px}
.art{height:206px;right:-6px;bottom:-2px;filter:drop-shadow(0 6px 8px var(--shadow))}
.copy{position:absolute;left:18px;top:18px;bottom:18px;width:170px;display:flex;flex-direction:column}
.copy .brand{font-size:21px}
.copy .h{font-size:${long ? 22.5 : 34}px;margin-top:14px;letter-spacing:-0.05em;line-height:1}
.copy .bottom{margin-top:auto}
.copy .url{display:block;font-size:11px;margin-top:8px}
`,
    `<div class="halo"></div>
<img class="art" src="${heroArt}" />
<div class="copy">
  <div class="brand">berufe<span>.</span></div>
  <div class="h">${c.hShort}</div>
  <div class="bottom">${cta(long ? "Criar perfil grátis" : c.ctaShort, 12)}<span class="url">berufe.com.br</span></div>
</div>`,
  );
}

function leaderboard(c) {
  const long = c.theme === "cream";
  return page(
    728,
    90,
    c.theme,
    `
.halo{width:104px;height:104px;left:2px;top:-7px}
.art{height:84px;left:8px;top:3px;filter:drop-shadow(0 3px 4px var(--shadow))}
.brandbox{position:absolute;left:108px;top:0;bottom:0;display:flex;align-items:center}
.brandbox .brand{font-size:25px}
.msg{position:absolute;left:204px;top:0;bottom:0;display:flex;flex-direction:column;justify-content:center;width:340px}
.msg .h{font-size:${long ? 24 : 30}px;letter-spacing:-0.045em;line-height:1}
.msg .sub{font-size:12.5px;margin-top:6px;font-weight:700}
.act{position:absolute;right:16px;top:0;bottom:0;display:flex;align-items:center}
`,
    `<div class="halo"></div>
<img class="art" src="${heroArt}" />
<div class="brandbox"><div class="brand">berufe<span>.</span></div></div>
<div class="msg"><div class="h">${c.hShort.replace("<br />", " ")}</div><div class="sub">${c.subShort}</div></div>
<div class="act">${cta(long ? "Criar perfil grátis" : c.ctaShort, 13)}</div>`,
  );
}

function skyscraper(c) {
  const long = c.theme === "cream";
  return page(
    300,
    600,
    c.theme,
    `
.halo{width:276px;height:276px;left:12px;top:${long ? 262 : 236}px}
.halo2{width:200px;height:200px;right:-70px;top:-60px}
.art{height:${long ? 236 : 262}px;left:50%;transform:translateX(-50%);top:${long ? 270 : 240}px;filter:drop-shadow(0 8px 10px var(--shadow))}
.copy{position:absolute;left:24px;top:26px;right:24px;bottom:26px;display:flex;flex-direction:column}
.copy .brand{font-size:30px}
.copy .eyebrow{font-size:10.5px;margin-top:24px;margin-bottom:10px}
.copy .h{font-size:${long ? 37 : 52}px;line-height:.97}
.copy .bottom{margin-top:auto;display:flex;flex-direction:column;gap:12px;align-items:flex-start}
.copy .url{font-size:13px;margin-left:4px}
`,
    `<div class="halo2"></div><div class="halo"></div>
<img class="art" src="${heroArt}" />
<div class="copy">
  <div class="brand">berufe<span>.</span></div>
  <div class="eyebrow">${c.eyebrow}</div>
  <div class="h">${c.h}</div>
  <div class="bottom">
    ${cta(c.cta, 15)}
    <span class="url">berufe.com.br</span>
  </div>
</div>`,
  );
}

// Image-only versions for Responsive Display / Performance Max / Demand Gen,
// where Google asks for imagery without baked-in text and adds headlines itself.
function clean(w, h) {
  const d = Math.min(w, h);
  return page(
    w,
    h,
    "teal",
    `
.halo{width:${d * 0.86}px;height:${d * 0.86}px;left:50%;top:50%;transform:translate(-50%,-50%)}
.halo2{width:${d * 1.12}px;height:${d * 1.12}px;left:50%;top:50%;transform:translate(-50%,-50%)}
.art{height:${d * 0.78}px;left:50%;top:50%;transform:translate(-50%,-50%)}
`,
    `<div class="halo2"></div><div class="halo"></div><img class="art" src="${heroArt}" />`,
  );
}

// ---------------------------------------------------------------------------
// Logo mark ("b." tile) — same geometry as apps/web/public/favicon.svg
// ---------------------------------------------------------------------------
// The mark is centred on its *ink* box (measured once, see ink offsets below) and sized so
// it survives Instagram's circular crop: the whole mark sits inside the inscribed circle.
function mark(size) {
  const k = size / 64; // favicon units -> px
  const scale = 1.2; // mark size relative to the favicon tile
  // Ink box of the favicon glyph+dot in 64-unit space: x 19.4..51.6, y 16..46.2
  const cx = (19.4 + 51.6) / 2;
  const cy = (16 + 46.2) / 2 + 0.36;
  const tx = 32 - cx * scale;
  const ty = 32 - cy * scale;
  return `<!doctype html><html><head><meta charset="utf-8"><style>
*{margin:0;padding:0}html,body{width:${size}px;height:${size}px;overflow:hidden;background:${C.teal}}
svg{display:block}</style></head><body>
<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 64 64">
<rect width="64" height="64" fill="${C.teal}"/>
<g transform="translate(${tx} ${ty}) scale(${scale})">
<text x="20" y="45" font-family="Georgia, 'Times New Roman', serif" font-weight="700" font-size="38" fill="${C.cream}">b</text>
<circle cx="47" cy="41" r="4.6" fill="${C.coral}"/>
</g></svg></body></html>`;
}

function wordmark() {
  return `<!doctype html><html><head><meta charset="utf-8"><style>
*{margin:0;padding:0}html,body{background:transparent}
.brand{display:inline-block;margin:120px;font-family:Georgia,"Times New Roman",serif;font-weight:700;letter-spacing:-0.045em;line-height:1;font-size:600px;color:${C.teal}}
.brand span{color:${C.coral}}</style></head><body><div class="brand">berufe<span>.</span></div></body></html>`;
}

// ---------------------------------------------------------------------------
// Instagram banner (3:1, 1500x500)
// ---------------------------------------------------------------------------
function banner() {
  return page(
    1500,
    500,
    "teal",
    `
.halo{width:520px;height:520px;right:76px;top:-10px}
.halo2{width:760px;height:760px;right:-110px;top:-130px}
.art{height:478px;right:100px;bottom:8px}
.copy{position:absolute;left:110px;top:0;bottom:0;width:860px;display:flex;flex-direction:column;justify-content:center}
.copy .brand{font-size:58px}
.copy .eyebrow{font-size:17px;margin-top:34px;margin-bottom:12px}
.copy .h{font-size:84px;letter-spacing:-0.05em;line-height:.98;text-wrap:nowrap}
.copy .sub{font-size:25px;margin-top:20px;max-width:700px;text-wrap:wrap}
.copy .url{margin-top:24px;font-size:22px;color:${C.mintMuted}}
`,
    `<div class="halo2"></div><div class="halo"></div>
<img class="art" src="${heroArt}" />
<div class="copy">
  <div class="brand">berufe<span>.</span></div>
  <div class="eyebrow">Profissionais perto de você</div>
  <div class="h">Sua casa em <em>boas mãos.</em></div>
  <div class="sub">Perfil verificado, portfólio e referências.<br />Fale direto pelo WhatsApp, sem taxa por contato.</div>
</div>`,
  );
}

// ---------------------------------------------------------------------------
// Asset list
// ---------------------------------------------------------------------------
const ads = "google-ads/creatives";
const sizes = [
  ["landscape-1200x628", 1200, 628, landscape],
  ["square-1200x1200", 1200, 1200, square],
  ["portrait-960x1200", 960, 1200, portrait],
  ["mpu-300x250", 300, 250, mpu],
  ["leaderboard-728x90", 728, 90, leaderboard],
  ["skyscraper-300x600", 300, 600, skyscraper],
];

const jobs = [
  { file: out("instagram/instagram-profile-icon-2048x2048.png"), w: 2048, h: 2048, html: mark(2048) },
  { file: out("instagram/instagram-banner-1500x500.png"), w: 1500, h: 500, html: banner() },
  { file: out("google-ads/logos/logo-square-1200x1200.png"), w: 1200, h: 1200, html: mark(1200) },
];
for (const [aud, c] of Object.entries(COPY)) {
  for (const [name, w, h, fn] of sizes) {
    jobs.push({ file: out(ads, aud, `${aud}-${name}.png`), w, h, html: fn(c) });
  }
}
for (const [name, w, h] of [
  ["landscape-1200x628", 1200, 628],
  ["square-1200x1200", 1200, 1200],
  ["portrait-960x1200", 960, 1200],
]) {
  jobs.push({ file: out(ads, "sem-texto", `imagem-${name}.png`), w, h, html: clean(w, h) });
}
jobs.push(...profissionalPost001Jobs);

// ---------------------------------------------------------------------------
// Render
// ---------------------------------------------------------------------------
const filter = process.argv[2];
const { shot, video, close, tmp } = await openRenderer();

for (const job of jobs) {
  if (filter && !job.file.includes(filter)) continue;
  await shot(job);
}

// Videos are slow (every frame is a screenshot), so they only render when named explicitly:
//   node arts/src/build.mjs profissional_post_002
// VIDEO_PREVIEW=0,2.7,5 renders just those stills (seconds) into $VIDEO_PREVIEW_DIR for design review.
for (const job of profissionalPost002Videos) {
  if (!filter || !job.file.includes(filter)) continue;
  const times = process.env.VIDEO_PREVIEW?.split(",").map(Number);
  await video(job, times && { times, dir: process.env.VIDEO_PREVIEW_DIR ?? "." });
}

// Landscape logo: transparent background, wordmark trimmed to its ink and fitted into 4:1.
if (!filter || "logo-landscape".includes(filter) || filter === "logo") {
  const raw = path.join(tmp, "wordmark.png");
  await shot({ file: raw, w: 2600, h: 1000, html: wordmark() }, { omitBackground: true });
  const target = out("google-ads/logos/logo-landscape-1200x300.png");
  // 12% vertical padding => ink height 228px of 300; width follows from the wordmark aspect.
  execFileSync("magick", [
    raw, "-trim", "+repage", "-resize", "x228", "-background", "none",
    "-gravity", "center", "-extent", "1200x300", "-strip", target,
  ]);
  console.log("✓", path.relative(artsDir, target));
}

await close();
