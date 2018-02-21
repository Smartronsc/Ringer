
class UserInterface

  # use assoc(line number) for line commands
  def initialize
    @file_manager  = FileManager.new 
    @text_processor = TextProcessor.new
  end
  
  def user_file
    @file_manager.send(:file_get_initialization) 
    puts "File to open or enter to select from file system:\n" 
    ARGF.each_line do |file|
      @file = file.chomp!
      if @file == "" 
        p @file
        @file = user_selection
        while File.directory?(@file)
          @file_manager.send(:file_get_information, @file) 
          @file = user_selection
        end
      end
      @file_manager.send(:file_history_push, @file)                          # store it for UserInterface class 
      break                                                                  # just one file at a time for now
    end
    user_pattern                                                             # update search_history
    arguments = [@file, "r"]
    text_lines = @file_manager.send(:file_open, *arguments)                  # initial open
    @text_processor.send(:text_exclude, text_lines)                          # initial exclude                                              
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
    path = user_selection("write")
    arguments = [path, @text_area]
    @file_manager.send(:file_write, *arguments)

  end
  
  def user_pattern
    puts "Pattern to find in a line:\n "
    ARGF.each_line do |pattern|
      @pattern = pattern.chomp!                                                
      @pattern = 'if /#{Regexp.escape(exclude)}/.match(text)' if pattern == ""  # default for development
      break                                                                     # just one pattern at a time for now
    end
    # save this search pattern in the next unused search history entry
    search_history = $search_history.to_h
    search_history.each_pair do |index, pattern|
      if pattern == ""                                                     # wait for next open slot
        $search_history["#{index}"] = "#{@pattern}"                        # store it for TextProcessor class 
        break
      end
    end
  end
  
  def user_selection(function = "read")
    key        = "root"                                                    # linux support only for now
    file_break = ""                                                        # save for "break"
    index      = 0                                                          # for user selection
    number    = 0                                                          # for selection from table  
    ui  = {}                                                                # presented for user selection
    puts "Select a folder:\n"                                              
    $file_information.each_key do |key| 
      unless key == ""
        puts "#{index} #{key}"                                              # the rest of actual UI
        ui.store(index, key)                                                # the rest of the internal UI
        index += 1
      end 
    end
    ARGF.each_line do |selection|                                          # parse user selection
      number = selection.chomp!.to_i
      p number
      break if (0..index).include?(number.to_i)                            # index reused from above  
    end
    file_length = 0
    folder = ui.fetch(number)                                              # get selection from UI table 
    puts "Directory is #{folder}\n"
    files = $file_information.fetch(folder)                                # get the files
    while files.length < 2                                                  # no files? just directory?
      puts "Checking: #{files * " "}\n"
      files = $file_information.fetch(files * " ")                          # yes, down one level
    end
    file_break = files                                                      # for path build
    # done with directories, time to selct a file
    index = 0
    fi = {}
    # prepend this option for write
    if function == "write"                                                  # tack in here for code reuse
      file = "new file"
      puts "#{index} #{file}"                                              # adds "new file" to UI
      fi.store(index, file)                                                # adds "new file" internally
      index += 1
    end
    puts "Select a file:\n" unless function == "write"                      # more reuse hoops
    files.each do |file| 
      puts "#{index} #{file}"                                              # actual UI
      fi.store(index, file)                                                # internal UI
      index += 1
    end
    ARGF.each_line do |selection|                                          # parse user selection
      number = selection.chomp!.to_i
      break if (0..index).include?(number.to_i)                            # index reused from above  
    end
    # file selected so build complete path
    path = ""
    file_length = 0
    file = fi.fetch(number)                                                # get selection from UI table
    if file == "new file"
      puts "Enter new file name:"
      ARGF.each_line do |selection|                                        # parse user selection
        file = selection.chomp!
        break
      end
      $file_information.each_key do |key|                                  # path for new file      
        unless key == "root" 
          path = path + "/#{key}"                                          # build up the path
          break if key == file_break                                        # done with diretories
        end
      end
    else
#      puts "#{folder}"
#      if folder == ""
      $file_information.each_key do |key|                                  # path for exsiting file
        unless key == "root"
          puts  "#{path}"
          path = path + "/#{key}"                                          # build up the path
          break if key == file_break                                        # done with diretories
        end
      end
#      end
    end
    path = path + "/#{file}"    
  end
  
end # class UserInterface
