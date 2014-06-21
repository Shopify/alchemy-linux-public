require 'tmpdir'
require 'fileutils'

Rake::TaskManager.record_task_metadata = true

root_dir          = File.dirname(File.expand_path(__FILE__))

namespace :site do
  desc "Generate and serve the site"
  task :serve, [:branch]  => [:apidoc] do | t, args |
    if args[:branch].nil?
      branch = "master"
    else
      branch = args[:branch]
    end

    sh "bundle exec jekyll serve --baseurl ''"
  end

  desc "Generate API docs"
  task :apidoc, [:branch] do | t, args |
    if args[:branch].nil?
      branch = "master"
    else
      branch = args[:branch]
    end
    tmp_dir = Dir.mktmpdir

    sh "git --git-dir=#{File.join(root_dir,'.git')} archive #{branch} | tar -xpf - -C #{tmp_dir}"

    Dir.chdir(tmp_dir) do
      sh "rake docs:generate"
    end

    doc_dir = File.join(root_dir, 'doc')

    FileUtils.rm_rf(doc_dir)
    FileUtils.move(File.join(tmp_dir,'doc'), doc_dir)
    FileUtils.rm_rf(tmp_dir)
  end
end

desc "Print a detailed help with usage examples"
task :help do

  help = <<-eos
Serve the test site
  rake site:serve
  eos
  puts help

end

# Print the help if no arguments are given
task :default do
  Rake::application.options.show_tasks = :tasks  
  Rake::application.options.show_task_pattern = //
  Rake::application.display_tasks_and_comments
end
