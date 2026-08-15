FROM ruby:3.4.10-slim-bookworm

ENV BUNDLE_JOBS=4 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_RETRY=3

RUN apt-get update -qq \
    && apt-get install --no-install-recommends -y build-essential curl libpq-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY apps/api/Gemfile apps/api/Gemfile.lock ./
RUN bundle install

COPY apps/api/ .
COPY apps/web/data/catalogs.json /catalog-data/catalogs.json

ENV CATALOG_SEED_PATH=/catalog-data/catalogs.json

ENTRYPOINT ["bin/docker-entrypoint"]
CMD ["bin/rails", "server", "--binding", "0.0.0.0", "--port", "3000"]
