# Immagine Hermes della lab: quella ufficiale più la CLI di GitHub, che
# serve per issue, PR e review. La versione si fissa in compose.yaml.
ARG HERMES_VERSION
FROM nousresearch/hermes-agent:${HERMES_VERSION}

RUN apt-get -o Acquire::Retries=3 update \
  && apt-get install -y --no-install-recommends gh \
  && rm -rf /var/lib/apt/lists/*
