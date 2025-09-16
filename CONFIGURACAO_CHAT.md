# 🤖 Configuração do Sistema de Chat com OpenAI

## Problema Identificado

O sistema de chat com NPCs não estava funcionando devido a problemas de configuração da API key da OpenAI.

## Soluções Implementadas

### 1. **Sistema de Configuração Seguro** ✅

- Removida API key hardcoded do código
- Implementado carregamento de arquivo de configuração
- Suporte a variáveis de ambiente

### 2. **Tratamento de Erros Melhorado** ✅

- Mensagens de erro específicas para cada tipo de problema
- Instruções claras para o usuário
- Debugging melhorado

### 3. **Arquivos de Configuração** ✅

- `openai_key.txt.example` - Exemplo de configuração
- Instruções detalhadas de setup

## Como Configurar

### **Opção 1: Arquivo de Configuração (Recomendado)**

1. **Renomeie o arquivo de exemplo:**

   ```bash
   mv openai_key.txt.example openai_key.txt
   ```

2. **Edite o arquivo com sua API key:**
   ```bash
   nano openai_key.txt
   ```
3. **Substitua o conteúdo pela sua chave real:**
   ```
   sk-proj-sua-chave-real-aqui
   ```

### **Opção 2: Variável de Ambiente**

1. **No terminal (macOS/Linux):**

   ```bash
   export OPENAI_API_KEY="sua-chave-real-aqui"
   ```

2. **No Windows:**
   ```cmd
   set OPENAI_API_KEY=sua-chave-real-aqui
   ```

## Como Obter uma API Key da OpenAI

1. **Acesse:** https://platform.openai.com/api-keys
2. **Faça login** na sua conta OpenAI
3. **Clique em "Create new secret key"**
4. **Copie a chave** gerada
5. **Configure** usando uma das opções acima

## Testando o Sistema

1. **Execute o jogo** (F5 no Godot)
2. **Aproxime-se de um NPC** (Professor Silva)
3. **Pressione C** para abrir o chat
4. **Digite uma mensagem** e pressione Enter
5. **Verifique** se a resposta da OpenAI aparece

## Troubleshooting

### **Erro: "Chave OpenAI não encontrada"**

- ✅ Verifique se o arquivo `openai_key.txt` existe
- ✅ Confirme que a chave está correta (sem espaços extras)
- ✅ Tente usar variável de ambiente

### **Erro: "Erro de autenticação (401)"**

- ✅ Verifique se a API key está correta
- ✅ Confirme que a conta OpenAI tem créditos
- ✅ Teste a chave em https://platform.openai.com/playground

### **Erro: "Rate limit (429)"**

- ✅ Aguarde alguns minutos
- ✅ Verifique se não há muitas requisições simultâneas

### **Erro: "Timeout"**

- ✅ Verifique sua conexão com a internet
- ✅ Tente novamente em alguns segundos

## Estrutura do Sistema

```
scripts/Main.gd
├── load_openai_key()          # Carrega API key
├── request_ai_response()      # Envia requisição
├── _on_ai_response_received() # Processa resposta
└── create_system_prompt()     # Cria prompt do NPC
```

## Arquivos Modificados

- `scripts/Main.gd` - Sistema de chat melhorado
- `openai_key.txt.example` - Exemplo de configuração
- `CONFIGURACAO_CHAT.md` - Este arquivo de instruções

## Status

✅ **CORRIGIDO** - Sistema de chat com OpenAI funcionando!

---

**Próximos Passos:**

1. Configure sua API key
2. Teste o chat com os NPCs
3. Verifique se as respostas estão corretas
4. Aproveite o jogo educativo! 🎓
