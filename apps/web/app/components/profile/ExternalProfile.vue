<script setup lang="ts">
import { computed } from "vue";
import type { PublicProfessionalProfile } from "~/types";

const props = defineProps<{
  professional: PublicProfessionalProfile;
  contactUrl: string;
  supportEmailUrl: string;
}>();
defineEmits<{ contact: []; share: [] }>();

const coverageLabel = computed(() => {
  if (props.professional.allJoinville) return "Atende toda Joinville";
  if (props.professional.neighborhoods.length) {
    return props.professional.neighborhoods.join(", ");
  }
  return "Joinville";
});
</script>

<template>
  <div class="external-profile">
    <section class="external-profile__hero">
      <DesignSystemContainer class="external-profile__hero-inner">
        <div class="external-profile__topbar">
          <NuxtLink to="/encontrar"
            ><UIcon name="i-lucide-arrow-left" /> Encontrar
            profissionais</NuxtLink
          >
          <button type="button" @click="$emit('share')">
            <UIcon name="i-lucide-share-2" /> Compartilhar perfil
          </button>
        </div>
        <div class="external-profile__identity">
          <DesignSystemAvatar
            :name="professional.name"
            :src="professional.avatar ?? undefined"
            :fallback-icon="
              professional.primaryServiceIcon ?? 'i-lucide-briefcase-business'
            "
            size="profile"
            shape="rounded"
          />
          <div>
            <span class="external-profile__source">
              <UIcon name="i-lucide-user-round-plus" /> Perfil adicionado por
              indicação
            </span>
            <h1>{{ professional.name }}</h1>
            <p><UIcon name="i-lucide-map-pin" /> {{ coverageLabel }}</p>
            <span v-if="professional.claimed" class="external-profile__claimed">
              <UIcon name="i-lucide-badge-check" /> Telefone confirmado pelo
              profissional
            </span>
            <span v-else class="external-profile__unclaimed">
              Este profissional ainda não reivindicou o perfil.
            </span>
          </div>
        </div>
      </DesignSystemContainer>
    </section>

    <DesignSystemContainer class="external-profile__content">
      <main>
        <DesignSystemSurfaceCard
          v-if="professional.services.length"
          as="section"
          class="external-profile__card"
        >
          <DesignSystemEyebrow>Serviços informados</DesignSystemEyebrow>
          <h2>Como este profissional pode ajudar.</h2>
          <div class="external-profile__services">
            <span
              v-for="service in professional.services"
              :key="service"
              class="external-profile__service"
            >
              <UIcon
                class="external-profile__service-icon"
                name="i-lucide-wrench"
              />
              {{ service }}
            </span>
          </div>
        </DesignSystemSurfaceCard>

        <DesignSystemSurfaceCard
          v-if="professional.relationships.length > 0"
          as="section"
          class="external-profile__card"
        >
          <div class="external-profile__section-heading">
            <div>
              <DesignSystemEyebrow>Rede profissional</DesignSystemEyebrow>
              <h2>Conexões confirmadas.</h2>
            </div>
            <span>{{ professional.relationships.length }}</span>
          </div>
          <div class="external-profile__relationships">
            <article
              v-for="relationship in professional.relationships"
              :key="relationship.id"
            >
              <DesignSystemAvatar
                :name="relationship.professionalName"
                :src="relationship.avatar ?? undefined"
                size="lg"
                shape="rounded"
              />
              <div>
                <strong>
                  {{
                    relationship.type === "worked_together"
                      ? "Trabalharam juntos"
                      : relationship.direction === "incoming"
                        ? `Recomendado por ${relationship.professionalName}`
                        : `Recomendou ${relationship.professionalName}`
                  }}
                </strong>
                <p v-if="relationship.note">“{{ relationship.note }}”</p>
                <NuxtLink
                  :to="`/profissionais/${relationship.professionalSlug}`"
                >
                  {{ relationship.professionalName }}
                  <UIcon name="i-lucide-arrow-up-right" />
                </NuxtLink>
              </div>
            </article>
          </div>
        </DesignSystemSurfaceCard>
      </main>

      <aside>
        <DesignSystemSurfaceCard class="external-profile__contact">
          <div class="external-profile__contact-heading">
            <UIcon
              class="external-profile__contact-icon"
              name="i-lucide-message-circle"
            />
            <h2>Fale diretamente com {{ professional.name.split(" ")[0] }}.</h2>
          </div>
          <p>O telefone permanece privado e a conversa acontece no WhatsApp.</p>
          <UButton
            color="primary"
            icon="i-lucide-message-circle"
            block
            :to="contactUrl"
            target="_blank"
            rel="noopener noreferrer"
            @click="$emit('contact')"
          >
            Conversar no WhatsApp
          </UButton>
        </DesignSystemSurfaceCard>
        <DesignSystemSurfaceCard class="external-profile__claim">
          <strong>{{
            professional.claimed
              ? "Este perfil é seu?"
              : "Você é este profissional?"
          }}</strong>
          <p>
            Confirme o telefone para responder às solicitações de conexão e
            completar seu perfil na Berufe.
          </p>
          <UButton
            to="/app/professional/login"
            color="neutral"
            variant="outline"
            block
          >
            {{
              professional.claimed
                ? "Completar meu perfil"
                : "Reivindicar perfil"
            }}
          </UButton>
        </DesignSystemSurfaceCard>
        <a class="external-profile__support" :href="supportEmailUrl">
          <UIcon name="i-lucide-flag" /> Informar um problema sobre este perfil
        </a>
      </aside>
    </DesignSystemContainer>
  </div>
