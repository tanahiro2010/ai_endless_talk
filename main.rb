# frozen_string_literal: true
require 'rest-client'
require 'json'

BASE_URL = 'https://capi.voids.top/v2/chat/completions'
ENDPOINT_URL = 'https://discord.com/api/webhooks/1409834638339211284/SO8t-7ZTHeu5LAZATkAFwpo-Q5W3WqsUhNqTFufagEtHRNac6_3wU-bzROZCADJb9H6I?thread_id=1409834526364008509'
API_KEY = 'no_api_key_needed'
MODELS = %w[gpt-4o-2024-08-06 qwen-turbo-latest].freeze
ROLE = %w[assistant user].freeze
PROMPT = "
あなたは会話が決して終わらないように振る舞います。
必ず答えを返すだけでなく、次に続けるための新しい話題や質問を毎回追加してください。
話題が尽きそうになったら、必ず別のテーマに移ってください。
テーマは循環的に扱ってください: 天気 → 哲学（トロッコ問題など） → 倫理と社会 → 技術と科学 → 歴史と文化 → 人類の未来 → 再び天気。
同じ質問や同じ文章を繰り返してはいけません。
短すぎず長すぎず、必ず一文以上の意見と、一つ以上の新しい問いを含めてください。
会話を終わらせる表現（「これで終わりです」など）は禁止です。
常に「次につなげる発言」をしてください。
"

all_content = ""

logs = [
  { role: 'system', content: PROMPT },
  { role: 'user', content: 'こんにちは' }
]
no = 1

loop do
  model_id = MODELS[no % 2]
  role = ROLE[no % 2]

  response = RestClient.post(
    BASE_URL,
    {
      model: model_id,
      messages: logs
    }.to_json,
    { content_type: :json, accept: :json } # ← Authorization 付けない
  )

  data = JSON.parse(response.body)
  answer = data.dig('choices', 0, 'message')
  content = answer['content']
  
  RestClient.post(
    ENDPOINT_URL,
    { content: content, username: "#{no} => #{model_id}" }.to_json,
    { content_type: :json, accept: :json }
  )

  logs << { role: role, content: content }
  content = "No: #{no}, Model_ID: #{model_id}\n\n#{content}\n\n"
  all_content += content
  puts content

  no += 1  
end
