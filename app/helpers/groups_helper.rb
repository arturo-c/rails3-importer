module GroupsHelper
  def export_group_data
    require 'csv'
    CSV.generate do |csv|
      csv << ['uuid', 'name', 'description', 'zip', 'type', 'category', 'groups_above']
      @groups.each do |g|
        csv << [g.uuid, g.name, g.description, g.location['zip'], g.type, g.category ? g.category[0] : '', g.groups_above ? g.groups_above.join(', ') : '']
      end
    end
  end
end
