class TextProcessor
  
  # this sets up the flat file
    def text_handler(handle)
      text_lines = {}
      file_in = handle.readlines
      file_in.each_with_index do |line, line_num|
        text_lines[line_num] = line.chomp
      end
    #  ask what to exclude (for now)
    @user_interface = UserInterface.new
    @user_interface.send(:user_exclude?, text_lines)
    end
    
    # this builds a hash table of excluded lines
    def text_exclude(exclude, text_lines)
      text_area    = {}
      exclude_count =  0
      line_number  = -1
      last_line    = -1
      last_text    = ""
      @pattern      = ""
      found        = false    
      text_lines.each do |line_num, text|                              # read the file line by line
        $search_history.to_h.each_pair do |symbol, pattern|            # get the current search patterns
          @pattern = pattern unless pattern == ""                      # formal argument cannot be an instance variable
          found = true if /#{Regexp.escape(pattern)}/.match(text) unless pattern == ""
        end
        if found                                                        # is it what is being looked for?
          if exclude_count > 0                                          # yes, only looked at this line?
            text_area.store(line_num, ["before", exclude_count])        # no, write out excluded line count
          end                                                          # end of if exclude_count > 0
          text_area.store(line_num+1, ["text", text])                  # write out this line
          line_number  = line_num                                      # expand scope beyond @text_lines.each do
          last_line    = line_num+1                                    # save for end of file processing
          last_text    = text                                          # save for end of file processing
          exclude_count = 1                                            # no lines have been excluded yet
        end 
        exclude_count += 1 unless /#{Regexp.escape(@pattern)}/.match(text) # if no match in this line
        found = false
    end
      if exclude_count > 0 
        puts "#{line_number} excluded #{exclude_count} trailing"
        text_area.store(line_number+1, ["after", exclude_count])
      end
      text_area.delete(last_line)                                      # remove last data line    
      text_area.store(last_line, ["text", last_text])                  # 0 lines excluded is wrong                    
      text_area.store(last_line+1, ["after", exclude_count])            # need to test/rework this
      @user_interface = UserInterface.new
      @user_interface.send(:user_display, text_area)
    end
    
    def text_deletex(handle)
      text_lines = {}
      text_area  = {}
      file_in = handle.readlines
      file_in.each_with_index do |line, line_num|
        text_lines[line_num] = line.chomp
      end
      found = false    
      text_lines.each do |line_num, text|                                # read the file line by line
        $search_history.to_h.each_pair do |symbol, pattern|              # get the current search patterns
          found = true if /#{Regexp.escape(pattern)}/.match(text) unless pattern == ""
        end
        text_area.store(line_num+1, ["text", text]) if found            # write out this line            
        found = false
      end  
      @user_interface = UserInterface.new
      @user_interface.send(:user_display, text_area)
    end
    
    def text_deletenx(handle)
      text_lines = {}
      text_area  = {}
      file_in = handle.readlines
      file_in.each_with_index do |line, line_num|
        text_lines[line_num] = line.chomp
      end
      not_found = true    
      text_lines.each do |line_num, text|                                # read the file line by line
        $search_history.to_h.each_pair do |symbol, pattern|              # get the current search patterns
          not_found = false if /#{Regexp.escape(pattern)}/.match(text) unless pattern == ""
        end
        text_area.store(line_num+1, ["text", text]) if not_found        # write out this line if not found
        not_found = true
      end  
      @user_interface = UserInterface.new
      @user_interface.send(:user_display, text_area)
    end

end # class TextProcessor

class UserInterface

  def user_options(text_area)
    puts <<-DELIMITER
    1. Include additional search pattern
    2. Delete all excluded text
    3. Delete all not excluded text
    4. Write! to file\n
      DELIMITER
    ARGF.each do |selection|
      selection.chomp!            
  
      case selection
        when "1"
          @file_manager = FileManager.new
          current_file = @file_manager.send(:file_history_current)                    # get the current file as it closed
          arguments = [current_file, "exclude"]
          @file_manager = FileManager.new
          @file_manager.send(:file_open, *arguments)                                  # open it  
        when "2"
          @file_manager = FileManager.new
          current_file = @file_manager.send(:file_history_current)                    # get the current file
          arguments = [current_file, "deletex"]                                          # delete all excluded lines
          @file_manager = FileManager.new
          @file_manager.send(:file_open, *arguments)                                  # open it
        when "3"
          @file_manager = FileManager.new
          current_file = @file_manager.send(:file_history_current)                    # get the current file
          arguments = [current_file, "deletenx"]                                        # delete all not excluded lines
          @file_manager = FileManager.new
          @file_manager.send(:file_open, *arguments)                                  # open it
        when "4"
          user_write!    
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
      file = "/home/runner/gem all.rb" if file == "" || file == nil          # default for development
      arguments = [file, "initial"]
      @file_manager = FileManager.new
      @file_manager.send(:file_open, *arguments) 
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

  def user_write!
    puts "in user_write!" 
  end
  
end # class UserInterface

class FileManager

  # Opens any given file either from the default file, console input or history
  def file_open(file, function)
    @handle = File.open("#{file}", "r")
    case function
      when "initial"
        file_history_push(file)
        @text_processor = TextProcessor.new
        @text_processor.send(:text_handler, @handle) 
      when "exclude"
        file_history_push(file)
        @text_processor = TextProcessor.new
        @text_processor.send(:text_handler, @handle) 
      when "deletex"
        @text_processor = TextProcessor.new
        @text_processor.send(:text_deletex, @handle)
      when "deletenx"                                  
        @text_processor = TextProcessor.new
        @text_processor.send(:text_deletenx, @handle)
      end
  end

  # Nothing really gets closed as yet 
  def file_close
    @handle.close
  end
  
  # Keeps the current working file available
  # Currently file history is only one deep
  def file_history_push(file)
    file_history = $file_history.to_h
    file_history.each_pair do |index, file_name|
      if file_name == ""
        file_name = file
        $file_history["#{index}"] = "#{file_name}"
        break
      end
    end
  end
  
  # Not in use
  # Needs to be tested
  def file_history_pop(file)
    file_history = $file_history.to_h
    current_history = file_history.pop
    file_history.each_pair do |index, file_name|
      if file_name == current_history
        $file_history.delete_field("#{index}")
        break
      end
    end
  end
  
  # lots of possible uses for this but right now current is current
  def file_history_current
    file_history = $file_history.to_h
    file_history.each_pair do |index, file_name|
      return file_name unless file_name == ""
    end
  end

end # End of class FileManager

require 'ostruct'


  # Eclipse Run or Run configuration must specify Ring.rb or the run will terminate
  # This must be the active tab when the Run button is clicked

# set up control structure for file names
$file_history = OpenStruct.new(:file01 => "", :file02 => "", :file03 => "", :file04 => "", :file05 => "", :file06 => "", :file07 => "", :file08 => "", :file09 => "")
# set up control structure for search strings
$search_history = OpenStruct.new(:search01 => "", :search02 => "", :search03 => "", :search04 => "", :search05 => "", :search06 => "", :search07 => "", :search08 => "", :search09 => "")
#p file_history.to_h
@user_interface = UserInterface.new
@user_interface.send(:user_file?)