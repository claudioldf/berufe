// Shared helpers for the art scripts (build.mjs, posts/*.mjs).
//
// Uses the Playwright + Lucide installs from apps/web (run `pnpm install` there first).

import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { createRequire } from "node:module";
import { fileURLToPath, pathToFileURL } from "node:url";

export const here = path.dirname(fileURLToPath(import.meta.url));
export const artsDir = path.resolve(here, "..");
const webDir = path.resolve(here, "../../apps/web");
const require = createRequire(path.join(webDir, "package.json"));
const { chromium } = require("@playwright/test");
const lucide = JSON.parse(
  fs.readFileSync(
    path.join(webDir, "node_modules/@iconify-json/lucide/icons.json"),
    "utf8",
  ),
);

export const out = (...p) => path.join(artsDir, ...p);
export const url = (p) => pathToFileURL(p).href;
const fontUrl = (f) => url(path.join(here, "fonts", f));
export const heroArt = url(
  path.join(webDir, "public/images/hero-home-care-illustration.webp"),
);

// ---------------------------------------------------------------------------
// Brand tokens (apps/web/app/assets/scss/main.scss + tailwind.css)
// ---------------------------------------------------------------------------
export const C = {
  teal: "#12625d",
  deep: "#17352f",
  coral: "#f8755d",
  coral400: "#ff8b75",
  cream: "#f7f5ef",
  mint: "#d8f0e7",
  mintMuted: "#a7d7c8",
};

export const icon = (name, size) => {
  const body = lucide.icons[name]?.body;
  if (!body) throw new Error(`Unknown lucide icon: ${name}`);
  return `<svg width="${size}" height="${size}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.25" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${body}</svg>`;
};


// ---------------------------------------------------------------------------
// Shared CSS
// ---------------------------------------------------------------------------
export const baseCss = (w, h) => `
@font-face{font-family:"Manrope";src:url("${fontUrl("manrope-latin-variable.woff2")}") format("woff2");font-weight:200 800;}
@font-face{font-family:"Newsreader";src:url("${fontUrl("newsreader-latin-variable.woff2")}") format("woff2");font-weight:200 800;font-style:normal;}
@font-face{font-family:"Newsreader";src:url("${fontUrl("newsreader-latin-italic-variable.woff2")}") format("woff2");font-weight:200 800;font-style:italic;}
*{box-sizing:border-box;margin:0;padding:0}
html,body{width:${w}px;height:${h}px;overflow:hidden;background:transparent}
.canvas{position:relative;width:${w}px;height:${h}px;overflow:hidden;background:var(--bg);color:var(--fg);font-family:"Manrope","Avenir Next",Avenir,sans-serif;-webkit-font-smoothing:antialiased}
.theme-teal{--bg:${C.teal};--fg:${C.cream};--muted:#cfe6dd;--em:${C.coral400};--eyebrow:${C.mintMuted};--halo:rgb(255 255 255 / 9%);--halo2:rgb(255 255 255 / 6%);--chip-bg:rgb(255 255 255 / 11%);--chip-line:rgb(255 255 255 / 26%);--shadow:rgb(5 30 27 / 38%)}
.theme-cream{--bg:${C.cream};--fg:${C.deep};--muted:#4d6660;--em:${C.teal};--eyebrow:${C.teal};--halo:${C.mint};--halo2:#e8f4f0;--chip-bg:#ffffff;--chip-line:rgb(23 53 47 / 16%);--shadow:rgb(23 53 47 / 26%)}
.brand{font-family:Georgia,"Times New Roman",serif;font-weight:700;letter-spacing:-0.045em;line-height:1}
.brand span{color:${C.coral}}
.eyebrow{font-weight:800;letter-spacing:.14em;text-transform:uppercase;color:var(--eyebrow)}
.h{font-family:"Newsreader",Georgia,serif;font-weight:500;letter-spacing:-0.055em;line-height:.96;text-wrap:balance}
.h em{font-style:italic;color:var(--em)}
.sub{font-weight:600;color:var(--muted);line-height:1.42;text-wrap:balance}
.cta{display:inline-flex;align-items:center;gap:.55em;background:${C.coral};color:${C.deep};font-weight:800;border-radius:999px;white-space:nowrap}
.url{font-weight:800;color:var(--fg);letter-spacing:.01em}
.chip{display:inline-flex;align-items:center;gap:.5em;background:var(--chip-bg);border:2px solid var(--chip-line);color:var(--fg);font-weight:700;border-radius:999px;white-space:nowrap}
.chip svg{color:${C.coral};flex:none}
.theme-cream .chip svg{color:${C.teal}}
.halo{position:absolute;border-radius:50%;background:var(--halo)}
.halo2{position:absolute;border-radius:50%;background:var(--halo2)}
.dot{position:absolute;border-radius:50%;background:${C.coral}}
.art{position:absolute;display:block;filter:drop-shadow(0 22px 28px var(--shadow))}
.abs{position:absolute}
`;

export const page = (w, h, theme, css, body) => `<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><style>${baseCss(w, h)}${css}</style></head><body><div class="canvas theme-${theme}">${body}</div></body></html>`;

export const cta = (label, size, extra = "") =>
  `<span class="cta" style="font-size:${size}px;padding:${size * 0.78}px ${size * 1.35}px;${extra}">${label}${icon("arrow-right", size * 1.1)}</span>`;

export const chips = (list, size) =>
  list
    .map(
      ([i, t]) =>
        `<span class="chip" style="font-size:${size}px;padding:${size * 0.5}px ${size * 0.95}px">${icon(i, size * 1.15)}${t}</span>`,
    )
    .join("");


// ---------------------------------------------------------------------------
// Renderer
// ---------------------------------------------------------------------------
// Opens one Chromium tab and screenshots HTML jobs ({ file, w, h, html }) to PNG.
export async function openRenderer() {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), "berufe-arts-"));
  const browser = await chromium.launch();
  const ctx = await browser.newContext({ deviceScaleFactor: 1 });
  const tab = await ctx.newPage();

  async function shot(job, opts = {}) {
    const htmlPath = path.join(tmp, `${path.basename(job.file)}.html`);
    fs.writeFileSync(htmlPath, job.html);
    await tab.setViewportSize({ width: job.w, height: job.h });
    await tab.goto(url(htmlPath));
    await tab.evaluate(async () => {
      await document.fonts.ready;
      await Promise.all(
        [...document.images].map((i) => (i.decode ? i.decode().catch(() => {}) : null)),
      );
    });
    fs.mkdirSync(path.dirname(job.file), { recursive: true });
    await tab.screenshot({ path: job.file, ...opts });
    const rel = path.relative(artsDir, job.file);
    if (!rel.startsWith("..")) console.log("✓", rel);
  }

  async function close() {
    await browser.close();
    fs.rmSync(tmp, { recursive: true, force: true });
  }

  return { shot, close, tmp };
}
