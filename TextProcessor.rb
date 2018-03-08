class TextProcessor
  
  def initialize
    @file_manager      = FileManager.new 
    @new_text_area    = {}
    @text_lines        = {}
    @line_start        = 0
    @line_end          = 0
    @line_actual      = -1
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
  # About the text_area:
  # * text_area full line format is [control_number, line_actual [control type, count or data in line]] as a hash
  # * text_area control format is control_number ["before", count of lines preceding] or ["text", data in line] as an array
  #
  # parameters are normalized to act as a range
  def text_mixer(text_area, parameters)
    # should not need to re-read here
    original_file = @file_manager.send(:file_history_current)                  # get the original file
    @text_lines  = @file_manager.send(:file_open, original_file)              # open it
    # text_end is used everywhere and has issues with being one off so be careful with it
    @text_end    = @text_lines.length                                        # actual data length
    @text_area    = text_area                                                  # contains display area
    @area_end    = @text_area.length                                          # actual area length
    @selection    = parameters[0]                                              # what to do
    @line_start  = parameters[1].to_i                                        # lower boundary for line data changes
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
    case @selection
      when "1"
        text_mixer_include
      when "2"
        text_mixer_exclude 
      when "3"
        text_mixer_rdnx                                                      # range delete not excluded
      when "4"
        text_mixer_rdx                                                        # range delete excluded  
      when "5"
        @text_processor.send(:text_copy, text_area, text_lines, @arguments)  # copy some lines 
      when "6"
        @text_processor.send(:text_move, text_area, text_lines, @arguments)  # move some lines 
      else
      puts("Exiting")
      exit
    end 
  end
  
  # The text area is the "memory" map used to build the display logged to console.
  # This gets called out of the various formatter to write a line from memory to the display.  
  def text_write_area(from, to)
    @text_area.each do |ta|                                    # area containing excluded information  
      if ta[0] >= from    
        if ta[0] <= to  
          @new_text_area.store(ta[0], ta[1])                    # copy to new text area
        end
      end
    end
  end
  
  # The text lines area is the copy of the original file read in from disk.
  # All this does is write from the text lines area to the display when requested
  # by formatters that are restoring excluded lines.
  def text_write_lines(from, to)
    @text_lines.each do |tl|                                    # original file 
      if tl[0] >= from                                      
        if tl[0] <= to 
          @new_text_area.store(tl[0]+1, ["text", tl[1]])        # copy to new text area
        end
      end
    end
  end
  
  # This includes more lines in text_area for 1. Include additional lines
  # It runs through text_area including new lines as specified.
  # It also adjusts the exclude counts as needed.
  def text_mixer_include
    exclude_count = 0
    @text_area.each do |ta|
      if ta[0] <= @line_start
        @new_text_area.store(ta[0], ta[1])                        # copy to new text area
      end
      if ta[0] == @block_start_index      
        @new_text_area.store(ta[0], ["before", exclude_count])    # calculate new exclude count
      end
      if ta[0] >= @line_start && ta[0] <= @line_end
        text_write_lines(@line_start, @line_end)                  # include these lines
      end
      if ta[0] > @line_end
        @new_text_area.store(ta[0], ta[1])                        # copy to new text area
      end
    end  
    return @new_text_area
  end
  
