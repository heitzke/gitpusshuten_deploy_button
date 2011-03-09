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
  end

  def base_dir
    "/tmp"
  end

  def deploy_dir
    "/#{base_dir}/#{guid}"
  end

  def clone_git_repo
    `git clone #{git_repo} #{deploy_dir}`
  end

  def cd_into_deploy_dir
    `cd #{deploy_dir}`
  end

  def initialize_gitpusshuten
    `heavenly initialize`
  end

  def configure_gitpusshuten
    file = <<-EOF
      pusshuten '#{guid}', :production do
        configure do |c|
          c.user   = 'gitpusshuten'
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
    `heavenly user install-root-ssh-key to production`
  end

  def install_rvm
    `heavenly rvm install to production`
  end

  def install_passenger
    `heavenly passenger install to production`
  end

  def add_user
    `heavenly user add to production`
  end

  def install_mysql
    `heavenly mysql install to production`
  end

  def add_mysql_user
    `heavenly mysql add-user to production`
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
  end

  def push_master
    `heavenly push branch master to production`
  end

  def modify_nginx_vhost
    file = <<-EOF
      server {
        listen 80;
        server_name #{domain}
        root /var/applications/#{guid}.production/public;
        passenger_enabled on;
      }
    EOF
  end

  def upload_nginx_vhost
    `heavenly nginx upload-vhost to production`
  end
end
