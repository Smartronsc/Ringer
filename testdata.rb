class TextProcessor
  
  # this sets up the flat file to be fed in to the exclusion logic
  def text_handler(handle, *text_area)
    text_lines = {}
    file_in = handle.readlines
    file_in.each_with_index do |line, line_num|
      text_lines[line_num] = line.chomp
    end
  #  ask what to exclude (for now)
  @user_processor = UserInterface.new
  @user_processor.send(:user_exclude?, text_lines)
  end
  
  # this builds a hash table of excluded lines
  def text_exclude(exclude, text_lines)
    text_area    = {}
    exclude_count =  0
    line_number  = -1
    last_line    = -1
    last_text    = ""
    found        = "false"    
    text_lines.each do |line_num, text|                                # read the file line by line
      $search_history.to_h.each_pair do |symbol, pattern|            # get the current search patterns
        found = true if /#{Regexp.escape(pattern)}/.match(text) unless pattern == ""
      end
      if found                                                          # is it what is being looked for?
      puts "found #{found}"
        if exclude_count > 0                                            # yes, only looked at this line?
          text_area.store(line_num, ["before", exclude_count])          # no, write out excluded line count
        end                                                            # end of if exclude_count > 0
        text_area.store(line_num+1, ["text", text])                    # write out this line
        line_number  = line_num                                        # expand scope beyond @text_lines.each do
        last_line    = line_num+1                                      # save for end of file processing
        last_text    = text                                            # save for end of file processing
        exclude_count = 0                                              # no lines have been excluded yet
      end                                                              #  
      exclude_count += 1 unless /#{Regexp.escape(exclude)}/.match(text) # if no match in this line
      found = false
    end
    if exclude_count > 1                                                # should be removed after testing
      puts "#{line_number+1} excluded #{exclude_count} trailing"        # I think it was copied code from line/lines display
      text_area.store(line_number+1, ["after", exclude_count])
    end
    if exclude_count == 1
      puts "#{line_number+1} excluded #{exclude_count} trailing"
      text_area.store(line_number+1, ["after", exclude_count])
    end
    text_area.delete(last_line)                                        # remove last data line    
    text_area.store(last_line, ["text", last_text])                    # 0 lines excluded is wrong                    
    text_area.store(last_line+1, ["after", exclude_count])              # need to test/rework this
    $memory_map = text_area                                            # refresh memory map with the current display
    @user_processor = UserInterface.new
    @user_processor.send(:user_display, text_area)
  end
  
  def text_deleter(handle)
    text_lines = {}
    file_in = handle.readlines
    file_in.each_with_index do |line, line_num|
      text_lines[line_num] = line.chomp
    end
    text_lines.each do |line_num, text|                                # read the file line by line
      search_history = $search_history.to_h                            # from Struct to Hash
      search_history.each do |index, search_pattern|                    
        unless search_pattern == ""                                    # from def user_exclude?(text_lines)
          unless /#{Regexp.escape(search_pattern)}/.match(text)        # is it what is being looked for?
            text_area.store(line_num+1, ["text", text])                # write out this line
            line_number  = line_num                                    # expand scope beyond @text_lines.each do
            last_line    = line_num+1                                  # save for end of file processing
            last_text    = text                                        # save for end of file processing
          end
        end
      end 
    end
  end
  
end # class TextProcessor


class UserInterface

  def user_options(text_area)
    puts <<-DELIMITER
    1. Include additional text
    2. Delete all excluded
    3. Delete all not excluded
      DELIMITER
    selection = gets.chomp              
#    selection = "1"
    case selection
      when "1"
      @file_processor = FileManager.new
      current_file = @file_processor.send(:file_history_current)                      # get the current file as it closed 
      @file_processor = FileManager.new
      @file_processor.send(:file_open, current_file)                                  # reopen it
      @text_processor = TextProcessor.new
      @text_processor.send(:text_handler, @handle)                                    # re-read in the lines from the file    
      when "2"
      @file_processor = FileManager.new
      current_file = @file_processor.send(:file_history_current)                      # get the current file
      @file_processor = FileManager.new
      @file_processor.send(:file_open, current_file)                                  # reopen it
      @text_processor = TextProcessor.new
      @text_processor.send(:text_deleter, @handle)                                    # re-read in the lines from the file    
      when "3"
      puts("Not available yet")
            exit
      else
      puts("Exiting")
      exit
    end
  end

  # use assoc(line number) for line commands
  def user_file?
#    puts "File to open gem all.rb or other: " 
    puts "File to open /home/brad/git/Ringer/TextProcessor.rb or other: " 
#    file = gets.chomp
#    file = "/home/brad/git/Ringer/TextProcessor.rb" if file == ""
    file = "gem all.rb" if file == nil
    @file_processor = FileManager.new
    @file_processor.send(:file_open, file) 
  end
  # finds non excluded text in the file and excludes it
  def user_exclude?(text_lines) 
    puts "String not to exclude: "
    exclude = gets.chomp
    exclude = 'if /#{Regexp.escape(exclude)}/.match(text)' if exclude == ""
    # save this search pattern the next unused search history entry
    search_history = $search_history.to_h
    search_history.each_pair do |index, search_pattern|
      if search_pattern == ""
        search_pattern = exclude
        $search_history["#{index}"] = "#{search_pattern}"
        break
      end
    end
    @text_processor = TextProcessor.new
    @text_processor.send(:text_exclude, exclude, text_lines)
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



class FileManager
  # Opens any given file either from the default file, console input or history
  def file_open(file)
    @handle = File.open("#{file}", "r")
    file_history_push(file)
    @text_processor = TextProcessor.new
    @text_processor.send(:text_handler, @handle) 
  end

  # Nothing really gets closed as yet 
  def file_close
    @handle.close
  end
  
  # Future use 
  def file_print(results)
    puts("in file_print for #{results}")
  end
  
  # Future use 
  def file_print_all
    puts("in file_all")
    file_in = @handle.readlines
    file_in.each { |line| p line }
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
@user_processor = UserInterface.new
@user_processor.send(:user_file?)
