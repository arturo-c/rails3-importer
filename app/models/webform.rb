class Webform
  include Mongoid::Document

  field :uuid, type: String
  field :admin_uuid, type: String
  field :data, type: Array

end
