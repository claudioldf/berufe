<template>
  <DesignSystemPageSection id="como-funciona" class="trust">
    <DesignSystemContainer class="trust__grid">
      <div class="trust__visual">
        <article
          class="trust__profile-card"
          aria-labelledby="trust-profile-title"
        >
          <header class="trust__profile-header">
            <span class="trust__profile-icon" aria-hidden="true">
              <UIcon name="i-lucide-user-round" />
            </span>
            <div>
              <small>Perfil profissional</small>
              <h3 id="trust-profile-title">Informações para decidir</h3>
            </div>
          </header>

          <div class="trust__profile-highlights">
            <div>
              <span aria-hidden="true">
                <UIcon name="i-lucide-images" />
              </span>
              <strong>Trabalhos publicados</strong>
            </div>
            <div>
              <span aria-hidden="true">
                <UIcon name="i-lucide-wrench" />
              </span>
              <strong>Serviços oferecidos</strong>
            </div>
          </div>

          <ul class="trust__profile-details">
            <li>
              <span aria-hidden="true">
                <UIcon name="i-lucide-shield-check" />
              </span>
              <div>
                <strong>Informações verificadas</strong>
                <small>Veja com clareza quais dados foram confirmados.</small>
              </div>
            </li>
            <li>
              <span aria-hidden="true">
                <UIcon name="i-lucide-quote" />
              </span>
              <div>
                <strong>Referências profissionais</strong>
                <small>Conheça quem pode recomendar aquele trabalho.</small>
              </div>
            </li>
          </ul>
        </article>

        <div class="trust__label">
          <span aria-hidden="true">
            <UIcon name="i-lucide-scan-search" />
          </span>
          <span>
            <strong>Compare antes de escolher.</strong>
            <small
              >Veja trabalhos, informações verificadas e referências.</small
            >
          </span>
        </div>
      </div>
      <div class="trust__copy">
        <DesignSystemEyebrow tone="inverse">
          Como a Berufe ajuda
        </DesignSystemEyebrow>
        <DesignSystemHeading tone="inverse">
          Conheça melhor antes de escolher.
        </DesignSystemHeading>
        <DesignSystemSectionCopy>
          Aqui, a confiança não se resume a uma nota. Você vê separadamente o
          que foi verificado, os trabalhos publicados e as referências de cada
          profissional.
        </DesignSystemSectionCopy>
        <ol class="trust__steps">
          <li>
            <span class="trust__step-icon" aria-hidden="true">
              <UIcon name="i-lucide-pencil" />
            </span>
            <div>
              <strong>Conte o que você precisa</strong>
              <p>
                Descreva o serviço que você precisa realizar, a cidade e o
                bairro.
              </p>
            </div>
          </li>
          <li>
            <span class="trust__step-icon" aria-hidden="true">
              <UIcon name="i-lucide-panels-top-left" />
            </span>
            <div>
              <strong>Compare os profissionais</strong>
              <p>
                Confira cada profissional que atende na sua cidade, compare os
                serviços, os trabalhos publicados e as referências de cada
                perfil.
              </p>
            </div>
          </li>
          <li>
            <span class="trust__step-icon" aria-hidden="true">
              <UIcon name="i-lucide-message-circle" />
            </span>
            <div>
              <strong>Fale direto pelo WhatsApp</strong>
              <p>
                Escolha o profissional e inicie a conversa pelo WhatsApp, sem
                intermediários. Simples e rápido.
              </p>
            </div>
          </li>
        </ol>
      </div>
    </DesignSystemContainer>
  </DesignSystemPageSection>
</template>
