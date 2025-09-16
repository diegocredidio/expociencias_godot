# 🚀 Guia de Export - Expo Godot

## 📋 Pré-requisitos

1. **Godot 4.4** instalado
2. **Export Templates** baixados
3. **Projeto funcionando** no editor

---

## 📥 Passo 1: Instalar Export Templates

1. Abra o Godot
2. Abra seu projeto `expo_godot`
3. Vá em **Editor** → **Manage Export Templates**
4. Clique em **Download and Install**
5. Aguarde o download (pode demorar alguns minutos)

---

## 🎯 Passo 2: Configurar Export Presets

### No Godot, vá em **Project** → **Export...**

### 🪟 Para Windows:

1. Clique em **Add...** → **Windows Desktop**
2. Configure:
   - **Export Path**: `builds/expo_godot_windows.exe`
   - **Runnable**: ☑️
   - **Export With Debug**: ☑️ (para testes)
   - **Embed PCK**: ☑️

**Seção Binary Format:**
- **64 bits**: ☑️
- **Embed PCK**: ☑️

**Seção Resources:**
- **Export Mode**: Export all resources
- **Filters**: `*.txt,*.json,*.key`

### 🍎 Para macOS:

1. Clique em **Add...** → **macOS**
2. Configure:
   - **Export Path**: `builds/expo_godot_macos.app`
   - **Runnable**: ☑️
   - **Export With Debug**: ☑️

**Seção Application:**
- **Bundle ID**: `com.expogodot.game`
- **Signature**: `godot_macOS` (ou deixe vazio)

**Seção Binary Format:**
- **Embed PCK**: ☑️

---

## 🔨 Passo 3: Gerar os Executáveis

### Opção A: Via Interface Godot
1. Na janela Export, selecione o preset
2. Clique em **Export Project**
3. Escolha o local e nome do arquivo
4. Clique em **Save**

### Opção B: Via Linha de Comando
Execute o script que criamos:
```bash
./build_exports.sh
```

---

## 📂 Estrutura Final

Após o export, você terá:

```
expo_godot/
├── builds/
│   ├── expo_godot_windows.exe    # Executável Windows
│   ├── expo_godot_macos.app/     # Aplicação macOS
│   └── ...
└── ...
```

---

## 📝 Instruções de Distribuição

### 🪟 Windows:
- Distribua o arquivo `expo_godot_windows.exe`
- Usuários precisam ter **Visual C++ Redistributable** instalado
- O arquivo contém tudo necessário (se Embed PCK estiver ativado)

### 🍎 macOS:
- Distribua a pasta `expo_godot_macos.app`
- Usuários podem precisar autorizar o app em **System Preferences** → **Security & Privacy**
- Para distribuição oficial, é necessário assinatura de desenvolvedor

---

## 🔧 Solução de Problemas

### ❌ "Export templates not found"
- Redownload os templates via **Editor** → **Manage Export Templates**

### ❌ "Invalid export path"
- Certifique-se que o diretório de destino existe
- Use caminhos absolutos se necessário

### ❌ Arquivo OpenAI Key não encontrado
- Certifique-se que `openai_key.txt` está na raiz do projeto
- Ou configure para ler de `user://openai_key.txt` no executável

---

## 📊 Configurações Recomendadas para Produção

### Para Release Final:
- **Export With Debug**: ☐ (desmarcar)
- **Optimize**: ☑️
- **Strip Debug Symbols**: ☑️

### Para Testes:
- **Export With Debug**: ☑️
- **Console Window**: ☑️ (Windows)

---

## 💡 Dicas Extras

1. **Teste sempre** os executáveis em máquinas limpas
2. **API Key**: Considere um sistema de configuração inicial
3. **Tamanho**: Arquivos ficam ~50-100MB (com assets)
4. **Logs**: Logs ficam em `user://logs/` no executável