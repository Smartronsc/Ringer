class TextProcessor
  
  def initialize
    @file_manager      = FileManager.new 
    @new_text_area    = {}
    @text_lines        = {}
    @line_start        = 0
    @line_end          = 0
    @block_prior_line  = []
    @block_prior_type  = ""
    @block_prior_count = 0
    @block_prior_index = 0
    @block_start_line  = []
    @block_start_type  = ""
    @block_start_count = 0
    @block_start_index = 0
    @block_end_line    = []
    @block_end_type    = ''
    @block_end_count  = 0
    @block_end_index  = 0
    @keys              = []
  end
  
  # About the text_area:
  # * text_area full line format is [control_number, line_actual [control type, count or data in line]] as a hash
  # * text_area control format is control_number ["before", count of lines preceding] or ["text", data in line] as an array
  #
  # parameters are normalized to act as a range
  
  # 1. Additional include pattern
  # This builds a hash table of the initial included lines.
  # * It runs a search history to support multiple includes.
  # * It does the Regexp matching for each pattern for each line.
  # * Everything is counted and excluded until a match is found.
  # * At that point the excluded count is written and text follows.
  # This logic repeats until the "after count is written if required.
  def text_include(text_lines)
    @text_end      = text_lines.length                              # actual data length used everywhere
    @text_area      = {}
    @exclude_count = 0
    @line_number    = -1
    @found          = false 
    after          = false  
    text_lines.each do |line_number, text|                        # read the file line by line
      @line_number = line_number                                  # formal argument cannot be an instance variable
      $search_history.to_h.each_pair do |symbol, pattern|          # get the current search patterns
        @pattern = pattern unless pattern == ""                    # formal argument cannot be an instance variable
        @found = true if /#{Regexp.escape(pattern)}/.match(text) unless pattern == ""
      end
      if @found                                                          # is it what is being looked for?
        if @exclude_count > 0                                            # yes, none excluded yet?
          @text_area.store(@line_number, ["before", @exclude_count])      # no, write out excluded line count
        end                                                      
        @text_area.store(@line_number+1, ["text", text])                  # always write out this line
        @exclude_count = 0                                                # no lines currently excluded
      else
        @text_area.store(@line_number+1, ["fill", ""]) unless @line_number == @text_end # line position
        @exclude_count += 1 if @line_number == @text_end                  # handle single excluded last line
      end 
      @exclude_count += 1 unless @found 
      @found = false
    end
    if @exclude_count > 0 
      @text_area.store(@line_number+1, ["after", @exclude_count])
      @exclude_count = 0
    end
    return @text_area
  end
  
  # 2. Additional exclude pattern
  def text_exclude(text_lines)
    @text_end      = text_lines.length                              # actual data length used everywhere
    @text_area      = {}
    @exclude_count = 0
    @line_number    = -1
    @found          = false 
    after          = false  
    text_lines.each do |line_number, text|                        # read the file line by line
      @line_number = line_number                                  # formal argument cannot be an instance variable
      $search_history.to_h.each_pair do |symbol, pattern|          # get the current search patterns
        @pattern = pattern unless pattern == ""                    # formal argument cannot be an instance variable
        @found = true if /#{Regexp.escape(pattern)}/.match(text) unless pattern == ""
      end
      if @found                                                          # is it what is being looked for?
        if @exclude_count > 0                                            # yes, none excluded yet?
          @text_area.store(@line_number, ["before", @exclude_count])      # no, write out excluded line count
        end                                                      
        @text_area.store(@line_number+1, ["text", text])                  # always write out this line
        @exclude_count = 0                                                # no lines currently excluded
      else
        @text_area.store(@line_number+1, ["fill", ""]) unless @line_number == @text_end # line position
        @exclude_count += 1 if @line_number == @text_end                  # handle single excluded last line
      end 
      @exclude_count += 1 unless @found 
      @found = false
    end
    if @exclude_count > 0 
      @text_area.store(@line_number+1, ["after", @exclude_count])
      @exclude_count = 0
    end
    return @text_area
  end

  def text_excluder
    p "text_excluder"
    @new_text_area.store(0, ["text", "Not yet implemented"])
    return @new_text_area
  end
  
  # 3. Delete all included text
  # Request is for all included lines to be deleted from the display.
  # All excluded lines are included.
  # test_ring0300 is the test case.
  def text_delete_in(text_lines)
    line_number  = 0
    text_area    = {}   
    text_lines.each do |line_num, text|                                # read the file line by line
      found = false 
      $search_history.to_h.each_pair do |symbol, pattern|              # get the current search patterns
        found = true if /#{Regexp.escape(pattern)}/.match(text) unless pattern == ""
      end
      text_area.store(line_number += 1, ["text", text]) unless found    # write out this line if not found
    end 
    return text_area 
  end
  
  # 4. Delete all excluded text
  # Request is for all excluded lines to be deleted from the display.
  # test_ring0400 is the test case.
  def text_delete_ex 
      @text_area.each do |ta|  
        ta1 = ta[1]                       
      if /#{Regexp.escape("text")}/.match(ta1[0]) 
        @new_text_area.store(ta[0], ta[1])          
      end
    end 
    return @new_text_area 
  end
  
    # The big picture is there are two things in play, the text_area which is built as the first exclude display
    # and the text_lines which is the original input file used to rebuild the text_area as required.
    # Beyond that the requirement is to track the various "lines excluded" positions, the number of lines excluded
    # for various conditions related to the actions required in rebuilding the original exclude display.
    # In particular block start is the exclude line information after the "after" line when doing any action.
    # The block end is needed for adjustments to the display for the exclude line after the last line in the action range.
    # While the block start information is for the exclude after the beginning of the action range the block prior
    # is needed for rebuilding the display with actions requiring additional excludes. Clearly if the prior exclude ends
    # on the line before the additional requested excludes starts the prior excludes need to be joined with the current.
    #
  def text_mixer(text_area, parameters)
    original_file = @file_manager.send(:file_history_current)                  # get the original file
    @text_lines  = @file_manager.send(:file_open, original_file)              # open it
    @text_end    = @text_lines.length                                        # actual data length
    @text_area    = text_area                                                  # contains display area
    @area_end    = @text_area.length                                          # actual area length
    @selection   = parameters[0]
    @line_start  = parameters[1].to_i                                    # lower boundary for line data changes
    @line_end    = parameters[2].to_i                                        # upper boundary for line data changes
    @keys        = text_area.keys                                            # text_area keys are the control areas
    @block_first  = @keys.first                                                # end of text_area
    @block_last  = @keys.last                                                # last control line in text_area
    @line_end    = @text_end if @line_end > @text_end                        # clean up directive 
    # 
    # find the section of data to modify based on finding the "before" type preceding and following the range
    # it is also necessary to keep track of the block prior to the block preceding for uses with excludes of excludes
    #
    @keys.each do |k|                                                          # find start text_area type "before"
      if k > @line_start                                                      # use this to format new following data
        @block_start_index = k                                                # and new preceding "before" information
        @block_start_line = text_area.values_at(k)                            # get control value using line number as key
        @block_start_line.flatten!                                            # comes back as one array too many
        @block_start_count = @block_start_line[1]                              # this is the amount to adjust
        @block_start_type  = @block_start_line[0]                              # just to make it clear, not needed
        break if @block_start_type == "before"                                # first one after k > line_start 
      else
        @block_start_index = @keys.last                                        # use last control number  
      end
    end
    @keys.each do |k|                                                        # find prior text_area of type "before"
      if k <= @line_start                                                    # use this to format new excluded data
        @block_prior_line = text_area.values_at(k)                            # get control using line number as key
        @block_prior_line.flatten!                                            # comes back as one array too many
        if @block_prior_line[0] == "before"                                  # if this is a "before" control
          @block_prior_count = @block_prior_line[1]                          # this is the amount to adjust
          @block_prior_index = k                                              # make this "prior" block
        end
      end  
    end
    @keys.each do |k|                                                        # find end text_area type "before"
      if k >= @line_end                                                      # use this to format new preceeding data
        @block_end_index = k                                                  # and new following "before" information
        @block_end_line  = text_area.values_at(k) 
        @block_end_line.flatten!
        @block_end_count = @block_end_line[1]
        break if @block_end_line[0] == "before"                              # first one after k > line_end
      else
        @block_end_index = @text_lines.length                                # use end of file
      end
    end
    return parameters
  end
  

  # 1. Include additional lines.
  # It runs through text_area including new lines as specified.
  # test_ringr100 is the test case.
  def text_mixer_include(parameters)
    @text_area.each { |ta| @new_text_area.store(ta[0], ta[1]) if ta[0] < @line_start } 
    @new_text_area.store(@line_start - 1, ["before", (@block_start_index - @line_start)-1 ])
    text_write_lines(@line_start-1, @line_end-1) 
    @new_text_area.store(@block_end_index, ["before", @block_end_index - @line_end])  
    @text_area.each { |ta| @new_text_area.store(ta[0], ta[1]) if ta[0] > @block_end_index } 
    return @new_text_area
  end
  
  # 2. Exclude additional lines.
  # It runs through text_area excluding new lines as specified
  # leaving out the range of lines to be excluded.
  # test_ring0200 is the test case.
  def text_mixer_exclude(parameters)
    p "text_mixer_exclude"
    @new_text_area.store(0, ["text", "Not yet implemented"])
   return @new_text_area
 end

