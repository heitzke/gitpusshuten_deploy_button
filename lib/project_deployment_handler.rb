class ProjectDeploymentHandler
  attr_accessor :guid, :git_repo, :server_ip, :root_password, :domain, :logger

  def initialize(guid, git_repo, server_ip, root_password, domain='www.example.com', logger=Rails.logger)
    @guid = guid
    @git_repo = git_repo
    @server_ip = server_ip
    @root_password = root_password
    @domain = domain
    @logger = logger
  end

  # For now this will just use CLI commands I think...longer-term it would actually use the gitpusshuten classes directly
  # Each of these methods wraps a CLI command
  def handle_deployment
    clone_git_repo
    cd_into_deploy_dir
    initialize_gitpusshuten
    configure_gitpusshuten
    install_root_ssh_key
    install_rvm
    install_passenger
    add_user
    install_mysql
    add_mysql_user
    configure_database_yml
    push_master
    modify_nginx_vhost
    upload_nginx_vhost
    log "\n== Finished!  You can now visit #{domain} ==\n"
  end

  def base_dir
    "/tmp"
  end

  def deploy_dir
    "#{base_dir}/#{guid}"
  end

  def clone_git_repo
    log "\n== cloning git repo: #{git_repo} ==\n"
    Open3.popen3("git clone #{git_repo} #{deploy_dir}") do |stdin, stdout, stderr|
      log stdout.read
    end
  end

  def cd_into_deploy_dir
    log "\n== cd into deploy dir ==\n"
    sleep 1
    FileUtils.cd(deploy_dir)
  end

  def log(message)
    logger.log message
  end

  def initialize_gitpusshuten
    log "\n== initialize gitpusshuten ==\n"
    sleep 1
    Open3.popen3("heavenly initialize") do |stdin, stdout, stderr|
      stdin.puts '1'
      stdin.close_write
      log stdout.read
    end
  end

  def configure_gitpusshuten
    log "\n== configure gitpusshuten ==\n"
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
    log "\n== install root ssh key ==\n"
    sleep 1
    begin
      Open3.popen3("heavenly user install-root-ssh-key to production") do |stdin, stdout, stderr|
        stdin.puts 'yes'
        stdin.close_write
      end
    rescue
      log 'rescued...'
    end
    Open3.popen3("heavenly user install-root-ssh-key to production") do |stdin, stdout, stderr|
      stdin.puts root_password
      stdin.close_write
      log stdout.read
    end
  end

  def install_rvm
    log "\n== install rvm ==\n"
    sleep 1
    Open3.popen3("heavenly rvm install to production") do |stdin, stdout, stderr|
      stdin.puts '4' # 1.9.2
      stdin.close_write
      log stdout.read
    end
  end

  def install_passenger
    log "\n== install passenger ==\n"
    sleep 1
    Open3.popen3("heavenly passenger install to production") do |stdin, stdout, stderr|
      stdin.puts '1' #Nginx
      stdin.flush
      stdin.puts '1' # Yeah, you can configure it that way
      stdin.close_write
      log stdout.read
    end
  end

  def add_user
    log "\n== add user ==\n"
    sleep 1
    Open3.popen3("heavenly user add to production") do |stdin, stdout, stderr|
      stdin.puts '1'
      stdin.close_write
      log stdout.read
    end
  end

  def install_mysql
    log "\n== install mysql ==\n"
    sleep 1
    Open3.popen3("heavenly mysql install to production") do |stdin, stdout, stderr|
      stdin.puts root_password
      stdin.flush
      stdin.puts root_password
      stdin.close_write
      log stdout.read
    end
  end

  def add_mysql_user
    log "\n== add mysql user ==\n"
    sleep 1
    Open3.popen3("heavenly mysql add-user to production") do |stdin, stdout, stderr|
      stdin.puts root_password
      stdin.flush
      stdin.puts guid # mysql user's password is the guid
      stdin.flush
      stdin.puts guid # mysql user's password is the guid
      stdin.close_write
      log stdout.read
    end
  end

  def configure_database_yml
    log "\n== configure database ==\n"
    file = <<-EOF
      production:
        adapter: mysql
        database: #{guid}_production
        pool: 5
        username: gitpusshuten
        password: #{guid}
        host: localhost
    EOF
    FileUtils.mkdir_p(File.join(deploy_dir, '.gitpusshuten', 'active_record'))
    File.open(File.join(deploy_dir, '.gitpusshuten', 'active_record', 'production.database.yml'), 'w') do |f|
      f << file
    end

    sleep 1
    Open3.popen3("heavenly active_record upload-configuration to production") do |stdin, stdout, stderr|
      log stdout.read
    end
  end

  def push_master
    log "\n== push master ==\n"
    sleep 1
    Open3.popen3("heavenly push branch master to production") do |stdin, stdout, stderr|
      log stdout.read
    end
  end

  def modify_nginx_vhost
    log "\n== modify nginx vhost ==\n"
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
    log "\n== upload nginx vhost ==\n"
    sleep 1
    Open3.popen3("heavenly nginx upload-vhost to production") do |sdtdin, stdout, stderr|
      log stdout.read
    end
  end
end
