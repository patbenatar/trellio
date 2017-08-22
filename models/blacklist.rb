class Blacklist
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic

  field :phone_number, type: String
  field :caller_name, type: String

  validates :phone_number, presence: true

  attr_accessor :phone_number, :caller_name
end
