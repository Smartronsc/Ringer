class UserInterface

  # use assoc(line number) for line commands
  def initialize
    @file_manager  = FileManager.new 
    @text_processor = TextProcessor.new
    @file = ""                                                               # gets built by user_prompt
  end
  
  def user_prompt(prompt, function)
    puts prompt                                                              # initial prompt 
    selection = ""
    file_information = {}
    ARGF.each_line do |file|
      @file = file.chomp!                                                   
      if @file == ""
        # initial load of $file_information dealing with / (root) and /home
        directories = @file_manager.send(:file_get_initialization)
        file_information = @file_manager.send(:file_get_files, directories) 
        selection = user_selection(file_information)
      end
      break
    end
    while File.directory?(selection)
      @file_manager.send(:file_get_more_information, selection) 
      selection = user_selection(file_information)
      unless File.directory?(selection)
        break
      end
    end
    file_information.each do |directory,files|
      files.each { |file| @file = "#{directory}/#{file.to_s}" if file == selection }
    end
    @file_manager.send(:file_history_push, @file)                          # store it for UserInterface class  
    if function == "read"
      user_pattern                                                        # update search_history
      arguments = [@file, "r"]
      text_lines = @file_manager.send(:file_open, *arguments)              # open for read
      @text_processor.send(:text_exclude, text_lines)                      # exclude 
      return @file
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
      if files.length > 1
        ui.store(index, directory)                                          # the internal UI
        puts "Now in directory: #{directory}" 
        files.each do |file| 
          unless file.start_with?(".")
            if File.directory?(file)
              puts "#{index} #{file}"
            else
              puts "  #{index} #{file}"
            end
            ui.store(index, file) 
            index += 1
          end
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
        path = user_prompt_write   
      else
      puts("Exiting")
      exit
    end
  end
  
  def user_prompt_write
    @choice = ""
    @path   = ""
    current_file = @file_manager.send(:file_history_current)                  # get the current file
    @file = current_file
    path_split = current_file.split("/")
    path_split.pop
    path_split.each do |d|
      @path = "#{@path}/#{d}" unless d == "" 
    end 
    @home = "/#{path_split.slice!(1)}"                                        # ignore root
      puts <<-DELIMITER
    1. Overwrite: #{@file}
    2. Append:    #{@file} 
    3. New file:  #{@path} 
    4. New path:  #{@home}\n 
      DELIMITER
    ARGF.each do |selection|
      @selection = selection.chomp! 
      case @choice                                                              # @choice actually runs after @selection 
        when "3"
          @path = "#{@path}/#{@selection}"
          arguments = [@path, @text_area, "w"]
          result = @file_manager.send(:file_write, *arguments)  
          user_prompt_write unless result                                       # write failed (no permission?)   
        when "4"
          @path = "#{@home}/#{@selection}"
          arguments = [@path, @text_area, "w"]
          result = @file_manager.send(:file_write, *arguments)
          user_prompt_write unless result                                       # write failed (no permission?)    
      end
      case @selection
        when "1"                                                                # overwrite the same file
          arguments = [@file, @text_area, "w"]
          @file_manager.send(:file_write, *arguments)            
        when "2"                                                                # append to the same file
          arguments = [@file, @text_area, "a"]
          @file_manager.send(:file_write, *arguments)    
        when "3"
          @choice = "3"                                                         # still need to ask for file name  
        when "4"
          @choice = "4"                                                         # still need to ask for path and file name
      end
      # these are the controls for the ARGF loop
      break unless ("1".."4").include?(@selection)                            # break if a line of text is read in   
      break if @selection == 1 || @selection == 2                             # break as file is already set
    end
    exit
  end
  # the first entry in to the utility ends up here
  # all the other functions also end up here since this is a visual tool
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