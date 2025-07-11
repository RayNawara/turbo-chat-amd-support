# frozen_string_literal: true

class AiChat < ApplicationRecord
  belongs_to :user

  has_many :ai_messages, -> { order(id: :asc) }, dependent: :delete_all

  SUPPORTED_AI_MODELS = {
    text: %w[phi3:mini llama3.1:latest mistral:latest mistral:7b-instruct-v0.3-q8_0 mixtral:8x7b-instruct-v0.1-q5_K_M codellama:7b-instruct codellama:34b-instruct phind-codellama:34b-v2 starcoder2:15b
 dolphin-llama3:8b jean-luc/big-tiger-gemma:27b-v1c-Q3_K_M vanilj/mistral-nemo-12b-celeste-v1.9:Q4_K_M qwen2.5-coder gemma2],
    image: %w[anythingV3_fp16.safetensors realisticVisionV60B1_v51HyperVAE.safetensors sdxl-turbo sdxl-anime ponyDiffusionV6XL_v6StartWithThisOne]
  }.freeze

  validates :ai_model_name, presence: true, inclusion: { in: SUPPORTED_AI_MODELS[:text] + SUPPORTED_AI_MODELS[:image] }

  enum :chat_type, { text: 0, image: 1 }

end
