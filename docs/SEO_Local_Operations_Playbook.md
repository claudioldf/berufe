# Operação de SEO local da Berufe

Este documento separa o que a aplicação automatiza do que precisa ser feito após cada publicação. O objetivo é manter páginas de serviço por cidade úteis, rastreáveis e indexáveis somente quando houver conteúdo editorial e oferta real.

## Status da implementação

Concluído nesta entrega:

- [x] criar coleções tipadas para conteúdo local e páginas de aquisição de profissionais;
- [x] publicar conteúdo editorial para 25 serviços em Joinville, Blumenau, Balneário Camboriú e Curitiba;
- [x] publicar conteúdo editorial próprio para os 25 serviços em `/para-profissionais`;
- [x] adicionar título, descrição, canonical, regra de `robots` e schema.org `Service` às páginas locais;
- [x] condicionar indexação, hubs e sitemap à presença simultânea de conteúdo publicado e oferta profissional real;
- [x] adicionar testes para metadados, inventário editorial, similaridade, schema e sitemaps;
- [x] validar aplicação web, build de produção, contrato OpenAPI, segurança e suíte Rails.

Pendente após o merge:

- [ ] Deploy coordenado da API e do site
- [ ] Confirmar `SITE_URL` de produção
- [ ] Enviar sitemap no Search Console
- [ ] Inspecionar uma amostra de URLs depois do deploy
- [ ] Iniciar aquisição legítima de links locais
- [ ] Orientar profissionais elegíveis sobre o próprio Perfil da Empresa
- [ ] Monitorar indexação e conversões semanalmente

## Decisões e limites operacionais

- A Berufe é o marketplace intermediador, não um prestador local. Por isso, suas páginas de serviço usam `Service`, profissionais reais como `provider` e a organização como `broker`.
- A Berufe não deve criar perfis locais próprios ou perfis por cidade. Somente profissionais que atendem presencialmente e são donos ou representantes autorizados do negócio devem administrar o próprio Google Perfil da Empresa.
- Conteúdo pronto não basta para indexação: quando não há oferta profissional pública para a combinação de serviço e cidade, a página permanece em `noindex` e fora do sitemap.
- Deploy, Search Console, Perfil da Empresa e aquisição de links são ações externas deliberadamente separadas desta mudança de código e exigem execução autorizada após o merge.

## Regra de publicação

Uma rota `/encontrar/{estado}/{cidade}/{servico}` só recebe `index, follow` e entra no sitemap quando as duas condições abaixo forem verdadeiras:

1. existe conteúdo editorial com `published: true` para a combinação;
2. a API informa pelo menos um perfil profissional público que atende o serviço e a cidade.

Sem uma dessas condições, a rota continua acessível para usuários, mas recebe `noindex, follow` e não aparece no sitemap. Os hubs de cidade e serviço seguem a mesma interseção. Isso evita anunciar uma oferta inexistente e impede que conteúdo ainda não revisado seja publicado apenas para cobrir uma palavra-chave.

