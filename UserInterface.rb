
class UserInterface

  # use assoc(line number) for line commands
  
  def user_file
    puts "File to open /home/brad/git/Ringer/testdata.rb or other:\n" 
    ARGF.each_line do |file|
      @file = file.chomp!                                                     
      @file = "/home/brad/git/Ringer/testdata.rb" if file == ""               # default for development
      arguments = [@file]
      @file_manager = FileManager.new
      @file_manager.send(:file_history_push, *arguments)                      # store it for UserInterface class 
      break                                                                   # just one file at a time for now
    end
    user_pattern                                                              # update search_history
    arguments = [@file]
    @file_manager = FileManager.new
    text_lines = @file_manager.send(:file_open, *arguments)                   # initial open
    @text_processor = TextProcessor.new
    @text_processor.send(:text_exclude, text_lines)                           # initial exclude                                              
  end
  
  def user_options(text_area)
    puts <<-DELIMITER
    1. Include additional search pattern
    2. Delete all excluded text
    3. Delete all not excluded text
    4. Write! to file\n
      DELIMITER
    ARGF.each do |selection|
      @selection = selection.chomp!                                                           
      break
    end
    case @selection
      when "1"
        user_pattern                                                           # update search_history 
        @file_manager = FileManager.new
        current_file = @file_manager.send(:file_history_current)               # get the current file
        @file_manager = FileManager.new
        text_lines = @file_manager.send(:file_open, current_file)              # open it 
        @text_processor = TextProcessor.new
        @text_processor.send(:text_exclude, text_lines)                        # additional excludes   
      when "2"
        @file_manager = FileManager.new
        current_file = @file_manager.send(:file_history_current)               # get the current file
        @file_manager = FileManager.new
        text_lines = @file_manager.send(:file_open, current_file)              # open it
        @text_processor = TextProcessor.new
        @text_processor.send(:text_deletex, text_lines)                        # delete all excluded lines   
      when "3"
        @file_manager = FileManager.new
        current_file = @file_manager.send(:file_history_current)               # get the current file
        @file_manager = FileManager.new
        text_lines = @file_manager.send(:file_open, current_file)              # open it
        @text_processor = TextProcessor.new
        @text_processor.send(:text_deletenx, text_lines)                       # delete all non excluded lines  
      when "4"
        user_write!    
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

  def user_write!
    puts "in user_write!" 
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
  
end # class UserInterface