
class FileManager
  
  # set up the data collection for  UserInterface::user_selection
  def file_get_initialization(structure = ENV["HOME"])                # this is linux specific for now
    $file_information = {}                                            # have this available everywhere
    files = [] 
    directory = ""
    directories = []                                                  
    things = structure.split('/')
    things.each do |thing|
      if thing == ""
        directories.push("/root")
      else
        directory = "#{directory}/#{thing}" 
        directories.push("#{directory}") if File.directory?("#{directory}")
      end
    end 
    return directories
  end
    
  def file_get_files(directories) 
    file_information = {"/home" => ["none"]}
    directory = ""
    files = []
     p "file_get_files directories #{directories}"
    directories.each do |directory| 
      unless directory == "/root"
        Dir.chdir("#{directory}")  
        Dir.foreach("#{directory}") do |d|  
          files.push(d) unless d == "." || d == ".." 
           p "file_get_files directories #{directories}"
        end
        file_information.store(directory, files)
         p "file_get_files file_information #{file_information}"
        files = []
      end
      return file_information
  end
    # p "file_information #{file_information}"
    return file_information
  end
      
  def file_get_information(directory) 
    @files = []                                                      
    Dir.chdir("#{directory}")                                        
    Dir.foreach("#{directory}") { |d| @files.push(d) unless d == "." || d == ".." }
    $file_information.store(directory, @files)
    @files = []
  end
  
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
      p "file_name #{file_name}"
      return file_name unless file_name == ""
    end
  end
    
end # class FileManager