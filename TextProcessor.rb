class TextProcessor
  
  def initialize
    @file_manager      = FileManager.new 
    @new_text_area     = {}
    @text_lines        = {}
    @line_start        = 0
    @line_end          = 0
    @line_actual       = -1
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
    @block_end_count   = 0
    @block_end_index   = 0
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
    original_file = @file_manager.send(:file_history_current)                  # get the original file
    @text_lines   = @file_manager.send(:file_open, original_file)              # open it
    @text_end     = @text_lines.length                                         # actual data length
    @text_area    = text_area                                                  # contains display area
    @area_end     = @text_area.length                                          # actual area length
    @selection    = parameters[0]                                              # what to do
    @line_start   = parameters[1].to_i                                         # lower boundary for line data changes
    @line_end     = parameters[2].to_i                                         # upper boundary for line data changes
    @keys         = text_area.keys                                             # text_area keys are the control areas
    @block_first  = @keys.first                                                # end of text_area
    @block_last   = @keys.last                                                 # last control line in text_area
    @line_end     = @text_end if @line_end > @text_end                         # clean up directive 
    # 
    # find the section of data to modify based on finding the "before" type preceding and following the range
    # it is also necessary to keep track of the block prior to the block preceding for uses with excludes of excludes
    #
    @keys.each do |k|                                                          # find start text_area type "before"
      if k > @line_start                                                       # use this to format new following data
        @block_start_index = k                                                 # and new preceding "before" information
        @block_start_line = text_area.values_at(k)                             # get control value using line number as key
        @block_start_line.flatten!                                             # comes back as one array too many
        @block_start_count = @block_start_line[1]                              # this is the amount to adjust
        @block_start_type  = @block_start_line[0]                              # just to make it clear, not needed
        break if @block_start_type == "before"                                 # first one after k > line_start 
      else
        @block_start_index = @keys.last                                        # use last control number  
      end
    end
    @keys.each do |k|                                                          # find prior text_area of type "before"
      if k < @line_start                                                       # use this to format new excluded data
        @block_prior_index = k                                                 # making this the possible "prior" block
        @block_prior_line = text_area.values_at(k)                             # get control using line number as key
        @block_prior_line.flatten!                                             # comes back as one array too many
        if @block_prior_line[0] == "before"                                    # if this is a "before" control
          @block_prior_count = @block_prior_line[1]                            # this is the amount to adjust
        end
      end  
    end
    @keys.each do |k|                                                          # find end text_area type "before"
      if k >= @line_end                                                        # use this to format new preceeding data
        @block_end_index = k                                                   # and new following "before" information
        @block_end_line  = text_area.values_at(k) 
        @block_end_line.flatten!
        @block_end_count = @block_end_line[1]
        break if @block_end_line[0] == "before"                                # first one after k > line_end
      else
        @block_end_index = @text_lines.length                                  # use end of file
      end
    end  
    case @selection
      when "1"
      text_mixer_include
      when "2"
      text_mixer_exclude 
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
    @text_area.each do |ta|                                     # area containing excluded information  
      if ta[0] >= from     
        if ta[0] <= to  
          @new_text_area.store(ta[0], ta[1])                    # copy to new text area
        end
      end
    end
  end
  
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
    p "text_mixer_include"
#    @user_interface = UserInterface.new
=begin
    amount = @line_end - @line_start
    stop_at = @line_start + amount
    p "amount #{amount} after #{@line_start} stop at #{stop_at}"
    p "line_start          #{@line_start}"
    p "line_end            #{@line_end}"
    p "text_end            #{@text_end}"
    p "block_start_index   #{@block_start_index}"
    p "block end_index     #{@block_end_index}"
    p "block_first         #{@block_first}"
    p "block_last          #{@block_last}"
=end
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
# It runs through text_area including new lines as specified.
# It also adjusts the exclude counts as needed.
def text_mixer_exclude
  p "text_mixer_exclude"
#=begin
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
#=end
  excluded      = 0
  exclude_count = 0
  @text_area.each do |ta|
      if ta[0] < @line_start
        @new_text_area.store(ta[0], ta[1])                          # copy to new text area
    end
    if ta[0] == @line_start                                         # start of exclusion
      if @line_start == @block_prior_index + 1                      # first exclude joins existing exclude
        exclude_count = @line_end+1 - @line_start + @block_prior_count
        @new_text_area.store(ta[0]-1, ["before", exclude_count])      # new exclude count
          p "here 1"
      else
        exclude_count = @block_start_index - @line_start    
        @new_text_area.store(ta[0]-1, ["before", exclude_count])      # new exclude count
          p "here 2"
      end
    end
    if ta[0] >= @line_start && ta[0] <= @line_end
      excluded += 1
      p "exclude #{ta} #{excluded}"
    end
    if ta[0] > @line_end
      @new_text_area.store(ta[0]-1, ["before", exclude_count + excluded]) # calculate new exclude count
      text_write_area(@line_end+1, @text_end)                         # include these lines
    end
  end  
  return @new_text_area
end

  # This builds a hash table of excluded lines.
  # * It runs a search history to support multiple excludes.
  # * It does the Regexp matching for each pattern for each line.
  # * Everything is counted and excluded until a match is found.
  # * At that point the excluded count is written and text follows.
  # This logic repeats until the "after count is written at EOF.
  def text_exclude(text_lines)
    text_area     = {}
    exclude_count = 0
    line_number   = -1
    last_line     = -1
    last_text     = ""
    found         = false 
    after         = false  
    text_lines.each do |line_number, text|                           # read the file line by line
      $search_history.to_h.each_pair do |symbol, pattern|            # get the current search patterns
        @pattern = pattern unless pattern == ""                      # formal argument cannot be an instance variable
        found = true if /#{Regexp.escape(pattern)}/.match(text) unless pattern == ""
      end
      if found                                                       # is it what is being looked for?
        if exclude_count > 0                                         # yes, only looked at this line?
          text_area.store(line_number, ["before", exclude_count])    # no, write out excluded line count
        end                                                          # end of if exclude_count > 0
        text_area.store(line_number+1, ["text", text])               # write out this line
        last_line    = line_number+1                                 # save for end of file processing
        last_text    = text                                          # save for end of file processing
        exclude_count = 0                                            # no lines have been excluded yet
      else
        text_area.store(line_number+1, ["fill", ""])                 # provides accurate line positioning
      end 
      exclude_count += 1 unless found                                # if no match in this line
      found = false
    end
    if exclude_count > 0 
      text_area.store(line_number+1, ["after", exclude_count])
    end
    return text_area
  end
  
  
  def text_deletex(text_lines)
    @user_interface = UserInterface.new
    text_area    = {}
    @line_actual = -1
    found        = false    
    text_lines.each do |line_num, text|                              # read the file line by line
      $search_history.to_h.each_pair do |symbol, pattern|            # get the current search patterns
        found = true if /#{Regexp.escape(pattern)}/.match(text) unless pattern == ""
      end
      text_area.store(line_num+1, ["text", text]) if found # write out this line            
      found = false
    end 
    return text_area 
  end
  
  def text_deletenx(text_lines)
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

end # class TextProcessor
