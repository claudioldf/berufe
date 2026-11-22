// Instagram post "profissional_post_002" — Reel for PROFESSIONALS (1080x1920 / 9:16, 30 fps, ~28 s).
//
// Concept: "Chamou cliente novo no WhatsApp? Ele vai perguntar 3 coisas." Each question a new
// customer asks before hiring is answered by something the product does today:
//   1. "Você já fez serviço parecido?"  -> photos of past services on the profile
//   2. "Posso confiar em você?"         -> identity-verified label + indication from other professionals
//   3. "Quanto fica o serviço?"         -> quote on the phone (fixed price or itemized)
// then the profile address, "R$ 0 por cliente / 0% do valor do serviço" and the call to action.
//
// Same voice rules as profissional_post_001 (plain words, their trades, no jargon) and the same
// claims policy: only what the product supports, no promise of customers or leads, no reviews, no
// fabricated profile. The chat is generic (no names, no timestamps, no WhatsApp branding), the quote
// card shows real fields (fixed price / itemized, customer-supplied materials, validity) with no
// invented amounts, and the "photos" are crops of the site's synthetic hero illustration.
//
// Render: node arts/src/build.mjs profissional_post_002   (needs ffmpeg; takes a few minutes)
// Stills for design review: VIDEO_PREVIEW=0,2.7,5 node arts/src/build.mjs profissional_post_002
//
// How it works: every animation is a CSS animation with an absolute delay on one shared clock, so
// the renderer can seek to any time and screenshot a frame (see openRenderer().video in lib.mjs).
//
// Safe zones: Reels UI covers roughly the top 270 px and bottom 380 px (and the right edge in the
// lower half), so content stays inside y 280-1540 and x 72-960.

import { C, cta, heroArt, icon, out, page } from "../lib.mjs";

const W = 1080;
const H = 1920;
const FPS = 30;
const DURATION = 28.5;
const COVER_TIME = 2.7; // hook fully on screen
const PROFILE_URL = "berufe.com.br/be/seu-nome"; // /be/<slug>, see apps/web/app/utils/publicProfiles.ts
const dir = (name) => out("instagram/posts/profissional_post_002", name);

// Scene windows in seconds: enter starts at `start`, exit finishes at `end` (consecutive scenes overlap).
const S = {
  hook: { start: 0, end: 3.4 },
  q1: { start: 3.2, end: 8.9 },
  q2: { start: 8.7, end: 14.4 },
  q3: { start: 14.2, end: 19.9 },
  pay: { start: 19.7, end: 24.6 },
  end: { start: 24.4, end: DURATION },
};

// animation: name, absolute delay (s), duration (s), easing. Fill "both" keeps the pre-start state hidden.
const a = (name, delay, dur = 0.5, ease = "var(--pop)") =>
  `animation:${name} ${dur}s ${ease} ${delay.toFixed(2)}s both`;

const scene = ({ start, end }, inner, { enter = true, exit = true } = {}) => {
  const list = [];
  if (enter) list.push(`sceneIn .3s ease-out ${start.toFixed(2)}s both`);
  if (exit) list.push(`sceneOut .3s ease-in ${(end - 0.3).toFixed(2)}s forwards`);
  return `<div class="scene"${list.length ? ` style="animation:${list.join(",")}"` : ""}>${inner}</div>`;
};

