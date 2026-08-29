<script setup lang="ts">
import { professionalSignupPath } from "~/utils/professional-auth";

const [catalogResult, featuredResult] = await Promise.all([
  useCatalogs(),
  useFeaturedProfessionals(),
]);
const services = computed(() => catalogResult.data.value?.services ?? []);
const featured = computed(() => featuredResult.data.value ?? []);

const { data: guides } = await useAsyncData("para-profissionais-guias", () =>
  queryCollection("guias").order("publishedAt", "DESC").limit(4).all(),
);

const title = "Para profissionais: perfil grátis, sem pagar por contato";
const description =
  "Mostre seu trabalho, receba contato direto pelo WhatsApp e apareça no Google — sem pagar por lead nem comissão sobre o serviço.";
const canonicalUrl = withSiteUrl("/para-profissionais");

useSeoMeta({
  title,
  description,
  ogTitle: title,
  ogDescription: description,
  ogUrl: () => canonicalUrl.value,
  ogType: "website",
});
useHead(() => ({ link: [{ rel: "canonical", href: canonicalUrl.value }] }));
defineOgImageSafely("BerufeDefault", { title, description });

const faq = [
  {
    question: "Preciso pagar para criar meu perfil?",
    answer:
      "Não. Criar perfil, publicar portfólio, receber contato e enviar orçamento pela Berufe é gratuito. Não cobramos comissão sobre o serviço fechado nem taxa por contato recebido.",
  },
  {
    question: "Como o cliente entra em contato comigo?",
    answer:
      "Direto pelo WhatsApp, sem intermediário. Quando alguém encontra seu perfil e decide falar com você, o contato abre uma conversa direta no seu WhatsApp — a conversa e o combinado ficam só entre vocês dois.",
  },
  {
    question: "Preciso ter site ou rede social para participar?",
    answer:
      "Não. Seu perfil na Berufe funciona sozinho: portfólio, serviços, área de atendimento e referências ficam tudo em um único lugar, pronto para aparecer em buscas.",
  },
  {
    question: "Quanto tempo leva para criar o perfil?",
    answer:
      "Poucos minutos. Você confirma seu celular, escolhe os serviços que presta e sua área de atendimento. Fotos de portfólio e confirmação de identidade podem ser adicionadas a qualquer momento depois.",
  },
];
</script>

<template>
  <div class="pillar">
    <section class="pillar__masthead">
      <DesignSystemContainer class="pillar__masthead-inner">
        <DesignSystemEyebrow>Para profissionais</DesignSystemEyebrow>
        <h1>
          Mostre seu trabalho.<br />
          <em>Sem pagar por contato.</em>
        </h1>
        <p>
          Crie um perfil gratuito com fotos do seu trabalho, identidade
          confirmada e referências de clientes reais. Quando alguém encontra seu
          perfil, o contato acontece direto pelo WhatsApp — sem intermediário
          cobrando por cada conversa.
        </p>
        <div class="pillar__masthead-actions">
          <UButton
            :to="professionalSignupPath"
            color="primary"
            size="xl"
            trailing-icon="i-lucide-arrow-right"
          >
            Criar perfil grátis
          </UButton>
          <span class="pillar__masthead-note">
            Grátis para sempre. Sem comissão sobre o serviço.
          </span>
        </div>
      </DesignSystemContainer>
    </section>

    <DesignSystemPageSection class="pillar__value">
      <DesignSystemContainer>
        <div class="value-grid">
          <div class="value-card">
            <UIcon name="i-lucide-image" aria-hidden="true" />
            <h2>Portfólio que gera confiança</h2>
            <p>
              Fotos de antes e depois organizadas por serviço — o que faz um
              visitante decidir chamar você, não outro profissional.
            </p>
          </div>
          <div class="value-card">
            <UIcon name="i-lucide-shield-check" aria-hidden="true" />
            <h2>Identidade confirmada</h2>
            <p>
              Um selo que mostra que você é quem diz ser — decisivo para quem
              vai deixar alguém desconhecido entrar em casa.
            </p>
          </div>
          <div class="value-card">
            <UIcon name="i-lucide-message-circle" aria-hidden="true" />
            <h2>Contato direto pelo WhatsApp</h2>
            <p>
              Sem cobrança por conversa. O combinado com o cliente fica só entre
              vocês dois, do primeiro contato ao orçamento fechado.
            </p>
          </div>
          <div class="value-card">
            <UIcon name="i-lucide-handshake" aria-hidden="true" />
            <h2>Rede de indicações</h2>
            <p>
              Confirme publicamente que já trabalhou com outros profissionais —
              cada relação vira prova de confiança a mais.
            </p>
          </div>
        </div>
      </DesignSystemContainer>
    </DesignSystemPageSection>

    <HomeFeaturedProfessionals
      v-if="featured.length"
      :professionals="featured"
    />

    <DesignSystemPageSection v-if="services.length" class="pillar__services">
      <DesignSystemContainer>
        <DesignSystemEyebrow>Por serviço</DesignSystemEyebrow>
        <DesignSystemHeading>
          Veja como conseguir clientes no seu ofício.
        </DesignSystemHeading>
        <div class="pillar__services-grid">
          <NuxtLink
            v-for="service in services"
            :key="service.id"
            :to="`/para-profissionais/${service.slug}`"
            class="service-chip"
          >
            <UIcon :name="service.icon" aria-hidden="true" />
            {{ service.name }}
          </NuxtLink>
        </div>
      </DesignSystemContainer>
    </DesignSystemPageSection>

    <DesignSystemPageSection v-if="guides?.length" class="pillar__guides">
      <DesignSystemContainer>
        <div class="section-heading section-heading--compact">
          <div>
            <DesignSystemEyebrow>Guias</DesignSystemEyebrow>
            <DesignSystemHeading>
              Leia mais sobre como conseguir clientes.
            </DesignSystemHeading>
          </div>
          <UButton
            to="/guias"
            variant="link"
            trailing-icon="i-lucide-arrow-right"
          >
            Ver todos os guias
          </UButton>
        </div>
        <div class="pillar__guides-grid">
          <NuxtLink
            v-for="guide in guides"
            :key="guide.path"
            :to="guide.path"
            class="guide-chip"
          >
            {{ guide.title }}
          </NuxtLink>
        </div>
      </DesignSystemContainer>
    </DesignSystemPageSection>

    <DesignSystemPageSection class="pillar__faq">
      <DesignSystemContainer>
        <DesignSystemEyebrow>Perguntas frequentes</DesignSystemEyebrow>
        <div class="faq-list">
          <details v-for="item in faq" :key="item.question" class="faq-item">
            <summary>{{ item.question }}</summary>
            <p>{{ item.answer }}</p>
          </details>
        </div>
      </DesignSystemContainer>
    </DesignSystemPageSection>

    <section class="pillar__final-cta">
      <DesignSystemContainer class="pillar__final-cta-inner">
        <h2>Crie seu perfil e comece a aparecer hoje.</h2>
        <UButton
          :to="professionalSignupPath"
          color="secondary"
          size="xl"
          trailing-icon="i-lucide-arrow-right"
        >
          Criar perfil grátis
        </UButton>
      </DesignSystemContainer>
    </section>
  </div>
