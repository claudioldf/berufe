# Be sure to restart your server when you modify this file.

# Configure parameters to be partially matched (e.g. passw matches password) and filtered from the log file.
# Use this to limit dissemination of sensitive information.
# See the ActiveSupport::ParameterFilter documentation for supported notations and behaviors.
Rails.application.config.filter_parameters += [
  :passw, :email, :phone, :code, :pin, :secret, :token, :challenge, :_key, :crypt, :salt, :certificate,
  :otp, :ssn, :cvv, :cvc, :birthdate, :display_name, :customer_name, :name, :headline, :bio, :whatsapp,
  :instagram, :youtube, :address, :description, :message, :notes, :context_note, :recommendation_text,
  :review_note, :cancellation_reason, :request_message, :query, :expression,
  :input_prompt, :raw_llm_response, :parsed_response
]