const css = `
:root{--pop:cubic-bezier(.2,.9,.3,1.18)}
@keyframes sceneIn{from{opacity:0;transform:translateY(46px)}to{opacity:1;transform:none}}
@keyframes sceneOut{from{opacity:1;transform:none}to{opacity:0;transform:translateY(-46px)}}
@keyframes pop{from{opacity:0;transform:translateY(54px) scale(.9)}to{opacity:1;transform:none}}
@keyframes fadeUp{from{opacity:0;transform:translateY(36px)}to{opacity:1;transform:none}}
@keyframes heroIn{from{transform:scale(.96)}to{transform:none}}
@keyframes hide{to{opacity:0}}
@keyframes dots{0%,70%,100%{transform:translateY(0);opacity:.4}35%{transform:translateY(-12px);opacity:1}}
@keyframes pulse{0%,100%{transform:scale(1)}50%{transform:scale(1.06)}}
@keyframes drift{from{transform:translate(0,0)}to{transform:translate(-46px,52px)}}

.scene{position:absolute;inset:0}
.halo{animation:drift 14s ease-in-out infinite alternate}
.wordmark{position:absolute;left:72px;top:286px;font-size:66px;z-index:5}
.pill{position:absolute;right:72px;top:300px;background:${C.coral};color:${C.deep};font-weight:800;font-size:28px;letter-spacing:.12em;text-transform:uppercase;border-radius:999px;padding:15px 30px}
.col{position:absolute;left:72px;width:888px;display:flex;flex-direction:column;gap:30px}

.msg{border-radius:56px;padding:38px 52px;font-size:56px;line-height:1.22;font-weight:600;letter-spacing:-.012em;color:${C.deep}}
.msg--in{align-self:flex-start;max-width:790px;background:${C.cream};border-top-left-radius:14px;transform-origin:left bottom}
.msg--out{align-self:flex-end;max-width:800px;background:${C.coral};border-top-right-radius:14px;font-weight:800;transform-origin:right bottom;box-shadow:0 22px 36px rgb(5 30 27 / 30%)}
.cust{position:relative;align-self:flex-start}
.typing{position:absolute;left:0;top:0;display:flex;gap:14px;background:${C.cream};border-radius:56px;border-top-left-radius:14px;padding:46px 58px;transform-origin:left bottom}
.typing i{width:20px;height:20px;border-radius:50%;background:#6f8780;animation:dots 1s ease-in-out infinite}
.typing i:nth-child(2){animation-delay:.15s}
.typing i:nth-child(3){animation-delay:.3s}

.card{background:${C.cream};color:${C.deep};border-radius:52px;padding:40px 44px;box-shadow:0 26px 44px rgb(5 30 27 / 30%)}
.hd{display:flex;align-items:center;gap:26px}
.ico{flex:none;display:grid;place-items:center;border-radius:50%;background:${C.mint};color:${C.teal}}
.hd .ico{width:84px;height:84px}
.hd .t{font-size:44px;font-weight:800;letter-spacing:-.02em;line-height:1.1;text-wrap:balance}
.tiles{display:flex;gap:16px;margin-top:32px}
.tile{width:190px;height:190px;border-radius:30px;background-color:${C.mint};background-repeat:no-repeat}
.fcard{display:flex;align-items:center;gap:30px;padding:36px 42px}
.fcard .ico{width:104px;height:104px}
.fcard .t{font-size:46px;font-weight:800;letter-spacing:-.02em;line-height:1.1}
.fcard .d{font-size:31px;font-weight:600;color:#4d6660;line-height:1.3;margin-top:8px}
.seg{display:flex;background:${C.mint};border-radius:999px;padding:8px;margin-top:30px}
.seg span{flex:1;text-align:center;font-size:33px;font-weight:800;padding:20px 0;border-radius:999px;color:${C.teal}}
.seg .on{background:${C.teal};color:${C.cream}}
.rows{display:flex;flex-direction:column;gap:18px;margin-top:30px}
.row{display:flex;align-items:center;gap:22px;font-size:34px;font-weight:700;line-height:1.2}
.row .ico{width:68px;height:68px}
.send{margin-top:34px;display:flex;align-items:center;justify-content:center;gap:18px;background:${C.coral};color:${C.deep};font-size:38px;font-weight:800;border-radius:999px;padding:30px 0}
.note{margin-top:22px;font-size:32px;font-weight:600;color:#4d6660;text-align:center}

.h2{font-family:"Newsreader",Georgia,serif;font-weight:500;letter-spacing:-.055em;line-height:.96;text-wrap:balance}
.h2 em{font-style:italic;color:var(--em)}
.addr{display:inline-flex;align-items:center;gap:18px;background:var(--chip-bg);border:2px solid var(--chip-line);border-radius:999px;padding:24px 42px;font-size:38px;font-weight:700;color:${C.cream}}
.addr svg{color:${C.coral};flex:none}
.stats{display:flex;gap:28px}
.stat{flex:1;background:${C.cream};color:${C.deep};border-radius:48px;padding:40px 40px 44px;box-shadow:0 26px 44px rgb(5 30 27 / 30%)}
.stat .num{font-family:"Newsreader",Georgia,serif;font-weight:500;font-size:150px;letter-spacing:-.055em;line-height:.9;color:#df5e48}
.stat .lbl{font-size:32px;font-weight:700;color:#4d6660;line-height:1.25;margin-top:16px;text-wrap:balance}
`;

