class Group
  include Mongoid::Document

  #has_many :members, autosave: true

  field :name, type: String
  field :uuid, type: String
  field :user_uuid, type: String
  field :org_webform_uuid, type: String
  field :description, type: String
  field :location, type: Hash
  field :category, type: Array
  field :type, type: String
  field :status, type: String
  field :err, type: String
  field :group_above, type: String

  index({ uuid: 1 } , { unique: true })

  def get_subgroups_members
    Resque.enqueue(GetSubgroupsMembers, self.id)
  end

  def get_group_members
    Resque.enqueue(GetGroupMembers, self.id)
  end

  def get_subgroups_members_roles
    Resque.enqueue(GetSubgroupsMembersRoles, self.id)
  end

  def get_group_members_roles
    Resque.enqueue(GetGroupMembersRoles, self.id)
  end

  def get_group
    Resque.enqueue(GetGroup, self.id)
  end

  def update_group
    Resque.enqueue(UpdateGroup, self.id)
  end
end
