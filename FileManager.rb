
class FileManager
 
  def file_get_information(branch = ENV["HOME"])
    $file_information = {}
    @files = []
    @directory = ""
    branch_split = branch.split('/')
    branch_split.each do |directory|
      @directory = directory
      if directory == "home" || directory == ""
        Dir.chdir("/#{directory}")  
        Dir.foreach("/#{directory}") do |d| 
          @files.push(d) unless d == "." || d == ".." 
        end
        $file_information.store(@directory, @files)
        @files = []
      else
        Dir.chdir("/home/#{directory}")  
        Dir.foreach("/home/#{directory}") do |d| 
          @files.push(d) unless d == "." || d == ".." 
        end  
        $file_information.store(@directory, @files)
        @files = []
      end
    end 
  end
  
  # Opens any given file either from the default file, console input or history
  def file_open(file)
    handle = File.open("#{file}", "r")
    text_lines = {}
    file_in = handle.readlines
    file_in.each_with_index do |line, line_num|
      text_lines[line_num] = line.chomp
    end
    return text_lines
  end

  # Nothing really gets closed as yet 
  def file_close
    @handle.close
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
      p file_name
      return file_name unless file_name == ""
    end
  end

end # End of class FileManager
