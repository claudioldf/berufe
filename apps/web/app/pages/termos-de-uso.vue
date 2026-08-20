<script setup lang="ts">
import LegalDocument from "~/components/legal/LegalDocument.vue";
import type { LegalDocumentSection } from "~/types";

const sections: LegalDocumentSection[] = [
  { id: "objeto", label: "Objeto e aceitação" },
  { id: "contas", label: "Contas e acesso" },
  { id: "papel", label: "Papel da Berufe" },
  { id: "perfis", label: "Perfis e conteúdo" },
  { id: "verificacao", label: "Verificação e moderação" },
  { id: "relacoes", label: "Relações profissionais" },
  { id: "busca", label: "Busca e contato" },
  { id: "orcamentos", label: "Orçamentos" },
  { id: "conduta", label: "Conduta e suspensão" },
  { id: "responsabilidade", label: "Responsabilidade" },
  { id: "disposicoes", label: "Disposições finais" },
];

useSeoMeta({
  title: "Termos de Uso",
  description: "Regras de uso da Berufe para profissionais e visitantes.",
  robots: "noindex, nofollow",
});
</script>

<template>
  <LegalDocument
    eyebrow="Relações claras começam por regras claras"
    title="Termos de Uso"
    description="Estas regras explicam o papel da Berufe, o que esperamos de cada pessoa e os limites do MVP."
    version="0.2 · minuta do MVP"
    updated-at="13 de agosto de 2026"
    :sections="sections"
  >
    <div class="legal-lead">
      <p>
        A Berufe permite que profissionais de reforma e manutenção apresentem
        seu trabalho e que visitantes encontrem informações aprovadas para
        decidir com quem conversar.
      </p>
      <p>
        Ao usar a plataforma, você declara que leu estes Termos e a
        <NuxtLink to="/privacidade">Política de Privacidade</NuxtLink>.
      </p>
    </div>

    <section id="objeto" class="legal-section">
      <h2>1. Objeto e aceitação</h2>
      <p>
        O MVP oferece cadastro e acesso de profissionais, perfis públicos,
        catálogo de serviços, busca por serviço e área, portfólio, verificação
        de identidade, relações entre profissionais já cadastrados, moderação
        manual, compartilhamento de perfil, orçamento simples e contato direto
        pelo WhatsApp.
      </p>
      <p>
        Quem não concordar com estes Termos não deve criar conta nem continuar
        usando as áreas autenticadas.
      </p>
    </section>

    <section id="contas" class="legal-section">
      <h2>2. Contas e acesso</h2>
      <p>
        Contas profissionais usam confirmação do telefone por código OTP do
        Infobip. A confirmação permite que a Berufe crie sua própria sessão de
        aplicação. O usuário deve manter controle do número e encerrar a sessão
        em dispositivos compartilhados.
      </p>
      <p>
        Contas administrativas usam e-mail e senha individuais. É proibido
        compartilhar acesso, tentar usar a conta de outra pessoa ou contornar
        limites de segurança.
      </p>
    </section>

    <section id="papel" class="legal-section">
      <h2>3. Papel da Berufe</h2>
      <p>
        A Berufe organiza e modera informações profissionais. Não é empregadora,
        representante, prestadora do serviço anunciado, parte da negociação nem
        garantidora de preço, prazo, segurança ou resultado.
      </p>
      <div class="legal-note">
        <UIcon name="i-lucide-info" />
        <p>
          <strong>Contato direto:</strong> visitante e profissional combinam
          escopo e condições fora da plataforma. O MVP não cobra por contatos,
          não recebe comissão e não processa pagamentos.
        </p>
      </div>
    </section>

    <section id="perfis" class="legal-section">
      <h2>4. Perfis, serviços e portfólio</h2>
      <p>
        O profissional é responsável por manter nome, apresentação, WhatsApp,
        serviços, área atendida e experiência declarada corretos. Só pode enviar
        imagens, textos e trabalhos que tenha direito de publicar.
      </p>
      <p>
        Serviços devem ser escolhidos no catálogo da Berufe. Imagens de
        portfólio aceitam apenas os formatos e limites indicados e permanecem
        privadas até a aprovação.
      </p>
    </section>

    <section id="verificacao" class="legal-section">
      <h2>5. Verificação e moderação</h2>
      <p>
        No MVP, a verificação manual abrange somente identidade. O selo
        significa que a equipe conferiu uma evidência específica; não representa
        licença profissional, certificação técnica, qualidade garantida nem
        ausência de risco.
      </p>
      <p>
        Perfis, fotos, itens de portfólio e solicitações de identidade podem ser
        aprovados, rejeitados, ocultados ou restaurados. Toda decisão
        administrativa relevante deve ter responsável, horário e justificativa
        quando aplicável.
      </p>
      <p>
        Conteúdo novo ou materialmente alterado não fica público antes de ser
        aprovado. A Berufe pode remover imediatamente conteúdo ou suspender uma
        conta quando houver risco, fraude, ilegalidade ou violação destes
        Termos.
      </p>
    </section>

    <section id="relacoes" class="legal-section">
      <h2>6. Relações profissionais</h2>
      <p>
        Somente profissionais com identidade aprovada podem iniciar uma relação
        com outro membro já cadastrado. A plataforma não permite relação consigo
        mesmo nem duplicata do mesmo tipo.
      </p>
      <p>
        O destinatário pode aceitar ou recusar. A relação aceita pode aparecer
        nos perfis públicos assim que for confirmada, desde que ambos os perfis
        continuem públicos e ativos. A recomendação profissional identifica seu
        autor e não pode ser anônima.
      </p>
    </section>

    <section id="busca" class="legal-section">
      <h2>7. Busca, compartilhamento e WhatsApp</h2>
      <p>
        A ordem dos resultados considera correspondência do serviço, cobertura,
        identidade verificada, portfólio, relações profissionais confirmadas e
        atualização do perfil. Não há compra de posição, nota oculta nem
        garantia de destaque.
      </p>
      <p>
        Compartilhar o perfil ou abrir o WhatsApp depende de ação da pessoa. A
        Berufe não lê a conversa nem confirma negociação ou contratação.
      </p>
    </section>

    <section id="orcamentos" class="legal-section">
      <h2>8. Orçamentos compartilhados</h2>
      <p>
        O profissional pode criar um orçamento com nome do cliente, descrição,
        itens, quantidades, valores, desconto, validade e observações. Ele é
        responsável pela exatidão das informações e pelas condições oferecidas.
      </p>
      <p>
        O rascunho é privado. Depois do compartilhamento, quem possuir o link
        válido pode visualizar e imprimir a apresentação. O link deve ser
        enviado somente ao destinatário e pode ser invalidado pela Berufe ou
        pelo estado do orçamento.
      </p>
      <div class="legal-note">
        <UIcon name="i-lucide-info" />
        <p>
          <strong>Limite do recurso:</strong> visualizar ou imprimir não
          significa aceitar, assinar ou pagar. A Berufe não gera contrato, nota
          fiscal, cobrança ou garantia.
        </p>
      </div>
    </section>

    <section id="conduta" class="legal-section">
      <h2>9. Conduta e suspensão</h2>
      <p>É proibido:</p>
      <ul>
        <li>
          informar identidade, experiência, serviço, relação ou trabalho falsos;
        </li>
        <li>publicar imagem, marca ou texto sem autorização;</li>
        <li>
          assediar pessoas, discriminar, promover atividade ilegal ou enviar
          conteúdo malicioso;
        </li>
        <li>
          manipular buscas e contagens, automatizar uso abusivo ou contornar
          segurança;
        </li>
        <li>
          usar dados obtidos na Berufe para spam, revenda de contatos ou
          finalidade incompatível.
        </li>
      </ul>
      <p>
        A Berufe pode limitar, ocultar, suspender ou encerrar o acesso de forma
        proporcional. A suspensão invalida a autorização da conta e suas sessões
        da aplicação, independentemente da situação do telefone no Infobip.
      </p>
    </section>

    <section id="responsabilidade" class="legal-section">
      <h2>10. Disponibilidade e responsabilidade</h2>
      <p>
        A plataforma pode ficar temporariamente indisponível por manutenção,
        falha de fornecedor ou incidente. A Berufe buscará restaurar o serviço e
        proteger os dados, mas não promete operação ininterrupta.
      </p>
      <p>
        Nos limites da lei, a Berufe não responde por declarações, negociações,
        atrasos, danos ou descumprimentos entre visitantes, profissionais e
        terceiros. Nada nestes Termos exclui responsabilidade que não possa ser
        afastada pela legislação.
      </p>
    </section>

    <section id="disposicoes" class="legal-section">
      <h2>11. Privacidade, alterações e lei aplicável</h2>
      <p>
        O tratamento de dados segue a Política de Privacidade. Cada versão
        destes Termos terá número e data; mudanças relevantes serão destacadas e
        poderão exigir novo aceite.
      </p>
      <p>
        A legislação brasileira é aplicável, sem afastar direitos obrigatórios
        do consumidor e regras de competência legal. Esta minuta não deve reger
        uma operação real: a versão 1.0 deverá incluir a identificação completa
        da responsável, canais oficiais e revisão jurídica antes do lançamento.
      </p>
    </section>
  </LegalDocument>
</template>
