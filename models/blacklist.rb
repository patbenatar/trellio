class Blacklist
  include MongoMapper::Document

  key :phone_number,  String, required: true
  key :caller_name,   String
  timestamps!

  attr_accessor :phone_number, :caller_name
end
