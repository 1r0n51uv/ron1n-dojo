"""Patch di Hermes v0.22.5: "birth" dei processi stabile su Linux.

L'owner riconosce un managed worker (worker.persist, gateway/session_worker.py)
confrontando con uguaglianza esatta la "birth" del processo, che su Linux è
psutil create_time() = starttime/HZ + btime di /proc/stat. Su WSL2 (Docker
Desktop su Windows) btime oscilla di qualche secondo quando l'orologio della
VM viene corretto: la birth dello stesso processo cambia, l'owner risponde
permission_denied e la card Kanban crasha ("Kanban owner refused: Kanban
execution unknown").

La patch somma allo starttime (che non cambia mai) un btime letto una volta
sola per avvio del kernel e condiviso fra i processi del container in
/tmp/hermes-stable-btime. Hermes fa già lo stesso su macOS (#140580).

Si applica in build (rooms/lab/Dockerfile); se il testo originale cambia con
una nuova versione di Hermes la build fallisce: controllare se upstream ha
corretto il problema e togliere la patch.
"""

import pathlib
import sys

TARGET = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "/opt/hermes/hermes_cli/process_identity.py")

OLD = """    import psutil
    if getattr(psutil, "MACOS", False):
"""

NEW = """    import psutil
    # dojo: su Linux starttime più un btime fissato per avvio (rooms/lab/patches/stable_birth.py).
    if getattr(psutil, "LINUX", False):
        platform_proc = getattr(proc, "_proc", None)
        if platform_proc is not None:
            try:
                return float(platform_proc.create_time(monotonic=True)) + _dojo_stable_boot_time()
            except TypeError:
                pass
    if getattr(psutil, "MACOS", False):
"""

HELPER = '''

_DOJO_BTIME_FILE = "/tmp/hermes-stable-btime"
_DOJO_BTIME = None


def _dojo_stable_boot_time() -> float:
    """btime di /proc/stat fissato al primo uso per questo avvio del kernel (boot_id),
    uguale per tutti i processi del container anche se il btime del kernel oscilla."""
    global _DOJO_BTIME
    if _DOJO_BTIME is not None:
        return _DOJO_BTIME
    import psutil
    try:
        with open("/proc/sys/kernel/random/boot_id", encoding="ascii") as f:
            boot_id = f.read().strip()
    except OSError:
        boot_id = ""
    try:
        with open(_DOJO_BTIME_FILE, encoding="ascii") as f:
            saved_id, saved = f.read().split()
        if saved_id == boot_id:
            _DOJO_BTIME = float(saved)
            return _DOJO_BTIME
    except (OSError, ValueError):
        pass
    current = float(psutil.boot_time())
    tmp = f"{_DOJO_BTIME_FILE}.{os.getpid()}"
    try:
        with open(tmp, "w", encoding="ascii") as f:
            f.write(f"{boot_id} {current}\\n")
        os.chmod(tmp, 0o644)
        try:
            # Il primo che scrive vince: chi arriva dopo legge il suo valore. Un file
            # di un avvio precedente (container riavviato) si sostituisce.
            os.link(tmp, _DOJO_BTIME_FILE)
        except FileExistsError:
            with open(_DOJO_BTIME_FILE, encoding="ascii") as f:
                parts = f.read().split()
            if len(parts) != 2 or parts[0] != boot_id:
                os.replace(tmp, _DOJO_BTIME_FILE)
        finally:
            if os.path.exists(tmp):
                os.unlink(tmp)
        with open(_DOJO_BTIME_FILE, encoding="ascii") as f:
            saved_id, saved = f.read().split()
        if saved_id == boot_id:
            _DOJO_BTIME = float(saved)
            return _DOJO_BTIME
    except (OSError, ValueError):
        pass
    return current
'''

source = TARGET.read_text(encoding="utf-8")
if source.count(OLD) != 1 or "def _process_create_time" not in source:
    sys.exit(f"stable_birth: testo atteso non trovato in {TARGET}: controlla la versione di Hermes")
source = source.replace(OLD, NEW)
anchor = "\n\ndef _process_create_time"
source = source.replace(anchor, HELPER + anchor, 1)
TARGET.write_text(source, encoding="utf-8")
print(f"stable_birth: applicata a {TARGET}")
