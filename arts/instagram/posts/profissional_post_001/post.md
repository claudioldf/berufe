# profissional_post_001 — "Mande um link"

First Instagram post, aimed at **professionals** (people who provide home services), not at customers.
A 5-slide carousel, 1080×1350 (4:5). Paste `caption.txt` as the caption.

Source: `arts/src/posts/profissional_post_001.mjs` (`node arts/src/build.mjs profissional_post_001`
re-renders the slides).

## Angle

The cover shows the hook as a chat every professional has had: a customer asks for examples of their
work and the reply is a link. (An earlier cover used the house illustration from the customer ads; it
read as customer-facing, so it was replaced.) The
carousel names three everyday pains, then answers each one with something the product does today.

| Pain (slide 2)                                                  | What answers it                                                    |
| --------------------------------------------------------------- | ------------------------------------------------------------------ |
| Digging through old photos when someone asks for examples       | Portfolio on the public profile, shared as one link (slide 3)      |
| Re-explaining everything by message, person by person           | Profile with services, coverage area and contact in one place (3)  |
| Being a stranger to someone who will let you into their home    | Identity-verified label and references from other professionals (3) |
| _(slide 4)_ Paying per contact or giving a cut of the job        | R$ 0 per contact and 0% commission; direct WhatsApp contact        |
| _(slide 4)_ Quotes improvised in chat                            | Quote link: fixed price or itemized, opened on the customer's phone without an account |

## Slides

| #   | File                   | On-slide text                                                                                                                              |
| --- | ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| 1   | `slide-01-cover.png`    | Para quem presta serviços — chat: "Oi! Você tem fotos de trabalhos que já fez?" → "Claro! Dá uma olhada:" + link — **Mande um link.** — Seu perfil na Berufe reúne serviços, fotos dos trabalhos e contato direto. Selo "Perfil grátis". |
| 2   | `slide-02-pains.png`    | Você conhece essa rotina? — Procurar fotos antigas… · Explicar tudo de novo… · Ser um desconhecido… — Existe um jeito mais simples.        |
| 3   | `slide-03-profile.png`  | Seu trabalho num link só. — berufe.com.br/profissionais/seu-nome — Serviços e região · Portfólio · Selo de identidade verificada · Indicações — Mande pelo WhatsApp ou fixe na bio do Instagram. |
| 4   | `slide-04-direct.png`   | Fale direto com o cliente. Sem pagar por isso. — R$ 0 por contato recebido · 0% de comissão sobre o serviço — Orçamento pelo WhatsApp      |
| 5   | `slide-05-cta.png`      | Crie seu perfil grátis. — 1 Confirme celular ou e-mail · 2 Serviços e região · 3 Fotos e verificação quando quiser — Criar perfil grátis (link na bio) |

The profile grid crops posts to the centre 3:4, so every slide keeps its content inside 84 px side
margins.

## Alt text (paste into "Advanced settings → Write alternative text", one per slide)

1. Conversa de mensagens: um cliente pergunta "Oi! Você tem fotos de trabalhos que já fez?" e o profissional responde "Claro! Dá uma olhada:" com um link de perfil da Berufe. Abaixo, o título "Mande um link." e o texto "Seu perfil na Berufe reúne serviços, fotos dos trabalhos e contato direto." Um selo diz "Perfil grátis".
2. Título "Você conhece essa rotina?" e três situações do dia a dia: procurar fotos antigas na galeria, explicar tudo de novo por mensagem e ser um desconhecido para quem vai deixar você entrar em casa. Abaixo: "Existe um jeito mais simples."
3. Título "Seu trabalho num link só" com um endereço de perfil da Berufe e quatro cartões: serviços e região de atendimento, portfólio com fotos dos trabalhos, selo de identidade verificada e indicações de outros profissionais.
4. Título "Fale direto com o cliente. Sem pagar por isso." com dois destaques, "R$ 0 por contato recebido" e "0% de comissão sobre o serviço", e um cartão sobre orçamento enviado pelo WhatsApp.
5. Título "Crie seu perfil grátis" com três passos: confirmar celular ou e-mail, escolher serviços e região, adicionar fotos e verificação de identidade quando quiser. Botão "Criar perfil grátis" e o aviso "Link na bio".

## What the post does not claim (on purpose)

Everything on the slides comes from `apps/web/app/pages/para-profissionais`,
`docs/Berufe_MVP_Feature_Plan.md`, and the founder's own outreach script in `docs/Entrevista.md`.

- **No promise of customers or leads.** The product is early; the founder's script says plainly
  "não vou te prometer clientes que ainda não temos". The caption only says people who search by
  service and city _can_ find the profile.
- **No customer reviews or ratings.** References come from other professionals in the network.
- **No fabricated profile or conversation.** The cover chat is a generic scenario (no names, no
  timestamps, no WhatsApp branding) and slides 1 and 3 show a placeholder address (`seu-nome`), not a
  real person.
- **No "Google ranking" or traffic numbers.**

## Before publishing

- **Link in bio** should point at `https://www.berufe.com.br/para-profissionais`. To measure this
  post, use `…/para-profissionais?utm_source=instagram&utm_medium=social&utm_campaign=profissional_post_001`.
- No Instagram handle is defined anywhere in the repo, so the caption does not mention one. Add an
  `@` mention or a "siga @…" line if the account name is final.
- If the product changes before the post goes out (fees, verification, quotes), re-check the slides
  against the live `/para-profissionais` page.
- No city is named on the slides: location is set when building the audience on Instagram.
