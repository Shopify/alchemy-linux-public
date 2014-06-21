require 'tmpdir'
require 'fileutils'

Rake::TaskManager.record_task_metadata = true

root_dir          = File.dirname(File.expand_path(__FILE__))

namespace :site do
  desc "Generate and serve the site"
  task :serve do | t, args |

    sh "bundle install"
    sh "bundle exec jekyll serve --baseurl ''"
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
