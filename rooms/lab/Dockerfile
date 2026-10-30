# Immagine Hermes della lab: quella ufficiale più la CLI di GitHub, che
# serve per issue, PR e review, e la CLI di Claude Code con il provider
# dell'abbonamento Claude. Le versioni si fissano in compose.yaml.
ARG HERMES_VERSION
FROM nousresearch/hermes-agent:${HERMES_VERSION}
ARG CLAUDE_CODE_VERSION
ARG CLAUDE_PLUGIN_COMMIT

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
COPY patches/stable_birth.py /tmp/stable_birth.py
RUN python3 /tmp/stable_birth.py /opt/hermes/hermes_cli/process_identity.py \
  && /opt/hermes/.venv/bin/python -m py_compile /opt/hermes/hermes_cli/process_identity.py \
  && rm /tmp/stable_birth.py

# Ponte ACP per i client sul PC come AionUi (ROOM-008): `docker exec -i -u
# hermes dojo-lab-hermes-1 dojo-acp <agente>` avvia `hermes -p <agente> acp`
# con la cartella di lavoro del container e senza server MCP del client.
COPY --chmod=0755 acp/dojo-acp /usr/local/bin/dojo-acp
