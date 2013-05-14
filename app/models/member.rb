class Member
  include Mongoid::Document

  #embeds_many :roles
  #embeds_one :submission
  #embeds_one :webform_data

  field :uuid, type: String
  field :group_name, type: String
  field :group_uuid, type: String
  field :admin_uuid, type: String
  field :member_id, type: Integer
  field :email, type: String
  field :parent_email, type: String
  field :first_name, type: String
  field :last_name, type: String
  field :birthday, type: String
  field :gender, type: String
  field :roles, type: Array
  field :address_1, type: String
  field :address_2, type: String
  field :city, type: String
  field :state, type: String
  field :country, type: String
  field :zip, type: String
  field :phone, type: String
  field :submission_id, type: Integer
  field :status, type: String
  field :join_date, type: String
  field :err, type: String

  

  validates :email, :uniqueness => {:scope => :group_name}

  def get_member_uuid
    Resque.enqueue(GetMemberUuid, self.id)
  end

  def create_member
    Resque.enqueue(CreateMember, self.id)
  end

  def add_to_group(group_uuid = nil)
    Resque.enqueue(AddToGroup, self.id, group_uuid)
  end

  def add_to_group_and_subgroups
    Resque.enqueue(AddToGroupAndSubgroups, self.id)
  end

  def remove_from_group(group_uuid = nil)
    Resque.enqueue(RemoveFromGroup, self.id, group_uuid)
  end

  def remove_from_group_and_subgroups
    Resque.enqueue(RemoveFromGroupAndSubgroups, self.id)
  end

  def create_child
    Resque.enqueue(CreateChild, self.id)
  end

  def get_group_member_roles
    Resque.enqueue(GetGroupMemberRoles, self.id)
  end

  def get_submission
    Resque.enqueue(GetSubmission, self.id)
  end

  def get_unique_submission
    Resque.enqueue(GetUniqueSubmission, self.id)
  end

  def assign_submission
    Resque.enqueue(AssignSubmission, self.id)
  end

  def get_webform_data
    Resque.enqueue(GetWebformData, self.id)
  end

  def self.unique_email
    map = %Q{
      function() {
        emit(this.email, {count: 1})
      }
    }

    reduce = %Q{
      function(key, values) {
        var result = {count: 0};
        values.forEach(function(value) {
          result.count += value.count;
        });
        return result;
      }
    }

    self.map_reduce(map, reduce).out(inline: true)
  end
end
