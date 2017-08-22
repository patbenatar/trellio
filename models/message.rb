require "./util/trello_helper"

class Message
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  field :trello_card_id, type: String
  field :recording_url, type: String
  field :transcription, type: String

  def trello_card
    @trello_card ||= if card_id = trello_card_id
      Trello::Card.find(card_id)
    else
      Trello::Card.create(
        name: "Voicemail from #{from} on #{Time.now.strftime("%-d/%-m/%Y at %-l:%M %P")}",
        list_id: TrelloHelper.default_list.id,
      ).tap { |c| update_attribute :trello_card_id, c.id }
    end
  end
end
