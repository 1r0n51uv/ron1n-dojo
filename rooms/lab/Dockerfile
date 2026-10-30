# Immagine Hermes della lab: quella ufficiale più la CLI di GitHub, che
# serve per issue, PR e review, la CLI di Claude Code con il provider
# dell'abbonamento Claude, hermes-webui, e config, SOUL, flows e skill della
# room. La CI la pubblica su ghcr.io/1r0n51uv/dojo-lab (ROOM-010). Le
# versioni si fissano qui; il contesto della build è la radice del repo.
ARG HERMES_VERSION=v0.22.5
FROM nousresearch/hermes-agent:${HERMES_VERSION}
# CLI ufficiale e provider dell'abbonamento Claude (MODELS-006): il plugin
# vuole Claude Code 2.1.293 o più recente.
ARG CLAUDE_CODE_VERSION=2.1.299
# NousResearch/hermes-official-plugins, claude-subscription-directsdk 0.3.3.
ARG CLAUDE_PLUGIN_COMMIT=1e326ddd28ae261821d7714d106fe114999a0bba

RUN apt-get -o Acquire::Retries=3 update \
  && apt-get install -y --no-install-recommends gh \
  && rm -rf /var/lib/apt/lists/*

# Abbonamento Claude Pro/Max come modello degli agenti (MODELS-006), spento
# finché non lo accende `dojo.sh claude`. La CLI ufficiale, non modificata,
# fa login e chiamate; il plugin claude-subscription-directsdk di Nous
# Research la guida come provider. Il plugin sta fra quelli inclusi in
# Hermes (/opt/hermes, di root): gli agenti lo usano ma non lo cambiano.
# Installazione locale in /opt/claude-code, non globale: il prefix globale di
# npm nell'immagine di Hermes è gestito dal suo package manager. Lo script
# postinstall e la dipendenza opzionale della piattaforma portano il binario
# vero: si chiedono esplicitamente, anche se la config di npm li spegnesse.
RUN node --version && npm --version \
  && mkdir -p /opt/claude-code \
  && npm install --prefix /opt/claude-code --no-audit --no-fund \
    --ignore-scripts=false --include=optional --foreground-scripts \
    "@anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}" \
  && node /opt/claude-code/node_modules/@anthropic-ai/claude-code/install.cjs \
  && ln -sf /opt/claude-code/node_modules/.bin/claude /usr/local/bin/claude \
  && npm cache clean --force \
  && claude --version
RUN src=$(mktemp -d) \
  && git -C "$src" init -q \
  && git -C "$src" fetch -q --depth 1 https://github.com/NousResearch/hermes-official-plugins "${CLAUDE_PLUGIN_COMMIT}" \
  && git -C "$src" archive FETCH_HEAD claude-subscription-directsdk \
    | tar -x -C /opt/hermes/plugins/model-providers \
  && rm -rf "$src" \
  && cd /opt/hermes/plugins/model-providers/claude-subscription-directsdk \
  && rm -rf tests evals assets conftest.py \
  && grep -qx 'name: claude-subscription-directsdk-experimental' plugin.yaml

# Birth dei processi stabile anche quando il btime del kernel oscilla
# (WSL2/Docker Desktop): senza, le card Kanban crashano con permission_denied.
# Dettagli in patches/stable_birth.py; la build fallisce se Hermes cambia.
COPY rooms/lab/patches/stable_birth.py /tmp/stable_birth.py
RUN python3 /tmp/stable_birth.py /opt/hermes/hermes_cli/process_identity.py \
  && /opt/hermes/.venv/bin/python -m py_compile /opt/hermes/hermes_cli/process_identity.py \
  && rm /tmp/stable_birth.py

# Interfaccia web hermes-webui (ROOM-009), nella stessa immagine: gira con il
# Python e il codice di Hermes già qui, senza scaricare nulla all'avvio. Le
# serve in più solo PyYAML, che va in /opt/hermes-webui/deps (PYTHONPATH del
# servizio webui) e non nella venv di Hermes. Di root, in sola lettura per
# l'utente hermes.
# nesquena/hermes-webui v0.52.544.
ARG WEBUI_COMMIT=687d80333870c3797d6858738621fca13d1bf27a
ARG PYYAML_VERSION=6.0.3
RUN src=$(mktemp -d) \
  && git -C "$src" init -q \
  && git -C "$src" fetch -q --depth 1 https://github.com/nesquena/hermes-webui "${WEBUI_COMMIT}" \
  && mkdir -p /opt/hermes-webui \
  && git -C "$src" archive FETCH_HEAD | tar -x -C /opt/hermes-webui \
  && rm -rf "$src" /opt/hermes-webui/tests /opt/hermes-webui/docs \
  && py=/opt/hermes/.venv/bin/python deps=/opt/hermes-webui/deps \
  && uv=$(command -v uv || find /opt/hermes /usr/local -name uv -type f -perm -u+x 2>/dev/null | head -1) \
  && if [ -n "$uv" ]; then \
       "$uv" pip install -q --python "$py" --target "$deps" "pyyaml==${PYYAML_VERSION}"; \
     else \
       "$py" -m pip install -q --target "$deps" "pyyaml==${PYYAML_VERSION}"; \
     fi \
  && PYTHONPATH="$deps" "$py" -c "import yaml, cryptography"

# Config e SOUL dei profiles, flows e skill della room (ROOM-012): di root,
# in sola lettura per gli agenti. I .env non entrano (.dockerignore).
COPY rooms/lab/profiles /opt/dojo/profiles
COPY flows /opt/dojo/flows
COPY skills /opt/dojo/skills
RUN find /opt/dojo/profiles -name '.env*' -delete \
  && for p in /opt/dojo/profiles/*/; do \
       test -f "${p}config.yaml" && test -f "${p}SOUL.md"; \
     done
COPY --chmod=0755 rooms/lab/seed/dojo-seed /opt/dojo/bin/dojo-seed
COPY --chmod=0755 rooms/lab/seed/016-dojo-seed /etc/cont-init.d/016-dojo-seed
