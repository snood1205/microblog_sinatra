# frozen_string_literal: true

class Root
  def self.join(*file_path)
    File.join(File.dirname(__FILE__), *file_path)
  end
end
