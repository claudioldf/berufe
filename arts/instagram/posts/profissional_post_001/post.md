# profissional_post_001 — "Serviço bem feito tem que aparecer"

First Instagram post, aimed at **professionals**: Brazilian self-employed home-service workers
(pedreiro, eletricista, pintor, encanador, diarista…), not at customers. A 5-slide carousel,
1080×1350 (4:5). Paste `caption.txt` as the caption.

Source: `arts/src/posts/profissional_post_001.mjs` (`node arts/src/build.mjs profissional_post_001`
re-renders the slides).

## Voice

Written the way these professionals talk, not the way the product is specced: plain words about
their world (serviço, cliente, foto do serviço, orçamento, indicação), short sentences, pride in the
work first and the tool second. Product jargon was swapped out:

| Product word         | On the slides                              |
| -------------------- | ------------------------------------------ |
| portfólio            | fotos dos serviços que você já fez         |
| contato direto       | o cliente chama você direto no WhatsApp    |
| sem intermediário    | sem atravessador                           |
| comissão             | 0% do valor do serviço fica com a Berufe   |
| taxa por contato     | R$ 0 por cliente que chamar você           |
| "Mande um link" (v1) | "Serviço bem feito tem que aparecer"       |

The cover calls out their trades by name ("Pedreiro, eletricista, pintor…") so they recognise
themselves in the feed.

## Angle

The cover shows a chat every professional has had: a customer asks for photos of past work. The
carousel then names three everyday pains and answers each one with something the product does today.

| Pain (slide 2)                                                         | What answers it                                                                      |
| ---------------------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| Scrolling the phone for photos when a customer asks                    | Photos of past services on the profile, at `berufe.com.br/be/seu-nome` (slide 3)      |
| Explaining everything again on WhatsApp, customer by customer          | Services, coverage area and photos in one place (3)                                  |
| The customer doesn't know you and hesitates to let you into their home | Identity-verified label and indications from other professionals (3)                 |
| _(slide 4)_ Paying per contact or giving a cut of the job              | R$ 0 per customer who calls; 0% of the service value goes to Berufe                  |
| _(slide 4)_ Quotes improvised in chat                                  | Quote on the phone: fixed price or itemized, opened by the customer without account  |

## Slides

| #   | File                   | On-slide text                                                                                                                                                                                                                  |
| --- | ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 1   | `slide-01-cover.png`   | Pedreiro, eletricista, pintor… — chat: "Boa tarde! Tem foto de serviço que você já fez?" → "Tenho sim! Olha aqui:" + address — **Serviço bem feito tem que aparecer.** — Junte suas fotos e seus serviços num lugar só. É de graça. Selo "Perfil grátis". |
| 2   | `slide-02-pains.png`   | Quem trabalha por conta própria sabe — Isso acontece com você? — foto perdida no celular · explicar tudo de novo no WhatsApp · cliente com receio — Tem jeito mais fácil.                                                       |
| 3   | `slide-03-profile.png` | Seu serviço num lugar só. — berufe.com.br/be/seu-nome — Serviços e onde atende · Fotos dos serviços · Selo de identidade verificada · Indicação de outros profissionais — Mande no WhatsApp ou coloque na bio do Instagram.      |
| 4   | `slide-04-direct.png`  | Sem atravessador — O cliente chama você direto no WhatsApp. — R$ 0 por cliente que chamar você · 0% do valor do serviço fica com a Berufe — Orçamento no celular                                                                |
| 5   | `slide-05-cta.png`     | Crie seu perfil grátis. — 1 Confirme celular ou e-mail · 2 Serviços e onde atende · 3 Fotos e identidade quando quiser — Criar perfil grátis (link na bio)                                                                       |

The profile grid crops posts to the centre 3:4, so every slide keeps its content inside 84 px
side margins.

## Alt text (paste into "Advanced settings → Write alternative text", one per slide)

1. Conversa de mensagens: um cliente pergunta "Boa tarde! Tem foto de serviço que você já fez?" e o profissional responde "Tenho sim! Olha aqui:" com o endereço de um perfil da Berufe. Abaixo, o título "Serviço bem feito tem que aparecer." e o texto "Junte suas fotos e seus serviços num lugar só. É de graça." Um selo diz "Perfil grátis".
2. Título "Isso acontece com você?" e três situações: o cliente pede foto de um serviço e você fica rolando o celular atrás, explicar tudo de novo no WhatsApp para cada cliente, e o cliente que não te conhece e tem receio de deixar você entrar em casa. Abaixo: "Tem jeito mais fácil."
3. Título "Seu serviço num lugar só" com o endereço berufe.com.br/be/seu-nome e quatro cartões: os serviços que você faz e onde atende, fotos dos serviços que você já fez, selo de identidade verificada e indicação de outros profissionais.
4. Título "O cliente chama você direto no WhatsApp" com dois destaques, "R$ 0 por cliente que chamar você" e "0% do valor do serviço fica com a Berufe", e um cartão sobre orçamento no celular.
5. Título "Crie seu perfil grátis" com três passos: confirmar celular ou e-mail, dizer quais serviços faz e onde atende, e colocar fotos e confirmar a identidade quando quiser. Botão "Criar perfil grátis" e o aviso "Link na bio".

## What the post does not claim (on purpose)

Everything on the slides comes from `apps/web/app/pages/para-profissionais`,
`docs/Berufe_MVP_Feature_Plan.md`, and the founder's own outreach script in `docs/Entrevista.md`.

- **No promise of customers or leads.** The product is early; the founder's script says plainly
  "não vou te prometer clientes que ainda não temos". The caption only says people who search by
  service and city _can_ find the profile.
- **No customer reviews or ratings.** Indications come from other professionals in the network.
- **No fabricated profile or conversation.** The cover chat is a generic scenario (no names, no
  timestamps, no WhatsApp branding) and slides 1 and 3 show a placeholder address (`seu-nome`), not
  a real person.
- **No "Google ranking" or traffic numbers.**

## Before publishing

- **Profile address** is `berufe.com.br/be/<slug>` (`apps/web/app/utils/publicProfiles.ts`). If that
  route changes, update `PROFILE_URL` in the template and re-render.
- **Link in bio** should point at `https://www.berufe.com.br/para-profissionais`. To measure this
  post, use `…/para-profissionais?utm_source=instagram&utm_medium=social&utm_campaign=profissional_post_001`.
- No Instagram handle is defined anywhere in the repo, so the caption does not mention one. Add an
  `@` mention or a "siga @…" line if the account name is final.
- No city is named on the slides: location is set when building the audience on Instagram. The
  caption still lists the four cities and uses city hashtags; remove them if you prefer.
- If the product changes before the post goes out (fees, verification, quotes), re-check the slides
  against the live `/para-profissionais` page.
