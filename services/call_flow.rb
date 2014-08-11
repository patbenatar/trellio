module CallFlow
  class << self
    def record_voicemail(message)
      Twilio::TwiML::Response.new do |r|
        r.Play ENV["MESSAGE_URL"]
        r.Pause
        r.Record(
          action: "/messages/#{message.id}/recorded",
          timeout: ENV["RECORD_TIMEOUT"],
          transcribeCallback: "/messages/#{message.id}/transcribed",
        )
      end.text
    end

    def forward
      Twilio::TwiML::Response.new do |r|
        r.Dial action: "/forward", timeout: ENV["RING_TIMEOUT"] do
          r.Number ENV["FORWARD_NUMBER"]
        end
      end.text
    end

    def hang_up
      Twilio::TwiML::Response.new do |r|
        r.Hangup
      end.text
    end
  end
end
