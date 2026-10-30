@echo off
rem Versione Windows di hermes-acp.sh, per AionUi su Windows (ROOM-008):
rem nel client e' il "launch path" dell'agente Hermes. `hermes acp` diventa
rem `dojo-acp <agente>` nel container della room; l'agente si sceglie con
rem DOJO_AGENT (default concierge), il container con DOJO_CONTAINER. Passano
rem solo i controlli di versione e di salute, niente altri comandi o flag.
setlocal EnableDelayedExpansion
if not defined DOJO_CONTAINER set "DOJO_CONTAINER=dojo-lab-hermes-1"
if not defined DOJO_AGENT set "DOJO_AGENT=concierge"
rem Docker Desktop mette docker.exe nel PATH di Windows; con Docker Engine
rem dentro WSL il comando passa da wsl.exe (distro di default, senza shell).
set "DOCKER=docker"
where docker >nul 2>&1 || set "DOCKER=wsl.exe -e docker"

rem Solo lettere, cifre, - e _: il nome finisce in una riga di comando. Il
rem controllo legge DOJO_AGENT con !...!, che non esegue un & nel valore.
echo(!DOJO_AGENT!| findstr /r /x "[a-z0-9_-][a-z0-9_-]*" >nul || (
  echo hermes-acp.cmd: DOJO_AGENT non valido 1>&2
  exit /b 2
)

if "%*"=="acp" goto acp
if "%*"=="--version" goto check
if "%*"=="acp --version" goto check
if "%*"=="acp --check" goto check
echo hermes-acp.cmd: comando non permesso: hermes %* 1>&2
exit /b 2

:acp
%DOCKER% exec -i -u hermes %DOJO_CONTAINER% dojo-acp %DOJO_AGENT%
exit /b %ERRORLEVEL%

:check
%DOCKER% exec -i -u hermes %DOJO_CONTAINER% hermes -p %DOJO_AGENT% %*
exit /b %ERRORLEVEL%
