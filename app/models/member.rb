class Member
  include Mongoid::Document

  field :uuid, type: String
  field :group_uuid, type: String
  field :group_name, type: String
  field :admin_uuid, type: String
  field :email, type: String
  field :parent_email, type: String
  field :first_name, type: String
  field :last_name, type: String
  field :birthday, type: String
  field :gender, type: String
  field :roles, type: Array
  field :submission_id, type: Integer
  field :member_id, type: Integer
  field :local, type: Boolean
  field :status, type: String
  field :err, type: String

  validates :email, :uniqueness => {:scope => :group_name}

  def get_member_uuid
    Resque.enqueue(GetMemberUuid, self.id)
  end

  def create_member
    Resque.enqueue(CreateMember, self.id)
  end

  def add_to_group
    Resque.enqueue(AddToGroup, self.id)
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
