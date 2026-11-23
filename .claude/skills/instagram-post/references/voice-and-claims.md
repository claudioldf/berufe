# Voice and claims

Applies to every post. Sources behind the facts: `apps/web/app/pages/para-profissionais`,
`docs/Berufe_MVP_Feature_Plan.md`, `docs/Entrevista.md`, `apps/web/app/utils/publicProfiles.ts`.
Re-read them when a line below looks out of date.

## Voice

The audience is a self-employed Brazilian home-service worker. Write what they would say to a
customer: short sentences, plain words about their world (serviço, cliente, foto do serviço,
orçamento, indicação), their trades named on screen, pride first and the tool second. A caption
or slide that sounds like a product spec gets rewritten.

| Product word      | Say instead                                   |
| ----------------- | --------------------------------------------- |
| portfólio         | fotos dos serviços que você já fez            |
| contato direto    | o cliente chama você direto no WhatsApp       |
| sem intermediário | sem atravessador                              |
| comissão          | 0% do valor do serviço fica com a Berufe      |
| taxa por contato  | R$ 0 por cliente que chamar você              |
| "mande um link"   | "serviço bem feito tem que aparecer"          |

Chat scenes show a customer's real phrasing ("Você já fez serviço parecido?", "Quanto fica o
serviço?") with no names, timestamps or WhatsApp branding.

## Claims the product supports

- Public profile at `berufe.com.br/be/<slug>`: services, coverage area, photos of past services.
- "Identidade verificada" label.
- Indications between verified professionals (recommended, or worked together; the recipient accepts).
- The customer contacts the professional directly on WhatsApp, with no fee per contact and no commission.
- Quote on the phone: fixed price or detailed, a list of materials the customer buys, validity;
  shared by WhatsApp link; the customer opens it without an account.
- Signup takes a few minutes (confirm celular or e-mail, pick services and area; photos and identity later).
- Free.

## Never claimed

Customers or leads coming in, customer reviews or ratings, Google ranking or traffic numbers, a
fabricated profile, person, price or statistic, and any feature outside the list above.
Everything in `data/*.json` and `public/images/` is synthetic: crops of the hero illustration stand in
for "photos of services" and are never presented as real work.

## Fixed pieces

- Profile address placeholder: `berufe.com.br/be/seu-nome`.
- CTA: **Criar perfil grátis**, with "Link na bio". The bio link is `https://www.berufe.com.br/para-profissionais`;
  measure a post with `?utm_source=instagram&utm_medium=social&utm_campaign=<folder name>`.
- No city anywhere: location is set in Instagram's audience builder.
- No Instagram handle exists in the repo; leave it out.

## Angles

Check the posts table in `arts/README.md` for what is covered, then offer unused ones. Candidates:

- Indicação between colleagues: who has worked with you can vouch for you.
- Atravessador: "quanto fica com a Berufe", R$ 0 and 0%.
- Orçamento no celular: materials list, validity, sent on WhatsApp.
- Onde você atende: say where you work, no city names on screen.
- Identidade verificada: what it is and why the customer cares.
- Perfil em poucos minutos: the three signup steps.

Covered so far: 001 (photos lost in the phone, re-explaining, a customer who does not know you),
002 (the three questions a new customer asks).
