desc 'Host related tasks'
#arg_name 'listhosts takes no arguments'
command [:host, :hosts] do |h|

  h.desc 'List all hosts'
  h.command [:all, :list] do |all|
    all.action do |global_options,options,args|
      response = RestClient.get("#{$url}/cli/list_hosts.yaml", {:params => {:auth_token => $token}} )
      puts response
    end
  end

  h.desc 'Add a host - [incomplete]'
  h.arg_name 'hostname'
  h.command [:add, :new] do |add|
    add.action do |global_options,options,args|
      #add a host code here...
    end
  end

  h.desc 'Remove a host'
  h.arg_name 'hostname'
  h.command [:rmhost, :rm] do |rm|
    rm.action do |global_options,options,args|
      help_now!('hostname string is required') if args.empty?
      host_id = ShivHost.get_host_id_from_boxname(args.shift)
      response = RestClient.delete("#{$url}/hosts/#{host_id}.json", {:params => {:auth_token => $token}})
    end
  end


  h.desc 'Show host details'
  h.long_desc 'Show the details of the host.  The host string argument that is
               provided will be used to do a fuzzy search in the database as
               such: LIKE \'%host_string%\'.'
  h.arg_name 'hostname'
  h.command :show do |show|
    show.desc "Show all notes related to the host"
    show.switch [:n, :notes], :negatable => false
    show.action do |global_options,options,args|
      #TODO: add more sanitization of input arguments
      help_now!('host string is required') if args.empty?

      host_id = ShivHost.get_host_id_from_hostname(args.shift)
      params =  "{ :params => { :auth_token => #{$token}}"
      response = JSON.parse(RestClient.get("#{$url}/hosts/#{host_id}.json", {:params => {:auth_token => $token, :notes => options[:n]}}))
      puts response.to_yaml
    end

  end


  h.desc 'Add Host Trait'
  h.arg_name 'hostname trait_name trait_value'
  h.long_desc 'Add a new trait to an existing host.'
  h.command [:addtrait, :ht, :trait] do |ht|
    ht.action do |global_options,options,args|
      # sanitize the args first
      help_now!('host, trait, and value need to be specified.') if args.size != 3
      #TODO: allow traits to be assigned using '='
      # ie. shiv host ht hostname trait_name=value
      #TODO: allow multiple traits to be assigned at once
      # ie. shiv host ht hostname trait1=value1 trait2=value2 trait3=value3

      host_id = ShivHost.get_host_id_from_hostname(args[0])

      url = "#{$url}/hosts/#{host_id}.json"
      payload = { "host" => { "#{args[1]}" => "#{args[2]}" }, :auth_token => $token }.to_json
      response = (RestClient.put url, payload, :content_type => :json)
      puts response.to_str unless response.to_str.empty?
    end
  end

  h.desc 'Remove Host Trait'
  h.arg_name 'hostname trait_name'
  h.long_desc 'Remove a trait from an existing host.'
  h.command [:rmtrait, :rmht] do |rt|
    rt.action do |global_options,options,args|
      help_now!('hostname and trait name need to be specified.') if args.size != 2
      host_id = ShivHost.get_host_id_from_hostname(args[0])

      url = "#{$url}/hosts/#{host_id}.json"
      payload = {"host" => { "#{args[1]}" => nil}, :auth_token => $token}.to_json
      response = (RestClient.put url, payload, :content_type => :json)
      puts response.to_str unless response.to_str.empty?
    end
  end

  h.desc 'Add Host Tag'
  h.arg_name 'hostname tag'
  h.long_desc 'Add a tag to an existing host.'
  h.command [:addtag, :tag] do |tag|
    tag.action do |global_options,options,args|
      help_now!('hostname and tag need to be specified.') if args.size != 2
      host_id = ShivHost.get_host_id_from_hostname(args[0])

      url = "#{$url}/hosts/#{host_id}.json"
      ## Need to get the current tag list and append the new one to it
      ## otherwise, the entire tag list gets rewritten
      payload = {"host" => {"tag" => "#{args[1]}" }, :auth_token => $token}
      response = (RestClient.put url, payload, :content_type => :json)
      puts response.to_str unless response.to_str.empty?
    end
  end

  h.desc 'Remove Host Tag'
  h.arg_name 'hostname tag'
  h.long_desc 'Remove a tag from an existing host.  The tag name needs to be an exact match.'
  h.command [:rmtag, :rtag] do |rtag|
    rtag.action do |global_options,options,args|
      help_now!('hostname and tag need to be specified.') if args.size !=2
      host_id = ShivHost.get_host_id_from_hostname(args[0])

      url = "#{$url}/hosts/#{host_id}.json"
      payload = {"host" => {"rtag" => "#{args[1]}" }, :auth_token => $token}
      response = (RestClient.put url, payload, :content_type => :json)
      puts response.to_str unless response.to_str.empty?
    end
  end

  h.desc 'Add Host Note'
  h.arg_name 'hostname note'
  h.long_desc 'Add a note to an existing host.'
  h.command [:addnote, :note] do |note|
    note.action do |global_options,options,args|
      help_now!('hostname and note need to be specified.') if args.size != 2
      host_id = ShivHost.get_host_id_from_hostname(args[0])

      url = "#{$url}/hosts/#{host_id}.json"
      ## Need to get the current note list and append the new one to it
      ## otherwise, the entire note list gets rewritten
      payload = {"host" => {"note" => "#{args[1]}" }, :auth_token => $token}
      response = (RestClient.put url, payload, :content_type => :json)
      puts response.to_str unless response.to_str.empty?
    end
  end

  h.desc 'Add host to box'
  h.long_desc "Add the specified host to a box using a hosting relationship.
               The specified box essentially hosts the specified hostname.
               This creates a realtionship between a host and it's hardware."
  h.arg_name 'hostname boxname'
  h.command [:addhosting, :hosting] do |hosting|
    hosting.action do |global_options,options,args|
      help_now!('hostname and boxname are both required') if args.size != 2
      host_id = ShivHost.get_host_id_from_hostname(args.shift)
      box_id = get_box_id_from_boxname(args.shift)
      payload = { "host" => { "box_id" => "#{box_id}" }, :auth_token => $token}.to_json
      url = "#{$url}/hosts/#{host_id}.json"
      response = (RestClient.put url, payload, :content_type => :json)
      puts response.to_str unless response.to_str.empty?
    end
  end

  h.desc 'Remove host from box'
  h.long_desc "Remove the specified host from a box by deleting the hosting
               relationship." 
  h.arg_name 'hostname'
  h.command [:rmhosting, :delhosting] do |hosting|
    hosting.action do |global_options,options,args|
      help_now!('hostname is required') if args.size != 1
      host_id = ShivHost.get_host_id_from_hostname(args.shift)
      payload = { "host" => { "box_id" => nil }, :auth_token => $token}.to_json
      url = "#{$url}/hosts/#{host_id}.json"
      response = (RestClient.put url, payload, :content_type => :json)
      puts response.to_str unless response.to_str.empty?
    end
  end

end

# collection of utility methods to use with the host commands
module ShivHost

  # Given a partial or full hostname, search the database for LIKE values
  # If there are multiple choices, present those to the user and let them
  # choose which host they actually meant.
  def ShivHost.get_host_id_from_hostname(hostname)
    url = "#{$url}/cli/searchHost.json"
    results = JSON.parse(RestClient.post url, {:search_text => hostname, :auth_token => $token})
    if results.count == 0
      exit_now!("Could not find a host that matched '#{hostname}'")
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

