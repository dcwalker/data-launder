require 'rubygems'
require 'rake'
require 'yaml'
require 'forgery'
require 'mysql'

config = YAML.load(File.read("config.yml"))
RAILS_ENV = ENV['RAILS_ENV'] || "staging"

desc "copy data from remote sql file to a staging environment, reset specified values and sensitive data"
task :stage_production_data do
  config.each do |app, app_config|
    puts app
    sql_file_name = determin_latest_snapshot(app_config["remote_sql_file_user"], app_config["remote_sql_file_host"], app_config["remote_sql_file_path"])
    success = download_data(app_config["remote_sql_file_user"], app_config["remote_sql_file_host"], File.expand_path(File.join(app_config["remote_sql_file_path"], sql_file_name)), "#{File.dirname(__FILE__)}/#{sql_file_name}")
    next unless success
    sql_file_name = sql_file_name.sub(/.gz/, '') if gunzip(sql_file_name)
    puts sql_file_name
    stage_data(sql_file_name, get_stage_database_config(app_config["database_config_location"]))
    local_cleanup(sql_file_name)
    reset_data(get_stage_database_config(app_config["database_config_location"]), app_config["specified_values"], app_config["sensitive_fields"])
  end
end

def determin_latest_snapshot(user, host, path)
  `ssh #{user}\@#{host} -t ls -m #{path}`.split(",").last.strip
end

def download_data(remote_user, remote_host, remote_path, local_dest)
  puts "scp #{remote_user}\@#{remote_host}:#{remote_path} #{local_dest}"
  `scp #{remote_user}\@#{remote_host}:#{remote_path} #{local_dest}`
  File.exists?(local_dest)
end

def gunzip(file)
  puts "gunzip #{file}"
  `gunzip #{file}`
  File.exists?(file.sub(/.gz/, ''))
end

def get_stage_database_config(database_config)
  YAML.load(File.read("#{database_config}")).fetch(RAILS_ENV)
end

def stage_data(sql_file, stage_config)
  puts "mysql --host=#{stage_config["host"]} --user=#{stage_config["user"]} --password=#{stage_config["password"]} #{stage_config["database"]} < #{sql_file}"
  `mysql --host=#{stage_config["host"]} --user=#{stage_config["user"]} --password=#{stage_config["password"]} #{stage_config["database"]} < #{sql_file}`
end

def reset_data(stage_config, specified_values, sensitive_fields)
  connection = Mysql.connect(stage_config["host"], stage_config["user"], stage_config["password"], stage_config["database"])
  unless(specified_values.nil?)
    specified_values.each do |table_name, table|
      table.each do |column, value|
        statement = connection.prepare("update #{table_name} set #{column} = '#{value}'")
        statement.execute
        statement.close
      end
    end
  end
  unless(sensitive_fields.nil?)
    sensitive_fields.each do |table, column|
      statement = connection.prepare("update #{table} set #{column} = ? where id = ?")
      connection.query("select id from #{table}").each do |id|
        statement.execute(get_forgery_string(column), id[0])
      end
      statement.close
    end
  end
end

def get_forgery_string(type)
  case type
    when "email"
      value = Forgery(:internet).email_address
    when "first_name"
      value = Forgery(:name).first_name
    when "last_name"
      value = Forgery(:name).last_name
    when *
      value = Forgery(:basic).number
    end
end

def local_cleanup(file)
  `rm #{file}`
  !File.exists?(file)
end