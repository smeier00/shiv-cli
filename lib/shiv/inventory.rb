#!/usr/bin/ruby

#Call with ../script/runner
require 'yaml'
require 'getoptlong'
#require 'net/http'
#require 'net/https'
require 'rubygems'
require 'json'
require 'uri'
require 'cgi'

#####HTTP Stuff ########
def post(ws,data)
    #data is expected to be 'json' 
    #ws WebService URL
     req = Net::HTTP::Post.new(ws, initheader = {'Content-Type' =>'application/json'})
          req.basic_auth @@user, @@password
          req.body = data
          uri = URI.parse("#{@@shivurl}#{ws}")
          #response = Net::HTTP.new(uri.host, uri.port).start {|http| http.request(req) }
           http = Net::HTTP.new(uri.host, uri.port)
           http.use_ssl = true if @@ssl
           http.verify_mode = OpenSSL::SSL::VERIFY_NONE if @@ssl
           response = http.request(req)
          #puts "Response #{response.code} #{response.message}:
          #{response.body}"
          @response = response.body
          return response.body
end

def get(ws)
  #ws = webservice url
  #ws = "/inv/showbox?name=CM000001&format=json"
  #uri = URI.parse("http://localhost:3000/inv/listbox?format=json")
  uri = URI.parse("#{@@shivurl}#{ws}")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true if @@ssl
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE if @@ssl
  request = Net::HTTP::Get.new(uri.request_uri)
  request.basic_auth @@user.to_s, @@password.to_s #unless @@user.nil? and @@password.nil? #Skip if no username/password set for apps that don't have auth (ex. tape tracker)
  response = http.request(request)
  #puts response.code             # => 301
  #puts response.body             # => The body (HTML, XML, blob, whatever)
  if response.code == '200'
    return response.body
  else
    return JSON.generate({ 'error' => { 'response_code' => response.code} })
  end
end
########## Box commands #############

def showbox(args)
   if args.nil?
     puts help
     exit
   end
   ws = "/inv/showbox?name=#{args}&format=json"
   result = get(ws)
   if @@machine_readable then
       puts result
   else 
       puts JSON.parse(result).to_yaml
   end
end

def newbox
  ws = "/inv/newbox?format=json"
  payload ={
    "commit" => "Submit"
  }.to_json
  return JSON.parse(post(ws,payload)).to_yaml
end

def listbox
  #ShivController.new.shivcmd_LISTBOX
  ws = "/inv/listbox?format=json"
  result = get(ws)
  if @@machine_readable then
    puts result
  else
    puts JSON.parse(result).to_yaml
  end
end

#b.addboxtrait(["CM000001", "vendor=Dell"])
def addboxtrait(args)
  ws = "/inv/addboxtrait"
  payload ={
    "box" => args[1],
    "trait" => args[2],
    "commit" => "Submit"
  }.to_json

  post(ws,payload)
end

def addboxtag(args)
  ws = "/inv/addboxtag"
  payload ={
    "box" => args[1],
    "tag" => args[2],
    "commit" => "Submit"
  }.to_json

  post(ws,payload)

end

def removeboxtrait(args)
   ws = "/inv/removeboxtrait"
   payload ={
     "box" => args[1],
     "trait" => args[2],
     "commit" => "Submit"
   }.to_json

  post(ws,payload)

end

def removeboxtags(args)
   ws = "/inv/removeboxtag"
  payload ={
    "box" => args[1],
    "tag" => args[2],
    "commit" => "Submit"
  }.to_json

  post(ws,payload)
 
  
end

#Add hosting

def addhosting(args)
#h.addhosting(["test2.sdsc.edu","CM000001"])
 ws = "/inv/addhosting"
 payload ={
    "host" => args[1],
    "box" => args[2],
    "commit" => "Submit"
  }.to_json

  post(ws,payload)

end

def addlink(args)
 ws = "/inv/addlink"
 payload ={
    "obj1" => args[1],
    "obj2" => args[2],
    "commit" => "Submit"
  }.to_json

  post(ws,payload)

end

def removelink(args)
 ws = "/inv/removelink"
 payload ={
    "obj1" => args[1],
    "obj2" => args[2],
    "commit" => "Submit"
  }.to_json

  post(ws,payload)

end

def removehosting(args)
#h.removehosting(["test2.sdsc.edu","CM000001"])
  ws = "/inv/removehosting"
 payload ={
    "host" => args[1],
    "box" => args[2],
    "commit" => "Submit"
  }.to_json
 
  post(ws,payload)

end

#################Host##################

