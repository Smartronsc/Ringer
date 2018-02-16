#!/usr/bin/ruby

require './FileManager.rb'

class TextProcessor
  
  # this sets up the flat file to be fed in to the exclusion logic
    def text_handler(handle)
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
      text_lines.each do |line_num, text|                               # read the file line by line
        $search_history.to_h.each_pair do |symbol, pattern|             # get the current search patterns
          found = true if /#{Regexp.escape(pattern)}/.match(text) unless pattern == ""
        end
        if found                                                        # is it what is being looked for?
          if exclude_count > 0                                          # yes, only looked at this line?
            text_area.store(line_num, ["before", exclude_count])        # no, write out excluded line count
          end                                                           # end of if exclude_count > 0
          text_area.store(line_num+1, ["text", text])                   # write out this line
          line_number  = line_num                                       # expand scope beyond @text_lines.each do
          last_line    = line_num+1                                     # save for end of file processing
          last_text    = text                                           # save for end of file processing
          exclude_count = 0                                             # no lines have been excluded yet
        end                                                             #  
        exclude_count += 1 unless /#{Regexp.escape(exclude)}/.match(text) # if no match in this line
        found = false
      end
      if exclude_count > 1                                               # should be removed after testing
        puts "#{line_number+1} excluded #{exclude_count} trailing"       # I think it was copied code from line/lines display
        text_area.store(line_number+1, ["after", exclude_count])
      end
      if exclude_count == 1
        puts "#{line_number+1} excluded #{exclude_count} trailing"
        text_area.store(line_number+1, ["after", exclude_count])
      end
      text_area.delete(last_line)                                       # remove last data line    
      text_area.store(last_line, ["text", last_text])                   # 0 lines excluded is wrong                    
      text_area.store(last_line+1, ["after", exclude_count])            # need to test/rework this
      @user_processor = UserInterface.new
      @user_processor.send(:user_display, text_area)
    end
    
    def text_deletex(handle)
      text_lines = {}
      text_area  = {}
      file_in = handle.readlines
      file_in.each_with_index do |line, line_num|
        text_lines[line_num] = line.chomp
      end
      found = "false"    
      text_lines.each do |line_num, text|                                # read the file line by line
        $search_history.to_h.each_pair do |symbol, pattern|              # get the current search patterns
          found = true if /#{Regexp.escape(pattern)}/.match(text) unless pattern == ""
        end
        text_area.store(line_num+1, ["text", text]) if found             # write out this line                                               #  
        found = false
      end  
      @user_processor = UserInterface.new
      @user_processor.send(:user_display, text_area)
    end
    
    def text_deletenx(handle)
      text_lines = {}
      text_area  = {}
      file_in = handle.readlines
      file_in.each_with_index do |line, line_num|
        text_lines[line_num] = line.chomp
      end
      not_found = "true"    
      text_lines.each do |line_num, text|                                # read the file line by line
        $search_history.to_h.each_pair do |symbol, pattern|              # get the current search patterns
          not_found = false if /#{Regexp.escape(pattern)}/.match(text) unless pattern == ""
        end
        text_area.store(line_num+1, ["text", text]) if not_found         # write out this line if not foune                                              #  
        not_found = true
      end  
      @user_processor = UserInterface.new
      @user_processor.send(:user_display, text_area)
    end

end # class TextProcessor