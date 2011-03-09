class ProjectDeploymentHandler
  attr_accessor :guid, :git_repo, :server_ip, :root_password, :domain

  def initialize(guid, git_repo, server_ip, root_password, domain='www.example.com')
    @guid = guid
    @git_repo = git_repo
    @server_ip = server_ip
    @root_password = root_password
    @domain = domain
  end

  # For now this will just use CLI commands I think...longer-term it would actually use the gitpusshuten classes directly
  # Each of these methods wraps a CLI command
  def handle_deployment
    puts "1"
    clone_git_repo
    puts "2"
    cd_into_deploy_dir
    puts "3"
    initialize_gitpusshuten
    puts "4"
    configure_gitpusshuten
    puts "5"
    install_root_ssh_key
    puts "6"
    install_rvm
    puts "7"
    install_passenger
    puts "8"
    add_user
    puts "9"
    install_mysql
    puts "1"
    add_mysql_user
    puts "2"
    configure_database_yml
    puts "3"
    push_master
    puts "4"
    modify_nginx_vhost
    puts "5"
    upload_nginx_vhost
  end

  def base_dir
    "/tmp"
  end

  def deploy_dir
    "#{base_dir}/#{guid}"
  end

  def clone_git_repo
    Open3.popen3("git clone #{git_repo} #{deploy_dir}") do |stdin, stdout, stderr|
      puts stdout.read
    end
  end

  def cd_into_deploy_dir
    sleep 1
    FileUtils.cd(deploy_dir)
  end

  def initialize_gitpusshuten
    sleep 1
    Open3.popen3("heavenly initialize") do |stdin, stdout, stderr|
      stdin.puts '1'
      stdin.close_write
      puts stdout.read
    end
  end

  def configure_gitpusshuten
    sleep 1
    file = <<-EOF
      pusshuten '#{guid}', :production do
        configure do |c|
          c.user   = 'gitpusshuten'
          c.password = '#{guid}'
          c.ip     = '#{server_ip}'
          c.port   = '22'
          c.path   = '/var/applications/'
        end
      
        modules do |m|
          m.add :bundler
          m.add :active_record
          m.add :passenger
          m.add :nginx
          m.add :rvm
          m.add :mysql
        end
      end
    EOF
    File.open(File.join(deploy_dir, '.gitpusshuten', 'config.rb'), 'w') do |f|
      f << file
    end
  end

  def install_root_ssh_key
    sleep 1
    begin
      Open3.popen3("heavenly user install-root-ssh-key to production") do |stdin, stdout, stderr|
        stdin.puts 'yes'
        stdin.close_write
      end
    rescue
      puts 'rescued...'
    end
    Open3.popen3("heavenly user install-root-ssh-key to production") do |stdin, stdout, stderr|
      stdin.puts root_password
      stdin.close_write
      puts stdout.read
    end
  end

  def install_rvm
    sleep 1
    Open3.popen3("heavenly rvm install to production") do |stdin, stdout, stderr|
      stdin.puts '4' # 1.9.2
      stdin.close_write
      puts stdout.read
    end
  end

  def install_passenger
    sleep 1
    Open3.popen3("heavenly passenger install to production") do |stdin, stdout, stderr|
      stdin.puts '1' #Nginx
      stdin.flush
      stdin.puts '1' # Yeah, you can configure it that way
      stdin.close_write
      puts stdout.read
    end
  end

  def add_user
    sleep 1
    Open3.popen3("heavenly user add to production") do |stdin, stdout, stderr|
      stdin.puts '1'
      stdin.close_write
      puts stdout.read
    end
  end

  def install_mysql
    sleep 1
    Open3.popen3("heavenly mysql install to production") do |stdin, stdout, stderr|
      stdin.puts root_password
      stdin.flush
      stdin.puts root_password
      stdin.close_write
      puts stdout.read
    end
  end

  def add_mysql_user
    sleep 1
    Open3.popen3("heavenly mysql add-user to production") do |stdin, stdout, stderr|
      stdin.puts root_password
      stdin.flush
      stdin.puts guid # mysql user's password is the guid
      stdin.flush
      stdin.puts guid # mysql user's password is the guid
      stdin.close_write
      puts stdout.read
    end
  end

  def configure_database_yml
    file = <<-EOF
      production:
        adapter: mysql2 # <--- Notice we are using the MySQL 2 gem.
        encoding: utf8
        reconnect: false
        database: #{guid}_production
        pool: 5
        username: gitpusshuten
        password: #{guid}
        host: localhost
    EOF
    File.open(File.join(deploy_dir, '.gitpusshuten', 'active_record', 'production.database.yml'), 'w') do |f|
      f << file
    end

    sleep 1
    Open3.popen3("heavenly active_record upload-configuration to production")
  end

  def push_master
    sleep 1
    Open3.popen3("heavenly push branch master to production")
  end

  def modify_nginx_vhost
    sleep 1
    file = <<-EOF
      server {
        listen 80;
        server_name #{domain};
        root /var/applications/#{guid}.production/public;
        passenger_enabled on;
      }
    EOF
    File.open(File.join(deploy_dir, '.gitpusshuten', 'nginx', 'production.vhost'), 'w') do |f|
      f << file
    end
  end

  def upload_nginx_vhost
    sleep 1
    Open3.popen3("heavenly nginx upload-vhost to production")
  end
end
