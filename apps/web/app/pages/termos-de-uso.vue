<script setup lang="ts">
import LegalDocument from "~/components/legal/LegalDocument.vue";
import type { LegalDocumentSection } from "~/types";

const sections: LegalDocumentSection[] = [
  { id: "responsavel", label: "Responsável e aceitação" },
  { id: "elegibilidade", label: "Elegibilidade e contas" },
  { id: "papel", label: "Papel da Berufe" },
  { id: "perfis", label: "Perfis e conteúdo" },
  { id: "indicacoes", label: "Perfis por indicação" },
  { id: "moderacao", label: "Verificação e moderação" },
  { id: "busca", label: "Busca e contato" },
  { id: "orcamentos", label: "Orçamentos e serviços" },
  { id: "recomendacoes", label: "Recomendações de clientes" },
  { id: "conduta", label: "Conduta e encerramento" },
  { id: "responsabilidade", label: "Disponibilidade e responsabilidade" },
  { id: "disposicoes", label: "Disposições finais" },
];

useSeoMeta({
  title: "Termos de Uso",
  description: "Regras vigentes de uso da Berufe.",
  robots: "index, follow",
});
</script>

<template>
  <LegalDocument
    eyebrow="Uma rede de confiança começa por regras claras"
    title="Termos de Uso"
    description="Estas regras explicam como a Berufe funciona, as responsabilidades de cada pessoa e os limites da plataforma."
    version="1.0"
    effective-at="1º de agosto de 2026"
    updated-at="23 de agosto de 2026"
    :sections="sections"
  >
    <div class="legal-lead">
      <p>
        A Berufe é operada por
        <strong>Rising Consultoria de Software LTDA.</strong>, CNPJ
        <strong>36.443.360/0001-05</strong>, com sede na Rua Princesa Isabel, nº
        213 – Sala 1, box 682, Centro, CENTRAL Cowork, Joinville/SC, CEP
        89201-270.
      </p>
      <p>
        Ao criar uma conta ou usar uma área autenticada, você aceita estes
        Termos e declara ter lido a
        <NuxtLink to="/privacidade">Política de Privacidade</NuxtLink>. Dúvidas
        e solicitações podem ser enviadas para
        <a href="mailto:suporte@berufe.com.br">suporte@berufe.com.br</a>.
      </p>
    </div>

    <section id="responsavel" class="legal-section">
      <h2>1. Responsável, objeto e aceitação</h2>
      <p>
        A Berufe oferece cadastro de profissionais, perfis públicos, busca por
        serviço e região, portfólio, verificação de identidade, conexões
        profissionais, perfis básicos por indicação, contato pelo WhatsApp,
        orçamentos compartilhados, acompanhamento de serviço e recomendações de
        clientes.
      </p>
      <p>
        Estes Termos se aplicam a profissionais, pessoas indicadas, clientes que
        recebem orçamentos ou convites e visitantes. Quem não concordar não deve
        criar conta nem continuar uma ação que exija aceitação.
      </p>
    </section>

    <section id="elegibilidade" class="legal-section">
      <h2>2. Elegibilidade, contas e acesso</h2>
      <p>
        A criação e o uso de conta profissional são permitidos somente a pessoas
        com 18 anos ou mais e capacidade para praticar os atos relacionados ao
        serviço anunciado. A Berufe pode suspender ou remover uma conta quando
        identificar que esse requisito não é atendido.
      </p>
      <p>
        Contas profissionais usam confirmação do telefone por código de uso
        único enviado pelo Infobip. A confirmação cria uma sessão própria da
        Berufe; ela não transfere para a Berufe a titularidade do número nem
        garante a identidade civil da pessoa.
      </p>
      <p>
        Contas administrativas usam e-mail e senha individuais, limites contra
        tentativas abusivas e sessões de curta duração. Cada pessoa deve
        proteger seu acesso, encerrar a sessão em dispositivo compartilhado e
        comunicar suspeitas de uso indevido ao suporte.
      </p>
    </section>

    <section id="papel" class="legal-section">
      <h2>3. Papel da Berufe</h2>
      <p>
        A Berufe organiza e apresenta informações profissionais. Não é
        empregadora, representante, prestadora do serviço anunciado, parte da
        contratação nem garantidora de preço, prazo, licença, segurança,
        qualidade ou resultado.
      </p>
      <div class="legal-note">
        <UIcon name="i-lucide-info" />
        <p>
          <strong>Operação gratuita:</strong> nesta versão, a Berufe não cobra
          pelo cadastro ou contato, não recebe comissão e não processa
          pagamentos. Uma futura cobrança exigirá informação prévia e aceite das
          condições aplicáveis.
        </p>
      </div>
    </section>

    <section id="perfis" class="legal-section">
      <h2>4. Perfis, serviços e conteúdo</h2>
      <p>
        O profissional é responsável pela exatidão e atualização do nome,
        apresentação, experiência, WhatsApp, serviços e área atendida. Deve
        possuir os direitos e autorizações necessários sobre imagens, marcas,
        textos, trabalhos e dados de terceiros que enviar.
      </p>
      <p>
        Ao publicar conteúdo, o titular concede à Berufe licença gratuita, não
        exclusiva e limitada à hospedagem, adaptação técnica e exibição
        necessárias ao funcionamento da plataforma. A licença termina quando o
        conteúdo é excluído, ressalvadas cópias temporárias e retenções legais.
      </p>
    </section>

    <section id="indicacoes" class="legal-section">
      <h2>5. Perfis criados por indicação</h2>
      <p>
        Um profissional com cadastro, telefone e identidade confirmados pode
        indicar outro profissional adulto por nome e telefone, com serviços e
        cobertura opcionais. Quem indica declara que pode compartilhar esses
        dados profissionais e responde por sua origem e exatidão.
      </p>
      <p>
        O perfil básico é identificado como criado por indicação e pode ficar
        público enquanto houver uma indicação ativa ou depois que o titular
        concluir o cadastro. O titular pode reivindicá-lo confirmando o telefone
        por SMS e pode solicitar despublicação ou exclusão pelo canal de
        suporte.
      </p>
    </section>

    <section id="moderacao" class="legal-section">
      <h2>6. Verificação e moderação</h2>
      <p>
        A verificação manual do MVP abrange somente identidade. O selo indica
        que uma evidência específica foi conferida; não representa licença
        profissional, certificação técnica, qualidade garantida ou ausência de
        risco.
      </p>
      <p>
        Perfis, fotos e portfólios elegíveis podem ficar públicos enquanto
        aguardam revisão. A moderação ocorre também depois da publicação, e a
        Berufe pode aprovar, rejeitar, ocultar ou restaurar conteúdo. A imagem
        de documento usada para verificar identidade permanece privada.
      </p>
      <p>
        Conteúdo ou conta pode ser ocultado ou suspenso imediatamente quando
        houver indício de fraude, risco, ilegalidade, violação de direitos ou
        descumprimento destes Termos.
      </p>
    </section>

    <section id="busca" class="legal-section">
      <h2>7. Busca, compartilhamento e WhatsApp</h2>
      <p>
        A descrição da busca é interpretada automaticamente para identificar
        serviços e localizações do catálogo. A busca então exige correspondência
        do serviço e da cobertura. Perfis com cadastro próprio precedem os
        perfis ainda não reivindicados; quando um bairro é identificado, a
        cobertura específica precede a cidade inteira. Depois, a ordem considera
        identidade verificada, portfólio aprovado, conexões confirmadas e a
        revisão mais recente do perfil. Não há compra de posição, nota oculta
        nem garantia de destaque.
      </p>
      <p>
        Compartilhar um perfil ou abrir o WhatsApp depende de ação da pessoa. A
        Berufe não envia, recebe nem lê a conversa realizada no WhatsApp e não
        confirma que houve negociação ou contratação.
      </p>
    </section>

    <section id="orcamentos" class="legal-section">
      <h2>8. Orçamentos e acompanhamento do serviço</h2>
      <p>
        O profissional pode cadastrar cliente, escopo, itens, quantidades,
        valores, desconto, endereço, data, validade e observações. Ele responde
        pela base legal para inserir dados do cliente e pela exatidão da oferta.
      </p>
      <p>
        O rascunho é privado. Quem recebe o link pode visualizar e imprimir,
        aprovar, recusar ou solicitar alterações. A aprovação cria um registro
        de serviço, e o mesmo link pode registrar pedido de conclusão,
        pendência, confirmação ou cancelamento.
      </p>
      <div class="legal-note">
        <UIcon name="i-lucide-info" />
        <p>
          <strong>Limite do recurso:</strong> essas ações registram a
          manifestação realizada na plataforma, mas não substituem contrato,
          nota fiscal, cobrança, pagamento ou garantias exigidas entre as
          partes.
        </p>
      </div>
    </section>

    <section id="recomendacoes" class="legal-section">
      <h2>9. Recomendações de clientes</h2>
      <p>
        Depois da conclusão, um cliente com e-mail informado pode receber um
        convite pessoal válido por 14 dias. A recomendação só é publicada quando
        o cliente confirma o serviço e autoriza expressamente a exibição do nome
        e do texto.
      </p>
      <p>
        Não há nota por estrelas nem revisão prévia. O autor responde pela
        veracidade e pelos direitos sobre o texto. A autorização de publicação
        pode ser retirada por
        <a href="mailto:suporte@berufe.com.br">suporte@berufe.com.br</a>.
      </p>
    </section>

    <section id="conduta" class="legal-section">
      <h2>10. Conduta, suspensão e encerramento</h2>
      <p>É proibido:</p>
      <ul>
        <li>fornecer informação falsa ou indicar pessoa sem autorização;</li>
        <li>publicar conteúdo ilegal, discriminatório ou sem direitos;</li>
        <li>
          assediar, fraudar, enviar código malicioso ou contornar segurança;
        </li>
        <li>manipular buscas, contagens, recomendações ou conexões;</li>
        <li>usar dados obtidos na Berufe para spam ou revenda de contatos.</li>
      </ul>
      <p>
        A Berufe pode advertir, limitar, ocultar, suspender ou encerrar acesso
        de forma compatível com a gravidade e o risco. O titular pode solicitar
        despublicação e exclusão irreversível dos dados elegíveis pelo suporte.
        Registros mínimos podem ser preservados quando exigidos por lei,
        segurança, auditoria ou exercício regular de direitos.
      </p>
    </section>

    <section id="responsabilidade" class="legal-section">
      <h2>11. Disponibilidade e responsabilidade</h2>
      <p>
        A plataforma pode ficar temporariamente indisponível por manutenção,
        falha de fornecedor, medida de segurança ou incidente. A Berufe buscará
        restaurar o serviço, mas não promete operação ininterrupta.
      </p>
      <p>
        Nos limites da lei, a Berufe não responde por declarações, negociações,
        serviços, atrasos ou descumprimentos entre profissionais, clientes e
        terceiros. Nada nestes Termos afasta responsabilidade ou direito que a
        legislação não permita excluir.
      </p>
    </section>

    <section id="disposicoes" class="legal-section">
      <h2>12. Privacidade, alterações e lei aplicável</h2>
      <p>
        O tratamento de dados segue a Política de Privacidade. Mudanças
        relevantes receberão nova versão e poderão exigir novo aceite antes da
        continuidade do uso autenticado.
      </p>
      <p>
        Aplicam-se as leis brasileiras. Direitos obrigatórios do consumidor e
        regras legais de competência permanecem preservados. Antes de medida
        judicial, as pessoas podem buscar solução pelo canal de suporte, sem
        prejuízo do acesso aos órgãos competentes.
      </p>
    </section>
  </LegalDocument>
</template>
