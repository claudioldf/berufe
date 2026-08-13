<script setup lang="ts">
import LegalDocument from '~/components/legal/LegalDocument.vue'
import type { LegalDocumentSection } from '~/types'

const sections: LegalDocumentSection[] = [
  { id: 'objeto', label: 'Objeto e aceitação' },
  { id: 'elegibilidade', label: 'Elegibilidade e cadastro' },
  { id: 'papel-berufe', label: 'Papel da Berufe' },
  { id: 'perfis', label: 'Perfis e conteúdo' },
  { id: 'verificacoes', label: 'Verificação e moderação' },
  { id: 'busca-contato', label: 'Busca e contato direto' },
  { id: 'recomendacoes', label: 'Recomendações e relações' },
  { id: 'orcamentos', label: 'Orçamentos' },
  { id: 'condicoes-economicas', label: 'Condições econômicas' },
  { id: 'obrigacoes', label: 'Obrigações e proibições' },
  { id: 'suspensao', label: 'Suspensão e encerramento' },
  { id: 'propriedade', label: 'Propriedade intelectual' },
  { id: 'responsabilidade', label: 'Responsabilidades' },
  { id: 'alteracoes', label: 'Privacidade e alterações' },
  { id: 'lei', label: 'Lei aplicável' },
]

useSeoMeta({
  title: 'Termos de Uso',
  description: 'Conheça as condições para usar a plataforma Berufe como visitante, cliente ou profissional.',
  robots: 'noindex, nofollow',
})
</script>