=begin    
    @store_lines = {}
    @text_lines.each do |tl|
      found = false 
      tl1 = tl[1]
      $search_history.to_h.each_pair do |symbol, pattern|                                        # get the current search patterns
        found = true if /#{Regexp.escape(pattern)}/.match(tl1) unless pattern == ""
      end
      @store_lines.store(tl[0], tl[1]) if found 
      p @store_lines if found
    end
    exclude_count = 0
#    @text_area.each { |ta| p ta }
    @text_area.each do |ta|
      found = false 
#      @new_text_area.store(ta[0], ta[1]) if ta[0] < @line_start
      $search_history.to_h.each_pair do |symbol, pattern|                                        # get the current search patterns
        found = true if /#{Regexp.escape(pattern)}/.match(ta1[1]) unless pattern == ""
      end    
      if found                                                                                    # can not be found if excluded
        @new_text_area.store(ta[0] - 1, ["before", exclude_count]) if exclude_count > 0
        exclude_count = 0  
        if ta[0] <= @block_prior_index - @block_prior_count                                                
          exclude_count += 1
          @new_text_area.store(@ta[0], ["fill", ""])
        elsif ta[0] == @block_prior_index - @block_prior_count                                      # start just before block prior
          @block_prior_count += 1
          @new_text_area.store(@ta[0], ["fill", ""])
        elsif ta[0] == @block_prior_index + 1                                                    # start just after block prior
          @block_prior_count += 1
          @new_text_area.store(@ta[0], ["fill", ""])
          @block_prior_index += 1
          @new_text_area.store(@block_prior_index, ["before", @block_prior_count])
        elsif ta[0] == @block_prior_index - @block_prior_count                                # start just before block prior
          @block_prior_count += 1
          @new_text_area.store(@ta[0], ["fill", ""])
        elsif ta[0] == @block_end_index + 1                                                      # start just after block end
          @block_end_count += 1
          @new_text_area.store(@ta[0], ["fill", ""])
          @block_end_index += 1
          @new_text_area.store(@block_end_index, ["before", @block_end_count])
        elsif ta[0] > @block_end_index                                                
          exclude_count += 1
          @new_text_area.store(@ta[0], ["fill", ""])
        elsif ta[0] == text_lines.length
          exclude_count += 1                                                
          @new_text_area.store(ta[0], ["after", exclude_count])
        end
      end
    end
