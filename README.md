# 🎮 Jogo Educativo de Dungeon - Godot

Um jogo educativo 3D desenvolvido em Godot 4.4 que ensina conteúdos do 6º ano do Brasil através de um dungeon crawler interativo.

## 🚀 Como Rodar no Browser

### Método Rápido (Recomendado)

1. **Abrir o Godot:**

   ```bash
   ./abrir_godot.sh
   ```

2. **Exportar para Web:**

   - No Godot: `Project > Export...`
   - Adicionar preset "Web"
   - Configurar Export Path: `web_build/index.html`
   - Baixar templates: `Editor > Manage Export Templates... > Download and Install`
   - Exportar: `Project > Export... > Export Project`

3. **Rodar no Browser:**
   ```bash
   python3 servidor_web.py
   ```

### Método Manual

Siga as instruções detalhadas no arquivo [COMO_EXPORTAR_PARA_WEB.md](COMO_EXPORTAR_PARA_WEB.md)

## 🎯 Sobre o Jogo

- **Tema:** Conteúdos educativos do 6º ano do Brasil
- **Mecânica:** Dungeon crawler 3D com NPCs interativos
- **Tecnologia:** Godot 4.4 + WebAssembly
- **Recursos:** Modular Dungeon Kit da Kenney

### 🎓 Conteúdos Educativos

- **Geografia:** Regiões do Brasil, fronteiras
- **Biologia:** Reinos dos seres vivos, classificação
- **Ciências:** Sistema solar, astronomia

### 🎮 Como Jogar

- **Movimento:** WASD ou setas do teclado
- **Interação:** E ou Espaço quando aparecer o prompt
- **Objetivo:** Responder perguntas educativas para desbloquear salas

## 📁 Estrutura do Projeto

```
expo_godot/
├── scenes/           # Cenas do Godot
├── scripts/          # Scripts GDScript
├── assets/           # Recursos 3D (dungeon kit)
├── web_build/        # Arquivos exportados para web
├── servidor_web.py   # Servidor web automático
└── abrir_godot.sh    # Script para abrir Godot
```

## 🛠️ Requisitos

- Godot 4.4.1 ou superior
- Python 3 (para servidor web)
- Browser moderno (Chrome, Firefox, Safari, Edge)

## 📝 Notas Importantes

- O jogo precisa ser servido por um servidor web (não funciona abrindo o HTML diretamente)
- Para funcionalidade completa, configure uma chave da OpenAI em `user://openai_key.txt`
- Testado em browsers modernos com suporte a WebAssembly

## 🎨 Recursos Utilizados

- **Modular Dungeon Kit** - Kenney (cenários 3D)
- **Mini Characters** - Kenney (personagens)
- **Godot Engine** - Motor de jogo
- **WebAssembly** - Exportação para web

---

**Desenvolvido para fins educativos** 🎓
