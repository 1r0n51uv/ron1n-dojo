"""Passa il config.yaml di un profile all'abbonamento Claude (MODELS-006).

Gira nel container della room con il Python di Hermes, chiamato da
`dojo.sh sync` subito dopo aver copiato il config.yaml del repo:

    python - <config.yaml> <modello>

Il modello principale diventa il provider claude-subscription-directsdk con
`<modello>` (per esempio sonnet); il modello di prima (il gateway LiteLLM)
diventa la prima riserva, così finita la quota di Claude si torna su GPT e sui
free. Contesto, commenti e il resto del file restano come sono.
"""

import sys

from ruamel.yaml import YAML

PROVIDER = "claude-subscription-directsdk-experimental"
# Login della CLI di Claude, nel volume della room (dojo.sh claude).
CONFIG_DIR = "/opt/data/claude"

percorso, modello = sys.argv[1], sys.argv[2]
yaml = YAML()
with open(percorso, encoding="utf-8") as f:
    config = yaml.load(f)

prima = config["model"]
if prima.get("provider") == PROVIDER:
    sys.exit(f"{percorso}: è già sull'abbonamento Claude")

riserva = {"provider": prima["provider"], "model": prima["default"]}
for chiave in ("base_url", "key_env"):
    if chiave in prima:
        riserva[chiave] = prima[chiave]

nuovo = {"provider": PROVIDER, "default": modello}
if "context_length" in prima:
    # La finestra resta quella del repo: più corta di 1M, la compattazione di
    # Hermes parte prima e la quota dura di più.
    nuovo["context_length"] = prima["context_length"]
config["model"] = nuovo
config["fallback_providers"] = [riserva] + list(config.get("fallback_providers") or [])

plugins = config.setdefault("plugins", {})
voci = plugins.setdefault("entries", {})
voci[PROVIDER] = {
    "settings": {
        "claude_config_dir": CONFIG_DIR,
        # Niente telemetria né feature flag: meno domini nell'allowlist.
        "claude_code_telemetry": False,
    }
}
# Una chiamata appesa senza output non tiene ferma la card per 30 minuti
# prima di passare alla riserva.
providers = config.setdefault("providers", {})
providers.setdefault(PROVIDER, {})["stale_timeout_seconds"] = 900

with open(percorso, "w", encoding="utf-8") as f:
    yaml.dump(config, f)
