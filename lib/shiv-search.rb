desc 'Search related tasks'

command [:search, :searches] do |s|

  s.desc 'search'
  s.arg_name 'search'
  s.command [:search] do |search|
  search.action do |global_options,options,args|
      help_now!('search string is required') if args.empty?
      #host_id = ShivHost.get_host_id_from_hostname(args.shift)
      search_text = args[0]
      payload = { "search_text" => search_text, :auth_token => $token}.to_json
      url = "#{$url}/search.json"
      response = (RestClient.post url, payload, :content_type => :json)
  end
