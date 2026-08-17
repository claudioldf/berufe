<script setup lang="ts">
import LegalDocument from "~/components/legal/LegalDocument.vue";
import type { LegalDocumentSection } from "~/types";

const sections: LegalDocumentSection[] = [
  { id: "escopo", label: "Escopo e responsáveis" },
  { id: "dados", label: "Dados que tratamos" },
  { id: "finalidades", label: "Como usamos os dados" },
  { id: "visibilidade", label: "Dados públicos e privados" },
  { id: "fornecedores", label: "Fornecedores" },
  { id: "whatsapp", label: "WhatsApp" },
  { id: "retencao", label: "Retenção e segurança" },
  { id: "direitos", label: "Direitos e contato" },
];

useSeoMeta({
  title: "Política de Privacidade",
  description:
    "Entenda como a Berufe trata dados de profissionais e visitantes.",
  robots: "noindex, nofollow",
});
</script>

<template>
  <LegalDocument
    eyebrow="Privacidade desde o primeiro dado"
    title="Política de Privacidade"
    description="Explicamos quais dados fazem parte da Berufe, por que precisamos deles e como os protegemos."
    version="0.2 · minuta do MVP"
    updated-at="13 de agosto de 2026"
    :sections="sections"
  >
    <div class="legal-lead">
      <p>
        A Berufe é uma rede local para profissionais de reforma e manutenção
        residencial. Profissionais criam perfis e apresentam evidências;
        visitantes pesquisam informações aprovadas e escolhem com quem conversar
        diretamente.
      </p>
      <p>
        Esta Política deve ser lida junto com os
        <NuxtLink to="/termos-de-uso">Termos de Uso</NuxtLink>.
      </p>
    </div>

    <section id="escopo" class="legal-section">
      <h2>1. Escopo e responsáveis</h2>
      <p>
        Esta Política abrange o cadastro e acesso de profissionais, perfil
        público, catálogo de serviços, busca, portfólio, verificação de
        identidade, relações entre profissionais, moderação, compartilhamento de
        perfil, criação e compartilhamento de orçamentos e contato pelo
        WhatsApp.
      </p>
      <p>
        A razão social, o CNPJ, o endereço e o canal oficial de privacidade
        serão inseridos antes do início da operação com dados reais.
      </p>
      <div class="legal-note">
        <UIcon name="i-lucide-info" />
        <p>
          <strong>Quem está abrangido:</strong> profissionais cadastrados,
          visitantes das páginas públicas e administradores autorizados.
        </p>
      </div>
    </section>

    <section id="dados" class="legal-section">
      <h2>2. Dados que tratamos</h2>
      <h3>2.1. Acesso e segurança</h3>
      <p>
        Para o acesso profissional, tratamos o número de telefone normalizado, o
        estado do desafio OTP do Infobip, a identidade confirmada pelo provedor
        e controles temporários contra abuso. Depois da confirmação, a Rails
        cria uma sessão própria e envia ao navegador apenas um cookie HttpOnly;
        tokens do Infobip não ficam no navegador.
      </p>
      <p>
        Administradores usam credenciais individuais de e-mail e senha. Também
        registramos aceite dos documentos legais, criação da conta, último
        acesso, revogação e dados técnicos mínimos de segurança.
      </p>

      <h3>2.2. Perfil e evidências</h3>
      <p>
        O profissional pode fornecer nome de exibição, foto, apresentação,
        experiência declarada, WhatsApp, serviços, bairros atendidos, imagens e
        descrições de portfólio e relações com outros profissionais já
        cadastrados.
      </p>
      <p>
        A verificação do MVP aceita somente imagem JPEG ou PNG de documento
        oficial com foto. O arquivo é privado, validado e regenerado antes da
        análise, acessado apenas por administradores autorizados e nunca exibido
        no perfil público.
      </p>

      <h3>2.3. Orçamentos</h3>
      <p>
        Um orçamento pode conter nome do cliente, descrição do serviço, itens,
        quantidades, valores, desconto, validade e observações. O rascunho é
        privado do profissional. Depois do compartilhamento, a apresentação ao
        cliente fica disponível somente a quem possuir o link longo e difícil de
        adivinhar.
      </p>

      <h3>2.4. Navegação e suporte</h3>
      <p>
        Registramos de forma mínima e agregada os termos de busca, serviço,
        área, quantidade de resultados, abertura de perfil e início de contato
        no WhatsApp. Mensagens enviadas voluntariamente ao suporte podem conter
        o endereço de resposta e o conteúdo informado pela pessoa.
      </p>
    </section>

    <section id="finalidades" class="legal-section">
      <h2>3. Como e por que usamos os dados</h2>
      <p>Tratamos dados apenas na medida necessária para:</p>
      <ul>
        <li>
          confirmar o telefone, administrar a sessão e proteger as contas;
        </li>
        <li>criar, revisar, publicar e manter perfis e portfólios;</li>
        <li>conferir identidade e moderar o conteúdo submetido;</li>
        <li>permitir busca por serviço e região com ordenação explicável;</li>
        <li>
          confirmar e publicar relações entre profissionais, após aceite e
          moderação;
        </li>
        <li>
          abrir o compartilhamento de perfil ou o contato solicitado pela
          pessoa;
        </li>
        <li>criar, manter, apresentar e compartilhar orçamentos protegidos;</li>
        <li>atender suporte, cumprir obrigações legais e defender direitos;</li>
        <li>medir de forma agregada se o MVP atende às necessidades locais.</li>
      </ul>
      <p>
        As bases legais aplicáveis serão definidas conforme a operação e a LGPD.
        O aceite geral desta Política não será tratado como consentimento para
        toda finalidade.
      </p>
    </section>

    <section id="visibilidade" class="legal-section">
      <h2>4. O que fica público e o que permanece protegido</h2>
      <div class="legal-table-wrap">
        <table class="legal-table">
          <thead>
            <tr>
              <th>Classificação</th>
              <th>Exemplos</th>
              <th>Quem acessa</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td><strong>Público</strong></td>
              <td>
                Perfil aprovado, serviços, região, foto, experiência declarada,
                portfólio, selos específicos e relações aprovadas.
              </td>
              <td>
                Qualquer visitante e, quando aplicável, mecanismos de busca.
              </td>
            </tr>
            <tr>
              <td><strong>Privado</strong></td>
              <td>
                Telefone, sessão, conteúdo pendente, respostas de relações,
                rascunhos e dados de cliente em orçamentos e motivos de
                moderação.
              </td>
              <td>Titular e equipe autorizada, conforme a necessidade.</td>
            </tr>
            <tr>
              <td><strong>Por link</strong></td>
              <td>Apresentação compartilhada de um orçamento.</td>
              <td>
                Quem possuir o link válido; a página não é indexada nem
                armazenada em cache compartilhado.
              </td>
            </tr>
            <tr>
              <td><strong>Restrito</strong></td>
              <td>
                Imagem usada para verificar identidade, credenciais
                administrativas e registros de acesso ao arquivo.
              </td>
              <td>Servidor e administradores estritamente autorizados.</td>
            </tr>
          </tbody>
        </table>
      </div>
      <p>
        Conteúdo novo ou materialmente alterado permanece indisponível enquanto
        aguarda aprovação. Conteúdo rejeitado, oculto ou ligado a uma conta
        suspensa não aparece publicamente.
      </p>
    </section>

    <section id="fornecedores" class="legal-section">
      <h2>5. Fornecedores necessários</h2>
      <p>
        A Berufe não vende dados pessoais nem comercializa contatos. Para operar
        o MVP, pode compartilhar apenas os dados necessários com:
      </p>
      <ul>
        <li>
          <strong>Vercel:</strong> hospedagem e distribuição da aplicação web;
        </li>
        <li>
          <strong>Render e PostgreSQL gerenciado:</strong> API, sessões, tarefas
          e banco de dados;
        </li>
        <li>
          <strong>Infobip:</strong> telefone, desafio OTP e resultado da
          confirmação;
        </li>
        <li>
          <strong>Cloudflare R2:</strong> imagens públicas e evidência privada
          de identidade;
        </li>
        <li>
          <strong>serviço de monitoramento:</strong> falhas técnicas, sem corpos
          sensíveis de requisição;
        </li>
        <li>
          <strong>autoridades e assessores:</strong> quando uma obrigação válida
          exigir.
        </li>
      </ul>
      <p>
        Alguns fornecedores podem processar dados fora do Brasil. Esses fluxos e
        contratos serão avaliados antes do lançamento.
      </p>
    </section>

    <section id="whatsapp" class="legal-section">
      <h2>6. WhatsApp e links externos</h2>
      <p>
        A Berufe só abre o WhatsApp depois de uma ação da pessoa para falar com
        um profissional. Também usa o compartilhamento nativo do dispositivo ou
        abre o WhatsApp quando o profissional decide divulgar seu perfil ou
        enviar um orçamento.
      </p>
      <div class="legal-note">
        <UIcon name="i-lucide-lock-keyhole" />
        <p>
          <strong>A Berufe não envia, recebe nem lê as conversas.</strong>
          Também não confirma negociação, contratação, pagamento ou resultado do
          serviço.
        </p>
      </div>
      <p>
        Ao sair da Berufe, passam a valer os termos e a política do serviço
        externo.
      </p>
    </section>

    <section id="retencao" class="legal-section">
      <h2>7. Retenção e segurança</h2>
      <p>
        Desafios OTP, sessões e controles contra abuso duram somente pela janela
        operacional definida. Eventos de descoberta são agregados e os registros
        mínimos são eliminados conforme a matriz de retenção. Uploads
        abandonados, rejeitados ou substituídos são limpos; a imagem de
        identidade é mantida apenas durante análise, contestação e eventual
        obrigação aplicável.
      </p>
      <p>
        Usamos HTTPS, cookies seguros, autorização no servidor, segundo fator
        administrativo, arquivos privados, acesso temporário e auditado à
        evidência de identidade, remoção de metadados desnecessários,
        identificadores de requisição e registros sem telefones, códigos,
        sessões ou documentos.
      </p>
      <p>
        Contas, perfis e orçamentos permanecem durante a relação com a Berufe e,
        depois dela, apenas pelo prazo exigido por obrigação, segurança ou
        defesa de direitos. A matriz operacional também define a retenção de
        rascunhos, links compartilhados e dados de clientes. Dados elegíveis são
        apagados ou anonimizados.
      </p>
    </section>

    <section id="direitos" class="legal-section">
      <h2>8. Direitos, alterações e contato</h2>
      <p>
        Nos termos da LGPD, o titular pode solicitar confirmação e acesso,
        correção, informações sobre compartilhamento, anonimização, bloqueio ou
        eliminação quando aplicável, portabilidade quando regulamentada,
        oposição e revisão de decisões exclusivamente automatizadas.
      </p>
      <p>
        A Berufe poderá confirmar a identidade do solicitante e preservar o
        mínimo exigido por lei, segurança ou exercício regular de direitos.
        Alterações relevantes terão nova versão e, quando necessário, novo
        aceite.
      </p>
      <p>
        Esta é uma minuta sem vigência para dados reais. A versão 1.0 deverá
        incluir a identificação completa da responsável, canal validado, matriz
        de retenção e revisão jurídica brasileira antes do lançamento.
      </p>
    </section>
  </LegalDocument>
</template>
