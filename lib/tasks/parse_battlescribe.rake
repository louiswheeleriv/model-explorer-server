require 'nokogiri'
require 'csv'

class BattleScribeCatalogueParser
  attr_reader :file_path, :csv_path

  def initialize(file_path, csv_path = nil)
    @file_path = file_path
    @csv_path = csv_path || Rails.root.join('resources', 'models_seed.csv')
  end

  def process
    validate_file!
    ensure_csv_directory!

    puts "Parsing units from: #{file_path}"
    puts "=" * 80

    units = parse_units
    display_units(units)
    update_csv(units)

    puts "=" * 80
    puts "Total: #{units.count} units"
    puts "CSV updated at: #{csv_path}"
  end

  private

  def validate_file!
    unless File.exist?(file_path)
      puts "Error: File not found at #{file_path}"
      exit 1
    end
  end

  def ensure_csv_directory!
    FileUtils.mkdir_p(File.dirname(csv_path))
  end

  def file_name
    @file_name ||= File.basename(file_path)
  end

  def faction_name
    @faction_name ||= file_name.gsub(/\.cat$/, '').split(' - ', 2).last
  end

  def parse_units
    # Parse the XML file
    doc = File.open(file_path) { |f| Nokogiri::XML(f) }

    # Remove namespaces to simplify XPath queries
    doc.remove_namespaces!

    # Find all top-level selectionEntry elements with type="unit" or type="model"
    # We want direct children of sharedSelectionEntries to get the actual units
    unit_entries = doc.xpath('//sharedSelectionEntries/selectionEntry[@type="unit" or @type="model"]')

    units = []
    unit_entries.each do |entry|
      unit_name = entry['name']
      units << unit_name
    end

    # Remove duplicates and sort
    units.uniq.sort
  end

  def display_units(units)
    puts "Found #{units.count} unique units:"
    puts "-" * 80
    units.each_with_index do |unit, index|
      puts "#{index + 1}. #{unit}"
    end
  end

  def update_csv(units)
    # Read existing CSV data (if file exists)
    existing_rows = []
    if File.exist?(csv_path)
      CSV.foreach(csv_path, headers: true) do |row|
        # Keep rows that are NOT from this file
        existing_rows << row.to_h if row['File Name'] != file_name
      end
    end

    # Add new rows for this file
    new_rows = units.map do |unit_name|
      {
        'File Name' => file_name,
        'Faction Name' => faction_name,
        'Model Name' => unit_name
      }
    end

    # Combine and sort all rows
    all_rows = (existing_rows + new_rows).sort_by do |row|
      [row['File Name'], row['Model Name']]
    end

    # Write to CSV
    CSV.open(csv_path, 'w') do |csv|
      # Write headers
      csv << ['File Name', 'Faction Name', 'Model Name']

      # Write all rows
      all_rows.each do |row|
        csv << [row['File Name'], row['Faction Name'], row['Model Name']]
      end
    end

    puts "Total rows in CSV: #{all_rows.count}"
  end
end

namespace :battlescribe do
  desc "Parse units from BattleScribe catalogue file and update CSV"
  task :parse_units => :environment do
    file_path = ENV['file_path']

    unless file_path
      puts "Error: file_path parameter is required"
      puts "Usage: rake battlescribe:parse_units file_path=\"./path/to/file.cat\""
      exit 1
    end

    parser = BattleScribeCatalogueParser.new(file_path)
    parser.process
  end

  desc "Parse all BattleScribe catalogue files in ./resources/battlescribe"
  task :parse_all => :environment do
    battlescribe_dir = Rails.root.join('resources', 'battlescribe')

    unless Dir.exist?(battlescribe_dir)
      puts "Error: Directory not found at #{battlescribe_dir}"
      exit 1
    end

    # Find all .cat files in the directory
    cat_files = Dir.glob(File.join(battlescribe_dir, '*.cat')).sort

    if cat_files.empty?
      puts "No .cat files found in #{battlescribe_dir}"
      exit 0
    end

    puts "Found #{cat_files.count} .cat files to process"
    puts "=" * 80

    cat_files.each_with_index do |file_path, index|
      puts "\n[#{index + 1}/#{cat_files.count}] Processing: #{File.basename(file_path)}"
      puts "-" * 80

      parser = BattleScribeCatalogueParser.new(file_path)
      parser.process
    end

    puts "\n" + "=" * 80
    puts "All files processed successfully!"

    # Show final CSV stats
    csv_path = Rails.root.join('resources', 'models_seed.csv')
    if File.exist?(csv_path)
      total_rows = CSV.read(csv_path).count - 1 # Subtract header row
      puts "Final CSV contains #{total_rows} total models"
    end
  end
end
