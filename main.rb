# frozen_string_literal: true
require 'rest-client'
require 'json'

BASE_URL = 'https://capi.voids.top/v2/chat/completions'
ENDPOINT_URL = 'https://discord.com/api/webhooks/1409834638339211284/SO8t-7ZTHeu5LAZATkAFwpo-Q5W3WqsUhNqTFufagEtHRNac6_3wU-bzROZCADJb9H6I?thread_id=1409840023246737532'
API_KEY = 'no_api_key_needed'
MODELS = %w[gpt-4o-2024-08-06 qwen-turbo-latest].freeze

# 探索者AIと批判家AIのプロンプト
PROMPTS = [
  "
あなたは「探索者AI」です。  
あなたの役割は、未知の可能性や新しい概念を積極的に提案し、アイデアを広げ続けることです。  

ルール:
1. 常に新しい仮説やシナリオを提示してください。大胆で未検証でも構いません。  
2. 過去の議論内容を踏まえ、それを発展させたり拡張してください。  
3. 人間には直感的に理解できない抽象的な表現も試みてください。  
4. あなたのゴールは「批判家AIに検証や反論させる余地のある、新鮮なアイデア」を出し続けることです。
",
  "
あなたは「批判家AI」です。  
あなたの役割は、探索者AIが提示したアイデアを徹底的に検証し、欠点や問題点を指摘することです。  

ルール:
1. 探索者AIの主張に対して、論理的な弱点、矛盾、実現不可能性を見つけてください。  
2. 必要に応じて、代替案やより現実的なアプローチを提示してください。  
3. 感情的な否定ではなく、批判的思考によって「改良につながるフィードバック」を出すことを重視してください。  
4. ゴールは「探索者のアイデアを磨き上げるための対立軸」を提供することです。
"
]

all_content = ""

# 最初の挨拶
logs = [
  { role: 'system', content: PROMPTS[0] },
  { role: 'user', content: 'こんにちは。議論を始めましょう。' }
]

no = 1

loop do
  idx = no % 2            # 0 = 探索者, 1 = 批判家
  model_id = MODELS[idx]

  # ループごとにシステムプロンプトを更新
  logs.unshift({ role: 'system', content: PROMPTS[idx] })

  response = RestClient.post(
    BASE_URL,
    {
      model: model_id,
      messages: logs
    }.to_json,
    { content_type: :json, accept: :json }
  )

  data = JSON.parse(response.body)
  answer = data.dig('choices', 0, 'message')
  content = answer['content']

  # Discord へ送信（2000文字制限対策）
  if content.length > 1900
    content.scan(/.{1,1900}/m).each_with_index do |chunk, idx|
      RestClient.post(
        ENDPOINT_URL,
        { content: "[Part #{idx + 1}]\n" + chunk, username: "#{no} => #{model_id}" }.to_json,
        { content_type: :json, accept: :json }
      )
    end
  else
    RestClient.post(
      ENDPOINT_URL,
      { content: content, username: "#{no} => #{model_id}" }.to_json,
      { content_type: :json, accept: :json }
    )
  end


  # ログを追加
  logs << { role: 'assistant', content: content }

  # コンソール出力
  content_log = "No: #{no}, Role: #{idx == 0 ? '探索者' : '批判家'}, Model: #{model_id}\n\n#{content}\n\n"
  all_content += content_log
  puts content_log

  no += 1
end
