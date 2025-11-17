# Define o diretório de saida
OUT_DIR = diagramas_svg

# 1. Define os arquivos a serem IGNORADOS
EXCLUDE_PUML = DEFS.puml DS-TEMPLATE.puml

# 2. Encontra todos os .puml, EXCETO os ignorados
SRC_PUML = $(filter-out $(EXCLUDE_PUML), $(wildcard *.puml))

# 3. Cria a lista de arquivos .svg de destino (na pasta OUT_DIR)
OUT_SVGS = $(patsubst %.puml, $(OUT_DIR)/%.svg, $(SRC_PUML))

.PHONY: image
image: $(OUT_SVGS)
	@clear
	@echo ">>> Todos os svg foram gerados!"

# Regra padrão: cria um .svg a partir de um .puml
# $@ = alvo (ex: diagramas_svg/a.svg)
# $< = prerequisito (ex: a.puml)
# $* = radical do nome (ex: a)
$(OUT_DIR)/%.svg: %.puml
	@echo ">>> Gerando imagem $@ a partir de $<..."
	@mkdir -p $(OUT_DIR)
	@plantuml -tsvg $<
	@mv $*.svg $@
	@echo ">>> Imagem gerada com sucesso."

.PHONY: clean
clean:
	@echo ">>> Limpando $(OUT_DIR)..."
	@rm -f $(OUT_DIR)/*.svg
	@echo ">>> Limpeza concluída."
	@sleep 1
	clear
