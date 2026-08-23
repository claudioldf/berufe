FROM ruby:3.4.10-slim-bookworm AS base

ENV BUNDLE_JOBS=4 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_RETRY=3

RUN apt-get update -qq \
    && apt-get install --no-install-recommends -y curl libpq5 libvips42 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

FROM base AS build-base

RUN apt-get update -qq \
    && apt-get install --no-install-recommends -y build-essential libpq-dev \
    && rm -rf /var/lib/apt/lists/*

COPY apps/api/Gemfile apps/api/Gemfile.lock ./

FROM build-base AS production-gems

RUN bundle config set without "development test" \
    && bundle install \
    && rm -rf /usr/local/bundle/ruby/*/cache /usr/local/bundle/ruby/*/bundler/gems/*/.git

FROM build-base AS development

RUN bundle install

COPY apps/api/ .
COPY apps/web/data/catalogs.json /catalog-data/catalogs.json
COPY apps/web/data/professionals.json /catalog-data/professionals.json
COPY apps/web/public/images/ /demo-images/

ENV CATALOG_SEED_PATH=/catalog-data/catalogs.json \
    PROFESSIONAL_DEMO_SEED_PATH=/catalog-data/professionals.json \
    PROFESSIONAL_DEMO_IMAGE_ROOT=/demo-images

ENTRYPOINT ["bin/docker-entrypoint"]
CMD ["bin/rails", "server", "--binding", "0.0.0.0", "--port", "3000"]

FROM production-gems AS application-build

COPY apps/api/ .
RUN bundle exec bootsnap precompile --gemfile app/ lib/

FROM base AS production

ENV BUNDLE_WITHOUT=development:test \
    CATALOG_SEED_PATH=/catalog-data/catalogs.json \
    RAILS_ENV=production

RUN groupadd --system --gid 1000 rails \
    && useradd --uid 1000 --gid 1000 --create-home --shell /bin/bash rails

COPY --from=production-gems /usr/local/bundle /usr/local/bundle
COPY --chown=rails:rails --from=application-build /app /app
COPY --chown=rails:rails apps/web/data/catalogs.json /catalog-data/catalogs.json

USER rails

EXPOSE 3000

ENTRYPOINT ["bin/docker-entrypoint"]
CMD ["bin/rails", "server", "--binding", "0.0.0.0"]
