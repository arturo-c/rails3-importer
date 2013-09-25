class Admin
  include Mongoid::Document

  #has_many :groups

  field :uuid, type: String
  field :name, type: String
  field :token, type: String
  field :secret, type: String
  field :status, type: String
  field :err, type: String
  attr_accessible :uuid, :name

  def self.create_with_omniauth(auth)
    create! do |admin|
      admin.uuid = auth[:uid]
      admin.name = auth[:info][:name] || ""
    end
  end

  def get_admin_groups
    Resque.enqueue(GetAdminGroups, self.id)
  end
 
  def process_import(chunk)
    Resque.enqueue(ProcessImport, self.id, chunk)
  end

  def process_group_import(chunk)
    Resque.enqueue(ProcessGroupImport, self.id, chunk)
  end

end