</template>

<style scoped lang="scss">
.pillar {
  &__masthead {
    padding: 48px 0 44px;
    background: #dff1eb;
  }

  &__masthead-inner h1 {
    margin: 0;
    font-family: var(--font-display);
    font-size: clamp(2.4rem, 5vw, 4.2rem);
    font-weight: 500;
    letter-spacing: -0.045em;
    line-height: 1.05;
  }

  &__masthead-inner h1 em {
    color: var(--color-brand);
    font-weight: inherit;
  }

  &__masthead-inner > p {
    max-width: 640px;
    margin: 18px 0 0;
    color: var(--ink-soft);
    line-height: 1.65;
  }

  &__masthead-actions {
    display: flex;
    align-items: center;
    gap: 16px;
    margin-top: 26px;
    flex-wrap: wrap;
  }

  &__masthead-note {
    color: var(--ink-soft);
    font-size: 0.86rem;
    font-weight: 700;
  }

  &__services-grid,
  &__guides-grid {
    display: flex;
    flex-wrap: wrap;
    gap: 10px;
    margin-top: 20px;
  }

  &__faq {
    background: var(--color-surface-warm);
  }

  &__final-cta {
    padding: 56px 0;
    background: var(--color-brand-strong);
    color: white;
  }

  &__final-cta-inner {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 24px;
    flex-wrap: wrap;
  }

  &__final-cta-inner h2 {
    margin: 0;
    font-family: var(--font-display);
    font-size: 1.8rem;
    font-weight: 500;
  }
}

.value-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 18px;
}

.value-card {
  padding: 22px;
  border: 1px solid var(--line);
  border-radius: 18px;

  > svg {
    margin-bottom: 12px;
    color: var(--color-brand);
    font-size: 1.6rem;
  }

  h2 {
    margin: 0 0 8px;
    font-family: var(--font-display);
    font-size: 1.05rem;
  }

  p {
    margin: 0;
    color: var(--ink-soft);
    font-size: 0.86rem;
    line-height: 1.55;
  }
}

.service-chip,
.guide-chip {
  display: inline-flex;
  align-items: center;
  gap: 7px;
  padding: 9px 14px;
  border: 1px solid var(--line);
  border-radius: 11px;
  color: var(--ink);
  font-size: 0.86rem;
  font-weight: 700;
  text-decoration: none;
}

.section-heading {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  margin-bottom: 20px;
  flex-wrap: wrap;
}

.faq-list {
  display: grid;
  gap: 10px;
  margin-top: 20px;
  max-width: 760px;
}

.faq-item {
  padding: 16px 18px;
  border: 1px solid var(--line);
  border-radius: 14px;
  background: white;
}

.faq-item summary {
  cursor: pointer;
  font-weight: 700;
}

.faq-item p {
  margin: 12px 0 0;
  color: var(--ink-soft);
  line-height: 1.6;
}

@media (width <= 900px) {
  .value-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (width <= 560px) {
  .value-grid {
    grid-template-columns: 1fr;
  }
}
</style>
