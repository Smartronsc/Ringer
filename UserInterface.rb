
class UserInterface

  # use assoc(line number) for line commands
  def initialize
    @file_manager   = FileManager.new 
    @text_processor = TextProcessor.new
  end
  
  def user_file
    @file_manager.send(:file_get_information) 
    puts "File to open or enter to select from file system:\n" 
    ARGF.each_line do |file|
      @file = file.chomp!  
#      user_selection if @file == "" 
      @file = "/home/brad/git/Ringer/testdata.rb" if file == ""           
      @file_manager.send(:file_history_push, @file)                           # store it for UserInterface class 
      break                                                                   # just one file at a time for now
   end
    user_pattern                                                              # update search_history
    arguments = [@file]
    text_lines = @file_manager.send(:file_open, *arguments)                   # initial open
    @text_processor.send(:text_exclude, text_lines)                           # initial exclude                                              
  end
  
  def user_options(text_area)
    puts <<-DELIMITER
    1. Include additional search pattern
    2. Delete all excluded text
    3. Delete all not excluded text
    4. Write to file\n
      DELIMITER
    ARGF.each do |selection|
      @selection = selection.chomp!                                                           
      break
    end
    case @selection
      when "1"
        user_pattern                                                           # update search_history 
        current_file = @file_manager.send(:file_history_current)               # get the current file
        text_lines   = @file_manager.send(:file_open, current_file)            # open it 
        @text_processor.send(:text_exclude, text_lines)                        # additional excludes   
      when "2"
        current_file = @file_manager.send(:file_history_current)               # get the current file
        text_lines   = @file_manager.send(:file_open, current_file)            # open it
        @text_processor.send(:text_deletex, text_lines)                        # delete all excluded lines   
      when "3"
        current_file = @file_manager.send(:file_history_current)               # get the current file
        text_lines   = @file_manager.send(:file_open, current_file)            # open it
        @text_processor.send(:text_deletenx, text_lines)                       # delete all non excluded lines  
      when "4"
        user_write    
      else
      puts("Exiting")
      exit
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

  def user_write
    puts "in user_write" 
  end
  
  def user_pattern
    puts "Pattern to find in a line:\n "
    ARGF.each_line do |pattern|
      @pattern = pattern.chomp!                                                 
      @pattern = 'if /#{Regexp.escape(exclude)}/.match(text)' if pattern == ""  # default for development
        break                                                                   # just one pattern at a time for now
    end
    # save this search pattern in the next unused search history entry
    search_history = $search_history.to_h
    search_history.each_pair do |index, pattern|
      if pattern == ""                                                      # wait for next open slot
        $search_history["#{index}"] = "#{@pattern}"                         # store it for TextProcessor class 
        break
      end
    end
  end
  
  def user_selection
    key    = "root"
    index  = 0
    number = 0
    table  = {}
    puts "Select a folder\n"
    puts "#{index} #{key}"   
    table.store(index, key)
    $file_information.each_key do |key| 
      unless key == ""
        index += 1
        puts "#{index} #{key}"
        table.store(index, key)
      end  
    end
    ARGF.each_line do |selection|
      number = selection.chomp!.to_i
      break if (1..index).include?(number.to_i) 
    end
    folder_name = table.fetch(number) 
    file = $file_information.fetch(folder_name)
    p file
  end
  
end # class UserInterface