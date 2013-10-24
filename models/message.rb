require "./util/trello_helper"

class Message
  include MongoMapper::Document

  key :trello_card_id, String
  key :recording_url, String
  key :transcription, String

  def trello_card
    @trello_card ||= if card_id = trello_card_id
      Trello::Card.find(card_id)
    else
      Trello::Card.create(
        name: "Voicemail: #{Time.now.strftime("%-d/%-m/%Y at %-l:%M %P")}",
        list_id: TrelloHelper.default_list.id,
      ).tap { |c| update_attribute :trello_card_id, c.id }
    end
  end
end