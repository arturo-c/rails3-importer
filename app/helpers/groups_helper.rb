module GroupsHelper
  def export_group_data
    require 'csv'
    CSV.generate do |csv|
      csv << ['uuid', 'name', 'nid', 'description', 'zip', 'type', 'category', 'groups_above']
      @groups.each do |g|
        csv << [g.uuid, g.name, g.nid, g.description, g.location ? g.location['zip'] : '', g.type, g.category ? g.category[0] : '', g.group_above]
      end
    end
  end
end
