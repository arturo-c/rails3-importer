class Group
  include Mongoid::Document

  has_and_belongs_to_many :admins
  has_many :webforms, autosave: true do
    def find_by_uuid(uuid)
      where(uuid: uuid).first
    end
    def find_by_name(name)
      where(title: name).first
    end
  end

  field :title, type: String
  field :title_lower, type: String
  field :uuid, type: String
  field :user_uuid, type: String
  field :description, type: String
  field :address_zip, type: Integer
  field :address_street, type: String
  field :address_city, type: String
  field :address_state, type: String
  field :category, type: Array
  field :group_type, type: String
  field :group_template, type: String
  field :clone_uuid, type: String
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

  def get_group_uuid(admin_id)
    Resque.enqueue(GetGroupUuid, self.id, admin_id)
  end

  def create_group(admin_id)
    Resque.enqueue(CreateGroup, self.id, admin_id)
  end

  def update_group
    Resque.enqueue(UpdateGroup, self.id)
  end

  def clone_group
    Resque.enqueue(CloneGroup, self.id)
  end

  def delete_group
    Resque.enqueue(DeleteGroup, self.id)
  end

  def create_groups_below(admin_id, group_template_id, top_level_id)
    Resque.enqueue(CreateGroupsBelow, self.id, admin_id, group_template_id, top_level_id)
  end

  def create_one_group(admin_id, group_template_id, top_level_id)
    Resque.enqueue(CreateOneGroup, self.id, admin_id, group_template_id, top_level_id)
  end

  def get_recursive_groups(groups, group_above_uuid = self.uuid)
    @subgroups ||= {}

    groups.each do |nid, group|
      @subgroups[group['uuid']] = {:title => group['title'], :group_above => group_above_uuid, :has_children => group['has_children']}
      if group['has_children']
        get_recursive_groups(group['below'], group['uuid'])
      end
    end

    return @subgroups
  end

  def create_import(admin_id)
    admin = Admin.find(admin_id)
    client = AllPlayers::Client.new(ENV["HOST"])
    client.prepare_access_token(admin.token, admin.secret, ENV["OMNIAUTH_PROVIDER_KEY"], ENV["OMNIAUTH_PROVIDER_SECRET"])
    more_params = {
      :group_type => self.group_type,
      :web_address => self.title.parameterize.underscore,
      :groups_above => [self.group_above]
    }
    count = 0
    begin
      address = {
        :zip => self.address_zip,
        :street => self.address_street,
        :city => self.address_city,
        :state => self.address_state
      }
      ap_group = client.group_create(
        self.title,
        self.description,
        address,
        {0 => self.category},
        more_params
      )
    rescue AllPlayers::Error => e
      if e.respond_to?(:code)
        if e.code == '406' && e.error.include?('already taken')
          count = count + 1
          more_params[:web_address] = self.title.parameterize.underscore + '_' + count.to_s
          retry
        end
      end
    ensure
      if ap_group
        self.status = 'Imported'
        self.uuid = ap_group['uuid']
      end
      self.save
    end
  end
end
