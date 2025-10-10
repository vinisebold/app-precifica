# Precifica

Aplicativo Flutter para organização, categorização e gestão de produtos com apoio de IA (Gemini), pensado para pequenos negócios, hortifrutis, mercearias ou qualquer contexto onde seja útil manter uma lista de itens organizada, editável e facilmente compartilhável.

## Objetivo
Fornecer uma experiência simples e poderosa para:
- Criar e gerenciar categorias de produtos.
- Adicionar, editar, ativar/desativar e remover produtos rapidamente.
- Reordenar categorias e produtos via drag & drop (com áreas de deleção).
- Salvar, carregar, exportar e importar “perfís” completos (estado da aplicação).
- Gerar um relatório textual compartilhável (ex.: para enviar pelo WhatsApp / e-mail).
- Reorganizar automaticamente a taxonomia usando IA (Gemini) mantendo todos os dados originais.

## Integração com IA
O app envia o JSON atual das categorias/produtos para o modelo Gemini (Google Generative AI) e recebe um JSON reorganizado, seguindo regras rígidas de preservação de dados. Nenhum item é descartado: apenas reagrupado, normalizado ou inserido em uma categoria “Outros” quando apropriado.

Principais cuidados no prompt:
1. Garantir resposta em JSON puro (sem texto extra ou Markdown).
2. Manter propriedades originais de cada produto.
3. Impedir categorias vazias.
4. Ordenação alfabética de categorias e produtos.
5. Possibilidade de criar/mesclar/renomear categorias.

## Arquitetura
- **Flutter** (Material 3 / theming).
- **Gerência de estado:** Riverpod.
- **Camadas:** `domain` (entidades, casos de uso) / `data` (services) / `presentation` (UI widgets + pages).
- **Perfis:** Persistidos/exportados como JSON (import/export manual + compartilhamento externo).
- **Serviço de IA:** `AIService` (HTTP + Gemini API).

## Executando localmente
Antes de rodar com IA, defina a chave via `--dart-define`.

Rodar em debug:
```
flutter run --dart-define=GEMINI_API_KEY=SUA_CHAVE_AQUI
```

Rodar em release (APK):
```
flutter build apk --release --dart-define=GEMINI_API_KEY=SUA_CHAVE_AQUI
```

Se a variável não for definida, o app lançará uma exceção ao tentar usar a IA.

## Segurança da Chave

Exemplo (GitHub Actions):
```yaml
- name: Build APK
	run: flutter build apk --release --dart-define=GEMINI_API_KEY=${{ secrets.GEMINI_API_KEY }}
```

## Possíveis Melhorias Futuras
- Testes de widget para sincronização de PageView e estado.
- Botão de cancelar organização com IA.
- Suporte offline/“rascunho” de alterações.
- Internacionalização (i18n).

## Tratamento de Erros
O serviço de IA lança exceção textual quando:
- Chave não configurada.
- Resposta da API não possui `candidates`.
- Código HTTP diferente de 200.

Os erros são consumidos e exibidos via SnackBar.

## Exportação / Importação de Perfis
- Exportação gera um arquivo/JSON compartilhável.
- Importação substitui o estado atual (confirmação obrigatória).

## Compartilhamento de Relatório
O relatório textual inclui categorias e produtos organizados para fácil envio a outras pessoas (WhatsApp, email etc.).

## Variável de Ambiente (IMPORTANTE)
Defina a sua chave Gemini:
```
GEMINI_API_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxx
```
Chamada em runtime via `String.fromEnvironment('GEMINI_API_KEY')`.

Se estiver rodando em CI / build automatizado, inclua:
```
flutter build apk --release --dart-define=GEMINI_API_KEY=${GEMINI_API_KEY}
```