# This excludes more lines in text_area for 2. Exclude additional lines
# It runs through text_area excluding new lines as specified simply
# leaving out the range of lines to be excluded.
def text_mixer_exclude
  exclude_count = 0
  @text_area.each do |ta|
    if ta[0] < @line_start
      @new_text_area.store(ta[0], ta[1])                              # copy to new text area
    end  
    if ta[0] == @line_start                                          # start of exclusion
      if @line_start == @block_prior_index || @line_start == @block_prior_index + 1 # continues existing exclude                                                                                          
        if @line_end >= @block_end_index - @block_end_count          # exclude overlaps two existing excludes
          if @line_start == @block_prior_index                        # overlays control
            exclude_count = ((@block_end_index) - @line_end) + ((@line_end+1) - @line_start) + @block_prior_count
          else                                                        # adjacent to contorl
            exclude_count = ((@block_end_index+1) - @line_end) + ((@line_end+1) - @line_start) + @block_prior_count
          end
          @new_text_area.store(ta[0]-1, ["before", exclude_count])    # new exclude count
        else
          exclude_count = @line_end+1 - @line_start + @block_prior_count
          @new_text_area.store(ta[0]-1, ["before", exclude_count])    # new exclude count      
        end
      else
        exclude_count = @block_start_index - @line_start    
        @new_text_area.store(ta[0]-1, ["before", exclude_count])      # new exclude count
      end
    end
    if ta[0] > @line_end
      if @line_end < @block_end_index - @block_end_count              # end exclude does not overlap
        if @line_start == @block_prior_index + 1                      # first exclude joins existing exclude
          exclude_count = ((@line_end+1) - @line_start) + @block_prior_count
          @new_text_area.store(ta[0]-1, ["before", exclude_count])    # new exclude count
        else
          exclude_count = ((@line_end+1) - @line_start)
          @new_text_area.store(ta[0]-1, ["before", exclude_count])    # calculate new exclude count
        end
      end
      if @line_end >= @block_end_index - @block_end_count            # exclude overlaps end exclude  
        @line_end = @block_end_index
      end
      text_write_area(@line_end+1, @text_end)                        # include these lines
    end
  end  
  return @new_text_area