<template>
  <LegalDocument
    eyebrow="Uma rede feita de confiança clara"
    title="Termos de Uso"
    description="Estas condições explicam o que a Berufe oferece, o que esperamos de quem participa e onde termina o papel da plataforma."
    version="0.1 · minuta"
    updated-at="12 de agosto de 2026"
    :sections="sections"
  >
    <div class="legal-lead">
      <p>
        A Berufe ajuda pessoas a encontrar profissionais de reforma e manutenção residencial a partir de informações e evidências claras. O contato e a contratação acontecem diretamente entre as pessoas envolvidas.
      </p>
      <p>
        Ao usar a plataforma ou criar uma conta, você declara ter lido estes Termos e a <NuxtLink to="/privacidade">Política de Privacidade</NuxtLink>. A aceitação válida da versão vigente será exigida antes da criação de um perfil profissional.
      </p>
    </div>

    <section id="objeto" class="legal-section">
      <h2>1. Objeto, definições e aceitação</h2>
      <p>Estes Termos regulam o acesso e o uso do site, páginas públicas e ferramentas da Berufe. Para facilitar a leitura:</p>
      <ul>
        <li><strong>visitante</strong> é quem navega, pesquisa ou consulta conteúdo público;</li>
        <li><strong>cliente</strong> é quem busca um profissional, envia uma recomendação, recebe um orçamento ou conversa diretamente com um profissional;</li>
        <li><strong>profissional</strong> é a pessoa cadastrada que cria e administra seu perfil e suas ferramentas;</li>
        <li><strong>usuário</strong> reúne visitantes, clientes e profissionais, conforme o contexto;</li>
        <li><strong>conteúdo</strong> inclui textos, imagens, documentos, evidências, recomendações, relações, denúncias e dados de orçamento enviados à plataforma.</li>
      </ul>
      <p>A identificação jurídica completa da responsável pela Berufe será incluída antes que estes Termos entrem em vigor para usuários reais.</p>
    </section>

    <section id="elegibilidade" class="legal-section">
      <h2>2. Elegibilidade, cadastro e acesso</h2>
      <p>Contas e envio de conteúdo são destinados a pessoas com pelo menos 18 anos e capacidade para praticar os atos correspondentes. Quem atua em nome de uma empresa declara possuir autorização para representá-la.</p>
      <p>Na primeira versão, apenas profissionais e administradores possuem contas. Clientes podem pesquisar, consultar perfis, receber orçamentos e enviar recomendações por fluxos específicos sem criar uma conta geral.</p>
      <p>O acesso profissional é feito por confirmação do número de telefone com código de uso único. O usuário deve:</p>
      <ul>
        <li>informar dados verdadeiros, atuais e pertencentes a ele;</li>
        <li>manter controle do telefone e do dispositivo usados para acessar a conta;</li>
        <li>não compartilhar códigos ou sessões e comunicar suspeitas de acesso indevido;</li>
        <li>manter suas informações e o número de WhatsApp atualizados.</li>
      </ul>
      <p>A Berufe pode aplicar limites de tentativas, recusar verificações inseguras e encerrar sessões para proteger usuários e a plataforma.</p>
    </section>

    <section id="papel-berufe" class="legal-section">
      <h2>3. O que a Berufe faz — e o que não faz</h2>
      <p>A Berufe oferece uma presença profissional estruturada, busca por serviço e região, apresentação de evidências, contato direto e uma ferramenta simples de orçamento.</p>
      <p><strong>A Berufe não presta o serviço residencial anunciado e não é empregadora, representante, sócia ou integrante da equipe dos profissionais.</strong> Também não é parte do contrato celebrado entre cliente e profissional e, no MVP, não agenda, recebe pagamentos, cobra comissão, vende contatos ou distribui uma solicitação a vários profissionais.</p>
      <p>Cliente e profissional são responsáveis por conversar, definir escopo, prazo, preço, materiais, autorizações, segurança, garantias e demais condições do serviço. Eles também devem verificar documentos ou requisitos adicionais relevantes para a contratação.</p>
      <div class="legal-note">
        <UIcon name="i-lucide-shield-check" />
        <p>A Berufe apresenta evidências específicas para apoiar uma escolha. Ela não promete que um contato resultará em contratação nem garante a qualidade, segurança ou resultado do serviço.</p>
      </div>
    </section>

    <section id="perfis" class="legal-section">
      <h2>4. Perfis, declarações e conteúdo</h2>
      <p>O profissional pode criar um perfil com nome, foto, apresentação, experiência declarada, serviços, regiões atendidas, portfólio e telefone para contato pelo WhatsApp. Serviços e bairros devem ser escolhidos nos catálogos controlados pela Berufe.</p>
      <p>Ao enviar conteúdo, o profissional:</p>
      <ul>
        <li>declara que as informações são verdadeiras, atuais e compatíveis com sua atuação;</li>
        <li>confirma possuir os direitos e autorizações necessários sobre textos, fotos, marcas e imagens de pessoas, imóveis ou trabalhos;</li>
        <li>compromete-se a não expor dados pessoais de clientes ou terceiros sem necessidade e autorização;</li>
        <li>reconhece que experiência profissional informada por ele será identificada como declaração, não como fato verificado;</li>
        <li>autoriza a Berufe, enquanto o conteúdo permanecer na plataforma, a armazená-lo, processá-lo, adaptá-lo tecnicamente e exibi-lo para operar e divulgar o perfil.</li>
      </ul>
      <p>Essa licença é não exclusiva, limitada às finalidades da plataforma e não transfere a titularidade do conteúdo à Berufe. Imagens públicas podem ser redimensionadas, reencodificadas e ter metadados desnecessários removidos.</p>
    </section>

    <section id="verificacoes" class="legal-section">
      <h2>5. Verificações, selos e moderação</h2>
      <p>O profissional pode solicitar a conferência de telefone, identidade, empresa ou certificado, conforme as opções disponíveis. Documentos enviados para análise são privados; somente o selo controlado pela Berufe e a data da conferência podem ser publicados.</p>
      <p>Cada selo descreve exatamente o que foi conferido. Um selo:</p>
      <ul>
        <li>não representa investigação completa de antecedentes;</li>
        <li>não valida toda declaração do perfil;</li>
        <li>não certifica habilidade técnica além do documento especificamente analisado;</li>
        <li>não constitui recomendação, seguro ou garantia do serviço.</li>
      </ul>
      <p>Perfis, fotos, portfólios, recomendações, relações e verificações podem passar por análise manual. A Berufe pode aprovar, rejeitar, ocultar, restaurar ou solicitar correção segundo critérios consistentes de segurança, clareza, pertinência e conformidade com estes Termos.</p>
      <p>Enquanto uma alteração material estiver pendente, a última versão aprovada poderá permanecer pública. Uma aprovação não impede revisão posterior diante de denúncia, informação nova, expiração, erro ou violação.</p>
    </section>

    <section id="busca-contato" class="legal-section">
      <h2>6. Busca e contato direto</h2>
      <p>A busca considera serviço, região atendida e sinais públicos específicos, usando critérios simples e explicáveis. A Berufe não mostra pontuação secreta, ranking comprado ou posição patrocinada no MVP.</p>
      <p>Os resultados não representam lista exaustiva nem recomendação personalizada. A ausência ou ordem de um perfil pode decorrer de área atendida, serviço selecionado, estado de publicação, evidências aprovadas ou atualização do cadastro.</p>
      <p>Ao tocar no botão de contato, o visitante escolhe abrir o WhatsApp com uma mensagem sugerida. A partir desse ponto, a conversa ocorre fora da Berufe. A plataforma pode contar o clique de forma agregada, mas não lê a mensagem, não confirma entrega e não conclui que houve contratação.</p>
    </section>

    <section id="recomendacoes" class="legal-section">
      <h2>7. Recomendações e relações profissionais</h2>
      <h3>7.1. Recomendações de clientes</h3>
      <p>Um profissional pode convidar cliente anterior por um link único. Para enviar a recomendação, o cliente deve confirmar que o serviço ocorreu, informar conteúdo verdadeiro e confirmar seu telefone. Não há notas por estrelas, avaliações abertas ou recomendações anônimas.</p>
      <p>A pessoa que recomenda é responsável por sua experiência e opinião. Deve evitar acusações, dados sensíveis, endereço exato, informações de terceiros ou conteúdo ofensivo. A Berufe pode moderar a recomendação e não garante sua publicação.</p>

      <h3>7.2. Relações entre profissionais</h3>
      <p>Profissionais que atendam aos critérios de verificação podem recomendar outro membro ou declarar que trabalharam juntos. A relação depende da confirmação da outra pessoa quando aplicável e de aprovação antes de se tornar pública. Relações não podem ser anônimas, compradas, trocadas por vantagens ou fabricadas.</p>
    </section>

    <section id="orcamentos" class="legal-section">
      <h2>8. Orçamentos compartilhados</h2>
      <p>A ferramenta permite ao profissional registrar nome do cliente, descrição, itens, quantidades, valores, desconto, validade e observações, revisar uma prévia e gerar um link para compartilhar.</p>
      <p>Os cálculos mostrados pela interface devem ser conferidos pelo profissional antes do envio. O profissional é o único responsável pelo conteúdo, preços, tributos, validade, condições e cumprimento da proposta.</p>
      <div class="legal-note">
        <UIcon name="i-lucide-file-lock-2" />
        <p>O link permite visualizar e imprimir a proposta. Ele <strong>não representa aceite, assinatura, contrato, nota fiscal, cobrança, pagamento ou garantia da Berufe</strong>.</p>
      </div>
      <p>O profissional deve enviar o link somente ao destinatário e considerar que qualquer pessoa que o receba poderá visualizar o conteúdo enquanto ele estiver válido. A Berufe pode invalidar o acesso por segurança, solicitação legítima ou encerramento do registro.</p>
    </section>

    <section id="condicoes-economicas" class="legal-section">
      <h2>9. Condições econômicas</h2>
      <p>No MVP descrito por estes Termos, a Berufe não cobra para vender ou liberar contatos de clientes, não recebe comissão sobre serviços e não processa pagamentos entre cliente e profissional.</p>
      <p>A existência de funcionalidades sem cobrança no MVP não cria promessa de gratuidade permanente para toda funcionalidade futura. Qualquer recurso pago deverá ser apresentado com preço, condições e aceite próprios antes da contratação, sem cobrança retroativa pelo uso já realizado.</p>
    </section>

    <section id="obrigacoes" class="legal-section">
      <h2>10. Obrigações e práticas proibidas</h2>
      <p>Todos devem usar a Berufe com boa-fé, respeitar a legislação e os direitos das outras pessoas. É proibido:</p>
      <ul>
        <li>criar identidade falsa, usar telefone alheio ou fornecer informação profissional enganosa;</li>
        <li>publicar trabalho, documento, marca, imagem ou relato sem direito ou autorização;</li>
        <li>forjar verificações, serviços, recomendações, relações ou colaborações;</li>
        <li>comprar, vender, trocar ou pressionar alguém por recomendações;</li>
        <li>enviar conteúdo discriminatório, ameaçador, ilegal, fraudulento, difamatório ou que viole a privacidade;</li>
        <li>expor senhas, códigos, documentos, endereços, dados financeiros ou outros dados desnecessários de terceiros;</li>
        <li>manipular métricas, automatizar acessos abusivos, sondar vulnerabilidades ou contornar limites de segurança;</li>
        <li>copiar em massa, revender, montar banco de dados ou explorar conteúdo da plataforma sem autorização;</li>
        <li>usar a Berufe para categorias ou finalidades ilícitas ou fora do escopo disponibilizado.</li>
      </ul>
      <p>Visitantes podem denunciar conteúdo público por meio do recurso disponível no perfil. Denúncias devem ser honestas, específicas e não podem ser usadas para assédio, retaliação ou vantagem comercial.</p>
    </section>

    <section id="suspensao" class="legal-section">
      <h2>11. Rejeição, suspensão e encerramento</h2>
      <p>A Berufe pode limitar funcionalidades, rejeitar ou ocultar conteúdo, revogar links, suspender acesso ou encerrar conta quando houver:</p>
      <ul>
        <li>violação destes Termos ou da legislação;</li>
        <li>risco à segurança, à privacidade ou a outras pessoas;</li>
        <li>fraude, abuso, falsidade ou tentativa de manipulação;</li>
        <li>ordem de autoridade competente;</li>
        <li>necessidade técnica urgente ou encerramento da funcionalidade.</li>
      </ul>
      <p>Quando for apropriado e não aumentar o risco, a Berufe informará o motivo e permitirá correção ou esclarecimento. Conteúdo suspenso ou oculto deixa de aparecer publicamente de imediato, embora registros mínimos possam ser preservados conforme a Política de Privacidade.</p>
      <p>O profissional poderá pedir correção ou exclusão de conta pelo canal oficial a ser publicado antes do lançamento. A remoção da conta não desfaz automaticamente contratos ou obrigações assumidas diretamente com clientes ou terceiros.</p>
    </section>

    <section id="propriedade" class="legal-section">
      <h2>12. Propriedade intelectual e serviços externos</h2>
      <p>A marca Berufe, a interface, os textos institucionais, o software, a organização dos catálogos e os demais elementos próprios da plataforma são protegidos pela legislação aplicável. Estes Termos não concedem direito de copiar, modificar, distribuir, licenciar ou explorar esses elementos além do uso normal da plataforma.</p>
      <p>O conteúdo do usuário continua pertencendo a ele ou aos respectivos titulares, sujeito à licença operacional descrita nestes Termos.</p>
      <p>Links para WhatsApp ou outros serviços são oferecidos por conveniência. A disponibilidade, segurança e o tratamento de dados nesses ambientes são definidos por seus próprios responsáveis e documentos.</p>
    </section>

    <section id="responsabilidade" class="legal-section">
      <h2>13. Disponibilidade e responsabilidades</h2>
      <p>A Berufe trabalhará para manter a plataforma disponível e proteger as informações, mas funcionalidades podem ser interrompidas por manutenção, falhas de fornecedores, internet, incidentes, atualização ou eventos fora de controle razoável.</p>
      <p>Dentro dos limites permitidos pela legislação, a Berufe não responde:</p>
      <ul>
        <li>pela execução, qualidade, segurança, prazo, preço ou resultado de serviço contratado diretamente;</li>
        <li>por declarações, conduta, atrasos ou descumprimentos de clientes, profissionais ou terceiros;</li>
        <li>por mensagens, negociações ou pagamentos realizados fora da plataforma;</li>
        <li>pela perda causada pelo compartilhamento indevido de código, sessão ou link privado pelo usuário;</li>
        <li>por indisponibilidade de serviço externo além de seu controle razoável.</li>
      </ul>
      <p>Nada nestes Termos exclui responsabilidade que não possa ser afastada por lei, direitos garantidos pela legislação de proteção de dados ou normas de defesa do consumidor aplicáveis. Cada caso será avaliado segundo a participação efetiva da Berufe e as circunstâncias concretas.</p>
    </section>

    <section id="alteracoes" class="legal-section">
      <h2>14. Privacidade, alterações e comunicações</h2>
      <p>O tratamento de dados pessoais é explicado na <NuxtLink to="/privacidade">Política de Privacidade</NuxtLink>, que integra estes Termos.</p>
      <p>A Berufe pode atualizar estas condições para refletir mudanças no produto, na operação ou na legislação. Cada versão terá número e data. Mudanças relevantes serão destacadas e, quando necessário, dependerão de novo aceite. A versão aceita e o momento da aceitação serão registrados para contas profissionais.</p>
      <p>Comunicações oficiais relacionadas à conta poderão ser feitas pelos canais cadastrados ou por avisos na própria plataforma. Não serão usadas mensagens automáticas pelo WhatsApp no MVP.</p>
    </section>

    <section id="lei" class="legal-section">
      <h2>15. Lei aplicável, contato e vigência</h2>
      <p>Estes Termos serão interpretados conforme as leis da República Federativa do Brasil. Questões serão encaminhadas ao canal oficial de suporte, preservados os foros e direitos assegurados obrigatoriamente pela legislação aplicável, inclusive os do consumidor quando incidentes.</p>
      <p>Esta é a <strong>versão 0.1, atualizada em 12 de agosto de 2026</strong>, e permanece uma minuta. Antes da vigência, esta seção receberá a identificação jurídica da responsável, CNPJ, endereço, canal de suporte e registro da revisão jurídica brasileira.</p>
    </section>
  </LegalDocument>
</template>
