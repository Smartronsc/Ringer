class UserInterface

  # use assoc(line number) for line commands
  def initialize
    @file_manager  = FileManager.new 
    @text_processor = TextProcessor.new
    @file = ""                                                            # gets built by user_prompt
  end
  
  def user_file_read
    puts 'Enter file name or "enter" for directory' 
    selection = ""
    file_information = {}
    ARGF.each_line do |file|
      @file = file.chomp!                                                  
      if @file == ""
        # initial load of $file_information dealing with / (root) and /home
        directories = @file_manager.send(:file_get_initialization)
        file_information = @file_manager.send(:file_get_files, directories) 
        @file_name = user_selection(file_information)
      end
      break
    end
    return @file_name
  end
  
  def user_selection(file_information)
    key        = "root"                                                   # linux support only for now
    file_break = ""                                                       # save for "break"
    index      = 0                                                        # for user selection
    number    = 0                                                         # for selection from table  
    ui        = {} 
    # build display for user selection
    file_information.each_pair do |directory, files|
      if files.length > 1
        ui.store(index, directory)                                        # the internal UI
        puts "Now in directory: #{directory}"
        @directory = directory
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
    file_name = "#{@directory}/#{ui[number]}"                              # get selection from UI table 
  end

  # Everything up until this point has been assumed to be an exclude request.
  # Now addition features are provided.
  #  1. Include additional search pattern
  #  2. Delete all excluded text         
  #  3. Delete all not excluded text     
  #  4. Range functions                  
  #  5. Write to file                 
  #
  def user_options(text_area)
    puts <<-DELIMITER
    1. Include additional search pattern
    2. Delete all excluded text
    3. Delete all not excluded text
    4. Range functions
    5. Write to file\n
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
        @text_processor.send(:text_exclude, text_lines)                       # additional excludes  
      when "2"
        current_file = @file_manager.send(:file_history_current)              # get the current file
        text_lines  = @file_manager.send(:file_open, current_file)            # open it
        @text_processor.send(:text_deletex, text_lines)                       # delete all excluded lines  
      when "3"
        current_file = @file_manager.send(:file_history_current)              # get the current file
        text_lines  = @file_manager.send(:file_open, current_file)            # open it
        @text_processor.send(:text_deletenx, text_lines)                      # delete all non excluded lines  
      when "4"
        user_ranges(text_area, text_lines)    
      when "5"
        path = user_prompt_write  
      else
      puts("Exiting")
      exit
    end
    return selection
  end
  
  def user_prompt_write
    @choice = ""
    @path  = ""
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
          user_prompt_write unless result                                      # write failed (no permission?)  
        when "4"
          @path = "#{@home}/#{@selection}"
          arguments = [@path, @text_area, "w"]
          result = @file_manager.send(:file_write, *arguments)
          user_prompt_write unless result                                      # write failed (no permission?)    
      end
      case @selection
        when "1"                                                                # overwrite the same file
          arguments = [@file, @text_area, "w"]
          @file_manager.send(:file_write, *arguments)            
        when "2"                                                                # append to the same file
          arguments = [@file, @text_area, "a"]
          @file_manager.send(:file_write, *arguments)    
        when "3"
          @choice = "3"                                                        # still need to ask for file name  
        when "4"
          @choice = "4"                                                        # still need to ask for path and file name
      end
      # these are the controls for the ARGF loop
      break unless ("1".."4").include?(@selection)                            # break if a line of text is read in  
      break if @selection == 1 || @selection == 2                            # break as file is already set
    end
    exit
  end
  # The first entry in to the utility ends up here.\n
  # All the other functions also end up here since this is a visual tool.\n
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
    selection = user_options(text_area)
    return selection
  end
  # Regexp pattern matching is used for the line exclude function.
  # Here the pattern is requested and stored in a global history file.
  # Currently up to 9 search patterns can be stored for basic support.
  # The current search pattern is returned.
  def user_pattern
    puts "Pattern to find in a line:\n "
    ARGF.each_line do |pattern|
      @pattern = pattern.chomp!                                                
#      @pattern = 'if /#{Regexp.escape(exclude)}/.match(text)' if pattern == ""  # default for development
      @pattern = 'lines' if pattern == ""  # default for development
      break                                                                      # just one pattern at a time for now
    end
    # save this search pattern in the next unused search history entry
    search_history = $search_history.to_h
    search_history.each_pair do |index, pattern|
      if pattern == ""                                                            # wait for next open slot
        $search_history["#{index}"] = "#{@pattern}"                              # store it for TextProcessor class 
        break
      end
    end
    return @pattern
  end
  
  def user_ranges(text_area, text_lines)
    puts <<-DELIMITER
    1. Select lines to be included
    2. Exclude additional lines
    3. Delete lines shown or excluded
    4. Insert lines
    5. Copy lines 
    6. Move lines
    
    Type your selection, a range or a single number amount with an "after" location
    For example 1 5..12 range to include or 1 7 5 the 7 lines after line 5
    Enter 6 10 0 or 6 10..20 0 to move lines 10 to 20 before line 1\n
      DELIMITER
    index = 1
    ARGF.each do |selection|
      selection = selection.chomp!
      selection_split = selection.split(" ")  
      selection_split.each do |s|                                                  # check for range indicated
        if s.include?("...")                                                      # range given?  
          range_split = s.split("...")                                            # yes, split it for first and last
          selection_split[1] = range_split[0]                                    
          selection_split[2] = range_split[1].to_i - 1  
          selection_split[2] = selection_split[2].to_s                            # stay with strings
        end                                    
        if s.include?("..")                                                        # range given?  
          range_split = s.split("..")                                              # yes, split it for first and last
          selection_split[1] = range_split[0]                                    
          selection_split[2] = range_split[1] 
        end
      end
      unless selection.match('\.')
        selection_split[2] = selection_split[1].to_i + selection_split[2].to_i
        selection_split[1].to_s
        selection_split[2].to_s                                      
      end

      if selection_split.length < 3                                                  # check length entered
        puts "Format is: Selection number then Range (11..23) or Amount with 'after' number"
        user_ranges(text_area, text_lines)                                                        # ask again for input
      end

      @arguments = selection_split                                                      
      break
    end
    @text_processor.send(:text_mixer, text_area, @arguments)
  end
  
end # class UserInterface
