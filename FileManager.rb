
class FileManager
  
  # set up the data collection for  UserInterface::user_selection
  def file_get_initialization(directories = ENV["HOME"])              # this is linux specific for now
    $file_information = {}                                            # have this available ecerywhere
    @files = []                                                       # this is for each folders files
    @directory = ""                                                   # this is for / (root) /home and others
    directory = directories.split('/')
    directory.each do |directory|
      @directory = directory
      if directory == "home" || directory == ""
        Dir.chdir("/#{directory}")                                    # take care of root and home  
        Dir.foreach("/#{directory}") { |d|  @files.push(d) unless d == "." || d == ".." }     
        @directory = "root" if directory == ""                        # normalizes for user_selection
        $file_information.store(@directory, @files)
        @files = []
      else
        Dir.chdir("/home/#{directory}")                               # do the rest of the folders 
        Dir.foreach("/home/#{directory}") { |d| @files.push(d) unless d == "." || d == ".." }
        $file_information.store(@directory, @files)
        @files = []
      end
    end 
  end
    
  # this does data collection for  UserInterface::user_selection  
  def file_get_information(directory) 
    @files = []                                                       # this is for each folders files                                                  
    Dir.chdir("#{directory}")                                         # do the rest of the folders 
    Dir.foreach("#{directory}") { |d| @files.push(d) unless d == "." || d == ".." }
    $file_information.store(directory, @files)
    @files = []
  end
  
  # Opens any given file either from the default file, console input or history
  def file_open(file, mode = "r")
    handle = File.open("#{file}")
    text_lines = {}
    file_in = handle.readlines
    file_in.each_with_index do |line, line_num|
      text_lines[line_num] = line.chomp
    end
    return text_lines
  end

# Writes any given file
  def file_write(file, text_area)
    handle = File.open("#{file}")
    text_area.each_line { |line| handle.write(line) }
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