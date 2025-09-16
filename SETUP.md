# 🎮 Expo Godot - Setup Guide

Este guia explica como configurar o projeto após clonar do repositório Git.

## ⚠️ Configuração Obrigatória

### 1. Chave da API OpenAI

O projeto requer uma chave válida da API OpenAI para funcionar. A chave **NÃO está incluída** no repositório por questões de segurança.

#### Como configurar:

1. **Obtenha sua chave OpenAI:**
   - Acesse [platform.openai.com](https://platform.openai.com/)
   - Crie uma conta ou faça login
   - Vá em "API Keys" e gere uma nova chave
   - **Importante:** Mantenha sua chave em segredo!

2. **Crie o arquivo de configuração:**
   ```bash
   # Na pasta raiz do projeto, crie:
   touch openai_key.txt
   ```

3. **Adicione sua chave ao arquivo:**
   ```
   # Conteúdo do openai_key.txt:
   sk-proj-sua_chave_openai_aqui
   ```

4. **Verificar se está funcionando:**
   - Abra o projeto no Godot
   - Execute o jogo
   - Interaja com um NPC (Professor Silva)
   - Se aparecer "OpenAI está pensando..." significa que está configurado corretamente

### 2. Modelo OpenAI Utilizado

O projeto está configurado para usar **GPT-4o-mini** com os seguintes parâmetros otimizados:
- `temperature: 0.8` (criatividade para variar perguntas)
- `presence_penalty: 0.2` (incentivo à variação de tópicos)

## 🎯 Funcionalidades Educacionais

### Disciplinas Disponíveis:
- **Geografia:** Baseado na BNCC 6º ano (identidade sociocultural, clima-relevo-vegetação, bacias hidrográficas, etc.)
- **Biologia:** 5 reinos dos seres vivos, classificação, fotossíntese, cadeia alimentar
- **Ciências:** Sistema solar, estados da matéria, fenômenos naturais
- **Revisão Geral:** Combinação de todos os temas

### Sistema de Avaliação:
- Perguntas dinâmicas geradas pelo OpenAI
- Avaliação com percentual (necessário 80%+ para passar)
- Máximo de 3 tentativas por NPC
- Geração automática de novas perguntas quando errar

## 🖥️ Controles e Interface

### Controles:
- **WASD** - Movimento do jogador
- **C** - Interagir com NPC (quando próximo)
- **ESC** - Alternar entre tela cheia e janela

### Interface:
- Chat responsivo (80% da tela)
- Fonte Barlow aplicada em todo o projeto
- Dialog com estilo moderno e cores customizadas

## 🔧 Configuração do Projeto

### Requisitos:
- **Godot 4.4** ou superior
- Conexão com internet (para API OpenAI)
- Chave OpenAI válida com créditos

### Primeira Execução:
1. Abra o projeto no Godot
2. Configure sua chave OpenAI (ver seção acima)
3. Execute o projeto (F5)
4. O jogo iniciará em tela cheia automaticamente

### Arquivo de Debug:
O projeto gera logs detalhados em `game_debug.log` para troubleshooting.

## 📁 Estrutura de Arquivos Importantes

```
expo_godot/
├── openai_key.txt          # ⚠️ CRIAR MANUALMENTE (sua chave OpenAI)
├── scenes/
│   ├── Main.tscn           # Cena principal com UI
│   ├── DungeonLevel.tscn   # Masmorra com NPCs
│   └── Player.tscn         # Jogador
├── scripts/
│   └── Main.gd             # Lógica principal e integração OpenAI
├── fonts/
│   └── Barlow-*.ttf        # Fontes do projeto
└── .gitignore              # Ignora chaves e arquivos sensíveis
```

## 🚫 O que NÃO está no Git

Por questões de segurança, os seguintes arquivos **não estão incluídos**:
- `openai_key.txt` - Sua chave da API
- `.godot/` - Cache do Godot
- Logs e arquivos temporários
- Builds e executáveis

## 🆘 Troubleshooting

### ❌ "OpenAI está pensando..." não sai
- Verifique se `openai_key.txt` existe e tem sua chave válida
- Confirme que sua chave OpenAI tem créditos disponíveis
- Verifique conexão com internet

### ❌ "Nenhum NPC selecionado"
- Aproxime-se mais do NPC
- Pressione C quando aparecer "Pressione C para conversar"
- Verifique o log para debugging

### ❌ Projeto não abre no Godot
- Confirme que está usando Godot 4.4+
- Importe o projeto corretamente
- Verifique se as fontes estão na pasta `fonts/`

---

**⚠️ IMPORTANTE:** Nunca faça commit da sua chave OpenAI! O arquivo `.gitignore` está configurado para evitar isso, mas sempre verifique antes de fazer push.

**🎯 OBJETIVO EDUCACIONAL:** Este projeto foi desenvolvido para ensinar Geografia, Biologia e Ciências seguindo a Base Nacional Comum Curricular (BNCC) do 6º ano.