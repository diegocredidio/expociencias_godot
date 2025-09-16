# 🔒 Configuração do Proxy Seguro OpenAI com Supabase

Este guia mostra como configurar um proxy seguro que esconde sua chave da OpenAI usando Supabase Edge Functions.

## 🎯 Por que usar um proxy?

✅ **Segurança**: Chave OpenAI fica no servidor, não no cliente
✅ **Controle**: Você controla o que pode ser enviado para OpenAI  
✅ **Custos**: Pode implementar rate limiting e controle de uso
✅ **Logs**: Monitora todas as requisições em um lugar

## 📋 Pré-requisitos

- Conta no [Supabase](https://supabase.com)
- Chave da [OpenAI](https://platform.openai.com)
- [Supabase CLI](https://supabase.com/docs/guides/cli) instalado

## 🚀 Passo 1: Configurar Projeto Supabase

### 1.1 Criar projeto
```bash
# Inicializar projeto Supabase
supabase init

# Fazer login
supabase login

# Linkiar com projeto existente (ou criar novo)
supabase link --project-ref your-project-id
```

### 1.2 Adicionar Edge Function
```bash
# Criar a função
supabase functions new openai-proxy

# A função já está criada em: supabase/functions/openai-proxy/index.ts
```

### 1.3 Configurar variáveis de ambiente
```bash
# Adicionar sua chave OpenAI como secret
supabase secrets set OPENAI_API_KEY=your-openai-key-here
```

### 1.4 Deploy da função
```bash
# Fazer deploy
supabase functions deploy openai-proxy

# Verificar se funcionou
supabase functions list
```

## 🔧 Passo 2: Configurar Godot

### 2.1 Atualizar configuração
Edite o arquivo `supabase_config.gd`:

```gdscript
const PROJECT_URL = "https://your-project-id.supabase.co"
const ANON_KEY = "your-anon-key-here"
```

### 2.2 Atualizar Main.gd
Substitua a variável no `Main.gd`:

```gdscript
var supabase_proxy_url = "https://your-project-id.supabase.co/functions/v1/openai-proxy"
```

### 2.3 Modificar funções existentes
Substitua as chamadas diretas à OpenAI por chamadas ao proxy:

**Antes:**
```gdscript
http_request.request("https://api.openai.com/v1/chat/completions", headers, HTTPClient.METHOD_POST, body)
```

**Depois:**
```gdscript
var response = await call_supabase_proxy(prompt, subject, quiz_mode)
```

## 🔄 Passo 3: Migrar Funções Existentes

### 3.1 Para perguntas de múltipla escolha:
```gdscript
func generate_quiz_question_for_npc(npc):
    var subject = current_npc_subject if current_npc_subject != "" else "Educação"
    var prompt = create_quiz_prompt(subject)
    
    var response = await call_supabase_proxy(prompt, subject, "pergunta_multipla_escolha")
    
    if response != "":
        parse_quiz_response(response)
    else:
        quiz_question.text = "❌ Erro ao gerar pergunta"
```

### 3.2 Para chat aberto:
```gdscript
func request_ai_response(user_message: String, npc):
    var subject = npc.subject if npc else "Educação"
    var prompt = create_chat_prompt(user_message, npc)
    
    var response = await call_supabase_proxy(prompt, subject, "pergunta_aberta")
    
    if response != "":
        chat_history.text += "\n[color=lightblue][b]" + npc.npc_name + ":[/b] " + response + "[/color]"
    else:
        chat_history.text += "\n[color=red]❌ Erro ao obter resposta[/color]"
```

## 🧪 Passo 4: Testar

### 4.1 Testar Edge Function diretamente
```bash
curl -X POST 'https://your-project-id.supabase.co/functions/v1/openai-proxy' \\
  -H 'Authorization: Bearer your-anon-key' \\
  -H 'Content-Type: application/json' \\
  -d '{
    "prompt": "Explique o que é fotossíntese",
    "subject": "Ciências",
    "quiz_mode": "pergunta_aberta"
  }'
```

### 4.2 Verificar logs
```bash
# Ver logs da função
supabase functions logs openai-proxy
```

## 🔒 Passo 5: Segurança Adicional

### 5.1 Implementar rate limiting
```typescript
// No index.ts da Edge Function
const rateLimitKey = req.headers.get('x-forwarded-for') || 'unknown';
// Implementar lógica de rate limiting aqui
```

### 5.2 Validar inputs
```typescript
// Validar tamanho do prompt
if (prompt.length > 1000) {
  return new Response('Prompt muito longo', { status: 400 });
}

// Filtrar conteúdo inadequado
const inappropriateWords = ['palavrao1', 'palavrao2'];
if (inappropriateWords.some(word => prompt.toLowerCase().includes(word))) {
  return new Response('Conteúdo inadequado', { status: 400 });
}
```

## 📊 Passo 6: Monitoramento

### 6.1 Dashboard Supabase
- Acesse o dashboard do Supabase
- Vá em "Edge Functions" 
- Monitore uso, logs e erros

### 6.2 Logs customizados
```typescript
// Adicionar logs personalizados
console.log('Request from:', req.headers.get('x-forwarded-for'));
console.log('Subject:', subject);
console.log('Response length:', aiResponse.length);
```

## 🎉 Resultado Final

- ✅ Chave OpenAI segura no servidor
- ✅ Controle total sobre requisições
- ✅ Logs centralizados
- ✅ Rate limiting configurável
- ✅ Jogo funcionando normalmente

## 🔧 Troubleshooting

### Erro: "OpenAI API key não configurada"
```bash
supabase secrets list
supabase secrets set OPENAI_API_KEY=your-key-here
```

### Erro CORS
Verifique se os headers CORS estão corretos na Edge Function.

### Timeout
Aumente o timeout no Godot ou otimize prompts na Edge Function.

---

**Agora sua chave OpenAI está segura! 🔒**