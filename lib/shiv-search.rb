desc 'Search related tasks'

command [:search] do |s|

  s.desc 'string'
  s.arg_name 'all'
  s.command [:all] do |search|
    search.action do |global_options,options,args|
      help_now!('search string is required') if args.empty?
      search_text = args[0]
      payload = { "search_text" => search_text, :auth_token => $token}.to_json
      url = "#{$url}/cli/searchAll.json"
      response = JSON.parse((RestClient.post url, payload, :content_type => :json))
      if $format == 'yaml'
        puts response.to_yaml
      elsif $format == 'json'
        puts response.to_json
      else
        puts response.to_yaml
      end
    end
  end


  s.desc 'var=val'
  s.arg_name 'var=val'
  s.command [:trait] do |trait_search|
    trait_search.action do |global_options,options,args|

      help_now!('search string is required') if args.empty?
      search_text = args[0]
      if ShivHost.validtrait?(search_text)
        payload = { "search_text" => search_text, :auth_token => $token}.to_json
        url = "#{$url}/cli/searchTrait.json"
        response = JSON.parse((RestClient.post url, payload, :content_type => :json))
        if $format == 'yaml'
          puts response.to_yaml
        elsif $format == 'json'
          puts response.to_json
        else
          puts response.to_yaml
        end
      else
        help_now!("Invalid trait found: #{search_text}   Valid trait: foo=bar")
      end
    end
  end


end