end


  # This builds a hash table of the initial excluded lines.
  # * It runs a search history to support multiple excludes.
  # * It does the Regexp matching for each pattern for each line.
  # * Everything is counted and excluded until a match is found.
  # * At that point the excluded count is written and text follows.
  # This logic repeats until the "after count is written at EOF.
  def text_exclude(text_lines)
    @text_end    = text_lines.length                              # actual data length used everywhere
    text_area    = {}
    exclude_count = 0
    line_number  = -1
    last_line    = -1
    found        = false 
    after        = false  
    text_lines.each do |line_number, text|                          # read the file line by line
      $search_history.to_h.each_pair do |symbol, pattern|          # get the current search patterns
        @pattern = pattern unless pattern == ""                    # formal argument cannot be an instance variable
        found = true if /#{Regexp.escape(pattern)}/.match(text) unless pattern == ""
      end
      if found                                                      # is it what is being looked for?
        if exclude_count > 0                                        # yes, none excluded yet?
          text_area.store(line_number, ["before", exclude_count])  # no, write out excluded line count
          last_line = line_number+1                                # save for end of file processing
        end                                                      
        text_area.store(line_number+1, ["text", text])              # always write out this line
        last_line = line_number+1                                  # save for end of file processing
        exclude_count = 0                                          # no lines currently excluded
      else
        text_area.store(line_number+1, ["fill", ""])                # provides accurate line positioning
        last_line = line_number+1                                  # save for end of file processing
      end 
      exclude_count += 1 unless found || line_number == @text_end-1 # if no match in this line
      found = false
    end
    if exclude_count > 0 
      text_area.store(line_number+1, ["after", exclude_count])
    end
    return text_area
  end
  
  # Request is for all excluded lines to be deleted from the display
  def text_delete_x(text_lines)
    @user_interface = UserInterface.new
    text_area    = {}
    @line_actual = -1
    found        = false    
    text_lines.each do |line_num, text|                              # read the file line by line
      $search_history.to_h.each_pair do |symbol, pattern|            # get the current search patterns
        found = true if /#{Regexp.escape(pattern)}/.match(text) unless pattern == ""
      end
      text_area.store(line_num+1, ["text", text]) if found          # write out this line            
      found = false
    end 
    return text_area 
  end
  
  # Request is for all not excluded lines to be deleted from the display
  def text_delete_nx(text_lines)
    @user_interface = UserInterface.new
    text_area    = {}
    @line_actual = -1
    not_found    = true    
    text_lines.each do |line_num, text|                                # read the file line by line
      $search_history.to_h.each_pair do |symbol, pattern|              # get the current search patterns
        not_found = false if /#{Regexp.escape(pattern)}/.match(text) unless pattern == ""
      end
      text_area.store(line_num+1, ["text", text]) if not_found # write out this line if not found
      not_found = true
    end 
    return text_area 
  end

  # 3. Delete not included lines
  # Request is for a range of lines to be deleted if included in the display
  def text_mixer_rdnx
    deleted_count = 0
    exclude_count = 0
    @text_area.each do |ta|
      @new_text_area.store(ta[0], ta[1]) if ta[0] < @line_start        # copy to new text area
      if ta[0] == @line_start                                          # start of exclusion
        if @line_start == @block_prior_index || @line_start == @block_prior_index + 1 # continues existing exclude    
          if @line_end >= @block_end_index - @block_end_count          # exclude overlaps two existing excludes
            if @line_start == @block_prior_index                        # overlays control
              exclude_count = ((@block_end_index) - @line_end) + ((@line_end+1) - @line_start) + @block_prior_count
            else                                                        # adjacent to contorl
              exclude_count = ((@block_end_index+1) - @line_end) + ((@line_end+1) - @line_start) + @block_prior_count
            end
            @new_text_area.store(ta[0]-1, ["before", exclude_count])    # new exclude count
          else
            exclude_count = @line_end+1 - @line_start + @block_prior_count
            @new_text_area.store(ta[0]-1, ["before", exclude_count])    # new exclude count
          end       
        end                  
      end 
      if (@line_start..@line_end).cover?(ta[0])                         # in range?
        ta1 = ta[1]                                                     # yes, get control word
        deleted_count += 1 if ta1[0] == "text"
      end                                                                 
      if ta[0] > @line_end
        if @line_end < @block_end_index - @block_end_count              # end exclude does not overlap
          excluded_count = @line_end - @line_start
          @new_text_area.store(ta[0]+1, ["before", excluded_count])       # new exclude count
          text_write_area(@block_end_index + 1, @text_end)              # include these lines
        end
        if @line_end >= @block_end_index - @block_end_count             # end exclude does overlap   
          excluded_count = (@block_end_index - @line_end) + (@line_end - @line_start) - deleted_count 
          excluded_count += 1 if @block_end_index == @line_end          # still counts as a line
          p deleted_count
          @new_text_area.store(ta[0]+1, ["before", excluded_count])  
          text_write_area(@block_end_index + 1, @text_end)              # include these lines
        end
      end
    end 
    return @new_text_area
  end 
  
  # 4. Delete excluded lines
  # Request is for a range of lines to be deleted if excluded from the display
  def text_mixer_rdx
    exclude_count = 0
    @text_area.each do |ta|
      if ta[0] < @line_start
        @new_text_area.store(ta[0], ta[1])                              # copy to new text area
      end
      if ta[0] == @line_start
        exclude_count = (@block_start_index - @line_start) - 1          # show one less than calculated    
        @new_text_area.store(ta[0]-1, ["before", exclude_count])        # new exclude count
      end
      if ta[0] >= @line_start && ta[0] <= @line_end
        ta1 = ta[1]                                                    # get [type, data]
        @new_text_area.store(ta[0], ta[1]) if ta1[0] == "text"          # copy to new text area                            
      end
      if ta[0] > @line_end
        if @line_end < @block_end_index - @block_end_count              # end exclude does not overlap
          @new_text_area.store(ta[0], ["before", @block_end_count])    # new exclude count
          text_write_area(@block_end_index + 1, @text_end)              # include these lines
        end
        if @line_end >= @block_end_index - @block_end_count            # exclude overlaps end exclude  
          excluded_count = @block_end_index - @line_end                #new exclude count  
          @new_text_area.store(ta[0], ["before", excluded_count]) 
          text_write_area(@block_end_index + 1, @text_end)              # include these lines
        end
      end 
    end  
    return @new_text_area
  end

=begin
    amount = @line_end - @line_start
    stop_at = @line_start + amount
    p "amount #{amount} after #{@line_start} stop at #{stop_at}"
    p "line_start          #{@line_start}"
    p "line_end            #{@line_end}"
    p "text_end            #{@text_end}"
    p "block_prior_index   #{@block_prior_index}"
    p "block_prior_count   #{@block_prior_count}"
    p "block_start_index   #{@block_start_index}"
    p "block end_index     #{@block_end_index}"
    p "block_first         #{@block_first}"
    p "block_last          #{@block_last}"
=end

end # class TextProcessor