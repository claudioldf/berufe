// Instagram post "profissional_post_001" — launch carousel for PROFESSIONALS (5 slides, 1080x1350 / 4:5).
//
// Audience: people who provide home services (electricians, painters, plumbers...). The post leads
// with their everyday pains and answers each with something the product does today.
//
// Output: arts/instagram/posts/profissional_post_001/slide-0N-*.png. The caption and alt text live
// next to the images (caption.txt, post.md) and are written by hand, not generated.
//
// Claims are limited to what the product supports (see apps/web/app/pages/para-profissionais and
// docs/Berufe_MVP_Feature_Plan.md): a shareable profile link with services, coverage area,
// portfolio photos, identity-verified label and references from other professionals; direct
// WhatsApp contact with no fee per contact and no commission; fixed-price or itemized quotes sent
// through WhatsApp that the customer opens without an account; setup in a few minutes. It does NOT
// promise customers or leads, and it does not claim customer reviews.

import { C, cta, heroArt, icon, out, page } from "../lib.mjs";

const W = 1080;
const H = 1350;
const dir = (name) => out("instagram/posts/profissional_post_001", name);

const frameCss = `
.top{position:absolute;left:84px;right:84px;top:76px;display:flex;align-items:center;justify-content:space-between}
.top .brand{font-size:60px}
.copy{position:absolute;left:84px;right:84px;top:214px}
.copy .eyebrow{font-size:26px;margin-bottom:24px}
.swipe{position:absolute;right:84px;bottom:76px;display:flex;align-items:center;gap:18px;font-weight:800;font-size:28px;color:var(--fg)}
.swipe--left{left:84px;right:auto}
.swipe i{display:grid;place-items:center;width:80px;height:80px;border-radius:50%;background:${C.coral};color:${C.deep}}
.ico{flex:none;display:grid;place-items:center;border-radius:50%}
`;

function slide({ theme, css = "", body, swipe = "right" }) {
  const hint =
    swipe === "none"
      ? ""
      : `<div class="swipe swipe--${swipe}"><span>Deslize</span><i>${icon("arrow-right", 40)}</i></div>`;
  return page(
    W,
    H,
    theme,
    frameCss + css,
    `<div class="top"><div class="brand">berufe<span>.</span></div></div>${body}${hint}`,
  );
}

// 1 — Hook: the question every professional hears, answered in three words -----------------
const cover = slide({
  theme: "teal",
  swipe: "left",
  css: `
.halo{width:960px;height:960px;right:-330px;bottom:-150px}
.halo2{width:560px;height:560px;left:-240px;top:-210px}
.art{height:730px;right:-52px;bottom:-12px}
.copy .h{font-size:214px;line-height:.92}
.copy .sub{font-size:36px;margin-top:34px;max-width:540px}
`,
  body: `<div class="halo2"></div><div class="halo"></div>
<img class="art" src="${heroArt}" />
<div class="copy">
  <div class="eyebrow">Cliente pediu exemplos do seu trabalho?</div>
  <div class="h">Mande<br /><em>um link.</em></div>
  <div class="sub">Seu perfil na Berufe reúne serviços, fotos dos trabalhos e contato direto. É grátis.</div>
</div>`,
});

// 2 — The pains ---------------------------------------------------------------------------
const pain = (ic, text) => `<div class="row"><div class="ico">${icon(ic, 44)}</div><div class="tx">${text}</div></div>`;
const pains = slide({
  theme: "cream",
  css: `
.halo2{width:620px;height:620px;right:-250px;top:-220px}
.copy .h{font-size:116px}
.rows{position:absolute;left:84px;right:84px;top:560px}
.row{display:flex;align-items:center;gap:34px;padding:34px 0;border-top:2px solid rgb(23 53 47 / 13%)}
.row:last-child{border-bottom:2px solid rgb(23 53 47 / 13%)}
.row .ico{width:100px;height:100px;background:#fff0ec;color:#df5e48}
.row .tx{font-size:37px;font-weight:700;line-height:1.28;color:${C.deep}}
.next{position:absolute;left:84px;bottom:104px;font-size:38px;font-weight:800;color:${C.teal}}
`,
  body: `<div class="halo2"></div>
<div class="copy">
  <div class="eyebrow">No dia a dia de quem presta serviço</div>
  <div class="h">Você conhece <em>essa rotina?</em></div>
</div>
<div class="rows">
  ${pain("images", "Procurar fotos antigas na galeria sempre que alguém pede exemplos.")}
  ${pain("message-circle", "Explicar tudo de novo, por mensagem, para cada pessoa que chama.")}
  ${pain("house", "Ser um desconhecido para quem vai deixar você entrar em casa.")}
</div>
<div class="next">Existe um jeito mais simples.</div>`,
});

