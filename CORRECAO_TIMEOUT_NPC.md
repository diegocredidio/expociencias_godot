# ⏰ Correção com Timeout para Detecção de NPC

## Problema Identificado

O usuário identificou que o diálogo pode estar abrindo muito rapidamente e travando os comandos antes da detecção do NPC ser processada completamente. Isso causaria o erro "❌ ERRO: Nenhum NPC selecionado".

## Solução Implementada

### **1. Sistema de Timeout para Detecção** ⏰

**Implementado timeout de 500ms** para confirmar a detecção do NPC antes de permitir interação:

```gdscript
var npc_detection_timeout = 0.5  # 500ms timeout para detecção
var npc_detection_timer = null
```

### **2. Processo de Detecção em Duas Etapas** 🔄

**Etapa 1 - Detecção Inicial:**

```gdscript
func _on_player_interaction_detected(npc):
    print("🎯 NPC DETECTADO: ", npc.npc_name if npc else "null")

    # Cancelar timer anterior se existir
    if npc_detection_timer:
        npc_detection_timer.queue_free()

    # Criar novo timer para confirmar detecção
    npc_detection_timer = get_tree().create_timer(npc_detection_timeout)
    npc_detection_timer.timeout.connect(_on_npc_detection_confirmed.bind(npc))

    print("⏰ TIMER INICIADO: Aguardando confirmação de detecção...")
```

**Etapa 2 - Confirmação Após Timeout:**

```gdscript
func _on_npc_detection_confirmed(npc):
    print("✅ DETECÇÃO CONFIRMADA: ", npc.npc_name if npc else "null")

    # Verificar se o NPC ainda está válido
    if npc and is_instance_valid(npc):
        print("✅ NPC VÁLIDO: Definindo como current_npc")
        current_npc = npc
        interaction_prompt.visible = true
    else:
        print("❌ NPC INVÁLIDO: Não foi possível confirmar detecção")
        current_npc = null
        interaction_prompt.visible = false

    npc_detection_timer = null
```

### **3. Verificação de Estado Robusta** ✅

**Antes de abrir o chat, o sistema verifica:**

1. **Timer ativo:** Se há timer de detecção em andamento
2. **NPC válido:** Se o NPC ainda existe e é válido
3. **Fallback:** Se não há NPC, tenta usar o `current_interactable` do player

```gdscript
func _on_player_interact_requested():
    # Verificar se há timer de detecção ativo
    if npc_detection_timer:
        print("⏰ TIMER ATIVO: Aguardando confirmação de detecção...")
        print("⏰ TEMPO RESTANTE: ", npc_detection_timer.time_left)
        return

    # Verificar se current_npc está válido
    if current_npc and is_instance_valid(current_npc):
        print("✅ NPC VÁLIDO: Abrindo chat")
        open_chat(current_npc)
    else:
        print("⚠️ ERRO: Nenhum NPC atual definido!")

        # Tentar usar o current_interactable do player como fallback
        if player and player.current_interactable and is_instance_valid(player.current_interactable):
            print("🔄 FALLBACK: Usando current_interactable do player")
            current_npc = player.current_interactable
            open_chat(current_npc)
```

### **4. Limpeza de Timers** 🧹

**Quando o NPC é perdido, o timer é cancelado:**

```gdscript
func _on_player_interaction_lost():
    print("❌ NPC PERDIDO")
    interaction_prompt.visible = false
    current_npc = null

    # Cancelar timer de detecção se existir
    if npc_detection_timer:
        npc_detection_timer.queue_free()
        npc_detection_timer = null
```

## Fluxo de Funcionamento

### **1. Jogador se aproxima do NPC:**

```
🎯 NPC DETECTADO: Prof. Silva
⏰ TIMER INICIADO: Aguardando confirmação de detecção...
```

### **2. Após 500ms:**

```
✅ DETECÇÃO CONFIRMADA: Prof. Silva
✅ NPC VÁLIDO: Definindo como current_npc
```

### **3. Jogador pressiona C:**

```
🤝 INTERAÇÃO SOLICITADA - current_npc: Prof. Silva
✅ NPC VÁLIDO: Abrindo chat
💬 ABRINDO CHAT COM: Prof. Silva
```

### **4. Se pressionar C muito cedo:**

```
🤝 INTERAÇÃO SOLICITADA - current_npc: null
⏰ TIMER ATIVO: Aguardando confirmação de detecção...
⏰ TEMPO RESTANTE: 0.3
```

## Benefícios da Solução

### **✅ Previne Interação Prematura**

- **Timeout de 500ms** garante que a detecção seja processada completamente
- **Verificação de estado** antes de abrir o chat

### **✅ Sistema de Fallback Robusto**

- **Múltiplas verificações** de validade do NPC
- **Fallback automático** para o `current_interactable` do player

### **✅ Debug Extensivo**

- **Logs detalhados** de cada etapa do processo
- **Informações de timing** para diagnóstico

### **✅ Limpeza Automática**

- **Cancelamento de timers** quando necessário
- **Prevenção de vazamentos** de memória

## Arquivos Modificados

- `scripts/Main.gd` - Sistema de timeout implementado
- `CORRECAO_TIMEOUT_NPC.md` - Este arquivo

## Status

✅ **TIMEOUT IMPLEMENTADO** - Sistema robusto de detecção com timeout de 500ms!

---

**Próximos Passos:**

1. Execute o jogo e teste a interação
2. Verifique se o timeout resolve o problema
3. Observe os logs do console para confirmar o funcionamento
4. Reporte se ainda há problemas! 🔍