</template>

<style scoped lang="scss">
.external-profile {
  min-height: 100vh;
  background: var(--color-surface-canvas);

  &__hero {
    padding: 28px 0 54px;
    background: var(--color-brand-strong);
    color: white;
  }

  &__topbar {
    display: flex;
    justify-content: space-between;
    margin-bottom: 44px;
  }

  &__topbar a,
  &__topbar button {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    border: 0;
    background: transparent;
    color: rgb(255 255 255 / 70%);
    font-size: 0.82rem;
    font-weight: 700;
    text-decoration: none;
    cursor: pointer;
  }

  &__identity {
    display: grid;
    grid-template-columns: auto 1fr;
    align-items: center;
    gap: 26px;
  }

  &__source,
  &__claimed {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    color: var(--color-brand-muted);
    font-size: 0.78rem;
    font-weight: 900;
    letter-spacing: 0.06em;
    text-transform: uppercase;
  }

  &__identity h1 {
    margin: 9px 0 10px;
    font-family: var(--font-display);
    font-size: clamp(2.8rem, 6vw, 5rem);
    font-weight: 500;
    letter-spacing: -0.05em;
    line-height: 0.95;
  }

  &__identity p,
  &__unclaimed {
    display: flex;
    align-items: center;
    gap: 6px;
    margin: 0 0 10px;
    color: rgb(255 255 255 / 70%);
    font-size: 0.86rem;
  }

  &__content {
    display: grid;
    grid-template-columns: minmax(0, 1fr) 330px;
    gap: 22px;
    align-items: start;
    padding-top: 30px;
    padding-bottom: 70px;
  }

  &__content main,
  &__content aside {
    display: grid;
    gap: 18px;
  }

  &__card,
  &__contact,
  &__claim {
    padding: 24px;
  }

  &__card h2,
  &__contact-heading h2 {
    margin: 7px 0 18px;
    font-family: var(--font-display);
    font-size: 1.8rem;
  }

  &__contact-heading {
    display: flex;
    align-items: center;
    gap: 8px;
    margin: 7px 0 18px;
  }

  &__contact-heading h2 {
    margin: 0;
    font-size: clamp(1.2rem, 1.6vw, 1.45rem);
    line-height: 1.1;
    white-space: nowrap;
  }

  &__services {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
  }

  &__service {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    padding: 8px 10px;
    border-radius: 9px;
    background: var(--mint);
    color: var(--color-brand-strong);
    font-size: 0.82rem;
    font-weight: 700;
  }

  &__service-icon {
    flex: 0 0 auto;
    width: 1rem;
    height: 1rem;
    color: var(--color-brand);
  }

  &__section-heading {
    display: flex;
    justify-content: space-between;
    gap: 16px;
  }

  &__section-heading > span {
    color: var(--ink-soft);
    font-weight: 800;
  }

  &__relationships {
    display: grid;
    gap: 10px;
  }

  &__relationships article {
    display: grid;
    grid-template-columns: auto 1fr;
    gap: 12px;
    padding: 14px 0;
    border-top: 1px solid var(--line);
  }

  &__relationships p,
  &__relationships a,
  &__contact p,
  &__claim p {
    color: var(--ink-soft);
    font-size: 0.83rem;
    line-height: 1.5;
  }

  &__relationships p {
    margin: 6px 0;
  }

  &__contact p,
  &__claim p {
    margin-bottom: 14px;
  }

  &__relationships a,
  &__support {
    color: var(--color-brand);
    font-weight: 700;
    text-decoration: none;
  }

  &__contact-icon {
    display: block;
    flex: 0 0 auto;
    align-self: center;
    color: var(--color-brand);
    font-size: 1.7rem;
    line-height: 1;
  }

  &__claim strong {
    font-family: var(--font-display);
    font-size: 1.25rem;
  }

  &__support {
    display: inline-flex;
    align-items: center;
    gap: 7px;
    padding: 0 4px;
    font-size: 0.79rem;
  }
}

@media (width <= 820px) {
  .external-profile__content {
    grid-template-columns: 1fr;
  }
}

@media (width <= 560px) {
  .external-profile__identity {
    grid-template-columns: 1fr;
  }
}
</style>
