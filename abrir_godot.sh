#!/bin/bash

# Script para abrir o Godot e configurar exportação para Web
echo "Abrindo Godot para configurar exportação Web..."

# Abrir o Godot com o projeto
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/diegocredidio/Documents/repogit/expo_godot

echo "Instruções para exportar para Web:"
echo "1. No Godot, vá em Project > Export..."
echo "2. Clique em 'Add...' e selecione 'Web'"
echo "3. Configure o Export Path como: web_build/index.html"
echo "4. Vá em Editor > Manage Export Templates..."
echo "5. Clique em 'Download and Install' para baixar os templates"
echo "6. Volte para Project > Export... e clique em 'Export Project'"
echo "7. Escolha o arquivo: web_build/index.html"