As páginas usam schema.org `Service`, com `areaServed`, profissionais reais em `provider` e a Berufe como `broker`. Esse modelo representa melhor um marketplace do que declarar a própria Berufe como um estabelecimento local. O vocabulário do Schema.org aceita `Place` em `areaServed`, `Person` ou `Organization` em `provider` e define `broker` como o intermediário da troca: [Service](https://schema.org/Service), [areaServed](https://schema.org/areaServed).

Dados estruturados devem sempre refletir o conteúdo visível. O Google recomenda conteúdo original, relevante e não enganoso, além de testar a página publicada: [diretrizes gerais de dados estruturados](https://developers.google.com/search/docs/appearance/structured-data/sd-policies).

## Checklist de publicação

- [ ] Fazer deploy da API e do site na mesma janela, para manter contrato e comportamento sincronizados.
- [ ] Confirmar que `SITE_URL` aponta para a origem canônica de produção, sem `localhost`.
- [ ] Abrir uma página com oferta, como `/encontrar/sc/joinville/{servico}`, e confirmar `index, follow`, canonical absoluto, H1 e conteúdo editorial.
- [ ] Abrir uma combinação sem oferta e confirmar `noindex, follow` e ausência no sitemap.
- [ ] Validar duas páginas locais no Schema Markup Validator e no Rich Results Test. `Service` ajuda máquinas a entender a entidade, mas não corresponde necessariamente a um rich result específico do Google.
- [ ] Confirmar que o sitemap contém apenas URLs canônicas e indexáveis. O Google recomenda sitemap gerado automaticamente para conjuntos maiores e inclusão somente das URLs desejadas nos resultados: [criar e enviar sitemap](https://developers.google.com/search/docs/crawling-indexing/sitemaps/build-sitemap).
- [ ] Enviar ou reenviar o sitemap no Search Console.
- [ ] Usar a Inspeção de URL em uma amostra pequena: uma página local com oferta, um hub de cidade, um hub de serviço e uma página para profissionais. Para muitas URLs, usar o sitemap; repetir pedidos individuais não acelera o rastreamento: [solicitar novo rastreamento](https://developers.google.com/search/docs/crawling-indexing/ask-google-to-recrawl).

## Revisão editorial antes de ampliar cidades

Antes de marcar uma nova página como publicada:

- confirmar que o serviço existe no catálogo e que os códigos de cidade e estado são os oficiais usados pela API;
- revisar título, descrição, ortografia, escopo e orientação de orçamento;
- acrescentar informações que realmente mudam a contratação naquela cidade e naquele tipo de serviço;
- remover afirmações sem fonte sobre preço, prazo, licença, segurança ou demanda;
- não publicar páginas que apenas troquem o nome da cidade;
- confirmar que a página leva diretamente a profissionais relevantes, sem funcionar como uma etapa vazia de encaminhamento.

O Google considera abuso criar muitas páginas substancialmente semelhantes para consultas por região ou gerar conteúdo em escala sem valor para o usuário. A política deve ser verificada antes de cada expansão: [políticas de spam — doorway e scaled content abuse](https://developers.google.com/search/docs/essentials/spam-policies).

## Google Perfil da Empresa

Não criar um Perfil da Empresa para a Berufe como se ela fosse um pedreiro, encanador ou estabelecimento em cada cidade. As regras atuais excluem empresas de geração de leads e negócios somente online: [elegibilidade do Perfil da Empresa](https://support.google.com/business/answer/13763036).

Cada profissional pode manter o próprio perfil quando for dono ou representante autorizado de um negócio elegível e realizar contato presencial com clientes. Um prestador que visita o cliente pode usar um único perfil de área de serviço, ocultar o endereço residencial e cadastrar áreas reais de atendimento. Perfis múltiplos por cidade, escritórios virtuais sem equipe ou endereços que não recebem clientes violam as diretrizes: [áreas de serviço](https://support.google.com/business/answer/9157481), [como representar uma empresa](https://support.google.com/business/answer/3038177).

A Berufe pode orientar os profissionais e permitir que cada um associe ao próprio perfil a URL pública individual. A propriedade, verificação e manutenção devem permanecer com o negócio representado.

## Aquisição de links locais

Priorizar menções editoriais legítimas e úteis para pessoas da região:

- associações comerciais, entidades de bairro e parceiros locais com relação real com a Berufe;
- fornecedores e lojas de materiais que publiquem listas ou guias de profissionais;
- imprensa local, projetos comunitários e estudos próprios sobre demanda ou oferta de serviços;
- diretórios moderados que exibam empresa, cidade e URL corretas;
- páginas dos próprios profissionais apontando para o perfil público na Berufe.

O destino deve ser a página mais específica e útil: perfil do profissional, página do serviço na cidade ou guia editorial. Não comprar pacotes de links, não automatizar cadastros em diretórios irrelevantes e não exigir texto-âncora exato repetido.

O relatório de Links do Search Console mostra uma amostra, não uma lista completa. Portanto, zero no relatório deve ser acompanhado com registros próprios de divulgação e tráfego de referência, sem assumir que todo link será exibido: [relatório de Links](https://support.google.com/webmasters/answer/9049606).

## Acompanhamento semanal

Registrar por cidade e serviço:

- páginas com oferta e conteúdo publicado;
- URLs enviadas e indexadas por sitemap;
- impressões, cliques, CTR e posição para consultas com intenção local;
- contatos iniciados e perfis visualizados por landing page;
- novos domínios de referência e tráfego de referência;
- páginas rastreadas e não indexadas, com motivo indicado pelo Google;
- conteúdo desatualizado, oferta zerada ou páginas que precisam voltar para `noindex`.

Nas primeiras quatro semanas após o deploy, revisar semanalmente uma amostra de páginas indexáveis e não indexáveis. Depois, manter revisão mensal e auditoria completa antes de adicionar novas cidades.
