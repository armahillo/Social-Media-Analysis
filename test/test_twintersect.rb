#!/usr/bin/ruby

require "test/unit"
require "test/flasher" # makes private methods public for these tests
require "twintersect"

=begin
 Having some issues getting "rake test" to run these correctly. I want to get this initially pushed up to GH so I'm just going to do it now and work on the tests afterwards. (I know, I know, everyone says that and tests never get written.)
=end


class TestTwintersect < Test::Unit::TestCase

INTERSECTIONS = Array[100,102,104]

USERS = Array["Groucho", "Harpo"]
FOLLOWERS = Hash["Groucho" => [100, 101, 102, 103, 104, 105],
             "Harpo" => [100, 102, 104, 106, 108, 110]]

NAMES = Hash[100 => "BadHorse",     101 => "CapnHammer", 
             102 => "Penny",        103 => "Moissst", 
             104 =>"BadHorse",      105 => "PinkPummeler", 
             106 => "MayorMcMayor", 107 => "TheDoctor", 
             108 => "GroupiesThatDoWeirdStuff", 
             109 => "BadCowboys",   110 => "Fred"]

  #TODO
  def test_download_followers
    # need to set up a way to stub the Twitter methods
  end

  def test_load_cache_data 
  puts "FOO"
    filename = "test.json"
    badfile = "nonexist.json"
    Twintersect.publicize_methods do
      file = Twintersect.load_cache_data filename
      assert $!.nil?
      
      bad = Twintersect.load_cache_data badfile
      assert !$!.nil?
    end
  end
  
  def test_find_intersections
     Twintersect.publicize_methods do
       intersections = Twintersect.find_intersections(FOLLOWERS, USERS)
       assert_equal intersections,INTERSECTIONS
     end
  end

  #TODO
  def test_update_cache
  end
  
  #TODO
  def test_get_follower_name
  end

  #TODO
  def test_get_follower_ids
    
  end

  #TODO
  def test_dump_to_file
  end

  #TODO
  def test_exposure

  end

  
end