=end  

  # 3. Delete included lines in range.
  # Request is for a range of lines to be deleted if included in the display.
  # test_ring0x00 is the test case.
  def text_mixer_range_include
    p "text_mixer_range_include"
    @exclude_count = 0
    @deleted_count = 0
    @text_area.each do |ta|
      if ta[0] < @line_start
        @new_text_area.store(ta[0], ta[1])                            # copy to new text area
      end
      if (@line_start..@line_end).cover?(ta[0])                      # in range?
        ta1 = ta[1]                                                  # get [type, data]
        if ta1[0] == "text"
          @deleted_count += 1 
        else
          @new_text_area.store(ta[0], ta[1])  if ta1[0] == "fill"
          if ta[0] == @line_end
            @exclude_count = @line_end - @line_start
            @new_text_area.store(ta[0], ["before", @exclude_count]) 
          end
        end
      end
      if ta[0] > @line_end
        text_write_area(@block_end_index+1, @text_end)              # include these lines
      end
    end
    return @new_text_area
  end
  
  # 4. Delete excluded lines in range.
  # Request is for a range of lines to be deleted if excluded from the display
  def text_mixer_range_exclude
    p "text_mixer_range_exclude"
    @exclude_count = 0
    @text_area.each do |ta|
      @new_text_area.store(ta[0], ta[1]) if ta[0] < @line_start        # copy to new text area
      if (@line_start..@line_end).cover?(ta[0])                        # in range?
        ta1 = ta[1]                                                    # get [type, data]
        if ta1[0] == "text"
          @new_text_area.store(ta[0], ta[1])
        end
      end  
      @new_text_area.store(ta[0], ["fill", ""]) if (@line_end...@block_end_index).cover?(ta[0])                                                                                    
      if ta[0] == @block_end_index
        if @line_end <= @block_end_index - @block_end_count            # end exclude does not overlap
          excluded_count = @block_end_index - @line_end
          @new_text_area.store(ta[0], ["before", excluded_count])      # new exclude count
        else                                                            # end exclude does overlap  
          excluded_count = (@block_end_index - @line_end)
          excluded_count += 1 if @block_end_index == @line_end          # still counts as a line
          @new_text_area.store(ta[0], ["before", excluded_count])  
        end
      end
      if ta[0] > @block_end_index
        text_write_area(@block_end_index + 1, @text_end)                # include these lines
      end
    end
    return @new_text_area
  end
  # 5. Insert lines.
  # Not really working but an interesting start
  def text_mixer_range_insert(parameters)
    p "text_mixer_range_insert"
    @text_lines_index = 0
    @text_lines.each do |tl|
      if @line_start == tl[0] + 2
        @text_area.store(@text_lines_index += 1, tl[1])
        @line_start.upto(@line_end) { @text_area.store(@text_lines_index += 1, "insert") } 
      else
        @text_area.store(@text_lines_index += 1, tl[1])
      end
    end
    text_exclude(@text_area)
    text_mixer(@text_area, parameters)
    return @text_area
  end
  # 6. Delete a block of lines
  def text_mixer_range_delete
    p "text_mixer_range_delete"
    @new_text_area = {}
    @text_area_index = 0
    @text_area.each do |ta|
      unless (@line_start..@line_end).cover?(ta[0])
        p "ta[0] #{ta[0]}"
        @new_text_area.store(@text_area_index += 1, ta[1]) 
      end
    end
    @new_text_area.each { |ta| p ta }
    return @new_text_area
  end
  # 7. Copy lines before or after.
  # Request is for a block of lines to be copied
  def text_mixer_range_copy
    p "text_mixer_range_copy"
      @new_text_area.store(0, ["text", "Not yet implemented"])
    return @new_text_area
  end
  # 8. Move lines before or after.
  # Request is for a block of lines to be moved
  def text_mixer_range_move
    p "text_mixer_range_move"
      @new_text_area.store(0, ["text", "Not yet implemented"])
    return @new_text_area
  end
