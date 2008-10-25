# Uncomment this if you reference any of your controllers in activate
# require_dependency 'application'

class FileSystemMirrorExtension < Radiant::Extension
  version "0.1"
  description "Allows you to pull and push Layout, Snippet, and Page Part content between the file system and the Radiant database."
  url "http://webadvocate.com"
  
  def activate
    require 'file_system_mirror'
    FileSystemMirror.init
  end
  
  def deactivate
  end
end