# profissional_post_002 — "Chamou cliente novo no WhatsApp? Ele vai perguntar 3 coisas."

Second Instagram post, again aimed at **professionals** (pedreiro, eletricista, pintor, encanador,
diarista…), this time as a **Reel**. Where post 001 named the pains, this one walks through the three
questions a new customer asks before hiring, and answers each with something the product does today.

| File         | What                                                                          |
| ------------ | ----------------------------------------------------------------------------- |
| `reel.mp4`   | 1080×1920 (9:16), 30 fps, 28.5 s, H.264 + silent AAC track                    |
| `cover.png`  | 1080×1920 cover frame (the hook fully on screen)                              |
| `caption.txt`| Caption to paste (pt-BR, plain voice, no cities)                              |

Source: `arts/src/posts/profissional_post_002.mjs`. Re-render with
`node arts/src/build.mjs profissional_post_002` (needs `ffmpeg`, or `FFMPEG=/path/to/ffmpeg`; about three
minutes to render the frames, seconds to encode).

## Voice

Same rules as post 001: plain words about their world (serviço, cliente, foto do serviço, orçamento,
indicação), their trades named on screen, no product jargon. The three questions are written the way a
customer actually types them in a chat.

## Storyboard

| Time (s)    | Scene          | On screen                                                                                                   | Product feature it shows                                      |
| ----------- | -------------- | ----------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------- |
| 0.0 – 3.4   | Hook           | Pedreiro, eletricista, pintor, diarista… — **Chamou cliente novo no WhatsApp?** — Ele vai perguntar 3 coisas. | —                                                             |
| 3.2 – 8.9   | Pergunta 1 de 3 | Customer: "Você já fez serviço parecido?" → "Já sim! Olha só:" → card **Fotos dos serviços que você já fez** (4 tiles) | Portfolio photos on the profile                                |
| 8.7 – 14.4  | Pergunta 2 de 3 | Customer: "Posso confiar em você?" → "Pode sim! Olha:" → **Identidade verificada** · **Indicação de outros profissionais** | Identity-verified label; indications from other professionals |
| 14.2 – 19.9 | Pergunta 3 de 3 | Customer: "Quanto fica o serviço?" → "Já te mando o orçamento:" → **Orçamento no celular** (Preço fechado / Detalhado, materiais que o cliente compra, validade) → Enviar pelo WhatsApp · "O cliente abre no celular, sem criar conta." | Quote generator: fixed price or itemized, customer-supplied materials, validity, share through WhatsApp, no customer account |
| 19.7 – 24.6 | Payoff         | **Tudo isso no seu perfil.** — berufe.com.br/be/seu-nome — R$ 0 por cliente que chamar você · 0% do valor do serviço fica com a Berufe | Public profile at `/be/<slug>`; no fee per contact, no commission |
| 24.4 – 28.5 | Call to action | Leva poucos minutos — **Crie seu perfil grátis.** — Criar perfil grátis · Link na bio                       | Free signup in a few minutes                                  |

The first frame already shows the headline (Instagram autoplays from it), and the hook is the cover.

## Safe zones

The Reels interface covers roughly the top 270 px, the bottom 380 px and the right edge in the lower
half, so all content stays inside y 280–1540 and x 72–960. The profile grid shows the centre 3:4 of
the cover, which contains the whole hook.

## Video description (for accessibility, since Reels have no alt-text field)

Vídeo vertical de 28 segundos com texto na tela, sem fala. Abre com "Chamou cliente novo no WhatsApp? Ele vai perguntar 3 coisas." Em seguida, três conversas de mensagens: o cliente pergunta "Você já fez serviço parecido?" e o profissional mostra fotos dos serviços que já fez; o cliente pergunta "Posso confiar em você?" e aparecem "Identidade verificada" e "Indicação de outros profissionais"; o cliente pergunta "Quanto fica o serviço?" e aparece um orçamento no celular, com preço fechado ou detalhado, que o profissional envia pelo WhatsApp. Depois: "Tudo isso no seu perfil", o endereço berufe.com.br/be/seu-nome, "R$ 0 por cliente que chamar você" e "0% do valor do serviço fica com a Berufe". Termina com "Crie seu perfil grátis" e "Link na bio".

## Audio

The video is silent on purpose (every message is on screen, so it works muted). Add audio inside the
Instagram app, picking from its licensed library. Do not use unlicensed music. If you add a voice-over
later, keep it to the on-screen lines.

## What the post does not claim (on purpose)

Same policy as post 001, from `apps/web/app/pages/para-profissionais`,
`docs/Berufe_MVP_Feature_Plan.md` and `docs/Entrevista.md`:

- **No promise of customers or leads.** The chat shows a customer asking questions, not a result.
- **No customer reviews or ratings.** Indications come from other professionals.
- **No fabricated profile, person or numbers.** The chat has no names, timestamps or WhatsApp
  branding; the address is a placeholder (`seu-nome`); the quote card shows real fields with no
  invented amounts; the "photos" are crops of the site's synthetic hero illustration, used as generic
  stand-ins for a professional's own work.
- **No "Google ranking" or traffic numbers.**

## Before publishing

- **Upload:** Instagram → Create → Reel → pick `reel.mp4`. Choose **Edit cover → Add from camera
  roll** and select `cover.png`. Add audio, then paste `caption.txt`.
- **Link in bio** should point at `https://www.berufe.com.br/para-profissionais`. To measure this
  post, use `…/para-profissionais?utm_source=instagram&utm_medium=social&utm_campaign=profissional_post_002`.
- No Instagram handle is defined anywhere in the repo, so the caption does not mention one.
- No city is named in the video or the caption: location is set when building the audience on
  Instagram.
- If the product changes before the post goes out (fees, verification, quotes), re-check the video
  against the live `/para-profissionais` page.
