class TextProcessor
  
  def initialize
    @file_manager  = FileManager.new 
  end
  
  def text_mixer(text_area, text_lines, parameters)
    selection   = parameters[0]
    index_start = parameters[1].to_i
    index_end   = parameters[2].to_i
    block_start = 0
    block_end   = 0
    block_start_line  = []
    block_start_type  = ""
    block_start_count = 0
    block_start_index = 0
    block_end_line    = []
    block_end_type    = ''
    block_end_count   = 0
    block_end_index   = 0
    keys = text_area.keys
    p keys
    keys.each do |k| 
      if k > index_start
        block_start_index = k
        block_start_line  = text_area.values_at(k)
        block_start_line.flatten!
        block_start_type  = block_start_line[0]
        block_start_count = block_start_line[1]
        break if block_start_type == "before" 
      end
    end
    keys.each do |k| 
      if k > index_end
        block_end_index = k
        block_end_line  = text_area.values_at(k) 
        block_end_line.flatten!
        block_end_type  = block_end_line[0]
        block_end_count = block_end_line[1]
        break if block_end_type == "before" 
      end
    end  
    p block_start_index
    p block_end_index 
    case selection
      when "1"
        current_file = @file_manager.send(:file_history_current)                # get the current file
        text_lines  = @file_manager.send(:file_open, current_file)              # open it 
#        @text_processor.send(:text_mixer, text_area, text_lines, @arguments)  # additional includes  
      when "2"
        current_file = @file_manager.send(:file_history_current)                # get the current file
        text_lines  = @file_manager.send(:file_open, current_file)              # open it
        @text_processor.send(:text_excludea, text_area, text_lines, @arguments) # additional excludes  
      when "3"
        current_file = @file_manager.send(:file_history_current)                # get the current file
        text_lines  = @file_manager.send(:file_open, current_file)              # open it
        @text_processor.send(:text_deletesx, text_area, text_lines, @arguments) # delete some lines 
      when "4"
        current_file = @file_manager.send(:file_history_current)                # get the current file
        text_lines  = @file_manager.send(:file_open, current_file)              # open it
        @text_processor.send(:text_insert, text_area, text_lines, @arguments)   # insert some lines 
      when "5"
        current_file = @file_manager.send(:file_history_current)                # get the current file
        text_lines  = @file_manager.send(:file_open, current_file)              # open it
        @text_processor.send(:text_copy, text_area, text_lines, @arguments)     # copy some lines 
      when "6"
        current_file = @file_manager.send(:file_history_current)                # get the current file
        text_lines  = @file_manager.send(:file_open, current_file)              # open it
        @text_processor.send(:text_move, text_area, text_lines, @arguments)     # move some lines 
      else
      puts("Exiting")
      exit
    end 
  end
  
  def text_write_area(from, amount, excluded)
  end
  
  def text_write_lines(from, amount, excluded)
  end
  
  
  
  # this includes more lines in text_area
  # parameters are either after line and amount as Strings
  # or a Range and after line as String
  def text_include(text_area, text_lines, parameters)
    @user_interface = UserInterface.new
    amount  = parameters[1].to_i - parameters[0].to_i
    after  = parameters[0].to_i 
    stop_at = after + amount
    ta_previous_index = 0
    ta_previous_line  = []
    ta_previous_type  = ""
    ta_previous_before  = 0
    ta_next_index = 0 
    ta_next_line  = []
    ta_next_type  = ""
    ta_next_before  = 0
    p "amount #{amount} after #{after} stop at #{stop_at}"
    text_area.each do |ta|                                            # start with text_area
      if ta[0] <= after                                              # keep useful information
        ta_previous_index = ta[0]                                    # get the line number
        ta_previous_line  = ta[1]                                    # get the type [0] and data [1]
        ta_previous_type  = ta_previous_line[0]                      # type of "before" or "text"
        ta_previous_before = ta_previous_line[1] if ta_previous_type == "before"  
      else
        if ta_previous_type == "before"
        ta_next_index = ta[0]                                    # get the line number
        ta_next_line  = ta[1]                                    # get the type [0] and data [1]
        ta_next_type  = ta_previous_line[0]                      # type of "before" or "text"
        ta_next_before = ta_previous_line[1]  
        break if ta[0] > after
      end
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
    new_text_area  = {}
    excluded      = 0
    if ta_previous_index == 0                                    # no controls yet  
      new_text_area.store(0, ["before", after - 1])              # write out excluded before "after"
      text_lines.each do |tl|                                    # original file 
        if tl[0] >= after                                        # nothing to do until "after"
          if tl[0] <= stop_at                                    # limit writing from original file
            new_text_area.store(tl[0], ["text", tl[1]])          # new composite output being built
          end
          if tl[0] == ta_next_index 
            excluded = (ta_next_index - stop_at) + 1              # adjust for above logic
            new_text_area.store(tl[0], ["before", excluded])      # write out new excluded value 
          end
        end
      end
    end
    text_area.each do |ta|                                        # text_area again
      if ta[0] > ta_next_index + 1                            # write out the rest unchanged
        new_text_area.store(ta[0], ta[1])                        # rest of output being built
      end
    end
    if ta_previous_index > 0                                    # no controls yet  
      text_area.each do |ta|                                        # text_area again
        if ta[0] > ta_next_index + 1                            # write out the rest unchanged
          new_text_area.store(ta[0], ta[1])                        # rest of output being built
        end
      end
      text_lines.each do |tl|                                      # original file 
        if tl[0]+1 > after                                          # start writing from original file
          unless tl[0]+1 > stop_at                                    # stop writing from original file
          new_text_area.store(tl[0], ["text", tl[1]])              # new composite output being built
#        p "#{after} > #{tl[0]} > #{stop_at} #{tl[1]}"
          end
        end
      end  
    end
#    new_text_area.each {|nta|p nta}
    @user_interface.send(:user_display, new_text_area)
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