// Supabase Edge Function - OpenAI Proxy
// Esconde a chave da OpenAI do cliente

import "https://deno.land/x/xhr@0.1.0/mod.ts";

interface RequestBody {
  prompt: string;
  subject?: string;
  quiz_mode?: string;
}

Deno.serve(async (req) => {
  // CORS Headers
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
  };

  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // Validar método
    if (req.method !== 'POST') {
      return new Response('Method not allowed', { 
        status: 405, 
        headers: corsHeaders 
      });
    }

    // Pegar a chave da OpenAI das variáveis de ambiente do Supabase
    const openaiApiKey = Deno.env.get('OPENAI_API_KEY');
    if (!openaiApiKey) {
      throw new Error('OpenAI API key não configurada');
    }

    // Rate limiting baseado no IP
    const rateLimitKey = req.headers.get('x-forwarded-for') || req.headers.get('x-real-ip') || 'unknown';
    console.log('Request from IP:', rateLimitKey);

    // Parse do body da requisição
    const body: RequestBody = await req.json();
    const { prompt, subject = "Educação", quiz_mode = "pergunta_aberta" } = body;

    if (!prompt) {
      return new Response('Prompt é obrigatório', { 
        status: 400, 
        headers: corsHeaders 
      });
    }

    // Validar tamanho do prompt (máximo 2000 caracteres)
    if (prompt.length > 2000) {
      console.log('Prompt muito longo:', prompt.length, 'caracteres');
      return new Response('Prompt muito longo (máximo 2000 caracteres)', { 
        status: 400, 
        headers: corsHeaders 
      });
    }

    // Lista de palavras/conteúdo inadequado
    const inappropriateWords = [
      'palavrao', 'ofensa', 'violencia', 'drogas', 'hack', 'malware',
      'senha', 'password', 'login', 'token', 'api_key', 'credit_card'
    ];
    
    const lowerPrompt = prompt.toLowerCase();
    const hasInappropriateContent = inappropriateWords.some(word => 
      lowerPrompt.includes(word.toLowerCase())
    );
    
    if (hasInappropriateContent) {
      console.log('Conteúdo inadequado detectado no prompt');
      return new Response('Conteúdo inadequado detectado', { 
        status: 400, 
        headers: corsHeaders 
      });
    }

    // Validar subject permitidos
    const allowedSubjects = [
      'Educação', 'Geografia', 'Biologia', 'Ciências', 'Matemática', 
      'História', 'Português', 'Revisão Geral'
    ];
    
    if (!allowedSubjects.includes(subject)) {
      console.log('Subject não permitido:', subject);
      return new Response('Matéria não permitida', { 
        status: 400, 
        headers: corsHeaders 
      });
    }

    // Construir prompt baseado no modo
    let fullPrompt = "";
    
    if (quiz_mode === "multipla_escolha") {
      fullPrompt = `${prompt}

MISSÃO: Crie uma pergunta de múltipla escolha CRIATIVA e VARIADA sobre ${subject} para 6º ano.

DIRETRIZES DE CRIATIVIDADE:
- EVITE perguntas básicas como "O que é..." ou "Qual a definição de..."
- Use contextos práticos, situações do cotidiano, exemplos concretos
- Varie entre: aplicação prática, análise, comparação, interpretação
- Para Português: use textos curtos, situações reais, análise de frases
- Para Ciências: experimentos, fenômenos naturais, corpo humano
- Para Geografia: lugares reais, mapas, clima, paisagens
- Para História: personagens, eventos, causas e consequências
- Para Matemática: problemas práticos, situações do dia a dia

FORMATO OBRIGATÓRIO (JSON):
{
  "question": "Sua pergunta criativa aqui?",
  "options": [
    "A) Primeira opção",
    "B) Segunda opção", 
    "C) Terceira opção",
    "D) Quarta opção"
  ],
  "correct_answer": 0,
  "explanation": "Explicação clara e didática"
}

VALIDAÇÃO OBRIGATÓRIA:
- Pergunta deve ser interessante e envolvente
- 4 alternativas plausíveis (evite opções óbvias)
- Uma única resposta correta
- Explicação educativa e motivadora
- Linguagem adequada para 11-12 anos
- Retorne APENAS o JSON válido`;
    } else if (quiz_mode === "pergunta_aberta") {
      fullPrompt = `${prompt}

REGRAS IMPORTANTES:
- Faça APENAS UMA pergunta específica sobre a disciplina mencionada
- Base-se no currículo BNCC 6º ano do ensino fundamental
- Seja direto e objetivo
- A pergunta deve testar conhecimento factual específico
- NÃO faça múltiplas perguntas em sequência
- NÃO dê introduções longas ou explicações preliminares`;
    } else if (quiz_mode === "avaliacao") {
      fullPrompt = `${prompt}

INSTRUÇÕES DE AVALIAÇÃO:
- Avalie com rigor acadêmico baseado no BNCC 6º ano
- Dê uma nota percentual de 0-100%
- Mínimo 70% para aprovação
- Seja preciso sobre correção factual
- Use o formato: "NOTA: X% - [explicação breve]"
- Considere apenas se a resposta está factualmente correta`;
    } else {
      fullPrompt = `${prompt}

Responda como um professor amigável e didático para alunos do 6º ano do ensino fundamental.
Seja claro, educativo e motivador. Use linguagem simples e exemplos práticos.`;
    }

    // Fazer requisição para OpenAI
    const openaiResponse = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openaiApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-4o-mini',
        messages: [
          {
            role: 'user',
            content: fullPrompt
          }
        ],
        max_tokens: 800,
        temperature: 0.9,
      }),
    });

    if (!openaiResponse.ok) {
      const errorText = await openaiResponse.text();
      throw new Error(`OpenAI API Error: ${openaiResponse.status} - ${errorText}`);
    }

    const openaiData = await openaiResponse.json();
    
    // Extrair resposta
    const aiResponse = openaiData.choices[0]?.message?.content || '';

    // Logs customizados para monitoramento
    console.log('=== OPENAI PROXY LOG ===');
    console.log('IP:', rateLimitKey);
    console.log('Subject:', subject);
    console.log('Quiz Mode:', quiz_mode);
    console.log('Prompt length:', prompt.length);
    console.log('Response length:', aiResponse.length);
    console.log('OpenAI tokens used:', openaiData.usage?.total_tokens || 'N/A');
    console.log('========================');

    // Retornar resposta
    return new Response(JSON.stringify({ 
      response: aiResponse,
      success: true,
      metadata: {
        subject,
        quiz_mode,
        prompt_length: prompt.length,
        response_length: aiResponse.length,
        tokens_used: openaiData.usage?.total_tokens
      }
    }), {
      headers: { 
        ...corsHeaders,
        'Content-Type': 'application/json' 
      },
    });

  } catch (error) {
    console.error('Erro no proxy OpenAI:', error);
    
    return new Response(JSON.stringify({ 
      error: error.message,
      success: false 
    }), {
      status: 500,
      headers: { 
        ...corsHeaders,
        'Content-Type': 'application/json' 
      },
    });
  }
});