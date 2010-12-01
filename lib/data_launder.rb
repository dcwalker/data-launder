module DataLaunder

  def self.fetch_data_from_source(connect_opts_string)
    file_path = self.generate_file_path
    self.mysqldump("#{connect_opts_string} > #{file_path}")
    return file_path
  end

  def self.load_data_on_destination(connect_opts_string, data_file)
    raise "Data file does not exist" unless File.exists?(data_file)
    `mysql #{connect_opts_string} < #{data_file}`
  end

  def self.generate_file_path
    File.join("tmp", "db-data-#{Date.today.to_s}.sql")
  end

  def self.mysqldump(options)
    `mysqldump #{options}`
  end

end
