class ProcessImport
  @queue = :process_import

  def self.perform(admin_id, chunk)
    chunk.each do |c|
      c = process_row(c, admin_id)
      group = Group.where(:uuid => c[:group_uuid]).first if c[:group_uuid]
      group = Group.where(:name => c[:group_name]).first unless c[:group_uuid]
      c[:group_name] = group.name if group
      c[:err] += 'Group not found' unless group
      c[:status] = 'Invalid Data' unless group
    end
    Member.collection.insert(chunk)
  end

  private
  def self.process_row(r, admin_id)
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
      end
      if r[:birthday].is_date?
        today = Date.today
        child = today.prev_year(13)
        if r[:birthday] > child
          errors += 'Parent email is required for child under 13.' unless r[:parent_email]
        end
        r[:birthday] = r[:birthday].to_s
      else
        errors += 'Invalid Date(use format 1985-08-22).'
      end
    end
    r[:roles] = r[:roles].split(",").collect(&:strip) if r[:roles]
    r[:email] = r[:email].gsub(/\s+/, "").strip if r[:email]
    r[:parent_email] = r[:parent_email].gsub(/\s+/, "").strip if r[:parent_email]
    r[:first_name] = r[:first_name].strip if r[:first_name]
    r[:last_name] = r[:last_name].strip if r[:last_name]
    r[:first_name].capitalize! if r[:first_name]
    r[:last_name].capitalize! if r[:last_name]
    errors += 'Missing first name.' unless r[:first_name]
    errors += 'Missing last name.' unless r[:last_name]
    r[:uuid] = r[:uuid].strip if r[:uuid] if r[:uuid]
    r[:err] = errors
    r[:status] = 'Invalid Data' unless errors == ''
    r[:status] = 'Processing' if errors == ''

    return r
  end

end
