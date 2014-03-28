class Member
  include Mongoid::Document

  field :uuid, type: String
  field :group_name, type: String
  field :group_uuid, type: String
  field :admin_uuid, type: String
  field :title, type: String
  field :member_id, type: Integer, default: -> { 0 }
  field :email, type: String
  field :parent_email, type: String
  field :first_name, type: String
  field :last_name, type: String
  field :birthday, type: String
  field :gender, type: String
  field :roles, type: Array, default: -> { Hash.new }
  field :address_1, type: String, default: -> { '' }
  field :address_2, type: String, default: -> { '' }
  field :city, type: String, default: -> { '' }
  field :state, type: String, default: -> { '' }
  field :country, type: String, default: -> { '' }
  field :zip, type: String, default: -> { '' }
  field :phone, type: String, default: -> { '' }
  field :submission_id, type: Integer
  field :submission_uuid, type: String
  field :status, type: String
  field :join_date, type: String, default: -> { Time.now.year.to_s + "-" + Time.now.month.to_s + "-" + Time.now.day.to_s }
  field :err, type: String
  field :old_member_id, type: String, default: -> { '' }
  field :old_group, type: String, default: -> { '' }
  field :old_user_uuid, type: String, default: -> { '' }
  field :create_new_submission, type: Boolean, default: -> { false }
  field :webform_fields, type: Hash

  def get_member_uuid
    Resque.enqueue(GetMemberUuid, self.id)
  end

  def create_member
    Resque.enqueue(CreateMember, self.id)
  end

  def add_to_group
    Resque.enqueue(AddToGroup, self.id)
  end

  def add_to_group_and_subgroups
    Resque.enqueue(AddToGroupAndSubgroups, self.id)
  end

  def remove_from_group
    Resque.enqueue(RemoveFromGroup, self.id)
  end

  def remove_from_group_and_subgroups
    Resque.enqueue(RemoveFromGroupAndSubgroups, self.id)
  end

  def get_child
    Resque.enqueue(GetChild, self.id)
  end

  def create_child
    Resque.enqueue(CreateChild, self.id)
  end

  def get_group_member_roles
    Resque.enqueue(GetGroupMemberRoles, self.id)
  end

  def get_submission(webform_uuid)
    Resque.enqueue(GetSubmission, self.id, webform_uuid)
  end

  def get_unique_submission
    Resque.enqueue(GetUniqueSubmission, self.id)
  end

  def assign_submission(webform_uuid)
    Resque.enqueue(AssignSubmission, self.id, webform_uuid)
  end

  def get_webform_data(webform_uuid)
    Resque.enqueue(GetWebformData, self.id, webform_uuid)
  end

  def delete_member
    Resque.enqueue(DeleteMember, self.id)
  end

  def unblock_member
    Resque.enqueue(UnblockMember, self.id)
  end

  def verify_import_submission(webform_uuid)
    Resque.enqueue(VerifyImportSubmission, self.id, webform_uuid)
  end

  def verify_import_roles
    Resque.enqueue(VerifyImportRoles, self.id)
  end

  def create_submission(webform_uuid)
    Resque.enqueue(CreateSubmission, self.id, webform_uuid)
  end

  def delete_submission(webform_uuid)
    Resque.enqueue(DeleteSubmission, self.id, webform_uuid)
  end
end
