#!/usr/bin/ruby

require './TextProcessor.rb'

class FileManager

  def file_open(file)
    @handle = File.open("#{file}", "r")
    @text_processor = TextProcessor.new
    @text_processor.send(:text_handler, @handle) 
  end

  def file_close
    @handle.close
  end
    
  def file_print(results)
    puts("in file_print for #{results}")
  end
  
  def file_print_all
    puts("in file_all")
    file_in = @handle.readlines
    file_in.each { |line| p line }
  end
  
end 