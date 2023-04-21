class SlackController < ApplicationController
  skip_before_action :verify_authenticity_token
  protect_from_forgery with: :null_session

  def incoming
    request_body = request.body.read
    timestamp = request.env['HTTP_X_SLACK_REQUEST_TIMESTAMP']
    signature = request.env['HTTP_X_SLACK_SIGNATURE']

    # TODO: lol yeah figure out why request validation is busted
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

          tokens = text.split(/ +/)
          first = tokens.shift

          if first == ":pinball:"
            case tokens[0]
            when 'hello'
              SlackNotifier.send_message("hello")
            when 'leaderboard'
              n = (tokens[1] || 3).to_i
              leaderboard = AsciiLeaderboard.top(n: n)
              SlackNotifier.send_message("```\n#{leaderboard}\n```")
            when 'players'
              leaderboard = AsciiLeaderboard.player_highs
              SlackNotifier.send_message("```\n#{leaderboard}\n```")
            when 'add'
              username = tokens[1]
              if username
                AddPlayerJob.perform_later(username)
                SlackNotifier.send_message("Adding #{username}, stand by...")
              end
            when 'remove'
              username = tokens[1]
              if username
                RemovePlayerJob.perform_later(username)
                SlackNotifier.send_message("Removing #{username}, stand by...")
              end
            else
              LOGGER.info("Unknown command: #{tokens[0]}")
            end
          end
          head 200
        else
          LOGGER.info("Unhandlend event: #{parsed['type']}")
        end
      else
        LOGGER.info("Unhandlend event: #{parsed['type']}")
      end
    else
      head :bad_request
    end
  end

  def is_valid_request?(request_body, timestamp, signature)
    digest = OpenSSL::Digest::SHA256.new
    hmac = OpenSSL::HMAC.new(SLACK_SIGNING_SECRET, digest)
    hmac.update("v0:#{timestamp}:#{request_body}")
    expected_signature = "v0=#{hmac.hexdigest}"

    # TODO: Include timestamp validation

    ActiveSupport::SecurityUtils.secure_compare(expected_signature, signature)
  end
end
