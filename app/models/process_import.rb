class ProcessImport
  @queue = :process_import

  def self.perform(admin_id, chunk)
    chunk.collect! { |c|
      group = Group.where(:name => c['group_name']).first
      c = process_import(c, admin_id)
      c
      #group = Group.where(:uuid => c[:group_uuid]).first if (c[:group_uuid] && !c[:group_uuid].empty?)
      #c[:group_name] = group.name if group
      #c[:group_uuid] = group.uuid if group
      #c[:err] = c.to_yaml unless group
      #c[:status] = 'Invalid Data' unless group
    }
    Member.collection.insert(chunk)
  end

  def self.process_import(r, admin_id)
    admin = Admin.find(admin_id)
    r[:admin_uuid] = admin.uuid
    r[:status] = 'Processing'
    errors = ''
    if r[:gender]
      r[:gender] = r[:gender].downcase
      r[:gender] = 'm' if r[:gender].casecmp('male') == 0
      r[:gender] = 'f' if r[:gender].casecmp('female') == 0
      unless r[:gender] == 'm' || r[:gender] == 'f'
        errors += 'Invalid Gender(enter m or f).'
      end
    end
    if r[:birthday]
      begin
        if r[:birthday].include? "/"
          d = r[:birthday].split("/")
          if d[2].length == 2
            year = d[2]
            y = '20' + year if year < '15'
            y = "19" + year if year > '14'
            d[2] = y
            r[:birthday] = Date.strptime(d.join('/'), "%m/%d/%Y")
          else
            r[:birthday] = Date.strptime(r[:birthday], "%m/%d/%Y")
          end
        else
          r[:birthday] = Date.parse(r[:birthday])
        end
      rescue
        errors += 'Invalid Date(use format 1985-08-22).'
      else
        today = Date.today
        child = today.prev_year(13)
        if r[:birthday] > child
          errors += 'Parent email is required for child under 13.' unless r[:parent_email]
        end
        r[:birthday] = r[:birthday].to_s
      end
    end
    r[:roles] = r[:roles].split(",").collect(&:strip) if r[:roles]
    r[:email] = r[:email].gsub(/\s+/, "").strip if r[:email]
    r[:parent_email] = r[:parent_email].gsub(/\s+/, "").strip if r[:parent_email]
    r[:first_name] = r[:first_name].strip.capitalize! if r[:first_name]
    r[:last_name] = r[:last_name].strip.capitalize! if r[:last_name]
    r[:uuid] = r[:uuid].strip if r[:uuid]
    r[:err] = errors
    r[:status] = 'Invalid Data' unless errors == ''
    r[:status] = 'Processing' if errors == ''

    return r
  end

end
