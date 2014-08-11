require "bundler/setup"
Bundler.require
require "securerandom"

require "./models/message"
require "./models/blacklist"
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

  if Blacklist.find_by_phone_number(params["From"])
    CallFlow.record_voicemail Message.create(from: params["From"])
  else
    CallFlow.forward
  end
end

post "/forward" do
  content_type "text/xml"

  if params["DialCallStatus"] == "no-answer"
    CallFlow.record_voicemail Message.create(from: params["From"])
  else
    CallFlow.hang_up
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

get "/ping" do; end # To keep Heroku Dyno awake

helpers do
  def protected!
    return if authorized?
    headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
    halt 401, "Not authorized\n"
  end

  def authorized?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? and @auth.basic? and @auth.credentials and @auth.credentials == ["admin", "wehaterecruiters!"]
  end
end

get "/blacklists/?" do
  protected!
  @blacklists = Blacklist.all
  @title = "Trellio Blacklist"
  erb :blacklist
end

get "/blacklists/new" do
  protected!
  @blacklist = Blacklist.new
  @title = "Add New Number"
  erb :new
end

post "/blacklists" do
  blacklist = Blacklist.create(params[:blacklist])
  redirect to("/blacklists")
end

get "/blacklists/:id/edit" do
  protected!
  @blacklist = Blacklist.find(params[:id])
  @title = "Edit Number"
  erb :edit
end

put "/blacklists/:id" do
  blacklist = Blacklist.find(params[:id])
  blacklist.update_attributes(params[:blacklist])
  redirect to("/blacklists")
end

get "/blacklists/delete/:id" do
  protected!
  @blacklist = Blacklist.find(params[:id])
  @title = "Delete Number"
  erb :delete
end

delete "/blacklists/:id" do
  Blacklist.find(params[:id]).destroy
  redirect to("/blacklists")
end
