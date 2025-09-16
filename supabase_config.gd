# Configuração do Supabase
# Substitua pelos seus valores reais

extends RefCounted
class_name SupabaseConfig

# Substitua por sua URL do projeto Supabase
const PROJECT_URL = "https://pzjqlgxuuwfethxwkinr.supabase.co"

# URL da Edge Function
const OPENAI_PROXY_URL = PROJECT_URL + "/functions/v1/openai-proxy"

# Chave anônima do Supabase (segura para usar no cliente)
const ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB6anFsZ3h1dXdmZXRoeHdraW5yIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDYzOTA2MzAsImV4cCI6MjA2MTk2NjYzMH0.bFv9e7Yo6fI9LPsIwJfp8eliL-hyq7TglV_rCQvye1U"