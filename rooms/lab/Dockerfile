# Immagine Hermes della lab: quella ufficiale più la CLI di GitHub, che
# serve per issue, PR e review. La versione si fissa in compose.yaml.
ARG HERMES_VERSION
FROM nousresearch/hermes-agent:${HERMES_VERSION}

RUN apt-get -o Acquire::Retries=3 update \
  && apt-get install -y --no-install-recommends gh \
  && rm -rf /var/lib/apt/lists/*

# Birth dei processi stabile anche quando il btime del kernel oscilla
# (WSL2/Docker Desktop): senza, le card Kanban crashano con permission_denied.
# Dettagli in patches/stable_birth.py; la build fallisce se Hermes cambia.
COPY patches/stable_birth.py /tmp/stable_birth.py
RUN python3 /tmp/stable_birth.py /opt/hermes/hermes_cli/process_identity.py \
  && /opt/hermes/.venv/bin/python -m py_compile /opt/hermes/hermes_cli/process_identity.py \
  && rm /tmp/stable_birth.py
