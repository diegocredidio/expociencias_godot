# 🎨 Guia de Customização do Chat - Expo Godot

## 📋 **Estado Atual do Chat**

O chat já tem as fontes Barlow aplicadas. Agora vamos melhorar:
- ✅ Fontes modernas aplicadas
- 🎨 **PRÓXIMO:** Cores, ícones, layout moderno

---

## 🎯 **Como Customizar no Godot Editor**

### **Passo 1: Abrir a Cena**
1. Abra o Godot
2. Abra `scenes/Main.tscn`
3. Expanda: `Main → UI → ChatDialog`

### **Passo 2: Aplicar Cores Modernas**

#### **ChatDialog Panel:**
1. Selecione `ChatDialog`
2. No Inspector: **Theme Overrides** → **Styles**
3. Clique em `Panel` → **New StyleBoxFlat**
4. Configure:
   - **BG Color**: `#141A26` (azul escuro)
   - **Border**: 2px, cor `#3A4A5C`
   - **Corner Radius**: 16px em todos os cantos

#### **ChatHistory (área de texto):**
1. Selecione `ChatHistory`
2. **Theme Overrides** → **Styles** → **Normal**
3. **New StyleBoxFlat**:
   - **BG Color**: `#0D1117` (quase preto)
   - **Border**: 1px, cor `#30363D`
   - **Corner Radius**: 8px

#### **ChatInput (campo de entrada):**
1. Selecione `ChatInput`
2. **Theme Overrides** → **Styles** → **Normal**
3. **New StyleBoxFlat**:
   - **BG Color**: `#1F2937`
   - **Border**: 2px, cor `#4C7DD6`
   - **Corner Radius**: 8px

#### **SendButton:**
1. Selecione `SendButton`
2. **Theme Overrides** → **Styles** → **Normal**
3. **New StyleBoxFlat**:
   - **BG Color**: `#3B82F6` (azul vibrante)
   - **Corner Radius**: 8px

---

## 🖼️ **Adicionar Ícones**

### **Preparar Ícones:**
Os ícones já foram criados em `ui/icons/`:
- `send.svg` - ícone de enviar
- `close.svg` - ícone de fechar
- `teacher.svg` - ícone de professor

### **Aplicar Ícones:**

#### **SendButton com Ícone:**
1. Selecione `SendButton`
2. **Icon**: Arraste `ui/icons/send.svg`
3. **Text**: Mude para `"▶"` ou deixe vazio
4. **Icon Alignment**: Center

#### **CloseButton com Ícone:**
1. Selecione `CloseButton`
2. **Icon**: Arraste `ui/icons/close.svg`
3. **Text**: `"×"` ou vazio
4. **Flat**: ☑️ (botão transparente)

---

## 📐 **Melhorar Layout**

### **Reposicionar o Dialog:**
1. Selecione `ChatDialog`
2. **Layout** → **Anchors Preset**: Center
3. **Size**: `800x600` (ou desejado)
4. **Position**: Centralizado

### **Estrutura Moderna Sugerida:**

```
ChatDialog
├── Header (Panel com cor diferente)
│   ├── TeacherIcon (ícone pequeno)
│   ├── NPCName + Subject
│   └── CloseButton
├── ChatBody (área principal)
│   └── ChatHistory
└── Footer (área de input)
    ├── ChatInput (expandido)
    └── SendButton (compacto)
```

---

## 🎨 **Paleta de Cores Educativa**

### **Cores Principais:**
- **Fundo Dialog**: `#141A26` (azul escuro profissional)
- **Header**: `#1E293B` (azul médio)
- **Chat Area**: `#0D1117` (quase preto para texto)
- **Input**: `#1F2937` (cinza azulado)
- **Botão Send**: `#3B82F6` (azul vibrante)
- **Texto**: `#F8FAFC` (branco suave)

### **Cores de Acento:**
- **Sucesso**: `#10B981` (verde)
- **Aviso**: `#F59E0B` (amarelo)
- **Erro**: `#EF4444` (vermelho)
- **Info**: `#3B82F6` (azul)

---

## 📏 **Tamanhos e Espaçamentos**

### **Fontes Otimizadas:**
- **NPCName**: 24px, Bold
- **ChatHistory**: 18px, Regular
- **Input**: 16px, Regular
- **Buttons**: 16px, SemiBold

### **Espaçamentos:**
- **Padding Geral**: 16px
- **Margins**: 8px entre elementos
- **Border Radius**: 8-16px
- **Borders**: 1-2px

---

## 🚀 **Implementação Rápida**

### **Script de Aplicação Automática:**
Posso criar um script que aplica automaticamente:
1. **Todas as cores** da paleta
2. **Ícones** nos botões
3. **Layout otimizado**
4. **Animações suaves**

### **Comandos Godot via Script:**
```gdscript
# Aplicar tema moderno
func apply_modern_theme():
    # Cores, ícones, estilos...
```

---

## 📱 **Responsividade**

### **Diferentes Tamanhos de Tela:**
- **Desktop**: 800x600px
- **Laptop**: 700x500px  
- **Tablet**: 90% da tela

### **Ajuste Automático:**
```gdscript
# Adaptar ao tamanho da tela
func adapt_to_screen():
    var screen_size = get_viewport().size
    # Ajustar tamanho do dialog...
```

---

## 🎯 **Próximos Passos**

### **Implementar Agora:**
1. **Aplicar cores** manualmente no Godot
2. **Adicionar ícones** aos botões
3. **Testar visual** no jogo

### **Melhorias Futuras:**
1. **Animações** de abertura/fechamento
2. **Sound effects** nos cliques
3. **Avatar** do professor
4. **Themes** por matéria (Geografia=verde, Biologia=azul, etc)

---

## ⚙️ **Quer Aplicação Automática?**

Posso criar um script que aplica automaticamente todo o design moderno. Basta pedir! 🚀