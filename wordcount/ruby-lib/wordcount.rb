module WordCount
  def WordCount.count(string,language)
    s = preprocess(string,language)
    # Split into words along spaces.
    return s.split(/\s+/).length
  end
  def WordCount.count_in_file(filename,language)
    contents = nil
    File.open(filename,'r') do |f|
      contents = f.read
    end
    return WordCount.count(contents,language)
  end
  def WordCount.preprocess(string,language)
    case language
    when :latex
	WordCount.preprocess_latex(string)
    else
	fail "Unknown language #{language}"
    end
  end
  def WordCount.preprocess_latex(string)
    s = string.dup
    # Remove all LaTeX comments
    s.gsub!(/%.*?\n/,' ')
    # Remove excess whitespace.
    s.strip! # Remove leading and tailing (aww) whitespace
    s.gsub!(/\s+/,' ') # multiple whitespace characters to one space
    # Mess with content.
    s.gsub!(/\\emph\{([^\}]*?)\}/,'\1') # Remove emphasis.
    s.gsub!(/\\l?dots\{\}/,'...') # Dot dot dot.
    s.gsub!(/\s+---?\s+/,' ') # Dashes surrounded by spaces into nothing
    s.gsub!(/(\S)---(\S)/,'\1 \2') # Intra---dashes into a space.
    s.gsub!(/"(``|'')/,'') # rm quotes; might get counted as separate wds
    return s
  end
end
