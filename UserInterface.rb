#!/usr/bin/ruby

require './FileManager.rb'

class UserInterface

  def user_options(text_area)
    puts <<-DELIMITER
    1. Include additional search pattern
    2. Delete all excluded text
    3. Delete all not excluded text\n
      DELIMITER
    ARGF.each do |selection|
      selection.chomp!             
  
      case selection
        when "1"
          @file_processor = FileManager.new
          current_file = @file_processor.send(:file_history_current)                      # get the current file as it closed 
          arguements = [current_file, "exclude"]
          @file_processor = FileManager.new
          @file_processor.send(:file_open, *arguements)                                   # reopen it  
        when "2"
          @file_processor = FileManager.new
          current_file = @file_processor.send(:file_history_current)                      # get the current file
          arguements = [current_file, "deletex"]                                          # delete all excluded lines
          @file_processor = FileManager.new
          @file_processor.send(:file_open, *arguements)                                   # reopen it
        when "3"
          @file_processor = FileManager.new
          current_file = @file_processor.send(:file_history_current)                      # get the current file
          arguements = [current_file, "deletenx"]                                         # delete all not excluded lines
          @file_processor = FileManager.new
          @file_processor.send(:file_open, *arguements)                                   # reopen it
          else
        puts("Exiting")
        exit
      end
    end
  end
  
  # use assoc(line number) for line commands
  def user_file?
    puts "File to open /home/brad/git/Ringer/testdata.rb or other:\n"    
    ARGF.each do |file|
      file.chomp!
      file = "/home/brad/git/Ringer/testdata.rb" if file == "" || file == nil          # default for development
      arguements = [file, "initial"]
      @file_processor = FileManager.new
      @file_processor.send(:file_open, *arguements) 
    end
   end
   
   # what do you what to look for?
   def user_exclude?(text_lines) 
     puts "Pattern to find in a line:\n "
     ARGF.each do |pattern|
       pattern.chomp!
       pattern = 'if /#{Regexp.escape(exclude)}/.match(text)' if pattern == ""          # default for development
       # save this search pattern the next unused search history entry
       search_history = $search_history.to_h
       search_history.each_pair do |index, search_pattern|
         if search_pattern == ""
           search_pattern = pattern
           $search_history["#{index}"] = "#{search_pattern}"
           break
         end
       end
       @text_processor = TextProcessor.new
       @text_processor.send(:text_exclude, pattern, text_lines)
     end
  end
    
  def user_display(text_area)
    puts"======== ====5====1====5====2====5====3====5====4====5====5====5====6====5====7====5====8====5====9====5====0====5====1====5====2====5=="
    text_area.each do |line, action|
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
    user_options(text_area)
  end

end # class UserInterface