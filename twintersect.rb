#!/usr/bin/env ruby
require 'rubygems'
require 'twitter'
require 'twitter_config'
require 'json'
require 'optparse'

class Twintersect

  attr_reader :users         # The usernames provided as arguments
  attr_reader :cache         # The cache of ids:=>names, loaded from / saved in cache.json
  attr_reader :intersections # All intersections that have been found
  attr_accessor :verbose     # Show verbose output?


  # Initialize
  # @param users[] The array of usernames to intersect
  # @param verbose Boolean declaring whether or not output should be verbose
  # @param cache_file The file where the cache should be loaded from / saved to
  
  def initialize(users = [], verbose = false, cache_file = "cache.json", output_file = "")
    @users = users
    @verbose = verbose
    @cache_file = cache_file
    @output_file = output_file
    
    # We kinda need at least 2 users for this to be worthwhile.
    if (@users.count < 2) then exit; end
        
    # Load up the data into the live cache 
    @cache = Twintersect.load_cache_data @cache_file

    # Load up the users following
    @following = download_following @users
  end


  # analyze() 
  # This the method you will want to call

  def analyze
    # [VERBOSE] #
    if @verbose then
      puts "Checking #{@users.count} users..."
      count = 0
      @users.each do |u|
        puts "#{u}: following #{@following[u].count} users"
        count += 1
      end
    end
    
    # This is run locally, the results are stored in @intersections
    @intersections = Twintersect.find_intersections(@following, @users)
        
    # [VERBOSE] #
    if @verbose then 
      puts "The users have #{@intersections.count} follows in common. Getting names..." 
    end

    # This portion is done via a series of API calls, though the number of 
    # API calls is reduced if some of the IDs exist in the cache. The
    # cache is updated when the script completes.
    intersecting_userlist = []
    @intersections.each do |id|
      intersecting_userlist << get_follower_name(id)
    end

    # [VERBOSE] #
    if @verbose then puts "Common Follows:" end
    
    # At this point, the cache file will be updated with any new id/name
    # pairs discovered. If the script crashes before this, the file should
    # remain intact.
    update_cache

    # Finally, if they provided an output file, dump the results to it    
    if (@output_file.length > 0) then
      dump_to_file intersecting_userlist

    # Otherwise, output the pairings as a JSON array
    else
      puts intersecting_userlist.inspect
    end
    
  end

  private #.,.-=.,.-=.,.-=.,.-=.,.-= No peeking! -=[,,_,,]:3
  
  def download_following users
    following = Hash.new
    users.each do |u|    
      begin
        following[u] = get_follower_ids(u)
      
      # Does that username exist?
      rescue Twitter::Error::NotFound
        if @verbose then puts "(__?){ Unable to find #{u}" end
        
      # OH NOES! TEH FAIL WHALE!
      rescue Twitter::Error::ServiceUnavailable
        abort "(__x){ ServiceUnavailable while attempting to get user IDs"
        if @verbose then puts "(__x){ try again soon. Unable to get user IDs." end
      end
    end
    return following
  end
  
  # load_cache_data(filename)
  # Load the cache data to reduce the number of API calls
  # @private
  # @param filename The filename to use as cache
  # @returns Hash A hash of the cache.
  def self.load_cache_data filename
    if (!File.exists?(filename)) then
      begin
        f = File.new(filename, "w+")
      rescue IOError
        abort "Unable to create file #{filename}"
      end
    else
      begin
        f = File.new(filename, "r") 
      rescue IOError
        abort "Unable to open file #{filename}"
      end
    end
    
    begin
      line = f.gets
    rescue IOError
      abort "Unable to read data from #{filename}."
    end
    
    if (!line.nil?) then
      cache = JSON.parse(line)
    else
      cache = Hash.new
    end
    
    f.close
    
    return cache
  end
  
  def dump_to_file userlist
    output = Hash.new
    output["Users"] = @users
    output["Common"] = userlist
    f = File.new(@output_file,'w')
    f.write output.inspect
    f.close
  end
  
  # get_follower_ids(username)
  # Get a collection of the user IDs followed by username
  # @param username The twitter username, eg. "aaronmhill"
  # @returns Array The collection of ids
  
  def get_follower_ids username
    Twitter.friend_ids(username).collection
  end


  # get_follower_name(id, rescued)
  # Get the name of a follower, based on their ID
  # This WILL make a remote call to the Twitter API if the ID is not
  # in the cache. Twitter rate-limits their API calls, so be aware
  # that rapid execution of the script may stall out at some point.
  # @param id The id of the user to inquire about
  # @param rescued boolean value of whether or not this was already called
  # @returns String the name of the user
  
  def get_follower_name(id, rescued = false)
    # Is the user already in our cache? If not, then ask Twitter.
    if (!@cache.has_key?(id.to_s)) then
      begin
      name = Twitter.user(id).screen_name.to_s
      rescue Twitter::Error::ServiceUnavailable
        # if this is the first attempt for the username, 
        # let the fail whale sleep it off and try one more time.
        if !rescued then
          if @verbose then puts "(__*\"){  Whew! Need a breather." end
          sleep(5)
          get_follower_name(id, true)
        
        # In this case, you might be rate-limited or maybe
        # the fail whale got epically fat and even the african
        # swallows can't carry it. In that case, we'll gracefully
        # update the cache to save our progress and then quit.
        else
          update_cache
          abort "ServiceUnavailable Error: Tried twice. Still whaled."
          if @verbose then puts "(__x){ I tried. [Progress is saved in #{@cache_file}. Try soon!]" end
        end
      end
      
      # Squirrel it away for future use. Note that the file is not updated
      # until update_cache() is called.
      @cache[id] = name
      if (@verbose) then puts "}(.__) -=> #{id} : #{name}" end
      return name
      
    # Hooray! It's already in the cache.
    else
      if (@verbose) then puts ">-+++D -=> #{id} : #{@cache[id.to_s]}" end
      return @cache[id.to_s]
    end
  end
  
  
  # update_cache()
  # Updates the cache file with the current contents of @cache
  
  def update_cache
    f = File.new(@cache_file, "w")
    f.write JSON.generate(@cache)
    f.close
  end

  
  # find_intersections()
  # Determines common IDs among the users provided
  
  def self.find_intersections following, users
    intersections = following[users.first]
    
    following.each do |u,f|
      intersections &= f
    end
    
    # necessary to prevent @cache from becoming ridiculously large
    return intersections.compact
  end


end

# OptParser rules. 'Nuff said.
options = {}
op = OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options] <username> <username2> ... <usernameN>"
  
  options[:verbose] = false
  opts.on('-v', '--verbose', 'Display progress to STDOUT') do
    options[:verbose] = true
  end
  
  options[:cache] = "cache.json"
  opts.on('-c', '--cache FILE', 'Use FILE for caching ids/names') do |cache|
    options[:cache] = cache
  end
  
  options[:output] = ""
  opts.on('-o', '--output FILE', 'Dump JSON array of results to FILE') do |dump|
    options[:output] = dump
  end
  
  opts.on('-h', '--help', 'Display this screen') do
    puts opts
    exit
  end
  
end

if (ARGV.count > 0) then
  op.parse!
  t = Twintersect.new(ARGV,options[:verbose],options[:cache],options[:output])
  t.analyze
end