=begin
  @text_area.each do |ta|
    unless @line_start == 0
      @offset = @line_end - @line_start
      @index = 0
      @hold_area = {}
      @new_text_area.store(ta[0], ta[1]) if ta[0] < @line_start        # copy to new text area
      if (@line_start..@line_end).cover?(ta[0]) 
        @new_text_area.store(ta[0] + @index, ["insert", ""])           # insert new lines  
        @index += 1
        ta1 = ta[1]
        @hold_area.store(ta[0] + @offset, [ta[1]]) if ta1[0] == "before" || ta1[0] == "after" 
        @hold_area.store(ta[0] + @offset, [ta[1]]) if ta1[0] == "text"
      end
      @block_end_index += @index
      if ta[0] == @block_end_index
        if @line_end <= @block_end_index - @block_end_count            # end exclude does not overlap
          excluded_count = @block_end_index - @line_end
          @new_text_area.store(ta[0], ["before", excluded_count])      # new exclude count
        else                                                            # end exclude does overlap 
          excluded_count = (@block_end_index - @line_end)
          excluded_count += 1 if @block_end_index == @line_end          # still counts as a line
          @new_text_area.store(ta[0], ["before", excluded_count])  
        end
      end
      if ta[0] > @block_end_index
        text_write_area(@block_end_index + 1, @text_end)                # include these lines
      end
    else
      @index = 1
      @line_end.to_i.downto(1) { |line| @new_text_area.store(@index += 1, ["insert", ""]) }
      @index.upto(@line_end) { |index| @new_text_area.store(index + @index, [ta[1]]); }
    end
  end
  p @new_text_area
