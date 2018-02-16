#!/usr/bin/ruby

require './TextProcessor.rb'

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
  
  # lots of possible uses for this but right now current is current
  def file_history_current
    file_history = $file_history.to_h
    file_history.each_pair do |index, file_name|
      return file_name unless file_name == ""
    end
  end
 
 end # End of class FileManager