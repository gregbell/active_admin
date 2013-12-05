require 'spec_helper'

describe ActiveAdmin::CSVBuilder do

  describe '.default_for_resource using Post' do
    let(:csv_builder) { ActiveAdmin::CSVBuilder.default_for_resource(Post) }

    it "should return a default csv_builder for Post" do
      csv_builder.should be_a(ActiveAdmin::CSVBuilder)
    end

    specify "the first column should be Id" do
      csv_builder.columns.first.name.should == 'Id'
      csv_builder.columns.first.data.should == :id
    end

    specify "the following columns should be content_column" do
      csv_builder.columns[1..-1].each_with_index do |column, index|
        expect(column.name).to eq Post.content_columns[index].name.humanize
        expect(column.data).to eq Post.content_columns[index].name.to_sym
      end
    end

    context 'when column has a localized name' do
      let(:localized_name) { 'Titulo' }

      before do
        Post.stub(:human_attribute_name).and_call_original
        Post.stub(:human_attribute_name).with(:title){ localized_name }
      end

      it 'gets name from I18n' do
        title_index = Post.content_columns.map(&:name).index('title') + 1 # First col is always id
        expect(csv_builder.columns[title_index].name).to eq localized_name
      end
    end
  end

  context 'when empty' do
    let(:builder){ ActiveAdmin::CSVBuilder.new }

    it "should have no columns" do
      builder.columns.should == []
    end
  end

  context "with a symbol column (:title)" do
    let(:builder) do
      ActiveAdmin::CSVBuilder.new do
        column :title
      end
    end

    it "should have one column" do
      builder.columns.size.should == 1
    end

    describe "the column" do
      let(:column){ builder.columns.first }

      it "should have a name of 'Title'" do
        column.name.should == "Title"
      end

      it "should have the data :title" do
        column.data.should == :title
      end
    end
  end

  context "with a block and title" do
    let(:builder) do
      ActiveAdmin::CSVBuilder.new do
        column "My title" do
          # nothing
        end
      end
    end

    it "should have one column" do
      builder.columns.size.should == 1
    end

    describe "the column" do
      let(:column){ builder.columns.first }

      it "should have a name of 'My title'" do
        column.name.should == "My title"
      end

      it "should have the data :title" do
        column.data.should be_an_instance_of(Proc)
      end
    end
  end

  context "with a separator" do
    let(:builder) do
      ActiveAdmin::CSVBuilder.new :col_sep => ";"
    end

    it "should have proper separator" do
      builder.options.should == {:col_sep => ";"}
    end
  end

  context "with csv_options" do
    let(:builder) do
      ActiveAdmin::CSVBuilder.new :force_quotes => true
    end

    it "should have proper separator" do
      builder.options.should == {:force_quotes => true}
    end
  end

end
