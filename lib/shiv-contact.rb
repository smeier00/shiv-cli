################################################################################
#                                                                              #
# Contact Related Tasks                                                        #
#                                                                              #
################################################################################

desc 'Contact related tasks'
command [:contact, :contacts] do |c|

  c.desc 'List all contacts'
  c.command :all do |all|
    all.action do
      response = RestClient.get("#{$url}/cli/list_contacts.yaml", {:params => {:auth_token => $token}} )
      puts response.to_str
    end
  end

  c.desc 'Add a new contact'
  c.command [:add, :new] do |add|
    add.action do
      #TODO: add flags for each key/value pair to avoid prompts
      contact = Hash.new
      contact[:email] = ask("Email Address?  ")
      contact[:first_name] = ask("First Name?  ").capitalize
      contact[:last_name] = ask("Last Name?  ").capitalize
      contact[:phone] = ask("Phone Number?  ")

      payload = { "contact" => contact, :auth_token => $token}.to_json
      url = "#{$url}/contacts.json"
      response = (RestClient.post url, payload, :content_type => :json)
      case response.code
      when 200..299
        puts "Created #{JSON.parse(response)['email']}"
      else
        puts "Failed to create new contact!"
      end
    end
  end


  c.desc 'Show contact details'
  c.long_desc 'Show the details of the contact.  The contact string argument that is
               provided will be used to do a fuzzy search in the database as
               such: LIKE \'%email_string%\'.'
  c.arg_name 'email_address'
  c.command :show do |show|
    show.desc "Show all notes related to the host"
    show.switch [:n, :notes], :negatable => false
    show.action do |global_options,options,args|
      #TODO: add more sanitization of input arguments
      help_now!('email address is required') if args.empty?

      contact_id = ShivContact.get_contact_id_from_email(args.shift)
      params =  "{ :params => { :auth_token => #{$token}}"
      response = JSON.parse(RestClient.get("#{$url}/contacts/#{contact_id}.json", {:params => {:auth_token => $token, :notes => options[:n]}}))
      puts response.to_yaml
    end

  end


  c.desc 'Add Contact Trait'
  c.arg_name 'email_address trait_name trait_value'
  c.long_desc 'Add a new trait or update an existing trait for an existing contact.'
  c.command [:addtrait, :trait] do |ht|
    ht.action do |global_options,options,args|
      # sanitize the args first
      help_now!('email address, trait, and value need to be specified.') if args.size != 3
      #TODO: allow traits to be assigned using '='
      # ie. shiv host ht hostname trait_name=value
      #TODO: allow multiple traits to be assigned at once
      # ie. shiv host ht hostname trait1=value1 trait2=value2 trait3=value3

      contact_id = ShivContact.get_contact_id_from_email(args.shift)

      url = "#{$url}/contacts/#{contact_id}.json"
      payload = { "contact" => { "#{args[0]}" => "#{args[1]}" }, :auth_token => $token }.to_json
      response = (RestClient.put url, payload, :content_type => :json)
      puts response.to_str unless response.to_str.empty?
    end
  end

  c.desc 'Remove Host Trait'
  c.arg_name 'email_address trait_name'
  c.long_desc 'Remove a trait from an existing host.'
  c.command [:rmtrait, :rt] do |rt|
    rt.action do |global_options,options,args|
      help_now!('email_address and trait name need to be specified.') if args.size != 2
      contact_id = ShivContact.get_contact_id_from_email(args.shift)

      url = "#{$url}/contacts/#{contact_id}.json"
      payload = {"contact" => { "#{args[0]}" => nil}, :auth_token => $token}.to_json
      response = (RestClient.put url, payload, :content_type => :json)
      puts response.to_str unless response.to_str.empty?
    end
  end


end

module ShivContact

  # Given a partial or full hostname, search the database for LIKE values
  # If there are multiple choices, present those to the user and let them
  # choose which host they actually meant.
  def ShivContact.get_contact_id_from_email(email)
    url = "#{$url}/cli/searchContact.json"
    results = JSON.parse(RestClient.post url, {:search_text => email, :auth_token => $token})
    if results.count == 0
      exit_now!("Could not find a contact that matched '#{email}'")
    elsif results.count > 1
      results.each_with_index do |r, index|
        puts "#{index}  - #{r["email"]}"
      end
      puts "Found multiple matches: please choose one... "
      json_index = ask("Which?   ", Integer) { |q| q.in = 0...results.size }
    end

    results[json_index ? json_index : 0]['id']

  end
end
