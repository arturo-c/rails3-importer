module GroupsHelper
  def export_group_data
    require 'csv'
    CSV.generate do |csv|
      csv << ['due date', 'user_uuid', 'user email', 'title', 'uuid', 'group_type', 'category', 'description', 'address_street', 'address_city', 'address_state', 'address_zip', 'group above name', 'group_above', 'group_template', 'payee_uuid', 'status', 'errors']
      @groups.each do |g|
        csv << [g.due_date, g.user_uuid, g.user_email, g.title, g.uuid, g.group_type, g.category, g.description, g.address_street, g.address_city, g.address_state, g.address_zip, g.group_above_name, g.group_above, g.group_template, g.payee, g.status, g.err]
      end
    end
  end
end
