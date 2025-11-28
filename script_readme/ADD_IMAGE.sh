#!/bin/bash

set -euo pipefail

AUTOMATION_FILE="script_readme/FILES_AUTOMATION.txt"
README="README.md"
HEADER="## Diagramas de sequência:"

if [[ ! -f "$AUTOMATION_FILE" ]]; then
    echo "[ERRO] Arquivo $AUTOMATION_FILE não encontrado."
    exit 1
fi

if [[ ! -f "$README" ]]; then
    echo "[ERRO] Arquivo $README não encontrado."
    exit 1
fi

# Remove bloco anterior (entre BEGIN_AUTOMATION e END_AUTOMATION)
sed -i '/<!--INICIO_DA_AUTOMAÇÃO -->/,/<!-- FIM_DA_AUTOMAÇÃO -->/d' "$README"

# Monta bloco novo
{
    echo "<!--INICIO_DA_AUTOMAÇÃO -->"
    cat "$AUTOMATION_FILE"
    echo "<!-- FIM_DA_AUTOMAÇÃO -->"
} > .tmp_automation_block

# Insere após "## Diagramas de sequência:"
awk -v header="$HEADER" -v insert=".tmp_automation_block" '
{
    print $0
    if ($0 ~ header) {
        system("cat " insert)
    }
}
' "$README" > "$README.tmp"

# Aplica mudanças
mv "$README.tmp" "$README"
rm -f .tmp_automation_block

echo "[README_SCRIPT] README.md atualizado com conteúdo de $AUTOMATION_FILE."