#!/usr/bin/ruby

class TextProcessor
  attr_writer :handle, :this_one, :these_lines, :text_area
  
  # this sets up the flat file to be fed in to the exclusion logic
  def text_handler(handle, this_one, these_lines, text_area)
#   puts("in text_handler")
    text_lines = {}
    file_in = handle.readlines
    file_in.each_with_index do |line, line_num|
      text_lines[line_num] = line.chomp
    end
  p these_lines
    lines_out = text_exclude(text_lines, this_one, these_lines, text_area)
  end
  
  # this builds the hash table of excluded lines
  def text_exclude(text_lines, this_one, these_lines, text_area)
#   puts "in exclude"
    p these_lines
    exclude_count =  0
    line_number   = -1
    last_line     = -1
    last_text     = ""
    lump          = ""
    text_lines.each do |line_num, text|                                 # read the file line by line
      text_lumps = text.split(" ")                                      # split up each line into lumps
      if text_lumps.include?(this_one)                                  # is it what is being looked for?
        if exclude_count > 0                                            # yes, only looked at this line?
          text_area.store(line_num, ["before", exclude_count])          # no, write out excluded line count
        end                                                             # end of if exclude_count > 0
        text_area.store(line_num+1, ["text", text])                     # lump found, write out this line
        line_number   = line_num                                        # expand scope beyond text_lines.each do
        last_line     = line_num+1                                      # save for end of file processing
        last_text     = text                                            # save for end of file processing
        exclude_count = 0                                               # no lines have been excluded yet
        lump = ""
      end                                                               # end of if text_lumps.include?(this_one)  
      exclude_count += 1 unless text_lumps.include?(this_one)           # if no lumps matched this_one in this line
    end
    if exclude_count > 1
      puts "#{line_number+1} excluded #{exclude_count} trailing"
      text_area.store(line_number+1, ["after", exclude_count])
    end
    if exclude_count == 1
      puts "#{line_number+1} excluded #{exclude_count} trailing"
      text_area.store(line_number+1, ["after", exclude_count])
    end
    text_area.delete(last_line)
    text_area.store(last_line, ["text", last_text]) 
    text_area.store(last_line+1, ["after", exclude_count])
    return text_area
  end
  
end # class TextProcessor
