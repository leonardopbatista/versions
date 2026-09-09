@echo off
setlocal
cd /d "%~dp0"

where git >nul 2>&1
if errorlevel 1 (
    echo Erro: Git nao foi encontrado no PATH.
    exit /b 1
)

if not exist "versions.json" (
    echo Erro: versions.json nao foi encontrado na raiz do repositorio.
    exit /b 1
)

git rev-parse --is-inside-work-tree >nul 2>&1
if errorlevel 1 (
    echo Erro: esta pasta nao pertence a um repositorio Git.
    exit /b 1
)

powershell.exe -NoProfile -Command ^
    "try { $document = Get-Content -Raw -LiteralPath 'versions.json' -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop; if ($null -eq $document -or $document -isnot [pscustomobject]) { throw 'A raiz deve ser um objeto JSON.' } } catch { Write-Error ('versions.json invalido: ' + $_.Exception.Message); exit 1 }"
if errorlevel 1 exit /b 1

git add -- "versions.json"
if errorlevel 1 goto :git_error

git diff --cached --quiet -- "versions.json"
if not errorlevel 1 (
    echo Nenhuma alteracao em versions.json para publicar.
    exit /b 0
)

git commit -m "Update versions" -- "versions.json"
if errorlevel 1 goto :git_error

git pull --rebase
if errorlevel 1 (
    echo Erro: nao foi possivel integrar as alteracoes remotas. Resolva o conflito e execute git push.
    exit /b 1
)

git push
if errorlevel 1 goto :git_error

echo versions.json publicado com sucesso.
exit /b 0

:git_error
echo Erro: um comando Git falhou. Verifique as mensagens acima.
exit /b 1