=end

  # 6. Move lines before or after.
  # Request is for a block of lines to be moved
  def text_mixer_range_delete
    p "text_mixer_range_delete"
       @new_text_area.store(0, ["text", "Not yet implemented"])
    return @new_text_area
  end
  # 7. Copy lines before or after.
  # Request is for a block of lines to be copied
  def text_mixer_range_copy
    p "text_mixer_range_copy"
       @new_text_area.store(0, ["text", "Not yet implemented"])
    return @new_text_area
  end
  # 8. Move lines before or after.
  # Request is for a block of lines to be moved
  def text_mixer_range_move
    p "text_mixer_range_move"
       @new_text_area.store(0, ["text", "Not yet implemented"])
    return @new_text_area
  end
=begin
    amount = @line_end - @line_start
    stop_at = @line_start + amount
    p "amount #{amount} at #{@line_start} stop at #{stop_at}"
    p "line start          #{@line_start}"
    p "line end            #{@line_end}"
    p "text end            #{@text_end}"
    p "block prior index   #{@block_prior_index}"
    p "block prior count   #{@block_prior_count}"
    p "block start index   #{@block_start_index}"
    p "block start count   #{@block_start_count}"
    p "block end index     #{@block_end_index}"
    p "block end count     #{@block_end_count}"
    p "block first         #{@block_first}"
    p "block last          #{@block_last}"
    @new_text_area.each { |ta| p ta }
=end
  
  
=begin 

=end
  # The text area is the "memory" map used to build the display logged to console.
  # This gets called out of the various formatter to write a line from memory to the display. 
  # Format is typically: [23, ["fill", ""]] or [24, ["before", 13]] 
  def text_write_area(from, to)
    @text_area.each { |ta| @new_text_area.store(ta[0], ta[1])  if (from..to).cover?(ta[0]) }
  end
  
  # The text lines area is the copy of the original file read in from disk.
  # All this does is write from the text lines area to the display when requested
  # by formatters that are restoring excluded lines.
  # Format is: [25, ["text", "25 r s t u v rstuv line2"]]
  def text_write_lines(from, to)
    @text_lines.each { |tl|  @new_text_area.store(tl[0]+1, ["text", tl[1]]) if (from..to).cover?(tl[0]) }
  end
  
end # class TextProcessor

