
class TextProcessor
  
  # this builds a hash table of excluded lines
  def text_exclude(text_lines)
    @user_interface = UserInterface.new
    text_area    = {}
    exclude_count =  0
    line_number  = -1
    last_line    = -1
    last_text    = ""
    found        = false 
    after        = false  
    text_lines.each do |line_num, text|                              # read the file line by line
      $search_history.to_h.each_pair do |symbol, pattern|            # get the current search patterns
        @pattern = pattern unless pattern == ""                      # formal argument cannot be an instance variable
        found = true if /#{Regexp.escape(pattern)}/.match(text) unless pattern == ""
      end
      if found                                                      # is it what is being looked for?
        if exclude_count > 0                                        # yes, only looked at this line?
          text_area.store(line_num, ["before", exclude_count])      # no, write out excluded line count
        end                                                          # end of if exclude_count > 0
        text_area.store(line_num+1, ["text", text])                  # write out this line
        line_number  = line_num                                      # expand scope beyond @text_lines.each do
        last_line    = line_num+1                                    # save for end of file processing
        last_text    = text                                          # save for end of file processing
        exclude_count = 0                                            # no lines have been excluded yet
      end 
      exclude_count += 1 unless found                                # if no match in this line
      found = false
  end
    if exclude_count > 0 
      puts "#{line_number} excluded #{exclude_count} trailing"
      text_area.store(line_number+1, ["after", exclude_count])
    end
    text_area.delete(last_line)                                      # remove last data line    
    text_area.store(last_line, ["text", last_text])                  # add last line of text                  
    text_area.store(last_line+1, ["after", exclude_count])          # and wrap it up!
    @user_interface.send(:user_display, text_area)
  end
  
  def text_deletex(text_lines)
    @user_interface = UserInterface.new
    text_area  = {}
    found = false    
    text_lines.each do |line_num, text|                              # read the file line by line
      $search_history.to_h.each_pair do |symbol, pattern|            # get the current search patterns
        found = true if /#{Regexp.escape(pattern)}/.match(text) unless pattern == ""
      end
      text_area.store(line_num+1, ["text", text]) if found            # write out this line            
      found = false
    end  
    @user_interface.send(:user_display, text_area)
  end
  
  def text_deletenx(text_lines)
    @user_interface = UserInterface.new
    text_area  = {}
    not_found = true    
    text_lines.each do |line_num, text|                                # read the file line by line
      $search_history.to_h.each_pair do |symbol, pattern|              # get the current search patterns
        not_found = false if /#{Regexp.escape(pattern)}/.match(text) unless pattern == ""
      end
      text_area.store(line_num+1, ["text", text]) if not_found        # write out this line if not found
      not_found = true
    end  
    @user_interface.send(:user_display, text_area)
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

end # class TextProcessor