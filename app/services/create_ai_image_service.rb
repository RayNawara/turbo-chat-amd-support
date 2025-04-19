# frozen_string_literal: true

# Required for base64 decoding and JSON parsing
require 'base64'
require 'json'

class CreateAiImageService
  prepend SimpleCommand
  include AiChats::Messageable # Make sure methods like add_ai_message, update_ai_message, notify_error expect :target

  def initialize(prompt:,
                 ai_chat_id: nil,
                 auth_token: ENV.fetch("IMAGE_GENERATION_AUTH_TOKEN"))
    @ai_chat_id = ai_chat_id
    @prompt = prompt
    @auth_token = auth_token
    # Initialize @ai_chat early for potential use in notify_error
    @ai_chat = AiChat.find_by(id: @ai_chat_id) if @ai_chat_id
  end

  def call
    # --- Initial Validations ---
    errors.add(:prompt, "is required") if prompt.blank?
    errors.add(:ai_chat_id, "is required") if ai_chat_id.blank?
    errors.add(:ai_chat, "not found") unless @ai_chat # Check the instance variable

    if errors.any?
      # Pass the target object for messageable context
      notify_error(target: @ai_chat, message: errors.full_messages.to_sentence) if @ai_chat
      return false # Indicate failure
    end

    show_spinner # Show spinner before the potentially long API call

    # --- API Call ---
    response = image_generation_service

    # --- Process Response ---
    image_binary_data = nil # Variable for decoded binary data

    if response.success?
      begin
        # 1. Parse JSON response
        parsed_response = JSON.parse(response.body)

        # 2. Extract base64 string (Confirmed key 'images', get first element)
        base64_string = parsed_response['images']&.first
        if base64_string.blank?
          raise StandardError, "No 'images' key with base64 string found in API response."
        end

        # 3. Decode base64 to binary
        image_binary_data = Base64.decode64(base64_string)
        if image_binary_data.blank?
          raise StandardError, "Failed to decode base64 string."
        end

      rescue JSON::ParserError => e
        errors.add(:api_response, "Invalid JSON received from image API: #{e.message}")
      rescue StandardError => e
        errors.add(:api_response, "Error processing image data: #{e.message}")
      end
    else
      # Handle non-2xx HTTP status codes
      error_detail = response.body.presence&.truncate(150) || "No details provided."
      errors.add(:api_request, "Image generation failed: Status #{response.status}. Details: #{error_detail}")
    end

    # --- Handle Processing Errors or Missing Data ---
    # Errors might have been added during API call OR during parsing/decoding
    if errors.any? || image_binary_data.nil?
      # Add a generic error if none specific yet but we failed to get data
      errors.add(:image_data, "Could not retrieve or process image data") if errors.empty?
      remove_spinner
      notify_error(target: @ai_chat, message: errors.full_messages.to_sentence)
      return false # Indicate failure
    end

    # --- Success Path: Create Message and Attach Image ---
    ai_message = nil
    begin
      ActiveRecord::Base.transaction do
        # Create the message record (answer is blank for image messages)
        ai_message = @ai_chat.ai_messages.create!(prompt: @prompt, answer: "")
        # Broadcast initial message placeholder before potentially long attachment step
        add_ai_message(ai_message: ai_message)

        # Attach the actual DECODED binary data
        ai_message.generated_image.attach(
          io: StringIO.new(image_binary_data),
          # Filename and content type based on Python example saving as PNG
          filename: "generated_image.png",
          content_type: "image/png"
        )
        # Note: create! saves the record, associating the attachment implicitly after transaction commit.
      end

      # If transaction successful and image attached
      remove_spinner
      # Broadcast the final update to replace placeholder / show image
      update_ai_message(ai_message: ai_message)

      return true # Indicate overall success

    rescue ActiveRecord::RecordInvalid => e
      # Catch validation errors during AiMessage create
      errors.add(:database, "Failed to save message: #{e.message}")
    rescue StandardError => e
      # Catch other potential errors during attachment/broadcast
      errors.add(:attachment, "Failed during image attachment/broadcast: #{e.message}")
    end

    # --- Handle Errors during DB/Attachment phase ---
    # If we reached here, the begin/rescue block above failed
    remove_spinner # Ensure spinner is removed on error
    notify_error(target: @ai_chat, message: errors.full_messages.to_sentence)
    # Log the error as well for server-side debugging
    Rails.logger.error "CreateAiImageService DB/Attachment failed: #{errors.full_messages.to_sentence}"
    return false # Indicate failure

  # --- Main rescue block for unexpected errors (e.g., during API call itself) ---
  rescue StandardError => e
    remove_spinner
    errors.add(:service_error, "An unexpected error occurred: #{e.message}")
    # Use @ai_chat if available, otherwise might need another way to notify user/admin
    notify_error(target: @ai_chat, message: errors.full_messages.to_sentence) if @ai_chat
    # Log the full error and backtrace for debugging
    Rails.logger.error "CreateAiImageService failed unexpectedly: #{e.message}\n#{e.backtrace.join("\n  ")}"
    return false # Indicate failure
  end

  private

  # Keep original attributes readable if needed elsewhere, added @ai_chat
  attr_reader :ai_chat_id, :prompt, :auth_token, :ai_chat

  # ai_chat method is effectively replaced by setting @ai_chat in initialize
  # def ai_chat ...

  def image_generation_service
    # Ensure @ai_chat and model name are present (already checked in call, but defensive check)
    unless @ai_chat && @ai_chat.ai_model_name.present?
      raise StandardError, "Cannot make image request without valid AiChat context and model name."
    end

    # Construct payload
    payload = {
      prompt: @prompt,
      # Assuming model_type parameter for the API matches the chat's model name
      model_type: @ai_chat.ai_model_name,
      width: ENV.fetch("IMAGE_GENERATION_WIDTH", 512).to_i,
      height: ENV.fetch("IMAGE_GENERATION_HEIGHT", 512).to_i
      # Add any other parameters your API needs (e.g., steps, sampler)
      # steps: ENV.fetch("IMAGE_GENERATION_STEPS", 20).to_i
    }

    # Construct headers
    headers = {
      # Add "Bearer " prefix if your token is a Bearer token (very common)
      # "Authorization" => "Bearer #{auth_token}",
      "Authorization" => auth_token, # Use as is if it already includes type or none needed
      "Content-Type" => "application/json",
      "Accept" => "application/json" # Good practice to specify accepted response type
    }

    # Make the request
    Faraday.post(
        ENV.fetch("IMAGE_GENERATION_URL"),
        payload.to_json,
        headers
      ) do |request|
      # Set timeouts (consider longer timeouts for image generation)
      request.options.timeout = ENV.fetch("IMAGE_GENERATION_TIMEOUT", 120).to_i # Connect/Open timeout
      request.options.read_timeout = ENV.fetch("IMAGE_GENERATION_READ_TIMEOUT", 120).to_i # Read timeout
    end
  end
end
