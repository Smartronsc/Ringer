class TextProcessor
  
  def initialize
    @file_manager      = FileManager.new 
    @new_text_area     = {}
    @text_lines        = {}
    @line_start        = 0
    @block_start_line  = []
    @block_start_type  = ""
    @block_start_count = 0
    @block_start_index = 0
    @line_end          = 0
    @block_end_line    = []
    @block_end_type    = ''
    @block_end_count   = 0
    @block_end_index   = 0
    @keys              = []
  end
  
  # text_area full line format is [line number, [control type, count or data in line]] as a hash
  # text_area control format is ["before", count of lines preceeding] or ["text", data in line] as an array
  # parameters are normalized to act as a range
  def text_mixer(text_area, parameters)
    selection     = parameters[0]
    @line_start   = parameters[1].to_i                                          # lower boundary for line data changes
    @line_end     = parameters[2].to_i                                          # upper boundary for line data changes
    @keys         = text_area.keys                                              # text_area keys are the line numbers
    @block_first  = @keys.first                                                 # end of text_area
    @block_last   = @keys.last                                                  # last control line in text_area
    @text_area    = text_area                                                   # contains display area
    original_file = @file_manager.send(:file_history_current)                   # get the original file
    @text_lines   = @file_manager.send(:file_open, original_file)               # open it 
    # find the section of data to modify based on finding 
    # the "before" type preceeding and following the range
    @keys.each do |k|                                                           # find start text_area type "before"
      if k > @line_start                                                        # use this to format new following data
        @block_start_index = k                                                  # and new preceding "before" information
        @block_start_line = text_area.values_at(k)                              # get control using line number as key
        @block_start_line.flatten!                                              # comes back as one array too many
        @block_start_type  = @block_start_line[0]                               # just to make it clear, not needed
        @block_start_count = @block_start_line[1]                               # this is the amount to adjust
        break if @block_start_type == "before"                                  # first one after k > line_start 
      else
        @block_start_index = @keys.last                                         # use last control number  
      end
    end
    @keys.each do |k|                                                           # find end text_area type "before"
      if k >= @line_end                                                          # use this to format new preceeding data
        @block_end_index = k                                                    # and new following "before" information
        @block_end_line  = text_area.values_at(k) 
        @block_end_line.flatten!
        @block_end_count = @block_end_line[1]
        break if @block_end_line[0] == "before"                                 # first one after k > line_end
      else
        @block_end_index = @text_lines.length                                   # use end of file
      end
    end  
    case selection
      when "1"
        text_include                                                            # additional includes  
      when "2"
        text_exclude                                                            # additional excludes  
      when "3"
        @text_processor.send(:text_deletesx, text_area, text_lines, @arguments) # delete some lines 
      when "4"
        @text_processor.send(:text_insert, text_area, text_lines, @arguments)   # insert some lines 
      when "5"
        @text_processor.send(:text_copy, text_area, text_lines, @arguments)     # copy some lines 
      when "6"
        @text_processor.send(:text_move, text_area, text_lines, @arguments)     # move some lines 
      else
      puts("Exiting")
      exit
    end 
  end
  
  def text_write_area(from, to)
    @text_area.each do |ta|                                    # area containing excluded information  
      if ta[0] > from     
        if ta[0] <= to                                              
          @new_text_area.store(ta[0], ta[1])                    # new composite output being built
        end
      end
    end
  end
  
  def text_write_lines(from, to)
    @text_lines.each do |tl|                                    # original file 
      if tl[0] >= from                                      
        if tl[0] <= to                                          
          @new_text_area.store(tl[0], ["text", tl[1]])          # new composite output being built
        end
      end
    end
  end
  
  # this includes more lines in text_area for 1. Select lines to be included
  def text_include
    @user_interface = UserInterface.new
    amount = @line_end - @line_start
    stop_at = @line_start + amount
    p "amount #{amount} after #{@line_start} stop at #{stop_at}"
    p "line_start          #{@line_start}"
    p "line_end            #{@line_end}"
    p "block_start_index   #{@block_start_index}"
    p "block end_index     #{@block_end_index}"
    p "block_first         #{@block_first}"
    p "block_last          #{@block_last}"
    
    # this logic handles an select of lines completely contained within the first excluded area
    if @line_start <= @block_start_index && @line_end <= @block_start_index
      @new_text_area.store(0, ["before", @line_start - 1]) # exclude 
      text_write_lines(@line_start, @line_end)                    # write additional lines selected 
      @new_text_area.store(@block_end_index, ["before", @block_end_index - @line_end]) # excluded
      text_write_area(@block_end_index, @block_last)              # the rest unchanged
    end
   
    # this logic handles a select of lines completely contained within the last excluded area
    if @line_start > @block_last                                  # everything that follows is excluded
      text_write_area(0, @block_start_index - 1)                  # write the start unchanged
      @new_text_area.store(@block_end_index, ["before", @line_start - @block_start_index]) # excluded
      text_write_lines(@line_start, @line_end)                    # write additional lines selected 
      @new_text_area.store(@block_last, ["before", @block_end_index - @line_end]) # excluded
    end
   
    # this logic handles an select of lines across at least one control 
    if @line_start >= @block_first || @line_end <= @block_last
      text_write_area(0, @line_start - 1)                         # write out text_area until control
      position = @block_start_index - @block_start_count + 1
      @new_text_area.store(position, ["before", @block_start_index - @line_start]) # excluded
      text_write_lines(@line_start, @line_end)                    # write additional lines selected 
      @new_text_area.store(@line_end + 1, ["before", @block_end_index - @line_end]) # excluded
      text_write_area(@line_end + 2, @block_last)                 # the rest unchanged
    end
    
    @user_interface.send(:user_display, @new_text_area)
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
      if found                                                       # is it what is being looked for?
        if exclude_count > 0                                         # yes, only looked at this line?
          text_area.store(line_num, ["before", exclude_count])       # no, write out excluded line count
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
    text_area.store(last_line+1, ["after", exclude_count])           # and wrap it up!
    @user_interface.send(:user_display, text_area)
  end
  
  
  def text_deletex(text_lines)
    @user_interface = UserInterface.new
    text_area  = {}
    found = false    
    text_lines.each do |line_num, text|                               # read the file line by line
      $search_history.to_h.each_pair do |symbol, pattern|             # get the current search patterns
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
      text_area.store(line_num+1, ["text", text]) if not_found         # write out this line if not found
      not_found = true
    end  
    @user_interface.send(:user_display, text_area)
  end

end # class TextProcessor