# 🚪 Sistema de Portas - Guia Completo

## 📋 Visão Geral

O sistema de portas foi completamente reformulado para oferecer:

- **Identificação única** de cada porta
- **Gerenciamento centralizado** de todas as portas
- **Colisão inteligente** que bloqueia passagem quando fechada
- **Desbloqueio automático** baseado em eventos de perguntas dos NPCs
- **Sistema de debug** para facilitar desenvolvimento

## 🚪 Portas Identificadas no Projeto

### 1. **Demo Gate** (`demo_gate`)

- **Localização**: StartingRoom
- **Status**: Sempre aberta (para testes)
- **Requisito**: Nenhum
- **Descrição**: "Demo Gate - Always open for testing"

### 2. **Door to Biology** (`door_to_biology`)

- **Localização**: Corridor1
- **Status**: Fechada inicialmente
- **Requisito**: Completar quiz do Prof. Silva (Geografia)
- **Descrição**: "Door to Biology Room - Requires completing Prof. Silva's Geography quiz"

### 3. **Door to Science** (`door_to_science`)

- **Localização**: Corridor2
- **Status**: Fechada inicialmente
- **Requisito**: Completar quiz da Profa. Santos (Biologia)
- **Descrição**: "Door to Science Room - Requires completing Profa. Santos's Biology quiz"

### 4. **Door to Final** (`door_to_final`)

- **Localização**: Corridor3
- **Status**: Fechada inicialmente
- **Requisito**: Completar quiz do Prof. Costa (Ciências)
- **Descrição**: "Door to Final Room - Requires completing Prof. Costa's Science quiz"

## 🔧 Como Funciona o Sistema

### **1. Registro Automático**

- Cada porta se registra automaticamente com o `DungeonLevel` ao inicializar
- O sistema mantém um registro completo de todas as portas
- Cada porta tem informações detalhadas (ID, NPC requerido, descrição, etc.)

### **2. Colisão Inteligente**

- **Porta Fechada**: Colisão ativa, bloqueia passagem do jogador
- **Porta Aberta**: Colisão desabilitada, permite passagem livre
- **Modelo Visual**: Muda automaticamente entre `gate-door.glb` (fechada) e `gate.glb` (aberta)

### **3. Desbloqueio Automático**

- Quando o jogador acerta uma pergunta do NPC, o sistema:
  1. Identifica qual porta deve ser desbloqueada
  2. Executa animação de desbloqueio
  3. Remove a colisão bloqueante
  4. Muda o modelo visual para porta aberta

## 🎮 Como Usar o Sistema

### **Para Desenvolvedores**

#### **Identificar Portas**

```gdscript
# Obter todas as portas
var all_doors = dungeon_level.get_all_doors()

# Obter porta específica
var door = dungeon_level.get_door_by_id("door_to_biology")

# Obter portas por NPC
var doors = dungeon_level.get_doors_by_npc("Prof. Silva")
```

#### **Verificar Status**

```gdscript
# Verificar se porta está bloqueando
if door.is_door_blocking():
    print("Porta está bloqueando passagem")

# Verificar se jogador pode passar
if door.can_player_pass():
    print("Jogador pode passar")
```

#### **Controlar Portas**

```gdscript
# Desbloquear porta específica
dungeon_level.unlock_door_by_id("door_to_biology")

# Bloquear porta específica
dungeon_level.lock_door_by_id("door_to_biology")

# Forçar desbloqueio (para debug)
door.force_unlock()
```

### **Para Debug**

#### **Usar o DoorDebug Script**

1. Adicione o script `DoorDebug.gd` como nó autônomo na cena
2. Use os controles:
   - **SPACE**: Imprime status de todas as portas
   - **ENTER**: Testa desbloqueio da porta mais próxima
   - **ESCAPE**: Testa bloqueio da porta mais próxima

#### **Verificar Status no Console**

```gdscript
# Imprimir status completo do sistema
dungeon_level.print_door_system_status()

# Obter estatísticas
var stats = dungeon_level.get_door_statistics()
print("Total de portas: ", stats["total_doors"])
```

## 🔄 Fluxo de Desbloqueio

### **1. Jogador Interage com NPC**

- Sistema detecta NPC próximo
- Abre interface de chat/quiz

### **2. Jogador Responde Corretamente**

- Sistema avalia resposta
- Se correta (≥80% ou resposta específica):
  - Chama `unlock_room_by_npc_name(npc_name)`
  - Sistema identifica qual porta desbloquear
  - Executa animação de desbloqueio
  - Remove colisão bloqueante

### **3. Porta Fica Acessível**

- Jogador pode passar livremente
- Modelo visual muda para porta aberta
- Sistema registra desbloqueio

## 🛠️ Adicionando Novas Portas

### **1. Na Cena (.tscn)**

```gdscript
[node name="NovaPorta" type="StaticBody3D" parent="CorridorX"]
script = ExtResource("door_script")
door_id = "nova_porta"
required_npc = "Nome do NPC"
is_locked = true
door_description = "Descrição da nova porta"
unlock_animation_duration = 1.0
```

### **2. Adicionar DoorModel**

```gdscript
[node name="DoorModel" parent="CorridorX/NovaPorta" instance=ExtResource("6_gate_door")]
```

### **3. Configurar NPC**

- Certifique-se de que o NPC tem `unlocks_room` configurado
- O sistema automaticamente mapeará NPC → Porta

## 🐛 Solução de Problemas

### **Porta Não Desbloqueia**

1. Verifique se o NPC tem `unlocks_room` configurado
2. Confirme se `required_npc` da porta corresponde ao nome do NPC
3. Use `print_door_system_status()` para verificar registro

### **Colisão Não Funciona**

1. Verifique se `BlockingCollision` foi criado automaticamente
2. Confirme se `collision.disabled` está sendo controlado corretamente
3. Teste com `door.is_door_blocking()`

### **Modelo Visual Não Muda**

1. Verifique se os arquivos GLB estão carregando corretamente
2. Confirme se `replace_door_model()` está sendo chamado
3. Teste com `door.update_door_state()`

## 📊 Monitoramento

### **Console Output**

O sistema imprime informações detalhadas:

```
🚪 Door door_to_biology initializing...
🚪 Door door_to_biology registered with door manager
🚪 Door door_to_biology ready!
   📝 Description: Door to Biology Room - Requires completing Prof. Silva's Geography quiz
```

### **Status Reports**

```
🚪 === DOOR SYSTEM STATUS ===
🚪 Total doors registered: 4
🚪 Locked doors: 3
🚪 Unlocked doors: 1

🚪 === DOOR DETAILS ===
🚪 demo_gate - 🔓 UNLOCKED - Requires: No requirement
🚪 door_to_biology - 🔒 LOCKED - Requires: Complete quiz with Prof. Silva
🚪 door_to_science - 🔒 LOCKED - Requires: Complete quiz with Profa. Santos
🚪 door_to_final - 🔒 LOCKED - Requires: Complete quiz with Prof. Costa
```

## ✅ Benefícios do Sistema

1. **Identificação Clara**: Cada porta tem ID único e descrição
2. **Gerenciamento Centralizado**: Todas as portas em um local
3. **Colisão Inteligente**: Bloqueia automaticamente quando fechada
4. **Desbloqueio Automático**: Baseado em eventos de perguntas
5. **Debug Facilitado**: Ferramentas para testar e monitorar
6. **Extensível**: Fácil adicionar novas portas
7. **Robusto**: Sistema de fallback e validações

O sistema está pronto para uso e pode ser facilmente expandido conforme necessário!
