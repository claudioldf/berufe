// Shared helpers for the art scripts (build.mjs, posts/*.mjs).
//
// Uses the Playwright + Lucide installs from apps/web (run `pnpm install` there first).

import { execFileSync } from "node:child_process";
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

  // Loads the job's HTML at its size and waits for fonts and images.
  async function load(job) {
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
  }

  const logDone = (file) => {
    const rel = path.relative(artsDir, file);
    if (!rel.startsWith("..")) console.log("✓", rel);
  };

  async function shot(job, opts = {}) {
    await load(job);
    fs.mkdirSync(path.dirname(job.file), { recursive: true });
    await tab.screenshot({ path: job.file, ...opts });
    logDone(job.file);
  }

  // Moves every CSS animation on the page to `seconds` and waits for the frame to paint.
  // Animations are paused first, so the page clock never advances on its own and each
  // frame is deterministic.
  const seek = async (seconds) => {
    await tab.evaluate(
      (ms) =>
        new Promise((resolve) => {
          for (const a of document.getAnimations()) {
            a.pause();
            a.currentTime = ms;
          }
          requestAnimationFrame(() => requestAnimationFrame(resolve));
        }),
      seconds * 1000,
    );
  };

  // Renders an animated page to an H.264 MP4 (Instagram-ready) by screenshotting it frame by
  // frame. `job`: { file, w, h, fps, duration, html, cover?: { time, file } }.
  // `preview`: { times: [seconds], dir } writes only those still frames, for design review.
  async function video(job, preview) {
    await load(job);
    if (preview) {
      fs.mkdirSync(preview.dir, { recursive: true });
      for (const t of preview.times) {
        await seek(t);
        await tab.screenshot({ path: path.join(preview.dir, `t${String(t).padStart(5, "0")}.png`) });
      }
      return;
    }

    const frames = path.join(tmp, `frames-${path.basename(job.file)}`);
    fs.mkdirSync(frames, { recursive: true });
    const total = Math.round(job.duration * job.fps);
    const coverIndex = job.cover ? Math.round(job.cover.time * job.fps) : -1;
    for (let i = 0; i < total; i++) {
      await seek(i / job.fps);
      const f = path.join(frames, `f${String(i).padStart(5, "0")}.png`);
      await tab.screenshot({ path: f });
      if (i === coverIndex) {
        fs.mkdirSync(path.dirname(job.cover.file), { recursive: true });
        fs.copyFileSync(f, job.cover.file);
        logDone(job.cover.file);
      }
      if (i % 90 === 0) console.log(`  frame ${i}/${total}`);
    }

    fs.mkdirSync(path.dirname(job.file), { recursive: true });
    // yuv420p + faststart keep it playable everywhere; a silent AAC track avoids "no audio"
    // edge cases in uploaders (music is added in the Instagram app).
    // FFMPEG=/path/to/ffmpeg overrides the binary (e.g. when the one on PATH is broken).
    const ffmpeg = process.env.FFMPEG ?? "ffmpeg";
    try {
      execFileSync(ffmpeg, [
        "-y", "-loglevel", "error",
        "-framerate", String(job.fps), "-i", path.join(frames, "f%05d.png"),
        "-f", "lavfi", "-i", "anullsrc=channel_layout=stereo:sample_rate=44100",
        "-c:v", "libx264", "-preset", "slow", "-crf", "18", "-pix_fmt", "yuv420p",
        "-r", String(job.fps), "-c:a", "aac", "-b:a", "128k", "-shortest",
        "-movflags", "+faststart", job.file,
      ], { stdio: ["ignore", "ignore", "pipe"] });
    } catch (error) {
      // Keep the rendered frames: re-encoding them takes seconds, re-rendering takes minutes.
      throw new Error(
        `ffmpeg (${ffmpeg}) failed to encode ${job.file}. The ${total} rendered frames are kept in ${frames}.\n` +
          `Fix ffmpeg (needs libx264 and aac) or point FFMPEG at a working binary, then re-encode.\n` +
          String(error.stderr ?? error.message),
      );
    }
    fs.rmSync(frames, { recursive: true, force: true });
    logDone(job.file);
  }

  async function close() {
    await browser.close();
    fs.rmSync(tmp, { recursive: true, force: true });
  }

  return { shot, video, close, tmp };
}
