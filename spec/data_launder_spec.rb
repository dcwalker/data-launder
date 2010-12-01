require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe DataLaunder do

  describe ".fetch_data_from_source" do
    before(:each) do
      Date.stub!(:today).and_return("someday")
      DataLaunder.stub!(:generate_file_path).and_return("path")
    end

    it "should call mysqldump with the provided connection options string and generated file path" do
      DataLaunder.should_receive(:mysqldump).with("options > path").and_return("data!")
      DataLaunder.fetch_data_from_source("options")
    end

    it "should return the path to the data file" do
      DataLaunder.stub!(:mysqldump).and_return("data!")
      DataLaunder.fetch_data_from_source("options").should == "path"
    end
  end

  describe ".load_data_on_destination" do
    it "should raise an exception if the data file is missing" do
      File.stub!(:exists?).and_raise
      lambda{DataLaunder.load_data_on_destination("options", "data_file")}.should raise_error
    end
    it "should use the data from the provided data file and connection options" do
      File.stub!(:exists?).and_return(true)
      DataLaunder.should_receive(:'`').with("mysql options < data_file").and_return("data!")
      DataLaunder.load_data_on_destination("options", "data_file")
    end
  end

  describe ".generate_file_path" do
    it "should return a file path that includes the date as a unique value" do
      Date.stub!(:today).and_return("someday")
      DataLaunder.generate_file_path.should match(/#{Date.today.to_s}/)
    end

    it "should return a file path that begins with tmp" do
      DataLaunder.generate_file_path.should match(/^tmp/)
    end
  end

  describe ".mysqldump" do
    it "should call mysqldump with the options provided" do
      DataLaunder.should_receive(:'`').with("mysqldump my options").and_return("data!")
      DataLaunder.mysqldump("my options")
    end

    it "should return the data from mysqldump" do
      DataLaunder.stub!(:'`').and_return("data!")
      DataLaunder.mysqldump("options").should == "data!"
    end
  end
end
