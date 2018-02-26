class TextProcessor
  
  # this includes more lines in text_area
  # parameters are either after line and amount as Strings
  # or a Range and after line as String
  def text_include(text_area, text_lines, parameters)
    @user_interface = UserInterface.new
    amount  = parameters[1].to_i - parameters[0].to_i
    after   = parameters[0].to_i 
    stop_at = after + amount
    after -= 1                                                        # adjust range to be after as well 
    ta_previous_index = 0
    ta_previous_line  = []
    ta_previous_type  = ""
    ta_previous_before   = 0
    ta_next_index = 
    ta_next_line  = []
    ta_next_type  = ""
    ta_next_before   = 0
    p "amount #{amount} after #{after}"
    text_area.each do |ta|                                            # start with text_area
      p ta
      if ta[0] <= after                                               # keep useful information
        ta_previous_index = ta[0]                                     # get the line number
        ta_previous_line  = ta[1]                                     # get the type [0] and data [1]
        ta_previous_type  = ta_previous_line[0]                       # type of "before" or "text"
        ta_previous_before = ta_previous_line[1] if ta_previous_type == "before"  
      else
        ta_next_index = ta[0]                                     # get the line number
        ta_next_line  = ta[1]                                     # get the type [0] and data [1]
        ta_next_type  = ta_previous_line[0]                       # type of "before" or "text"
        ta_next_before = ta_previous_line[1] if ta_previous_type == "before"  
        break if ta[0] > after
      end
    end
    p "ta_previous_index #{ta_previous_index}"  
    p "ta_previous_line #{ta_previous_line}"   
    p "ta_previous_type #{ta_previous_type}"   
    p "ta_previous_before #{ta_previous_before}" 
    p "ta_next_index #{ta_next_index}"      
    p "ta_next_line #{ta_next_line}"       
    p "ta_next_type #{ta_next_type}"       
    p "ta_next_before #{ta_next_before}"     
    new_text_area = {}
    text_area.each do |ta|                                          # text_area again
      if ta[0] < ta_previous_index                                  # until we hit a control
        new_text_area.store(ta[0],ta[1])
#        p "#{ta[0]} #{ta[1]}"
      end
    end
    text_lines.each do |tl| 
      if tl[0]+1 > after 
        unless tl[0]+1 > stop_at  
          new_text_area.store(tl[0],tl[1]) 
#          p "#{after} > #{tl[0]} > #{stop_at} #{tl[1]}"
        end
      end  
    end
    
    
    # need to subtract ta_next_line "before" value from amount and write new before record
    
    
#    new_text_area.each { |nta| p nta }    
    @user_interface.send(:user_display, text_area)
  end
  
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

end # class TextProcessor