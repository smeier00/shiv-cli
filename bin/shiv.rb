#!/usr/bin/env ruby

$:.unshift File.join(File.dirname(__FILE__), '../lib/shiv')

require 'yaml'
require 'getoptlong'
#require 'net/http'
require 'net/https'
require 'rubygems'
require 'json'
require 'uri'
require 'inventory'


@@user = nil
@@password = nil
@@debug = nil
@@host = 'inv.sdsc.edu'
@@port = '3000'
@@ssl = false
@@machine_readable = false

def help_local
#Probably will nuke this at some point, or use for client specific help messages.
    <<EOF

    Available parameters:
        --host <host number>
        --port <port number>
        --user <username>
        --password <password>
        --ssl  Enable SSL

    Available commands:
        listhost,lshost
        listbox,lsbox
        list <type>
        new  <type>
        newhost
        newbox
        showhost
        showbox
        show
        addhosting
        removehosting,delhosting,rmhosting
        addhosttrait,ht,tt
        removehosttrait,delhosttrait,rmhosttrait,rmht,rmtt
        addboxtrait,bt
        removeboxtrait,delboxtrait,rmboxtrait,rmbt
        addhosttag,addhtag,addttag
        removehosttag,delhosttag,rmhosttag,delhtag,rmhtag,rmttag
        addboxtag,addbtag
        removeboxtag,delboxtag,rmboxtag,removebtag,delbtag,rmbtag
        note,notes **
        addnote,addnotes **
        locate **
        available **
        whatsthere
        search
        esearch
        showt **
        ** => not yet implemented
EOF

end
#####

# Parse option parameters
opts = GetoptLong.new(
      [ '--host', '-H', GetoptLong::REQUIRED_ARGUMENT ],
      [ '--port', '-p', GetoptLong::REQUIRED_ARGUMENT ],
      [ '--ssl', '-s', GetoptLong::NO_ARGUMENT ],
      [ '--user', '-U', GetoptLong::REQUIRED_ARGUMENT ],
      [ '--password', '-P', GetoptLong::REQUIRED_ARGUMENT ],
      [ '--machine-readable', '-m', GetoptLong::NO_ARGUMENT ],
      [ '--debug', '-d', GetoptLong::NO_ARGUMENT ]
    )

begin
    opts.each do |opt, arg|
        case opt
            when "--host"
                @@host = arg
            when "--port"
                @@port = arg
            when "--user"
                @@user = arg.to_s.chomp
            when "--password"
                 @@password = arg.to_s.chomp
            when "--ssl"
                 @@ssl = true
            when "--debug"
                @@debug = true
            when "--machine-readable"
                @@machine_readable = true
        end
    end
rescue
    puts help
    exit(1)
end


@@shivurl= @@ssl ? 'https://' + @@host + ':' + @@port : 'http://' + @@host + ':' + @@port
@@test_password = "true" #Testing password option. True allows for "no password" in testing phase.

# Parse command options
opt = ARGV[0] 

if opt.nil? #No options, No service.
  puts help
  exit
end

###TODO, source USERNAME/PASSWORD environment variables
if @@test_password == "false"

  if @@user.nil? or @@password.nil?
    puts "Error: Missing username or password"
    puts help
    exit
  end

end

def separate_args(arguments)
  separate_arguments = Array.new 
  arguments.each do |a|
    a.split.each do |b|
      separate_arguments << b
    end
  end
  return separate_arguments
end

args = ARGV
opt.each do |opt, arg|
      puts opt
     case opt
       when 'showbox'
          ARGV.each do |a|
           @box = ARGV[1] 
          end
          showbox(@box) 
       when 'newbox','nb'
           puts newbox
       when 'listbox','lsbox'
            listbox
       when 'addboxtrait','bt'
           addboxtrait(args)
       when 'removeboxtrait','rmbt'
           removeboxtrait(args)
       when 'addboxtag','addbtag'
           addboxtag(args)
       when 'removeboxtag','rmbtag'
           removeboxtags(args)
       when 'search'
          search_args=separate_args(args)
          search(search_args)
       when 'esearch'
          search_args=separate_args(args)
          puts "esearch #{search_args.inspect}"
          esearch(search_args)
       when 'listhost'
            listhost
       when 'list'
            type = ["esearch","type\=#{args[1]}"]
            search_args = separate_args(type)
            search(search_args)
       when 'listtypes','listtype'
            listtypes
       when 'newhost'
            newhost(args)
       when 'new'
           args.shift
           new(args)
       when 'showhost','show'
            puts showhost(args)
       when 'addhosting'
            addhosting(args) 
       when 'removehosting','rmhosting','delhosting'
            removehosting(args)
       when 'addhosttag','addhtag','addtag'
            addhosttag(args)
       when 'removehosttag','delhosttag','rmhosttag','delhtag','rmhtag','rmtag'
            removehosttag(args)
       when 'addhosttrait','ht','at'
           addhosttrait(args)
       when 'removehosttrait','rmht','delhosttrait','rmt'
            removehosttrait(args)
       when 'showt'
          showt(args)
       when 'whatsthere'
            #puts ShivController.new.shivcmd_WHATSTHERE([args[1]])
            whatsthere(args)
       when 'note'
           note(args)
       when 'addnote'
           addnote(args)
       when 'help'
           help(args)
       else
           help(args)
       end
end
