namespace :radiant do
  namespace :extensions do
    namespace :file_system_mirror do
      desc "Initialize the File System Mirror directory structure"
      task :init do |t|
        FileSystemMirror.init
      end
      
      desc "Pull"
      task :pull => :environment do
        FileSystemMirror.pull
      end

      desc "Push"
      task :push => :environment do
        FileSystemMirror.push
      end
    end
  end
end

desc "An alias for radiant:extensions:file_system_mirror:pull" 
namespace :file_system_mirror do
  task :pull do  
    Rake::Task['radiant:extensions:file_system_mirror:pull'].invoke  
  end
end

desc "An alias for radiant:extensions:file_system_mirror:push" 
namespace :file_system_mirror do
  task :push do  
    Rake::Task['radiant:extensions:file_system_mirror:push'].invoke  
  end
end