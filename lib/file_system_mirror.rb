class FileSystemMirror
  PAGES_DIR = "#{RAILS_ROOT}/radiant_mirror/pages"
  SNIPPETS_DIR = "#{RAILS_ROOT}/radiant_mirror/snippets"
  LAYOUTS_DIR = "#{RAILS_ROOT}/radiant_mirror/layouts"
  TRASH_DIR = "#{RAILS_ROOT}/radiant_mirror/.trash"
  
  NUM_TRASH_FOLDERS_TO_KEEP = 3
  
  @@fsm_source_directories = [PAGES_DIR, SNIPPETS_DIR, LAYOUTS_DIR]
  cattr_reader :fsm_source_directories
  
  @@fsm_directories = fsm_source_directories + [TRASH_DIR]
  cattr_reader :fsm_directories
  
  @@content_type_extensions = {
    'text/html' => 'html',
    'text/css' => 'css',
    'application/javascript' => 'js'
  }
  cattr_reader :content_type_extensions
  
  @@filter_type_extensions = {
    'Textile' => 'textile',
    'Markdown' => 'markdown',
    'SmartyPants' => 'markdown'
  }
  cattr_reader :filter_type_extensions
  
  class << self
    def init
      FileUtils.mkdir_p fsm_directories
    end
    
    def pull
      unless fsm_directories.all? {|d| File.exist? d }
        init
      end
      
      # Copy existing files to a timestamped trash folder
      dest = File.join(TRASH_DIR, Time.now.utc.strftime("%Y%m%d%H%M%S"))
      FileUtils.mkdir_p(dest)
      
      fsm_source_directories.each do |dir|
        # Rescursively copy the contents of the directory
        FileUtils.cp_r dir, dest
        # Then delete the contents
        FileUtils.rm_rf(Dir.glob(File.join(dir, "*")))
      end
      
      # Cleanup old trash directories.  Delete the oldest n directories (n is given by +NUM_TRASH_FOLDERS_TO_KEEP+)
      dirs_to_delete = Dir.glob(File.join(TRASH_DIR, "*")).sort.reverse[NUM_TRASH_FOLDERS_TO_KEEP..-1] || []
      dirs_to_delete.each do |trash|
        FileUtils.rm_rf(trash)
      end
      
      # Grab radiant resources (Layouts, Snippets, PageParts)
      resources.each do |resource|
        File.open(filename(resource), "w") do |file|
          file.print resource.content
        end
      end
    end
    
    def push
      # Only push what is already in the site
      resources.each do |resource|
        file = filename(resource)
        if File.exist? file
          File.open(file, "r") do |file|
            resource.update_attribute(:content, file.read)
          end
        end
      end
    end
    
    private
    def filename(resource)
      case resource
      when Layout
        File.join(LAYOUTS_DIR, "#{resource.name}.#{extension(resource)}")
      when Snippet
        File.join(SNIPPETS_DIR, "#{resource.name}.#{extension(resource)}")
      when PagePart
        path = resource.page.url.split('/').delete_if(&:blank?) # Gets path components as an array
        dir = File.join(path[0...-1])
        slug = path.last || 'home'
        unless dir.empty?
          FileUtils.mkdir_p File.join(PAGES_DIR, dir)
        end
        File.join(PAGES_DIR, dir, "#{slug}.#{resource.name}.#{extension(resource)}")
      else
        'unknown.txt'  
      end
    end
    
    def extension(resource)
      case resource
      when Layout
        content_type_extensions[resource.content_type] || 'html'
      when PagePart, Snippet
        filter_type_extensions[resource.filter_id] || 'html'
      else
        'html'
      end
    end
    
    def resources
      resources  = Layout.find(:all)
      resources += Snippet.find(:all)
      resources += Page.find(:all).collect(&:parts).flatten
    end
  end
end