# app/controllers/api/v1/gemini_controller.rb

class Api::V1::GeminiController < ApplicationController
  # 接收 /api/v1/gemini/analyze_worries (暫時不存資料，純回傳分析)
  def analyze_worries
    render json: service.analyze_worries(params[:text])
  rescue StandardError => e
    render_error(e)
  end

  # 接收 /api/v1/gemini/generate_steps (⭐ 核心改造：存入資料庫)
  def generate_steps
    # 【開發小技巧】因為前端目前還沒有做登入功能，
    # 我們先寫一個「防呆機制」：去資料庫抓第一個 User，如果沒有就自動幫你建一個假的。
    user = User.first || User.create!(name: "開發測試員", email: "test@example.com", firebase_uid: "test1234")

    # 1. 呼叫 Service 取得 Google Gemini 的 AI 結果
    ai_results = service.generate_steps(params[:goal])
    
    # 2. 開啟資料庫「交易 (Transaction)」機制
    ActiveRecord::Base.transaction do
      # 建立主目標 (Goal)
      goal = user.goals.create!(
        title: params[:goal],
        domain: ai_results["domain"],
        risk_level: ai_results["riskLevel"]
      )
      
      # 將 AI 回傳的步驟陣列，逐一建立成任務 (Task)
      ai_results["steps"].each_with_index do |step_title, index|
        goal.tasks.create!(
          title: step_title, 
          position: index, 
          status: "pending"
        )
      end
      
      # 3. 把剛存進資料庫的 Goal 連同它底下的 Tasks，一起打包成 JSON 傳回給 React 前端
      render json: goal.as_json(include: :tasks)
    end

  rescue StandardError => e
    render_error(e)
  end

  # 接收 /api/v1/gemini/generate_plan (未來也可以擴充成更新 Task 的子步驟)
  def generate_plan
    render json: service.generate_plan(params[:goal], params[:steps])
  rescue StandardError => e
    render_error(e)
  end

  # 接收 /api/v1/gemini/process_unplanned_task
  def process_unplanned_task
    title = service.process_unplanned_task(params[:input])
    render json: { title: title }
  rescue StandardError => e
    render_error(e)
  end

  private

  def service
    @service ||= GeminiService.new
  end

  def render_error(error)
    Rails.logger.error("Controller Error: #{error.message}")
    # 印出完整的錯誤追蹤，方便你在終端機抓蟲
    Rails.logger.error(error.backtrace.join("\n")) 
    render json: { error: "Internal Server Error", details: error.message }, status: :internal_server_error
  end
end