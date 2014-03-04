class Webform
  include Mongoid::Document

  belongs_to :group
  belongs_to :admin

  field :uuid, type: String
  field :name, type: String
  field :data_fields, type: Array

end
