#!/usr/bin/ruby

require 'io/console'

class UserInterface
  attr_accessor :handle, :this_one, :these_lines, :text_area
  
  # use assoc(line number) for line commands
  def user_initiation
#   puts("in user_io")
    @text_area = {}
  end
  # finds non excluded text in the file and excludes it
  def user_exclusion 
#   puts("in user_exclusion")
    @this_one = "Cucumber"
    puts "String to exclude"
    open("/proc/self/fd/0",mode="r") {|d| p d }
#    @this_one = $stdin.gets.chomp 
  end
  # finds text in the file and includes it if excluded
  def user_inclusion 
#   puts("in user_inclusion")
    @these_lines = [9,20]
    open("/proc/self/fd/0",mode="r") {|d| p d }
#    @this_one = $stdin.gets.chomp 
  end
  
  
  def user_display(text_area)
#   puts("in user_display")
    puts"======== ====5====1====5====2====5====3====5====4====5====5====5====6====7====5====8====5====9====5====0====5====1====5====2====5====3=="
    @text_area.each do |line, action|
      if action[0] == "before" 
        puts "-------- -------------------------------------------------------- #{action[1]} lines excluded ---------------------------------------------------"
      end 
      if action[0] == "text" 
        format = "%08d %-80s" % [line, action[1]]
        puts format
      end
      if action[0] == "after" 
        puts "-------- -------------------------------------------------------- #{action[1]} lines excluded ----------------------------------------------------"
      end 
    end 
  end
  
end # class UserInterface