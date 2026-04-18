# app/controllers/api/v1/gemini_controller.rb

class Api::V1::GeminiController < ApplicationController
  # 接收 /api/v1/gemini/analyze_worries
  def analyze_worries
    render json: service.analyze_worries(params[:text])
  rescue StandardError => e
    render_error(e)
  end

  # 接收 /api/v1/gemini/generate_steps
  def generate_steps
    render json: service.generate_steps(params[:goal])
  rescue StandardError => e
    render_error(e)
  end

  # 接收 /api/v1/gemini/generate_plan
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
    render json: { error: "Internal Server Error" }, status: :internal_server_error
  end
end