class Admin
  include Mongoid::Document

  has_and_belongs_to_many :groups do
    def find_by_uuid(uuid)
      where(uuid: uuid).first
    end
    def find_by_name(name)
      where(title: name).first
    end
  end

  field :uuid, type: String
  field :name, type: String
  field :organization, type: String
  field :token, type: String
  field :secret, type: String
  field :status, type: String
  field :err, type: String
  field :webform_fields, type: Array
  field :webform, type: String
  field :group_template, type: String
  attr_accessible :uuid, :name, :organization

  def self.create_with_omniauth(auth)
    create! do |admin|
      admin.uuid = auth[:uid]
      admin.name = auth[:info][:name] || ""
    end
  end

  def get_admin_groups
    Resque.enqueue(GetAdminGroups, self.id)
  end

  def get_org_groups(org_uuid, template = nil)
    Resque.enqueue(GetOrgGroups, self.id, org_uuid, template)
  end
 
  def process_import(chunk)
    Resque.enqueue(ProcessImport, self.id, chunk)
  end

  def process_group_import(chunk)
    Resque.enqueue(ProcessGroupImport, self.id, chunk)
  end

  def create_group_template(group_id)
    Resque.enqueue(CreateGroupTemplate, self.id, group_id)
  end

  def verify_group_import(chunk)
    Resque.enqueue(VerifyGroupImport, self.id, chunk)
  end

end
