<p align="center">
  <img src="assets/icon.png" alt="Precifica" width="120"/>
</p>

<h1 align="center">Precifica</h1>

<p align="center">
  Gerencie produtos, preços e compartilhe listas de forma simples e inteligente.
</p>

---

## 📱 Sobre o Aplicativo

**Precifica** é um aplicativo voltado para pequenos negócios, como hortifrutis, mercearias e feiras, que precisam gerenciar listas de produtos e preços de forma prática. Com ele, você pode criar relatórios prontos para enviar pelo WhatsApp, organizar categorias com ajuda de inteligência artificial e salvar diferentes perfis de produtos.

---

## ✨ Principais Funcionalidades

| Funcionalidade | Descrição |
|----------------|-----------|
| **Categorias e Produtos** | Crie categorias e adicione produtos com nome e preço |
| **Ativar/Desativar** | Toque em um produto para ativar ou desativar rapidamente |
| **Arrastar e Soltar** | Reorganize categorias arrastando-as para a posição desejada |
| **Organização com IA** | Reorganize automaticamente seus produtos em categorias usando Gemini AI |
| **Perfis** | Salve, carregue, importe e exporte configurações completas |
| **Relatórios** | Gere listas de preços formatadas para compartilhar via WhatsApp ou e-mail |
| **Modelos de Relatório** | Personalize título, formatação e filtros dos seus relatórios |

---

## 🚀 Como Usar

### Primeiro Acesso
Ao abrir o app pela primeira vez, um tutorial interativo guiará você pelos passos básicos:
1. Criar sua primeira categoria
2. Adicionar seu primeiro produto
3. Experimentar um perfil de exemplo (Hortifruti)

### Uso Diário
1. **Abra o app** e selecione uma categoria na barra inferior
2. **Atualize os preços** tocando no campo de preço de cada produto
3. **Ative ou desative produtos** com um toque simples
4. **Compartilhe** o relatório pelo botão de compartilhar no topo

### Organização com IA
1. Abra o menu lateral (☰)
2. Toque em **"Organizar com IA"**
3. Confirme a reorganização
4. A IA agrupará seus produtos em categorias coerentes automaticamente

### Gerenciamento de Perfis
- **Salvar**: Guarde sua configuração atual como um perfil
- **Carregar**: Restaure um perfil salvo anteriormente
- **Importar/Exportar**: Compartilhe perfis via arquivo JSON

---

## 🛠️ Configuração para Desenvolvedores

### Pré-requisitos
- Flutter SDK 3.4.0 ou superior
- Chave de API do [Google AI Studio](https://aistudio.google.com/apikey)

### Executar em modo debug
```bash
flutter run --dart-define=GEMINI_API_KEY=SUA_CHAVE
```

### Gerar APK de release
```bash
flutter build apk --release --dart-define=GEMINI_API_KEY=SUA_CHAVE
```

### CI/CD (GitHub Actions)
```yaml
- name: Build APK
  run: flutter build apk --release --dart-define=GEMINI_API_KEY=${{ secrets.GEMINI_API_KEY }}
```

---