def listhost
   #ShivController.new.shivcmd_LISTHOST
   ws = "/inv/listhost?format=json"
   result = get(ws)
   if @@machine_readable then
     puts result
   else
     puts JSON.parse(result).to_yaml
   end
end

def listtypes
  ws = "/inv/listtypes?format=json"
  result = get(ws)
   if @@machine_readable then
     puts result
   else
     puts JSON.parse(result).to_yaml
   end
end

def newhost(args)
 #ShivController.new.shivcmd_NEWHOST([args])
 tmp = ["filler",args[1],"type\=host"]
 ws = "/inv/newhost"
 payload ={
    "name" => args[1],
    "traits" => args.slice(2, args.size - 2),
    "commit" => "Submit"
  }.to_json

  post(ws,payload)
  # addhosttrait(tmp)
end

def new(args)
 #Call new host
 #Call addhosttrait and set <obj_name> type=<type>
 #Arg[0] => type
 #Arg[1] => obj_name
 #  tmp = ["filler",args[1],"type\=#{args[0]}"]
  newhost(args)
 # addhosttrait(tmp)
end

def showhost(args)
  #h.showhost(["test2.sdsc.edu"])
  #ShivController.new.shivcmd_SHOWHOST([args[1]])
  host = CGI.escape(args[1])
  if host.nil?
    puts help
    exit
  end
  ws = "/inv/showhost?name=#{host}&format=json"
  response = get(ws)
  if @@machine_readable then
    return response
  else
    return JSON.parse(response).to_yaml
  end
end

def addhosttag(args)
#h.addhosttag(["test3.sdsc.edu", "consumes:service:samqfs:/archive/science"])
  ws = "/inv/addhosttag"
  payload ={
    "host" => args[1],
    "tag" => args[2],
    "commit" => "Submit"
  }.to_json

  post(ws,payload)

end

def removehosttag(args)
#h.removehosttag(["test3.sdsc.edu", "consumes:service:samqfs:/archive/science"])
   ws = "/inv/removehosttag"
  payload ={
    "host" => args[1],
    "tag" => args[2],
    "commit" => "Submit"
  }.to_json

  post(ws,payload)
 
end

def removehosttrait(args)
  ws = "/inv/removehosttrait"
  payload ={
    "host" => args[1],
    "trait" => args[2],
    "commit" => "Submit"
  }.to_json
  post(ws,payload)
end

def addhosttrait(args)
  ws = "/inv/addhosttrait"
  payload ={
    "host" => args[1],
    "trait" => args[2],
    "commit" => "Submit"
  }.to_json
  post(ws,payload)
end

def delete(args)
  ws = "/inv/delete"
  payload ={
	"name" => args[1]
  }.to_json
  post(ws,payload)
end


########Search###############
def esearch(args)
  args.delete_at(0)
  search_params = ''
  args.each do |a|
    search_params += 'search_text[]=' + a + '&'
  end
  ws="/inv/search?extended=true&#{search_params}format=json"
  result=get(ws)
  if @@machine_readable then
    puts result
  else
    #puts JSON.parse(result)
    puts JSON.parse(result).to_yaml
  end
end

def search(args)
  args.delete_at(0)
  search_params = ''
  args.each do |a|
    search_params += 'search_text[]=' + a + '&'
  end
  ws="/inv/search?#{search_params}format=json"
  result=get(ws)
  if @@machine_readable then
    puts result
  else
    #puts JSON.parse(result)
    puts JSON.parse(result).to_yaml
  end
end
#####################################

####showt
def showt(args)
  #ShivController.new.shivcmd_SHOWT(args)
  puts "TODO: showt still needs to be implemented"
end

def whatsthere(args)
 #ShivController.new.shivcmd_WHATSTHERE([args[1]])
 ws = "/inv/whatsthere?search_text=#{args[1]}&format=json"
 result=get(ws)
 if @@machine_readable then
   puts result.to_yaml
 else
   puts result.to_yaml
 end
end

def note(args)
 #ShivController.new.shivcmd_WHATSTHERE([args[1]])
 ws = "/inv/note?search_text=#{args[1]}&format=json"
 result=get(ws)
 if @@machine_readable then
   puts result
 else
   #puts JSON.parse(result).to_yaml
   puts result
 end
end

def addnote(args)
  ws = "/inv/addnote"
  payload ={
    "host" => args[1],
    "note" => args[2],
    "commit" => "Submit"
  }.to_json

  post(ws,payload)

end

def help(args)

  ws = "/inv/help?search_text=#{args[1]}&format=json"
  result=get(ws)
  puts result
end
#######
