class SlackController < ApplicationController
  skip_before_action :verify_authenticity_token
  protect_from_forgery with: :null_session

  def incoming
    request_body = request.body.read
    timestamp = request.env['HTTP_X_SLACK_REQUEST_TIMESTAMP']
    signature = request.env['HTTP_X_SLACK_SIGNATURE']

    if is_valid_request?(request_body, timestamp, signature)
      parsed = JSON.parse(request_body)
      case parsed['type']
      when 'url_verification'
        challenge = parsed['challenge']
        render json: { challenge: challenge }
      when 'event_callback'
        parsed = parsed['event']

        case parsed['type']
        when 'message'
          text = parsed['text']

          message = SlackCommandProcessor.process(text)

          if message
            SlackNotifier.send_message(message)
          end
        else
          LOGGER.info("Unhandlend event: #{parsed['type']}")
        end
      else
        LOGGER.info("Unhandlend event: #{parsed['type']}")
      end
      head 200
    else
      head :bad_request
    end
  end

  def is_valid_request?(request_body, timestamp, signature)
    digest = OpenSSL::Digest::SHA256.new
    hmac = OpenSSL::HMAC.new(SLACK_SIGNING_SECRET, digest)
    hmac.update("v0:#{timestamp}:#{request_body}")
    expected_signature = "v0=#{hmac.hexdigest}"

    if (Time.now.utc.to_i - timestamp.to_i).abs > 5.minutes.to_i
      return false
    end

    ActiveSupport::SecurityUtils.secure_compare(expected_signature, signature)
  end
end
