require          'yaml'
require_relative 'lib/util'

$root_dir          = File.dirname(File.expand_path(__FILE__))
$config_path       = File.dirname(File.expand_path(__FILE__)) + '/config.yml'
$dependencies      = ['lzma','git','bc','wget','chroot','gcc','cpio','find','dd','tar','mkfs.ext4','mount','sudo']

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
  task :ramfs => [:check_depends, :system, :kernel] do
    cwd = Dir.pwd

    bin_dir = File.join($root_dir, 'bin')
    threads = `nproc`.strip
    sh "mkdir -p #{bin_dir}"
    sh "mkdir -p #{$ramfs_mount}"
    sh "mkdir -p #{$ramfs_dir}"

    # Install busybox and init script
    sh "mkdir -p #{$ramfs_dir}/bin"
    sh "cp #{$chroot_dir}/init #{$ramfs_dir}/init"
    sh "cp #{$chroot_dir}/bin/busybox #{$ramfs_dir}/bin/busybox"
    sh "chmod +x #{$ramfs_dir}/bin/busybox"
    Dir.chdir("#{$ramfs_dir}/bin")
    sh "ln -sf busybox sh"

    # generate the system image
    Dir.chdir( $chroot_dir )
    puts "Cloning pruned system with tar pipe..."
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
      -print | grep -v include > #{$ramfs_dir}/contents"

    size =`cat #{$ramfs_dir}/contents | sudo du -ks | awk '{print $1}'`.to_i # 1024 is the block size output of du with -k option
    size_bytes = ( size/1024 + $config['loopback']['buffer'] ) * 1024
    blocks = size_bytes / $config['loopback']['bs']
    #sh "sudo umount #{$ramfs_dir}/system.img"
    sh "sudo dd if=/dev/zero of=#{$ramfs_dir}/system.img bs=#{$config['loopback']['bs']}K count=#{blocks}"
    sh "sudo mkfs.ext4 -i 4096 #{$ramfs_dir}/system.img"
    sh "sudo mount -o loop #{$ramfs_dir}/system.img #{$ramfs_mount}"
    sh "cat #{$ramfs_dir}/contents | sudo tar -cpf - -T -  | sudo tar -C #{$ramfs_mount} -xpf -" # copy system to loopback via tarpipe
    sh "sudo umount #{$ramfs_mount}"

    # Generate the ramfs containing bootstrap init, and loopback system.img
    Dir.chdir( $ramfs_dir )
    sh "find . | sudo cpio -H newc -ov -R 0:0 | lzma -T #{threads} -9 > #{File.join(bin_dir, $config['ramfs_name'])}"
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
    sh "sed -i 's:^CONFIG_LOCALVERSION=.*$:CONFIG_LOCALVERSION=\"Alchemy-Linux-#{version}\":g' #{kernel_config}"

    sh "echo 'y' | make oldconfig"
    sh "make -j`nproc`"
    sh "make -j`nproc` modules"
    sh "INSTALL_MOD_PATH=#{$chroot_dir} sudo make modules_install"
    sh "mv arch/x86/boot/bzImage #{File.join(bin_dir,$config['image_name'])}"

  end

  desc "(re)build everything"
  task :all, [:version] => [:info, :ramfs] do
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
  $ramfs_dir  = "#{$config['work_dir']}/ramfs"
  $ramfs_mount = "#{$config['work_dir']}/ramfs_mount"
else
  puts "A config file is required. See config.yml.example for details"
  Rake::Task["default"].invoke
  exit 1
end
