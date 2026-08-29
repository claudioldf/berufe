<script setup lang="ts">
import LegalDocument from "~/components/legal/LegalDocument.vue";
import type { LegalDocumentSection } from "~/types";

const sections: LegalDocumentSection[] = [
  { id: "responsavel", label: "Responsável e alcance" },
  { id: "dados", label: "Dados e fontes" },
  { id: "finalidades", label: "Finalidades e bases legais" },
  { id: "visibilidade", label: "Visibilidade dos dados" },
  { id: "indicacoes", label: "Perfis por indicação" },
  { id: "fornecedores", label: "Fornecedores e transferências" },
  { id: "navegacao", label: "Navegação e armazenamento" },
  { id: "retencao", label: "Retenção e exclusão" },
  { id: "seguranca", label: "Segurança e automação" },
  { id: "direitos", label: "Direitos e contato" },
];

useSeoMeta({
  title: "Política de Privacidade",
  description: "Como a Berufe trata e protege dados pessoais.",
  robots: "index, follow",
});
</script>

<template>
  <LegalDocument
    eyebrow="Privacidade desde o primeiro dado"
    title="Política de Privacidade"
    description="Este aviso explica quais dados pessoais a Berufe trata, para quais finalidades, com quem compartilha e como exercer seus direitos."
    version="1.0"
    effective-at="1º de agosto de 2026"
    updated-at="29 de agosto de 2026"
    :sections="sections"
  >
    <div class="legal-lead">
      <p>
        A controladora é <strong>Rising Consultoria de Software LTDA.</strong>,
        CNPJ <strong>36.443.360/0001-05</strong>, Rua Princesa Isabel, nº 213 –
        Sala 1, box 682, Centro, CENTRAL Cowork, Joinville/SC, CEP 89201-270.
      </p>
      <p>
        A Berufe atua como agente de tratamento de pequeno porte e disponibiliza
        a Equipe de Suporte como canal de privacidade em
        <a href="mailto:suporte@berufe.com.br">suporte@berufe.com.br</a>. Esta
        Política deve ser lida com os
        <NuxtLink to="/termos-de-uso">Termos de Uso</NuxtLink>.
      </p>
    </div>

    <section id="responsavel" class="legal-section">
      <h2>1. Responsável e alcance</h2>
      <p>
        Esta Política abrange profissionais cadastrados, pessoas incluídas por
        indicação, clientes presentes em orçamentos, autores de recomendações,
        visitantes das páginas públicas e administradores autorizados.
      </p>
      <p>
        Ela se aplica ao cadastro e acesso, perfis, busca, portfólio,
        verificação de identidade, conexões, moderação, WhatsApp, orçamentos,
        acompanhamento de serviços, recomendações, suporte, segurança e medição
        agregada do produto.
      </p>
    </section>

    <section id="dados" class="legal-section">
      <h2>2. Dados pessoais e fontes</h2>
      <h3>2.1. Cadastro, acesso e segurança</h3>
      <p>
        Tratamos telefone, confirmação e estado do desafio OTP, datas de
        cadastro e acesso, versões aceitas dos documentos, sessão da aplicação e
        registros técnicos contra abuso. Administradores usam e-mail, senha
        protegida por hash, eventos de acesso e limites de tentativa.
      </p>

      <h3>2.2. Perfil, portfólio e verificação</h3>
      <p>
        O profissional pode fornecer nome de exibição, data de nascimento, foto,
        apresentação, experiência, WhatsApp, redes sociais, serviços, bairros,
        imagens e descrições de trabalhos e conexões profissionais.
      </p>
      <p>
        Para verificar identidade, recebemos uma imagem JPEG ou PNG de documento
        oficial com foto e a data declarada. O arquivo é privado, regenerado
        para remover metadados desnecessários e acessado somente por
        administradores autorizados, com registro do acesso.
      </p>

      <h3>2.3. Indicações profissionais</h3>
      <p>
        Um profissional elegível pode informar nome, telefone, serviços e
        cobertura de outra pessoa. Registramos quem indicou, a conexão, o
        contexto opcional e a data em que declarou poder compartilhar os dados.
      </p>

      <h3>2.4. Clientes, orçamentos e recomendações</h3>
      <p>
        Um profissional pode cadastrar nome, WhatsApp e e-mail do cliente. O
        orçamento pode incluir serviço, endereço, data, itens, quantidades,
        valores, desconto, validade, observações, decisão do cliente, mensagens,
        conclusão, pendências e cancelamento.
      </p>
      <p>
        Para recomendações, tratamos e-mail ou sua impressão criptográfica,
        token temporário, nome de exibição, texto, confirmação do serviço e
        autorização de publicação.
      </p>

      <h3>2.5. Navegação e suporte</h3>
      <p>
        Para sugerir a cidade da busca, o endereço IP do visitante é enviado à
        MaxMind e convertido em uma localização aproximada de cidade, estado e
        país. A cidade efetivamente usada fica visível e pode ser alterada. Se a
        localização não puder ser determinada ou ainda não for atendida, a busca
        usa Joinville/SC e informa essa escolha.
      </p>
      <p>
        A descrição digitada na busca é enviada ao provedor de inteligência
        artificial para identificar serviço e localização e gerar um rascunho
        curto, em primeira pessoa, para o contato com o profissional. Não
        guardamos a frase original. Sua impressão criptográfica, os critérios
        estruturados, palavras-chave filtradas e o rascunho sem dados pessoais
        podem permanecer em cache por até 24 horas. Registramos separadamente a
        quantidade de resultados, a abertura de perfil e o início de contato no
        WhatsApp, sem identificador persistente do visitante e sem guardar a
        mensagem efetivamente editada ou enviada no WhatsApp. Solicitações de
        suporte incluem o contato, o conteúdo enviado e os registros necessários
        ao atendimento.
      </p>
      <p>
        Os dados vêm do próprio titular, de profissionais que cadastram clientes
        ou indicações, de administradores e da geração automática estritamente
        necessária ao uso e à segurança da plataforma.
      </p>
    </section>

    <section id="finalidades" class="legal-section">
      <h2>3. Finalidades e bases legais</h2>
      <div class="legal-table-wrap">
        <table class="legal-table">
          <thead>
            <tr>
              <th>Finalidade</th>
              <th>Base legal principal</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>Conta, sessão, perfil, orçamento e serviço solicitado.</td>
              <td>Execução de contrato ou procedimentos preliminares.</td>
            </tr>
            <tr>
              <td>
                Segurança, prevenção a abuso, suporte e melhoria agregada.
              </td>
              <td>Legítimo interesse, necessidade e proteção de direitos.</td>
            </tr>
            <tr>
              <td>Verificação manual de identidade e prevenção a fraude.</td>
              <td>Prevenção à fraude e segurança do titular.</td>
            </tr>
            <tr>
              <td>Perfil profissional básico criado por indicação.</td>
              <td>Legítimo interesse, com transparência e oposição.</td>
            </tr>
            <tr>
              <td>Publicação de recomendação de cliente.</td>
              <td>Consentimento específico, comprovável e revogável.</td>
            </tr>
            <tr>
              <td>Obrigações, auditoria, incidentes e defesa.</td>
              <td>Obrigação legal e exercício regular de direitos.</td>
            </tr>
          </tbody>
        </table>
      </div>
      <p>
        A leitura ou aceitação geral desta Política não é usada como
        consentimento para todas as finalidades. Quando dependermos de
        consentimento, a autorização será separada e poderá ser retirada.
      </p>
    </section>

    <section id="visibilidade" class="legal-section">
      <h2>4. Visibilidade e destinatários</h2>
      <div class="legal-table-wrap">
        <table class="legal-table">
          <thead>
            <tr>
              <th>Classificação</th>
              <th>Dados</th>
              <th>Acesso</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td><strong>Público</strong></td>
              <td>
                Perfil publicado ou indicado, nome, serviços, cobertura, foto,
                apresentação, experiência, portfólio, selos, conexões e
                recomendações autorizadas.
              </td>
              <td>Qualquer visitante e mecanismos de busca.</td>
            </tr>
            <tr>
              <td><strong>Por link</strong></td>
              <td>Orçamento, decisões e acompanhamento do serviço.</td>
              <td>Quem possuir o link válido, sem indexação.</td>
            </tr>
            <tr>
              <td><strong>Privado</strong></td>
              <td>
                Conta, telefone em texto, sessão, rascunhos, clientes,
                solicitações pendentes, motivos e registros operacionais.
              </td>
              <td>Titular e equipe autorizada conforme a necessidade.</td>
            </tr>
            <tr>
              <td><strong>Restrito</strong></td>
              <td>Documento de identidade e credenciais administrativas.</td>
              <td>Servidor e administradores estritamente autorizados.</td>
            </tr>
          </tbody>
        </table>
      </div>
      <p>
        Perfil, foto e portfólio elegíveis podem ficar públicos com estado de
        revisão pendente. Conteúdo rejeitado, oculto, excluído ou ligado a conta
        suspensa deixa de ser exibido.
      </p>
      <p>
        O telefone profissional não é escrito na página, mas é usado para formar
        o link de WhatsApp quando o visitante escolhe iniciar contato.
      </p>
    </section>

    <section id="indicacoes" class="legal-section">
      <h2>5. Perfis criados por indicação</h2>
      <p>
        O perfil indicado informa claramente sua origem e se foi reivindicado. A
        Berufe usa os dados profissionais fornecidos pelo indicador para
        apresentar a conexão e facilitar a descoberta local, com medidas de
        minimização, reivindicação por SMS e oposição.
      </p>
      <p>
        A pessoa indicada pode confirmar o telefone para assumir o perfil ou
        escrever para
        <a href="mailto:suporte@berufe.com.br">suporte@berufe.com.br</a> para
        despublicá-lo, corrigir informações ou solicitar exclusão. A
        despublicação é tratada imediatamente após a verificação do pedido.
      </p>
    </section>

    <section id="fornecedores" class="legal-section">
      <h2>6. Fornecedores e transferências internacionais</h2>
      <p>A Berufe não vende dados nem comercializa contatos. Usa:</p>
      <ul>
        <li>
          <strong>Railway e PostgreSQL gerenciado:</strong> aplicação, API,
          banco, sessões, tarefas e logs operacionais na região da Virgínia,
          Estados Unidos;
        </li>
        <li>
          <strong>Infobip:</strong> telefone, desafio OTP, entrega e resultado
          da confirmação;
        </li>
        <li>
          <strong>Cloudflare R2:</strong> armazenamento de imagens públicas e
          arquivos privados;
        </li>
        <li>
          <strong>Resend:</strong> entrega de e-mails transacionais, com dados
          de conta e registros operacionais nos Estados Unidos;
        </li>
        <li>
          <strong>Bugsnag/SmartBear:</strong> erros, versão da aplicação, rota
          normalizada e pilha técnica, sem identificação deliberada do usuário
          ou corpo da requisição;
        </li>
        <li>
          <strong>MaxMind:</strong> endereço IP para estimar cidade, estado e
          país e definir a localização inicial da busca;
        </li>
        <li>
          <strong>autoridades e assessores:</strong> somente quando houver base
          jurídica e necessidade.
        </li>
      </ul>
      <p>
        O tratamento pode envolver os Estados Unidos, a Alemanha e outros países
        constantes das listas vigentes de subprocessadores. A Berufe verifica a
        base e o mecanismo de cada transferência e adota contratos,
        cláusulas-padrão da ANPD ou outra garantia válida. Informações e cópia
        das garantias aplicáveis podem ser solicitadas ao canal de privacidade.
      </p>
      <p>
        WhatsApp, Instagram e YouTube são serviços independentes abertos apenas
        por ação do usuário e passam a aplicar seus próprios termos e avisos.
      </p>
    </section>

    <section id="navegacao" class="legal-section">
      <h2>7. Cookies, armazenamento e medição</h2>
      <p>
        A sessão usa um cookie próprio, seguro, HttpOnly e SameSite, necessário
        para autenticação. A Berufe não usa cookies publicitários nem cria
        perfil persistente de navegação.
      </p>
      <p>
        O navegador pode guardar somente preferências não pessoais, como a
        variação visual da página inicial. Dados de onboarding permanecem na
        memória da sessão e as informações salvas são recuperadas do servidor.
      </p>
      <p>
        A busca registra eventos sem identificador persistente. Nas buscas por
        texto livre, a Berufe mantém por seis meses o texto informado, a
        resposta bruta da inteligência artificial e a interpretação controlada,
        com acesso restrito a administradores para análise do negócio e
        auditoria. O campo é limitado a 200 caracteres e não deve ser usado para
        informar telefone, e-mail, CPF ou outros dados pessoais. Interações
        repetidas usam somente impressões pseudonimizadas e temporárias: até 24
        horas para evitar buscas duplicadas e dez minutos para ações sobre um
        profissional.
      </p>
      <p>
        A localização aproximada pode permanecer em memória por até 24 horas,
        associada somente a uma impressão criptográfica do IP. Falhas de
        consulta permanecem por até cinco minutos. O IP em texto não é incluído
        nesse cache nem nos registros específicos da consulta de localização.
      </p>
    </section>

    <section id="retencao" class="legal-section">
      <h2>8. Retenção, despublicação e exclusão</h2>
      <ul>
        <li>desafio OTP: até 10 minutos;</li>
        <li>limites antiabuso de OTP: até 24 horas;</li>
        <li>
          sessão profissional: inatividade de 7 dias e limite absoluto de 30
          dias; sessão administrativa: 30 minutos e 12 horas;
        </li>
        <li>eventos normalizados de busca: 90 dias;</li>
        <li>
          prompts e respostas da busca por inteligência artificial: 6 meses;
        </li>
        <li>
          análises temporárias da busca por inteligência artificial: 24 horas;
        </li>
        <li>
          localização aproximada associada a impressão criptográfica do IP: até
          24 horas; falha de consulta: até cinco minutos;
        </li>
        <li>métricas diárias agregadas: 730 dias;</li>
        <li>
          imagem de identidade: 30 dias após aprovação, rejeição ou expiração;
        </li>
        <li>
          convite para recomendação: 14 dias, com limpeza do registro
          operacional em até 30 dias após conclusão ou expiração;
        </li>
        <li>
          mídia rejeitada, substituída, excluída ou não anexada: até 30 dias;
        </li>
        <li>
          conta, perfil, clientes, orçamentos e serviços: enquanto necessários à
          relação ou até pedido verificado de encerramento;
        </li>
        <li>
          recomendação: enquanto publicada ou até retirada da autorização;
        </li>
        <li>
          registros mínimos pseudonimizados de aceite, consentimento, fraude,
          auditoria e defesa: cinco anos.
        </li>
      </ul>
      <p>
        Em pedido verificado, a Berufe despublica o perfil, revoga sessões e
        links imediatamente e exclui ou anonimiza os dados elegíveis em até 30
        dias. A exclusão é irreversível; cópias de segurança deixam de conter os
        dados conforme o ciclo contratado do provedor.
      </p>
      <p>
        O profissional cadastrado pode iniciar esse pedido em
        <strong>Conta e privacidade</strong>, após nova confirmação do telefone
        por SMS. A tela fornece um protocolo sem identificadores pessoais para
        acompanhar o processamento. O suporte permanece disponível quando o
        autoatendimento não puder ser usado.
      </p>
    </section>

    <section id="seguranca" class="legal-section">
      <h2>9. Segurança, incidentes e automação</h2>
      <p>
        Usamos HTTPS, criptografia em trânsito e em repouso pelos provedores,
        cookies seguros, autorização no servidor, segregação de arquivos, links
        temporários, limitação de tentativas, regeneração de imagens, filtros de
        logs, trilhas administrativas e monitoramento de erros com minimização
        de dados.
      </p>
      <p>
        Incidentes relevantes são avaliados e comunicados à ANPD e aos titulares
        afetados quando exigido. Nenhuma medida elimina todos os riscos;
        suspeitas podem ser comunicadas ao suporte.
      </p>
      <p>
        A ordem da busca é automatizada pelos critérios descritos nos Termos:
        tipo do perfil, cobertura específica, identidade verificada, portfólio
        aprovado, conexões confirmadas e revisão do perfil, sempre depois da
        correspondência de serviço e região. Não há compra de posição. A Berufe
        não toma decisão exclusivamente automatizada que determine contratação,
        preço, pagamento ou acesso a serviço profissional.
      </p>
    </section>

    <section id="direitos" class="legal-section">
      <h2>10. Direitos, solicitações e alterações</h2>
      <p>
        O titular pode pedir confirmação, acesso, correção, informação sobre
        compartilhamento, anonimização, bloqueio, exclusão, portabilidade quando
        regulamentada, revisão de decisão automatizada, oposição e retirada de
        consentimento. Também pode reclamar à ANPD.
      </p>
      <p>
        Profissionais cadastrados podem solicitar a exclusão irreversível em
        <strong>Conta e privacidade</strong>. Os demais direitos, pedidos de
        pessoas sem acesso ao autoatendimento e dúvidas podem ser enviados para
        <a href="mailto:suporte@berufe.com.br">suporte@berufe.com.br</a>. A
        Berufe confirmará a identidade sem pedir dados excessivos, responderá de
        forma simplificada quando possível e fornecerá declaração completa de
        acesso no prazo legal de até 15 dias.
      </p>
      <p>
        A correção ou exclusão pode ser comunicada a operadores e destinatários
        quando necessário. A Berufe informará eventual impossibilidade e a base
        para preservar dados. Mudanças relevantes nesta Política receberão nova
        versão e, quando necessário, novo aceite.
      </p>
    </section>
  </LegalDocument>
</template>
