module GroupsHelper
  def export_group_data
    require 'csv'
    CSV.generate do |csv|
      csv << ['status', 'errors', 'uuid', 'title', 'description', 'address_street', 'address_city', 'address_state', 'address_zip', 'group_type', 'category', 'group_above', 'group_template', 'payee_uuid', 'user_uuid', 'due date', 'user email', 'group above name']
      @groups.each do |g|
        csv << [g.status, g.err, g.uuid, g.title, g.description, g.address_street, g.address_city, g.address_state, g.address_zip, g.group_type, g.category, g.group_above, g.group_template, g.payee, g.user_uuid, g.due_date, g.user_email, g.group_above_name]
      end
    end
  end
end
