class ProcessImport
  @queue = :process_import

  def self.perform(admin_id, chunk)
    chunk.collect! { |c|
      #c = self.process_import(c, admin_id)
      #webform_data = Webform.where(:uuid => webform_uuid).first.data
      #data = {}
      #webform_data.each do |cid, name|
      #data.merge!(cid => c[name.parameterize.underscore.to_sym]) if c.has_key?(name.parameterize.underscore.to_sym)
      #data.merge!(cid => nil) if !c.has_key?(name.parameterize.underscore.to_sym)
      #end
      c = self.process_import(c, admin_id)
      group = Group.where(:uuid => c['group_uuid']).first if c['group_uuid']
      group = Group.where(:title_lower => c['title'].to_s.strip.downcase).first if (!c['group_uuid'] && c['title'])
      c['group_uuid'] = group.uuid if group
      c['title'] = group.title.to_s if group
      c['status'] = 'Group Not Found' unless group
      if c['_id']
        member = Member.find(c['_id'])
        unless member.nil?
          r = c.to_hash.with_indifferent_access.symbolize_keys
          member.update_attributes(member.attributes.merge(r))
          member.save
          c = nil
        end
      end
      c
    }
    Member.collection.insert(chunk) if chunk.length > 0
  end

  def self.process_import(r, admin_id)
    admin = Admin.find(admin_id)
    r['admin_uuid'] = admin.uuid
    r['status'] = 'Processing'
    errors = ''
    if r['gender']
      r['gender'] = r['gender'].downcase
      r['gender'] = 'm' if r['gender'].casecmp('male') == 0
      r['gender'] = 'f' if r['gender'].casecmp('female') == 0
      unless r['gender'] == 'm' || r['gender'] == 'f'
        errors += 'Invalid Gender(enter m or f).'
      end
    end
    if r['birthday']
      begin
        if r['birthday'].include? "/"
          d = r['birthday'].split("/")
          if d[2].length == 2
            year = d[2]
            y = '20' + year if year < '15'
            y = "19" + year if year > '14'
            d[2] = y
            r['birthday'] = Date.strptime(d.join('/'), "%m/%d/%Y")
          else
            r['birthday'] = Date.strptime(r['birthday'], "%m/%d/%Y")
          end
        else
          r['birthday'] = Date.parse(r['birthday'])
        end
      rescue
        errors += 'Invalid Date(use format 1985-08-22).'
      else
        today = Date.today
        child = today.prev_year(13)
        if r['birthday'] > child
          errors += 'Parent email is required for child under 13.' unless r['parent_email']
        end
        r['birthday'] = r['birthday'].to_s
      end
    end
    if r['join_date']
      begin
        if r['join_date'].include? "/"
          r['join_date'] = Date.strptime(r['join_date'], "%m/%d/%Y")
        else
          r['join_date'] = Date.parse(r['join_date'])
        end
      rescue
        errors += 'Invalid date for join date'
      end
      r['join_date'] = r['join_date'].to_s
    end
    if r['roles']
      roles = r['roles'].split(",").collect(&:strip) unless r['roles'].kind_of? Hash
      flags = r['flags'].split(",").collect(&:strip) if r['flags']
      r['roles'] = Hash.new
      roles.each do |role|
        r['roles'][role] = '' if flags.nil?
        r['roles'][role] = flags.shift unless flags.nil?
      end
    end
    if r['email']
      r['email_'] = r['email'].strip.downcase
    end
    if r['parent_email']
      r['parent_email_'] = r['parent_email'].strip.downcase
    end
    if r['first_name']
      r['first_name_'] = r['first_name'].strip.downcase
    else
      errors += 'Missing first name.'
    end
    if r['last_name']
      r['last_name_'] = r['last_name'].strip.downcase
    else
      errors += 'Missing last name.'
    end
    r['uuid'] = r['uuid'].strip if r['uuid']
    r['err'] = errors
    r['status'] = 'Invalid Data' unless errors == ''

    r['data_fields'] = Hash.new
    r.map do |key, value|
      if key.include? 'webform_'
        v = key.split 'webform_'
        admin.webform_fields.each do |k, s|
          if s.parameterize.underscore == v[1].parameterize.underscore
            r['data_fields'][k] = value
          end
        end
        r.delete(key)
      end
    end
    return r
  end

end
