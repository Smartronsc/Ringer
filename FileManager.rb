#!/usr/bin/ruby

#  puts Dir.pwd <== shows you where you are running


class FileManager
  attr_accessor :handle, :file

  def file_open
 #  puts("in file_open")
    @handle = File.open("/home/brad/workspace/Ringer/testdata", "r") 
  end

  def file_close
#    puts("in file_close")
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
  
end # class FileManager