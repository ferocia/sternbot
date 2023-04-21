require 'net/http'
class SlackNotifier
  def self.send_message(message)
    uri = URI(SLACK_INCOMING_WEBHOOK)
    params = {'text' => message}
    headers = {'Content-Type' => 'application/json'}

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri.request_uri, headers)
    request.body = params.to_json

    response = http.request(request)

    if response.code.to_i != 200
      LOGGER.error "Slack notification failed!"
    end
  end
end