// Square crop of the hero illustration drawn into a tile (region of `r` px at x0,y0 of the 1224x1285 art).
const crop = (x0, y0, r, size = 190) => {
  const s = size / r;
  return `background-image:url(${heroArt});background-size:${1224 * s}px ${1285 * s}px;background-position:${-x0 * s}px ${-y0 * s}px`;
};

const pill = (n, s) => `<div class="pill" style="${a("pop", s + 0.3, 0.4)}">Pergunta ${n} de 3</div>`;

// customer question: typing dots first, then the message
const asks = (text, s) => `<div class="cust">
  <div class="typing" style="animation:pop .3s var(--pop) ${(s + 0.5).toFixed(2)}s both,hide .12s linear ${(s + 1.35).toFixed(2)}s forwards"><i></i><i></i><i></i></div>
  <div class="msg msg--in" style="${a("pop", s + 1.4)}">${text}</div>
</div>`;

// 0 — Hook (visible from the very first frame so the autoplay frame and the cover are strong) --
const hook = scene(
  S.hook,
  `<div class="abs" style="left:72px;right:72px;top:520px">
  <div class="eyebrow" style="font-size:30px;letter-spacing:.1em;margin-bottom:28px;${a("heroIn", 0, 0.6, "ease-out")}">Pedreiro, eletricista, pintor, diarista…</div>
  <div class="h2" style="font-size:136px;${a("heroIn", 0, 0.6, "ease-out")}">Chamou cliente<br />novo no<br />WhatsApp?</div>
  <div class="h2" style="font-size:92px;margin-top:52px;${a("fadeUp", 1.0, 0.6, "ease-out")}">Ele vai perguntar<br /><em>3 coisas.</em></div>
</div>`,
  { enter: false },
);

// 1 — "Você já fez serviço parecido?" -> photos of past services ---------------------------------
const q1 = scene(
  S.q1,
  `${pill(1, S.q1.start)}
<div class="col" style="top:520px">
  ${asks("Você já fez serviço parecido?", S.q1.start)}
  <div class="msg msg--out" style="${a("pop", S.q1.start + 2.7)}">Já sim! Olha só:</div>
  <div class="card" style="${a("pop", S.q1.start + 3.2)}">
    <div class="hd"><div class="ico">${icon("images", 44)}</div><div class="t">Fotos dos serviços que você já fez</div></div>
    <div class="tiles">
      <div class="tile" style="${crop(300, 540, 360)};${a("pop", S.q1.start + 3.5, 0.45)}"></div>
      <div class="tile" style="${crop(840, 760, 360)};${a("pop", S.q1.start + 3.65, 0.45)}"></div>
      <div class="tile" style="${crop(560, 200, 360)};${a("pop", S.q1.start + 3.8, 0.45)}"></div>
      <div class="tile" style="${crop(40, 690, 360)};${a("pop", S.q1.start + 3.95, 0.45)}"></div>
    </div>
  </div>
</div>`,
);

// 2 — "Posso confiar em você?" -> identity label + indications ------------------------------------
const q2 = scene(
  S.q2,
  `${pill(2, S.q2.start)}
<div class="col" style="top:540px">
  ${asks("Posso confiar em você?", S.q2.start)}
  <div class="msg msg--out" style="${a("pop", S.q2.start + 2.7)}">Pode sim! Olha:</div>
  <div class="card fcard" style="${a("pop", S.q2.start + 3.2)}">
    <div class="ico">${icon("badge-check", 56)}</div>
    <div><div class="t">Identidade verificada</div><div class="d">O selo aparece no seu perfil.</div></div>
  </div>
  <div class="card fcard" style="${a("pop", S.q2.start + 3.75)}">
    <div class="ico">${icon("handshake", 56)}</div>
    <div><div class="t">Indicação de outros profissionais</div><div class="d">Colegas de profissão indicam o seu trabalho.</div></div>
  </div>
</div>`,
);

