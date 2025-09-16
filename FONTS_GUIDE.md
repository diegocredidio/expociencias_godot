# 🔤 Guia de Fontes - Expo Godot

## ✅ **Sim, fontes vão embarcadas no executável!**

### 🎯 **Como funciona:**
- Fontes adicionadas ao projeto ficam **incluídas** nos assets
- No export, as fontes são **empacotadas** junto com o executável
- **Usuários não precisam** ter a fonte instalada

---

## 📁 **Estrutura Recomendada**

```
expo_godot/
├── fonts/
│   ├── Roboto-Regular.ttf
│   ├── Roboto-Bold.ttf
│   ├── OpenSans-Regular.ttf
│   └── ...
└── ...
```

---

## 🔤 **Formatos Suportados**

### ✅ **Recomendados:**
- **`.ttf`** - TrueType (mais comum)
- **`.otf`** - OpenType (suporte completo)
- **`.woff2`** - Web fonts (Godot 4+)

### 📜 **Licenças Seguras:**
- **Google Fonts** - Open Font License (livre)
- **Open Font Library** - Fontes livres
- **Font Squirrel** - Fontes comerciais gratuitas

---

## 🚀 **Como Adicionar Fontes**

### Passo 1: Baixar a Fonte
- **Google Fonts**: https://fonts.google.com/
- **DaFont**: https://www.dafont.com/ (verifique licença)
- **Font Squirrel**: https://www.fontsquirrel.com/

### Passo 2: Adicionar ao Projeto
1. Crie pasta `fonts/` no projeto
2. Copie os arquivos `.ttf` para `fonts/`
3. No Godot, as fontes aparecerão no FileSystem

### Passo 3: Criar FontFile Resource
1. No FileSystem, clique com botão direito na fonte
2. **Change file type** → **FontFile**
3. Ou import automaticamente

### Passo 4: Usar na Interface
1. Selecione um **Label** ou **RichTextLabel**
2. Na propriedade **Theme Overrides** → **Fonts**
3. Arraste a fonte do FileSystem

---

## 🎨 **Fontes Recomendadas para Educação**

### **Para Interface:**
- **Roboto** - Limpa e legível
- **Open Sans** - Muito legível
- **Lato** - Friendly e profissional

### **Para Texto Longo:**
- **Source Serif Pro** - Serifa elegante
- **Crimson Text** - Ótima para leitura
- **Libre Baskerville** - Clássica

### **Para Títulos:**
- **Montserrat** - Moderna e impactante
- **Poppins** - Geométrica e friendly
- **Nunito** - Rounded e acessível

---

## 📋 **Exemplo de Implementação**

### Estrutura de Theme:
```
Theme Principal:
├── Default Font: Roboto-Regular.ttf (16px)
├── Heading Font: Montserrat-Bold.ttf (24px)
├── UI Font: Open Sans-Regular.ttf (14px)
└── Code Font: Fira Code-Regular.ttf (12px)
```

### Configuração no Godot:
1. **Project Settings** → **Rendering** → **Fonts**
2. **Dynamic Fonts** → **Use Filter** ☑️
3. **Hinting** → **Light** (para telas HD)

---

## 🔧 **Otimização para Export**

### **Tamanhos de Fonte:**
- Interface: 14-16px
- Texto: 16-18px  
- Títulos: 24-32px
- Debug: 12px

### **Reduzir Tamanho:**
- Use apenas pesos necessários (Regular, Bold)
- Evite fontes com muitos caracteres especiais
- Consider subset para idiomas específicos

---

## 💡 **Dicas Importantes**

### ✅ **Boas Práticas:**
- **Teste legibilidade** em diferentes tamanhos de tela
- **Use fallbacks** (fonte do sistema como backup)
- **Mantenha consistência** entre elementos

### ⚠️ **Cuidados:**
- **Verifique licenças** antes de distribuir
- **Teste performance** com muitas fontes
- **Fontes grandes** aumentam tamanho do executável

### 🎯 **Para seu projeto educativo:**
- Priorize **legibilidade**
- Use **contrastes adequados**
- Teste com **diferentes idades** de usuários

---

## 📊 **Impacto no Executável**

### **Tamanhos Típicos:**
- Fonte Regular: ~50-200KB
- Família completa: ~500KB-2MB
- Google Fonts: Geralmente otimizadas

### **Total para seu projeto:**
- 3-4 fontes bem escolhidas: ~1-3MB
- Impacto mínimo no tamanho final do jogo

---

## 🔗 **Links Úteis**

- **Google Fonts**: https://fonts.google.com/
- **Font Squirrel**: https://www.fontsquirrel.com/
- **Google Webfonts Helper**: https://gwfh.mranftl.com/
- **Godot Docs - Fonts**: https://docs.godotengine.org/en/stable/tutorials/ui/gui_using_fonts.html