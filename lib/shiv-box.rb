################################################################################
#                                                                              #
# Box Related Tasks                                                            #
#                                                                              #
################################################################################

desc 'Box related tasks'
command [:box, :boxes] do |b|

  b.desc 'List all boxes'
  b.command :all do |all|
    all.action do
      #TODO: add --where flag to add search terms
      response = RestClient.get("#{$url}/cli/list_boxes.yaml", {:params => {:auth_token => $token}} )
      puts response.to_str
    end
  end

  b.desc 'Add a new box'
  b.command [:add, :new] do |add|
    add.action do
      box = Hash.new
      box[:vendor] = ask("Vendor?  ").capitalize
      box[:model] = ask("Model?  ").upcase
      box[:serial] = ask("Serial Number?  ").upcase
      box[:purchase_date] = ask("Purchase Date?  ", Date){ |q| q.default = Date.today.to_s}
      box[:location] = ask("Location? [format: SDSC_WEST:Z39:u15] ")

      payload = { "box" => box, :auth_token => $token}.to_json
      url = "#{$url}/boxes.json"
      response = (RestClient.post url, payload, :content_type => :json)
      case response.code
      when 200..299
        puts "Created #{JSON.parse(response)['name']}"
      else
        puts 'Failed to create new box!'
      end
    end
  end

  b.desc 'Remove a box'
  b.long_desc "Permanently removes the box"
  b.arg_name 'boxname'
  b.command [:rmbox, :rm] do |rm|
    rm.action do |global_options,options,args|
      help_now!('boxname string is required') if args.empty?
      box_id = ShivBox.get_box_id_from_boxname(args.shift)
      response = RestClient.delete("#{$url}/boxes/#{box_id}.json", {:params => {:auth_token => $token}})
    end
  end


  b.desc 'Show box details'
  b.long_desc "Show the details of the box.  The box string argument that is provided will be used
               to do a fuzzy search in the database as such: LIKE '%box_string%'."
  b.arg_name 'boxname'
  b.command :show do |show|
    show.desc "Show all notes related to the box"
    show.switch [:n, :notes], :negatable => false
    show.action do |global_options,options,args|
      #TODO: add more sanitization of input arguments
      help_now!('box string is required') if args.empty?

      box_id = ShivBox.get_box_id_from_boxname(args.shift)
      response = JSON.parse(RestClient.get("#{$url}/boxes/#{box_id}.json", {:params => {:auth_token => $token, :notes => options[:n]}}))
      puts response.to_yaml
    end

  end

  b.desc 'Add host to box'
  b.long_desc "Add the specified host to a box using a
               hosting relationship.  The specified box essentially hosts the specified
               hostname.  This creates a realtionship between a host and it's hardware."
  b.arg_name 'boxname hostname'
  b.command [:addhosting, :hosting] do |hosting|
    hosting.action do |global_options,options,args|
      help_now!('boxname and hostname are both required') if args.size != 2
      box_id = ShivBox.get_box_id_from_boxname(args.shift)
      host_id = ShivHost.get_host_id_from_hostname(args.shift)
      payload = { "host" => { "box_id" => "#{box_id}" }, :auth_token => $token}.to_json
      url = "#{$url}/hosts/#{host_id}.json"
      response = (RestClient.put url, payload, :content_type => :json)
      puts response.to_str unless response.to_str.empty?
    end
  end

  b.desc 'Remove host from box'
  b.long_desc "Remove the hosting relationship between a host and the specified box"
  b.arg_name 'boxname hostname'
  b.command [:rmhosting, :rhosting] do |rh|
    rh.action do |global_options,options,args|
      help_now!('boxname and hostname are both required') if args.size != 2
      box_id = ShivBox.get_box_id_from_boxname(args.shift)
      help_now!('box could not be found!') if box_id.nil?

      host_id = ShivHost.get_host_id_from_hostname(args.shift)
      help_now!('host could not be found!') if host_id.nil?

      payload = { "host" => { "box_id" => nil }, :auth_token => $token}.to_json
      url = "#{$url}/hosts/#{host_id}.json"
      response = (RestClient.put url, payload, :content_type => :json)
      puts response.to_str unless response.to_str.empty?
    end
  end

  b.desc 'Add Box Trait'
  b.arg_name 'boxname trait_name trait_value'
  b.long_desc 'Add a new trait to an existing box.'
  b.command [:addtrait, :bt, :trait] do |bt|
    bt.action do |global_options,options,args|
      # sanitize the args first
      help_now!('box, trait, and value need to be specified.') if args.size != 3
      #TODO: allow traits to be assigned using '='
      # ie. shiv host ht boxname trait_name=value
      #TODO: allow multiple traits to be assigned at once
      # ie. shiv host ht boxname trait1=value1 trait2=value2 trait3=value3

      box_id = ShivBox.get_box_id_from_boxname(args[0])

      url = "#{$url}/boxes/#{box_id}.json"
      payload = { "box" => { "#{args[1]}" => "#{args[2]}" }, :auth_token => $token }.to_json
      response = (RestClient.put url, payload, :content_type => :json)
      puts response.to_str unless response.to_str.empty?
    end
  end

  b.desc 'Remove Box Trait'
  b.arg_name 'boxname trait_name'
  b.long_desc 'Remove a trait from an existing box.'
  b.command [:rmtrait, :rmbt, :rt] do |rt|
    rt.action do |global_options,options,args|
      help_now!('boxname and trait name need to be specified.') if args.size != 2
      box_id = ShivBox.get_box_id_from_boxname(args[0])

      url = "#{$url}/boxes/#{box_id}.json"
      payload = {"box" => { "#{args[1]}" => nil}, :auth_token => $token}.to_json
      response = (RestClient.put url, payload, :content_type => :json)
      puts response.to_str unless response.to_str.empty?
    end
  end

  b.desc 'Add Box Tag'
  b.arg_name 'boxname tag'
  b.long_desc 'Add a tag to an existing box.'
  b.command [:addtag, :tag] do |tag|
    tag.action do |global_options,options,args|
      help_now!('boxname and tag need to be specified.') if args.size != 2
      box_id = ShivBox.get_box_id_from_boxname(args[0])

      url = "#{$url}/boxes/#{box_id}.json"
      ## Need to get the current tag list and append the new one to it
      ## otherwise, the entire tag list gets rewritten
      payload = {"box" => {"tag" => "#{args[1]}" }, :auth_token => $token}
      response = (RestClient.put url, payload, :content_type => :json)
      puts response.to_str unless response.to_str.empty?
    end
  end

  b.desc 'Remove Box Tag'
  b.arg_name 'boxname tag'
  b.long_desc 'Remove a tag from an existing box.  The tag name needs to be an exact match.'
  b.command [:rmtag, :rtag] do |rtag|
    rtag.action do |global_options,options,args|
      help_now!('boxname and tag need to be specified.') if args.size !=2
      box_id = ShivBox.get_box_id_from_boxname(args[0])

      url = "#{$url}/boxes/#{box_id}.json"
      payload = {"box" => {"rtag" => "#{args[1]}" }, :auth_token => $token}
      response = (RestClient.put url, payload, :content_type => :json)
      puts response.to_str unless response.to_str.empty?
    end
  end

  b.desc 'Add Box Note'
  b.arg_name 'boxname note'
  b.long_desc 'Add a note to an existing host.'
  b.command [:addnote, :note] do |note|
    note.action do |global_options,options,args|
      help_now!('boxname and note need to be specified.') if args.size != 2
      box_id = ShivBox.get_box_id_from_boxname(args[0])

      url = "#{$url}/boxes/#{box_id}.json"
      ## Need to get the current note list and append the new one to it
      ## otherwise, the entire note list gets rewritten
      payload = {"box" => {"note" => "#{args[1]}" }, :auth_token => $token}
      response = (RestClient.put url, payload, :content_type => :json)
      puts response.to_str unless response.to_str.empty?
    end
  end


end

module ShivBox

  # Given a partial or full box name, search the database for LIKE values
  # If there are multiple choices, present those to the user and let them
  # choose which box they actually meant.
  def ShivBox.get_box_id_from_boxname(boxname)
    url = "#{$url}/cli/searchBox.json"
    results = JSON.parse(RestClient.post url, {:search_text => boxname, :auth_token => $token})
    if results.count == 0
      exit_now!("Could not find a box that matched '#{boxname}'")
    elsif results.count > 1
      results.each_with_index do |r, index|
        puts "#{index}  - #{r["name"]}"
      end
      puts "Found multiple matches: please choose one... "
      json_index = ask("Which?   ", Integer) { |q| q.in = 0...results.size }
    end

    results[json_index ? json_index : 0]['id']

  end

end
