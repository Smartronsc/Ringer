

class UserInterface

  # use assoc(line number) for line commands
  def initialize
    @file_manager  = FileManager.new 
    @text_processor = TextProcessor.new
  end
  
  def user_prompt(prompt, function)
    puts prompt                                                              # initial prompt 
    selection = ""
    file_information = {}
    ARGF.each_line do |file|
      @file = file.chomp!
      prompt = "Enter File or directory"                                      # follow on prompt 
      if @file == ""
        # initial load of $file_information dealing with / (root) and /home
        directories = @file_manager.send(:file_get_initialization)
        #p "127 directories #{directories}"
        file_information = @file_manager.send(:file_get_files, directories) 
        #p "129 file_information #{file_information}"
        selection = user_selection(file_information)
        #p "132 selection #{selection}"
      end
      break
    end
    while File.directory?(selection)
      #puts "30 selection #{selection}"
      # p "140 directories #{directories}"
      @file_manager.send(:file_get_more_information, selection) 
      #puts "34 file_information #{file_information}"
      selection = user_selection(file_information)
      #puts "36 selection #{selection}"
      unless File.directory?(selection)
        puts "38 File selected is: #{selection}"
        break
      end
    end
    file_information.each do |directory,files|
      #puts "149 selection #{selection} key #{directory} value #{files}"
      files.each { |file| @file = "#{directory}/#{file.to_s}" if file == selection }
        #puts "154 #{@file}"
    end
    @file_manager.send(:file_history_push, @file)                          # store it for UserInterface class  
=begin
      |mode|reads|writes|starts writing at|if preexists
      |r   |yes  |      |n/a              |ok
      |r+  |yes  |yes   |beginning        |fail
      |w   |     |yes   |beginning        |overwrite
      |w+  |yes  |yes   |beginning        |overwrite
      |a   |     |yes   |end              |append
      |a+  |yes  |yes   |end              |append
=end    
    if function == "read"
      user_pattern                                                         # update search_history
      arguments = [@file, "r"]
      text_lines = @file_manager.send(:file_open, *arguments)              # open for read
      @text_processor.send(:text_exclude, text_lines)                      # exclude 
      return @file
    else 
      puts "Current file is: #{@file}" 
      puts "Enter 'a' to append, 'x' to exit, another file name or enter to write over this file"                                                      
      arguments = [@file, @text_area, "w"]
      @file_manager.send(:file_write, *arguments)              # open for write, possible save copy?               
    end
  end
  
  def user_selection(file_information, *function)
    key        = "root"                                                    # linux support only for now
    file_break = ""                                                        # save for "break"
    index      = 0                                                          # for user selection
    number    = 0                                                          # for selection from table  
    ui        = {} 
    # build display for user selection
    file_information.each_pair do |directory, files|
      #puts "168 #{directory} #{files}"
      if files.length > 1
        #puts "171 #{index} #{directory}"                                  # the actual UI
        ui.store(index, directory)                                          # the internal UI
        files.each do |file| 
          puts "#{index} #{file}" 
          ui.store(index, file) 
          index += 1
        end
      end
    end
    # parse user selection
    ARGF.each_line do |selection|                                          
      number = selection.chomp!.to_i
      break if (0..index).include?(number.to_i)                            # index reused from above  
    end
    selection = ui[number]                                                  # get selection from UI table 
end
=begin
def user_get_file
    action = ":file_get_initialization"
    @file_manager.send(action) 
    puts prompt 
    ARGF.each_line do |file|
      @file = file.chomp!
      if @file == "" 
        @file = user_selection
        if File.directory?(@file)
          @file_manager.send(:file_get_information, @file) 
          @file = user_selection
          puts "99 File: #{@file}"
        end
      end
      @file_manager.send(:file_history_push, @file)                          # store it for UserInterface class 
      break                                                                  # just one file at a time for now
    end
    
    user_pattern                                                            # update search_history
    
    arguments = [@file, "r"]
    text_lines = @file_manager.send(:file_open, *arguments)                  # initial open
    @text_processor.send(:text_exclude, text_lines)                          # initial exclude    
  end
=end
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
        user_pattern                                                          # update search_history 
        current_file = @file_manager.send(:file_history_current)              # get the current file
        text_lines  = @file_manager.send(:file_open, current_file)            # open it 
        @text_processor.send(:text_exclude, text_lines)                        # additional excludes  
      when "2"
        current_file = @file_manager.send(:file_history_current)              # get the current file
        text_lines  = @file_manager.send(:file_open, current_file)            # open it
        @text_processor.send(:text_deletex, text_lines)                        # delete all excluded lines  
      when "3"
        current_file = @file_manager.send(:file_history_current)              # get the current file
        text_lines  = @file_manager.send(:file_open, current_file)            # open it
        @text_processor.send(:text_deletenx, text_lines)                      # delete all non excluded lines  
      when "4"
        user_write    
      else
      puts("Exiting")
      exit
    end
  end
  
  def user_display(text_area)
    @text_area = text_area                                                  # save for user_write
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
    path = user_prompt("Enter file to write or enter to select from file system:\n", "write")
#    arguments = [path, @text_area]
#    p arguments
#  @file_manager.send(:file_write, *arguments)

  end
  
  def user_pattern
    puts "Pattern to find in a line:\n "
    ARGF.each_line do |pattern|
      @pattern = pattern.chomp!                                                
      @pattern = 'if /#{Regexp.escape(exclude)}/.match(text)' if pattern == ""  # default for development
      break                                                                    # just one pattern at a time for now
    end
    # save this search pattern in the next unused search history entry
    search_history = $search_history.to_h
    search_history.each_pair do |index, pattern|
      if pattern == ""                                                    # wait for next open slot
        $search_history["#{index}"] = "#{@pattern}"                        # store it for TextProcessor class 
        break
      end
    end
  end

end # class UserInterface
