#!/usr/bin/env python3
"""
Servidor web simples para testar o jogo Godot exportado para Web
"""

import http.server
import socketserver
import os
import webbrowser
from pathlib import Path

def main():
    # Verificar se a pasta web_build existe
    web_build_path = Path("web_build")
    if not web_build_path.exists():
        print("❌ Pasta 'web_build' não encontrada!")
        print("   Primeiro exporte o projeto do Godot para Web.")
        print("   Siga as instruções no arquivo COMO_EXPORTAR_PARA_WEB.md")
        return
    
    # Verificar se o arquivo index.html existe
    index_file = web_build_path / "index.html"
    if not index_file.exists():
        print("❌ Arquivo 'web_build/index.html' não encontrado!")
        print("   Primeiro exporte o projeto do Godot para Web.")
        return
    
    # Configurar o servidor
    PORT = 8000
    os.chdir(web_build_path)
    
    Handler = http.server.SimpleHTTPRequestHandler
    
    with socketserver.TCPServer(("", PORT), Handler) as httpd:
        print(f"🚀 Servidor web iniciado em http://localhost:{PORT}")
        print(f"📁 Servindo arquivos da pasta: {web_build_path.absolute()}")
        print("🌐 Abrindo o jogo no browser...")
        print("⏹️  Pressione Ctrl+C para parar o servidor")
        
        # Abrir o browser automaticamente
        webbrowser.open(f"http://localhost:{PORT}")
        
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n🛑 Servidor parado.")

if __name__ == "__main__":
    main()
