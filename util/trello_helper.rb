module TrelloHelper
  def self.default_list
    Trello::Board.find(ENV["TRELLO_BOARD_ID"]).lists.first
  end
end