// 3 — The answer: one link with everything -----------------------------------------------
const tile = (ic, label) => `<div class="t"><div class="ico">${icon(ic, 40)}</div><div class="l">${label}</div></div>`;
const profile = slide({
  theme: "teal",
  css: `
.halo2{width:620px;height:620px;right:-260px;top:-240px}
.copy .h{font-size:124px}
.link{position:absolute;left:84px;top:552px;display:inline-flex;align-items:center;gap:18px;background:var(--chip-bg);border:2px solid var(--chip-line);border-radius:999px;padding:22px 38px;font-size:31px;font-weight:700;color:${C.cream}}
.link svg{color:${C.coral};flex:none}
.grid{position:absolute;left:84px;right:84px;top:676px;display:grid;grid-template-columns:1fr 1fr;gap:24px}
.t{display:flex;align-items:center;gap:24px;background:${C.cream};color:${C.deep};border-radius:38px;padding:30px 32px;min-height:172px}
.t .ico{width:86px;height:86px;background:${C.mint};color:${C.teal}}
.t .l{font-size:31px;font-weight:800;line-height:1.2;letter-spacing:-.01em}
.share{position:absolute;left:84px;bottom:92px;width:640px;display:flex;align-items:center;gap:22px;font-size:31px;font-weight:700;line-height:1.3;color:${C.cream}}
.share .ico{width:76px;height:76px;background:${C.coral};color:${C.deep}}
`,
  body: `<div class="halo2"></div>
<div class="copy">
  <div class="eyebrow">Seu perfil na Berufe</div>
  <div class="h">Seu trabalho <em>num link só.</em></div>
</div>
<div class="link">${icon("link", 36)}<span>berufe.com.br/profissionais/seu-nome</span></div>
<div class="grid">
  ${tile("map-pin", "Serviços e região de atendimento")}
  ${tile("images", "Portfólio com fotos dos trabalhos")}
  ${tile("badge-check", "Selo de identidade verificada")}
  ${tile("handshake", "Indicações de outros profissionais")}
</div>
<div class="share"><div class="ico">${icon("share-2", 36)}</div><span>Mande pelo WhatsApp ou fixe na bio do Instagram.</span></div>`,
});

// 4 — Direct contact, no fees, quotes ------------------------------------------------------
const direct = slide({
  theme: "cream",
  css: `
.halo2{width:620px;height:620px;right:-250px;top:-220px}
.copy .h{font-size:104px}
.tiles{position:absolute;left:84px;right:84px;top:672px;display:flex;gap:28px}
.tile{flex:1;background:${C.teal};color:${C.cream};border-radius:40px;padding:38px 40px 42px}
.tile .num{font-family:"Newsreader",Georgia,serif;font-weight:500;font-size:140px;letter-spacing:-.055em;line-height:.9;color:${C.coral400}}
.tile .lbl{font-size:30px;font-weight:700;color:#cfe6dd;line-height:1.25;margin-top:16px}
.quote{position:absolute;left:84px;bottom:76px;width:690px;display:flex;align-items:center;gap:28px;background:#fff;border:2px solid rgb(23 53 47 / 13%);border-radius:38px;padding:30px 36px}
.quote .ico{width:88px;height:88px;background:${C.mint};color:${C.teal}}
.quote .t1{font-size:36px;font-weight:800;color:${C.deep};letter-spacing:-.02em}
.quote .t2{font-size:27px;font-weight:600;color:#4d6660;line-height:1.35;margin-top:6px}
`,
  body: `<div class="halo2"></div>
<div class="copy">
  <div class="eyebrow">Sem intermediário</div>
  <div class="h">Fale direto<br />com o cliente.<br /><em>Sem pagar por isso.</em></div>
</div>
<div class="tiles">
  <div class="tile"><div class="num">R$ 0</div><div class="lbl">por contato recebido</div></div>
  <div class="tile"><div class="num">0%</div><div class="lbl">de comissão sobre o serviço</div></div>
</div>
<div class="quote"><div class="ico">${icon("receipt-text", 42)}</div><div><div class="t1">Orçamento pelo WhatsApp</div><div class="t2">Preço fechado ou detalhado. O cliente abre no celular, sem criar conta.</div></div></div>`,
});

// 5 — Call to action ---------------------------------------------------------------------
const step = (n, text) => `<div class="step"><b>${n}</b><span>${text}</span></div>`;
const closing = slide({
  theme: "teal",
  swipe: "none",
  css: `
.halo2{width:640px;height:640px;right:-260px;top:-230px}
.copy .h{font-size:132px}
.steps{position:absolute;left:84px;right:84px;top:612px;display:flex;flex-direction:column;gap:42px}
.step{display:flex;align-items:center;gap:30px;font-size:37px;font-weight:700;line-height:1.25;color:${C.cream}}
.step b{flex:none;display:grid;place-items:center;width:78px;height:78px;border-radius:50%;background:${C.coral};color:${C.deep};font-size:38px;font-weight:800}
.main-cta{position:absolute;left:84px;bottom:96px;display:flex;align-items:center;gap:30px}
.main-cta .url{font-size:32px}
`,
  body: `<div class="halo2"></div>
<div class="copy">
  <div class="eyebrow">Leva poucos minutos</div>
  <div class="h">Crie seu perfil <em>grátis.</em></div>
</div>
<div class="steps">
  ${step(1, "Confirme seu celular ou e-mail")}
  ${step(2, "Escolha seus serviços e a região onde você atende")}
  ${step(3, "Adicione fotos e a verificação de identidade quando quiser")}
</div>
<div class="main-cta">${cta("Criar perfil grátis", 40)}<span class="url">Link na bio</span></div>`,
});

export const profissionalPost001Jobs = [
  ["slide-01-cover.png", cover],
  ["slide-02-pains.png", pains],
  ["slide-03-profile.png", profile],
  ["slide-04-direct.png", direct],
  ["slide-05-cta.png", closing],
].map(([name, html]) => ({ file: dir(name), w: W, h: H, html }));
