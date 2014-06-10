require          'yaml'
require_relative 'lib/util'

$root_dir          = File.dirname(File.expand_path(__FILE__))
$config_path       = File.dirname(File.expand_path(__FILE__)) + '/config.yml'
$dependencies      = ['lzma','git','bc','wget','chroot','gcc','cpio','find']

Rake::TaskManager.record_task_metadata = true

# Main namespace for building
namespace :build do

  desc "Print the build configuration"
  task :info do 
    puts $config.to_yaml
  end

  desc "Check build dependencies"
  task :check_depends do
    puts "Checking build dependencies..."
    $dependencies.each do |depend|
       begin
         sh "which #{depend}"
       rescue
         puts "Error - missing dependencie #{depend}"
         exit
       end
    end
  end

  desc "(re)build the system and initramfs"
  task :system, [:version] => ["util:seed_image", "util:insert_overlays", "util:bind_chroot"] do | t, args |
    begin
      sh "sudo chroot #{$chroot_dir} /bootstrap/setup.sh"
    ensure
      Rake::Task["util:post_build"].invoke
    end
  end


  desc "Create the lzma compressed ramfs from the system image"
  task :ramfs => [:check_depends, :system] do
    bin_dir = File.join($root_dir, 'bin')
    threads = `nproc`.strip
    sh "mkdir -p #{bin_dir}"
    cwd = Dir.pwd
    Dir.chdir( $chroot_dir )
    sh "sudo find . \
      -path ./extracted -prune -o \
      -path ./bootstrap -prune -o \
      -path ./packages -prune -o \
      -path ./distfiles -prune -o \
      -path ./usr/share/locale -prune -o \
      -path ./usr/share/doc -prune -o \
      -path ./usr/share/gtk-doc -prune -o \
      -path ./usr/share/man -prune -o \
      -path ./tmp -prune -o \
      -path ./packages -prune -o \
      -path ./var/tmp -prune -o \
      -path ./usr/portage -prune -o \
      -path ./usr/local/portage -prune -o \
      -path ./var/db/pkg -prune -o \
      -path ./usr/share/mime -prune -o \
      -print | grep -v include | sudo cpio -H newc -ov -R 0:0 | lzma -T #{threads} -9 > #{File.join(bin_dir, $config['ramfs_name'])}"
    Dir.chdir( pwd )
  end

  desc "(re)build the kernel"
  task :kernel, [:version] => [:check_depends] do | t, args |
    cwd = Dir.pwd
    bin_dir = File.join($root_dir, 'bin')
    sh "mkdir -p #{bin_dir}"

    if args[:version].nil?
      version = "wip"
    else
      version = args[:version]
    end

    sh "sudo mkdir -p #{$config['kernel_src']}"
    sh "sudo chown -R `whoami` #{$config['kernel_src']}"
    unless File.directory? "#{File.join($config['kernel_src'],'.git')}"
      sh "git clone #{$config['linux_url']} #{$config['kernel_src']}"
    end

    Dir.chdir($config['kernel_src'])
    sh "git fetch"

    if $config.has_key? 'kernel_ver'
      sh "git checkout #{$config['kernel_ver']}"
    else
      sh "git checkout `git describe --abbrev=0 --tags`"
    end

    kernel_config = File.join($config['kernel_src'], '.config')

    sh "cp #{File.join($root_dir, 'kernels', $config['kernel_conf'])} #{kernel_config}"
    sh "sed -i 's:^CONFIG_LOCALVERSION=.*$:CONFIG_LOCALVERSION=\"Alchemy Linux #{version}\":g' #{kernel_config}"
    # Used to embed ramfs into kernel, not supported yet
    #sed -i -e "s|^CONFIG_INITRAMFS_SOURCE=.*$|CONFIG_INITRAMFS_SOURCE=\"$RAMFS_FILE\"|" .config
    #[ -n "$CHROOT_DIR" ] && rm -rf $CHROOT_DIR/lib/modules/*
    #sh "make -j`nproc` modules"
    #INSTALL_MOD_PATH=$CHROOT_DIR make modules_install

    sh "echo 'y' | make oldconfig"
    sh "make -j`nproc`"
    sh "mv arch/x86/boot/bzImage #{File.join(bin_dir,$config['image_name'])}"

  end

  desc "(re)build everything"
  task :all, [:version] => [:info, :ramfs, :kernel] do 
    image_size = `du -hs #{File.join($root_dir,'bin',$config['image_name'])}`.strip
    ramfs_size = `du -hs #{File.join($root_dir,'bin',$config['ramfs_name'])}`.strip
    puts "Build completed! Output image is #{image_size}, and ramfs is #{ramfs_size}"
  end

end

desc "Print a detailed help with usage examples"
task :help do

  help = <<-eos

The repository is for building and customizing Alchemy Linux.

Check config.yml.example for a sample configuration.

To perform a full build:

  rake build:all[version] # the version param is optional

To build just the system:

  rake build:ramfs

To build just the kernel:

  rake build:kernel

To clean up:

  rake util:clean
  eos
  puts help

end

# Print the help if no arguments are given
task :default do
  Rake::application.options.show_tasks = :tasks  
  Rake::application.options.show_task_pattern = //
  Rake::application.display_tasks_and_comments
end

# Load the config file if exists, or print help
if File.exists? $config_path
  $config = YAML::load(File.open($config_path))
  $chroot_dir = "#{$config['work_dir']}/chroot_dir"
else
  puts "A config file is required. See config.yml.example for details"
  Rake::Task["default"].invoke
  exit 1
end
