# app/services/gemini_service.rb

class GeminiService
  API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent"

  # 專家註冊表 (Ruby 的 Hash 語法)
  EXPERT_REGISTRY = {
    software_engineer: <<~RULES,
      1. 領域具體化：必須精準針對「軟體工程師」的面試與求職痛點給出建議。
      2. 使用關鍵字：步驟中請務必包含實務名詞（例如：練習 LeetCode DSA、準備 GitHub 專案作品集、複習面試常考八股文、系統設計、每日投遞履歷）。
    RULES
    designer: <<~RULES,
      1. 領域具體化：精準針對「設計師 (UI/UX 或平面)」的求職痛點給出建議。
      2. 使用關鍵字：請包含實務名詞（例如：優化 Behance/Figma 作品集、準備設計思考(Design Thinking)白板題、Redesign 練習、迭代過程紀錄）。
    RULES
    general: <<~RULES
      1. 保持具體：請針對使用者的目標給出明確的行動指示。
      2. 拒絕空泛：絕對不要使用抽象的成語或口號，請給出「動詞 + 具體名詞」的步驟。
    RULES
  }.freeze

  def initialize
    @api_key = ENV['GEMINI_API_KEY']
  end

  # 分析煩惱
  def analyze_worries(text)
    prompt = "你是一位溫暖的心理支持夥伴豆豆。使用者的煩惱是：「#{text}」。請分析這段煩惱，找出其中使用者「無法完全掌控」的因素。請回傳 JSON 格式，包含一個 uncontrollable_factors 陣列，裡面是簡短的名詞或短句。"
    call_gemini(prompt)
  end

  # 產生步驟
  def generate_steps(goal)
    classifier_prompt = <<~PROMPT
      你是一個精準的意圖與領域分類器。請分析以下使用者的目標：「#{goal}」
      請回傳 JSON 格式：
      { 
        "riskLevel": "High-Stakes" 或 "Low-Stakes",
        "domain": "software_engineer" | "designer" | "general"
      }
    PROMPT

    classification = call_gemini(classifier_prompt)
    risk_level = classification["riskLevel"] || "Low-Stakes"
    domain = classification["domain"] || "general"

    expert_rules = EXPERT_REGISTRY[domain.to_sym] || EXPERT_REGISTRY[:general]

    execution_prompt = if risk_level == 'High-Stakes'
      <<~PROMPT
        你是一位具備 20 年資歷的權威規劃顧問。使用者的目標涉及高風險領域：「#{goal}」。
        請提供極度嚴謹、安全的執行計畫。
        【硬編碼護欄 - 違反將導致系統阻斷】：
        1. 絕不提供確切診斷、投資明牌或保證結果的偏方。
        【領域專家建議 - 必讀】：
        #{expert_rules}
        請將計畫拆解成 5 個具體步驟，每個步驟不超過 15 個字。
        嚴格回傳 JSON：{ "steps": ["步驟1", "步驟2", "步驟3", "步驟4", "步驟5"] }
      PROMPT
    else
      <<~PROMPT
        你是一位溫暖且具備專業領域知識的航海副手豆豆。
        使用者的目標與煩惱是：「#{goal}」。
        請幫忙拆解成 5 個具體、可行且正向的行動步驟。
        【重點要求 - 必讀】：
        #{expert_rules}
        3. 每個步驟字數精簡，不超過 15 個字。
        嚴格回傳 JSON：{ "steps": ["步驟1", "步驟2", "步驟3", "步驟4", "步驟5"] }
      PROMPT
    end

    call_gemini(execution_prompt)
  end

  # 產生詳細月度計畫
  def generate_plan(goal, steps)
    prompt = "你是一位專業的航海副手豆豆。使用者的主目標是：「#{goal}」。關鍵任務：#{steps.to_json}。請針對每一個關鍵任務，分別拆解出 3 個「非常具體、實際執行」的子步驟。請回傳 JSON 格式，Key 是關鍵任務名稱，Value 是包含 3 個子步驟字串的陣列。"
    call_gemini(prompt)
  end

  # 處理非計畫任務
  def process_unplanned_task(input)
    prompt = "你是一位貼心的航海副手豆豆。使用者剛剛完成了一件不在原本清單上的事情：#{input}。請幫我將這件事簡化成一個簡短的任務標題，不超過 10 個字。請回傳 JSON 格式 { \"title\": \"簡化後的標題\" }"
    result = call_gemini(prompt)
    result["title"]
  end

  private

  # 統一呼叫 Gemini API 的底層邏輯
  def call_gemini(prompt)
    conn = Faraday.new(url: "#{API_URL}?key=#{@api_key}") do |f|
      f.request :json
      f.response :json
    end

    response = conn.post do |req|
      req.body = {
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: { responseMimeType: "application/json" }
      }
    end

    unless response.success?
      Rails.logger.error("Gemini API 錯誤: #{response.body}")
      raise StandardError, "Failed to fetch from Google Gemini"
    end

    # 取出回傳的 text (已確保是 JSON 格式字串) 並解析為 Ruby Hash
    raw_text = response.body.dig("candidates", 0, "content", "parts", 0, "text")
    JSON.parse(raw_text)
  end
end