// 3 — "Quanto fica o serviço?" -> quote on the phone ---------------------------------------------
const q3 = scene(
  S.q3,
  `${pill(3, S.q3.start)}
<div class="col" style="top:450px">
  ${asks("Quanto fica o serviço?", S.q3.start)}
  <div class="msg msg--out" style="${a("pop", S.q3.start + 2.7)}">Já te mando o orçamento:</div>
  <div class="card" style="${a("pop", S.q3.start + 3.2)}">
    <div class="hd"><div class="ico">${icon("receipt-text", 44)}</div><div class="t">Orçamento no celular</div></div>
    <div class="seg"><span class="on">Preço fechado</span><span>Detalhado</span></div>
    <div class="rows">
      <div class="row"><div class="ico">${icon("package", 34)}</div>Materiais que o cliente compra</div>
      <div class="row"><div class="ico">${icon("calendar-clock", 34)}</div>Validade do orçamento</div>
    </div>
    <div class="send" style="${a("pop", S.q3.start + 4.1, 0.45)}">${icon("send", 40)}Enviar pelo WhatsApp</div>
    <div class="note" style="${a("fadeUp", S.q3.start + 4.5, 0.5, "ease-out")}">O cliente abre no celular, sem criar conta.</div>
  </div>
</div>`,
);

// 4 — Everything on one profile; what it costs -----------------------------------------------------
const pay = scene(
  S.pay,
  `<div class="abs" style="left:72px;right:72px;top:520px">
  <div class="eyebrow" style="font-size:34px;margin-bottom:26px;${a("fadeUp", S.pay.start + 0.2, 0.5, "ease-out")}">Seu perfil na Berufe</div>
  <div class="h2" style="font-size:132px;${a("fadeUp", S.pay.start + 0.35, 0.6, "ease-out")}">Tudo isso <em>no seu perfil.</em></div>
  <div style="margin-top:50px;${a("pop", S.pay.start + 1.2)}"><div class="addr">${icon("link", 40)}<span>${PROFILE_URL}</span></div></div>
  <div class="stats" style="margin-top:56px">
    <div class="stat" style="${a("pop", S.pay.start + 2.0)}"><div class="num">R$ 0</div><div class="lbl">por cliente que chamar você</div></div>
    <div class="stat" style="${a("pop", S.pay.start + 2.4)}"><div class="num">0%</div><div class="lbl">do valor do serviço fica com a Berufe</div></div>
  </div>
</div>`,
);

// 5 — Call to action (holds to the end) ------------------------------------------------------------
const end = scene(
  S.end,
  `<div class="abs" style="left:72px;right:72px;top:600px">
  <div class="eyebrow" style="font-size:34px;margin-bottom:28px;${a("fadeUp", S.end.start + 0.3, 0.5, "ease-out")}">Leva poucos minutos</div>
  <div class="h2" style="font-size:150px;${a("fadeUp", S.end.start + 0.45, 0.6, "ease-out")}">Crie seu perfil <em>grátis.</em></div>
  <div style="margin-top:70px;${a("pop", S.end.start + 1.3)}"><div style="display:inline-flex;animation:pulse 1.6s ease-in-out ${(S.end.start + 2.2).toFixed(2)}s infinite">${cta("Criar perfil grátis", 46)}</div></div>
  <div style="margin-top:44px;font-size:42px;font-weight:800;color:${C.cream};${a("fadeUp", S.end.start + 1.8, 0.5, "ease-out")}">Link na bio</div>
</div>`,
  { exit: false },
);

const html = page(
  W,
  H,
  "teal",
  css,
  `<div class="halo halo2" style="width:900px;height:900px;left:-420px;top:-300px"></div>
<div class="halo" style="width:1100px;height:1100px;right:-620px;bottom:-480px"></div>
<div class="brand wordmark">berufe<span>.</span></div>
${hook}${q1}${q2}${q3}${pay}${end}`,
);

export const profissionalPost002Videos = [
  {
    file: dir("reel.mp4"),
    w: W,
    h: H,
    fps: FPS,
    duration: DURATION,
    html,
    cover: { time: COVER_TIME, file: dir("cover.png") },
  },
];
