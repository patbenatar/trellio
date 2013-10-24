require "bundler/setup"
Bundler.require
require "securerandom"

require "./models/message"
require "./services/call_flow"

register Sinatra::Reloader

configure do
  MongoMapper.database = "trellio"

  Trello.configure do |config|
    config.developer_public_key = ENV["TRELLO_DEVELOPER_PUBLIC_KEY"]
    config.member_token = ENV["TRELLO_MEMBER_TOKEN"]
  end
end

configure :production do
  MongoMapper.setup({ "production" => { "uri" => ENV["MONGOLAB_URI"] } }, "production")
end

post "/incoming" do
  content_type "text/xml"
  CallFlow.forward
end

post "/forward" do
  content_type "text/xml"

  if params["DialCallStatus"] == "no-answer"
    CallFlow.record_voicemail Message.create
  end
end

post "/messages/:id/recorded" do
  message = Message.find(params[:id])
  message.update_attributes recording_url: params["RecordingUrl"]
  message.trello_card.add_comment "Recording: #{message.recording_url}"
end

post "/messages/:id/transcribed" do
  message = Message.find(params[:id])
  message.update_attributes transcription: params["TranscriptionText"]
  message.trello_card.add_comment "Transcription: #{message.transcription}"
end

get "/authorize_trello" do
  <<-STRING
  <a href="https://trello.com/1/authorize?key=#{ENV["TRELLO_DEVELOPER_PUBLIC_KEY"]}&name=Trellio&expiration=never&response_type=token&scope=read,write">Click here</a>
  and set the token provided to `TRELLO_MEMBER_TOKEN` environment variable.
  STRING
end