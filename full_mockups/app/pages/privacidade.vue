<script setup lang="ts">
import LegalDocument from '~/components/legal/LegalDocument.vue'
import type { LegalDocumentSection } from '~/types'

const sections: LegalDocumentSection[] = [
  { id: 'escopo', label: 'Escopo e responsáveis' },
  { id: 'dados-coletados', label: 'Dados que tratamos' },
  { id: 'finalidades', label: 'Como usamos os dados' },
  { id: 'visibilidade', label: 'Dados públicos e privados' },
  { id: 'compartilhamento', label: 'Compartilhamento' },
  { id: 'whatsapp', label: 'WhatsApp e links externos' },
  { id: 'cookies', label: 'Cookies e métricas' },
  { id: 'retencao', label: 'Retenção e exclusão' },
  { id: 'seguranca', label: 'Segurança' },
  { id: 'direitos', label: 'Seus direitos' },
  { id: 'transferencias', label: 'Transferências internacionais' },
  { id: 'alteracoes', label: 'Alterações e contato' },
]

useSeoMeta({
  title: 'Política de Privacidade',
  description: 'Entenda como a Berufe trata dados de profissionais, clientes e visitantes da plataforma.',
  robots: 'noindex, nofollow',
})
</script>

<template>
  <LegalDocument
    eyebrow="Privacidade desde o primeiro dado"
    title="Política de Privacidade"
    description="Explicamos com clareza quais dados fazem parte da Berufe, por que precisamos deles e quais escolhas estão nas mãos de cada pessoa."
    version="0.1 · minuta"
    updated-at="12 de agosto de 2026"
    :sections="sections"
  >
    <div class="legal-lead">
      <p>
        A Berufe é uma rede local para profissionais de reforma e manutenção residencial. Profissionais criam perfis e apresentam evidências; visitantes pesquisam, comparam informações aprovadas e escolhem com quem conversar diretamente.
      </p>
      <p>
        Esta Política descreve o tratamento de dados pessoais nesse contexto e deve ser lida junto com os <NuxtLink to="/termos-de-uso">Termos de Uso</NuxtLink>.
      </p>
    </div>

    <section id="escopo" class="legal-section">
      <h2>1. Escopo e responsáveis</h2>
      <p>
        Esta Política se aplica ao site e às funcionalidades da Berufe, incluindo cadastro e acesso de profissionais, perfis públicos, busca, verificações, portfólios, recomendações, relações profissionais, denúncias, painel e orçamentos compartilhados.
      </p>
      <p>
        Para os tratamentos descritos aqui, a organização responsável pela Berufe determinará as finalidades e os meios essenciais do uso dos dados pessoais. A razão social, o CNPJ, o endereço e o canal oficial de privacidade serão inseridos nesta seção antes do início da operação com dados reais.
      </p>
      <div class="legal-note">
        <UIcon name="i-lucide-info" />
        <p><strong>Quem está abrangido:</strong> profissionais cadastrados, pessoas que enviam recomendações ou denúncias, clientes que recebem orçamentos e visitantes das páginas públicas.</p>
      </div>
    </section>

    <section id="dados-coletados" class="legal-section">
      <h2>2. Dados que tratamos</h2>

      <h3>2.1. Cadastro, autenticação e segurança</h3>
      <p>Quando um profissional cria ou acessa uma conta, podemos tratar:</p>
      <ul>
        <li>número de telefone confirmado e normalizado;</li>
        <li>identificador estável fornecido pelo serviço de autenticação, estado da verificação e referências da sessão;</li>
        <li>nome profissional, função da conta, situação cadastral e datas de criação ou último acesso;</li>
        <li>versão e momento do aceite dos Termos e desta Política;</li>
        <li>contadores ou resumos temporários associados a telefone e endereço IP para limitar tentativas de código e prevenir abuso.</li>
      </ul>
      <p>A Berufe não pretende armazenar senhas nem o conteúdo dos códigos de uso único. Esses elementos ficam sob responsabilidade do provedor de autenticação contratado.</p>

      <h3>2.2. Perfil e atividade profissional</h3>
      <p>O profissional pode fornecer nome de exibição, foto, título, biografia, experiência declarada, telefone de WhatsApp, serviços, especialidades e bairros atendidos. Também pode enviar imagens e descrições de portfólio, solicitações de verificação, convites, relações profissionais e informações necessárias para criar orçamentos.</p>

      <h3>2.3. Evidências de verificação</h3>
      <p>
        Para conferir identidade, empresa ou certificado, podemos receber documentos oficiais, comprovantes ou certificados e seus metadados de arquivo. Esses materiais são privados, acessados apenas por pessoas autorizadas para a análise e não aparecem nas páginas públicas. Evitamos coletar números completos de documentos quando eles não forem operacionalmente indispensáveis.
      </p>

      <h3>2.4. Recomendações, relações e denúncias</h3>
      <p>Uma pessoa convidada a recomendar um profissional pode informar nome de exibição, serviço realizado, período aproximado, texto da recomendação e confirmação de que o serviço ocorreu. A confirmação telefônica gera um identificador criptográfico não reversível do número para identificar duplicidades e abuso; o número não é publicado e não cria uma conta de cliente.</p>
      <p>Relações entre profissionais podem conter o nome dos envolvidos, tipo de relação e um contexto breve. Denúncias podem conter categoria, descrição e, opcionalmente, um contato privado do denunciante.</p>

      <h3>2.5. Orçamentos</h3>
      <p>Um orçamento pode conter nome do cliente, descrição do serviço, itens, quantidades, valores, desconto, validade e observações. O rascunho é privado. Depois do compartilhamento, a visualização fica disponível somente a quem possuir o link longo e difícil de adivinhar.</p>

      <h3>2.6. Navegação e operação</h3>
      <p>Podemos tratar dados técnicos mínimos de requisições, como data, horário, identificador da requisição, informações necessárias à segurança e registros de falha. As buscas registram termo normalizado, serviço, cidade ou bairro, quantidade de resultados e se ao menos um perfil foi aberto, sem criar uma identidade persistente do visitante.</p>
    </section>

    <section id="finalidades" class="legal-section">
      <h2>3. Como e por que usamos os dados</h2>
      <p>Tratamos dados apenas na medida necessária para:</p>
      <ul>
        <li>autenticar profissionais e administrar contas e sessões;</li>
        <li>criar, revisar, publicar e manter perfis profissionais;</li>
        <li>permitir buscas por serviço e região e apresentar resultados explicáveis;</li>
        <li>conferir evidências específicas e moderar conteúdo enviado à plataforma;</li>
        <li>viabilizar recomendações de clientes e relações confirmadas entre profissionais;</li>
        <li>criar e apresentar orçamentos por links protegidos;</li>
        <li>abrir ações de compartilhamento ou contato solicitadas pelo próprio usuário;</li>
        <li>prevenir fraude, abuso de códigos, acesso indevido e manipulação de métricas;</li>
        <li>atender solicitações, denúncias, obrigações legais e defender direitos;</li>
        <li>medir, por dados agregados, se a plataforma atende às necessidades locais.</li>
      </ul>
      <p>
        Conforme a operação concreta e a legislação aplicável, esses tratamentos poderão se apoiar na execução dos serviços solicitados e de procedimentos relacionados, no cumprimento de obrigações legais, no exercício regular de direitos, na proteção contra fraude, no legítimo interesse avaliado de forma responsável ou no consentimento, quando ele for efetivamente necessário. A Berufe não tratará o aceite geral desta Política como consentimento para toda e qualquer finalidade.
      </p>
    </section>

    <section id="visibilidade" class="legal-section">
      <h2>4. O que fica público e o que permanece protegido</h2>
      <div class="legal-table-wrap">
        <table class="legal-table">
          <thead><tr><th>Classificação</th><th>Exemplos</th><th>Quem acessa</th></tr></thead>
          <tbody>
            <tr><td><strong>Público</strong></td><td>Perfil publicado, serviços, região, foto, portfólio, selos, recomendações e relações confirmadas.</td><td>Qualquer visitante e, quando aplicável, mecanismos de busca.</td></tr>
            <tr><td><strong>Privado</strong></td><td>Telefone, relações pendentes ou recusadas, rascunhos, dados do cliente no orçamento, denúncias e motivos de moderação.</td><td>Titular, proprietário do registro e equipe autorizada, conforme a necessidade.</td></tr>
            <tr><td><strong>Por link</strong></td><td>Versão compartilhada de um orçamento e informações destinadas ao cliente.</td><td>Quem tiver o link válido. O conteúdo não deve ser indexado nem entrar em cache compartilhado.</td></tr>
            <tr><td><strong>Restrito</strong></td><td>Documentos de verificação, credenciais, referências de sessão e resumos de tokens.</td><td>Servidor e equipe estritamente autorizada.</td></tr>
          </tbody>
        </table>
      </div>
      <p>
        O profissional escolhe quais informações enviar, mas a publicação depende das regras da plataforma e da aprovação aplicável. Alterações materiais podem voltar à moderação; enquanto isso, a última versão aprovada pode continuar pública. Conteúdo pendente, rejeitado, oculto ou associado a perfil suspenso não deve aparecer publicamente.
      </p>
    </section>

    <section id="compartilhamento" class="legal-section">
      <h2>5. Com quem compartilhamos dados</h2>
      <p>A Berufe não vende dados pessoais nem comercializa contatos de clientes. O compartilhamento ocorre somente para operar a plataforma ou atender deveres legítimos, inclusive com:</p>
      <ul>
        <li><strong>Vercel:</strong> hospedagem do site, distribuição de conteúdo e registros técnicos de requisições;</li>
        <li><strong>Render e PostgreSQL gerenciado:</strong> hospedagem da API, processamento de tarefas, banco de dados e registros técnicos;</li>
        <li><strong>provedor de autenticação:</strong> telefone, desafio de autenticação, identificador da conta, sessão e estado da confirmação;</li>
        <li><strong>Cloudflare R2:</strong> armazenamento de imagens, arquivos de portfólio e documentos privados de verificação;</li>
        <li><strong>WhatsApp:</strong> somente quando a pessoa solicita abrir um contato ou compartilhamento, nos termos da seção seguinte;</li>
        <li><strong>autoridades e assessores:</strong> quando necessário para cumprir a lei, uma ordem válida, investigar incidentes ou exercer direitos.</li>
      </ul>
      <p>Fornecedores recebem apenas os dados compatíveis com sua função e devem ser avaliados quanto a segurança, privacidade, retenção e subcontratação antes do lançamento.</p>
    </section>

    <section id="whatsapp" class="legal-section">
      <h2>6. WhatsApp e links externos</h2>
      <p>
        A Berufe usa links oficiais para abrir o WhatsApp no dispositivo quando um visitante escolhe falar com um profissional ou quando alguém decide compartilhar um perfil, convite, pedido de recomendação ou orçamento. O texto sugerido e o link só são enviados ao WhatsApp depois da ação do usuário.
      </p>
      <div class="legal-note">
        <UIcon name="i-lucide-lock-keyhole" />
        <p><strong>A Berufe não envia, recebe nem lê as conversas.</strong> Também não confirma entrega de mensagem, negociação, contratação, aceite de orçamento ou pagamento.</p>
      </div>
      <p>Ao sair da Berufe, passam a valer os termos e a política do serviço externo. Links de orçamento, convite ou recomendação devem ser compartilhados apenas com as pessoas destinatárias, pois podem autorizar ações ou exibir informações sem exigir uma conta.</p>
    </section>

    <section id="cookies" class="legal-section">
      <h2>7. Cookies, segurança e métricas</h2>
      <p>
        A versão planejada da Berufe utiliza apenas mecanismos necessários à sessão autenticada, proteção contra requisições indevidas, preferências essenciais e deduplicação temporária de ações. Não há plataforma externa de publicidade ou analytics no MVP, nem criação de perfil comportamental de visitantes.
      </p>
      <p>
        Métricas como buscas, visualizações de perfil, cliques para o WhatsApp e orçamentos compartilhados são mantidas de forma agregada. Controles temporários podem evitar que repetições óbvias aumentem esses totais, mas não servem para construir uma identidade permanente do visitante.
      </p>
      <p>Se a Berufe passar a usar cookies opcionais ou tecnologias para novas finalidades, esta Política e os controles de escolha serão atualizados antes da ativação.</p>
    </section>

    <section id="retencao" class="legal-section">
      <h2>8. Por quanto tempo mantemos os dados</h2>
      <p>Os prazos definitivos serão registrados em uma matriz operacional antes do lançamento. Eles seguirão os critérios abaixo, sem manter dados por tempo indeterminado apenas porque podem ser úteis no futuro:</p>
      <div class="legal-table-wrap">
        <table class="legal-table">
          <thead><tr><th>Categoria</th><th>Critério de retenção</th></tr></thead>
          <tbody>
            <tr><td>Desafios, sessões e controles de OTP</td><td>Até a expiração da sessão, do desafio ou da janela curta de prevenção de abuso.</td></tr>
            <tr><td>Buscas e métricas</td><td>Eventos mínimos pelo período necessário à agregação; totais agregados enquanto forem úteis para medir o MVP.</td></tr>
            <tr><td>Uploads pendentes</td><td>Até conclusão, rejeição, abandono ou expiração do envio, seguida da limpeza do objeto privado.</td></tr>
            <tr><td>Convites e recomendações</td><td>Até conclusão, revogação ou expiração do token; registros moderados conforme necessidade de exibição e prevenção de abuso.</td></tr>
            <tr><td>Verificações</td><td>Arquivos somente pelo período necessário à análise, contestação e obrigação aplicável; selo e trilha mínima podem durar mais.</td></tr>
            <tr><td>Orçamentos</td><td>Enquanto forem mantidos pelo profissional, o link estiver compartilhado ou houver necessidade operacional ou legal legítima.</td></tr>
            <tr><td>Denúncias e moderação</td><td>Enquanto necessárias à análise, segurança, consistência das decisões e exercício regular de direitos.</td></tr>
            <tr><td>Conta e perfil</td><td>Durante a relação com a Berufe e, depois dela, apenas pelo prazo exigido por obrigação ou defesa de direitos.</td></tr>
          </tbody>
        </table>
      </div>
      <p>Na exclusão, dados públicos são retirados das respostas da Berufe, arquivos elegíveis são apagados do armazenamento e registros privados são eliminados ou anonimizados, salvo aquilo que precise ser preservado por obrigação legal, segurança, prevenção de fraude ou exercício regular de direitos.</p>
    </section>

    <section id="seguranca" class="legal-section">
      <h2>9. Como protegemos os dados</h2>
      <p>O projeto adota medidas proporcionais aos dados tratados, incluindo:</p>
      <ul>
        <li>conexões HTTPS e cookies de sessão seguros e inacessíveis a scripts;</li>
        <li>autorização no servidor para operações profissionais e administrativas;</li>
        <li>acesso temporário e registrado a documentos de verificação;</li>
        <li>armazenamento separado para mídia pública e arquivos privados;</li>
        <li>remoção de metadados desnecessários de imagens públicas;</li>
        <li>tokens longos, de finalidade única, guardados no banco somente em forma protegida;</li>
        <li>autenticação reforçada para administradores e trilhas das decisões de moderação;</li>
        <li>registros técnicos sem telefones, códigos, tokens brutos, documentos ou detalhes de clientes.</li>
      </ul>
      <p>Nenhum sistema é absolutamente seguro. Incidentes serão investigados e, quando aplicável, comunicados aos titulares e às autoridades conforme a legislação e a avaliação de risco.</p>
    </section>

    <section id="direitos" class="legal-section">
      <h2>10. Seus direitos sobre os dados</h2>
      <p>Nos limites e condições previstos na Lei Geral de Proteção de Dados, o titular pode solicitar, entre outros:</p>
      <ul>
        <li>confirmação da existência de tratamento e acesso aos dados;</li>
        <li>correção de dados incompletos, inexatos ou desatualizados;</li>
        <li>informações sobre compartilhamento e sobre as consequências de escolhas relevantes;</li>
        <li>anonimização, bloqueio ou eliminação de dados desnecessários, excessivos ou tratados em desconformidade;</li>
        <li>portabilidade, quando regulamentada e aplicável;</li>
        <li>eliminação de dados tratados com consentimento e revogação desse consentimento;</li>
        <li>oposição a tratamento baseado em hipótese diferente do consentimento, quando houver descumprimento da lei;</li>
        <li>revisão de decisões tomadas unicamente por tratamento automatizado, se essa situação vier a existir.</li>
        <li>apresentação de petição à Autoridade Nacional de Proteção de Dados e aos órgãos de defesa do consumidor, quando cabível.</li>
      </ul>
      <p>A Berufe poderá confirmar a identidade do solicitante e pedir informações estritamente necessárias para localizar os dados e evitar acesso indevido. Alguns pedidos podem ser limitados por obrigações legais, direitos de terceiros, prevenção de fraude ou necessidade de preservar evidências para exercício regular de direitos.</p>
      <p>Até que o canal oficial de privacidade seja definido, esta minuta não deve ser usada para receber solicitações reais. O contato validado será publicado aqui antes do lançamento.</p>
    </section>

    <section id="transferencias" class="legal-section">
      <h2>11. Transferências internacionais</h2>
      <p>
        Alguns fornecedores de hospedagem, autenticação, armazenamento ou suporte podem processar dados fora do Brasil ou utilizar infraestrutura distribuída. Antes do lançamento, a Berufe deverá identificar esses fluxos e adotar os mecanismos exigidos pela legislação brasileira, além de avaliar contratos, localização, segurança e suboperadores envolvidos.
      </p>
    </section>

    <section id="alteracoes" class="legal-section">
      <h2>12. Alterações, vigência e contato</h2>
      <p>
        Cada versão desta Política terá número e data próprios. Alterações relevantes serão apresentadas de modo destacado e, quando necessário, comunicadas aos usuários cadastrados ou submetidas a novo aceite. A versão aceita por cada profissional será registrada junto com a data do aceite.
      </p>
      <p>
        Esta é a <strong>versão 0.1, atualizada em 12 de agosto de 2026</strong>, e permanece uma minuta sem vigência para tratamento de dados reais. A versão 1.0 deverá incluir a identificação completa da responsável, o canal de privacidade, a matriz de retenção aprovada e o registro da revisão jurídica brasileira.
      </p>
    </section>
  </LegalDocument>
</template>
