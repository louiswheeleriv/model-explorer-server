require 'nokogiri'
require 'csv'

class BattleScribeCatalogueParser
  attr_reader :file_path, :csv_path, :include_legends

  def initialize(file_path:, csv_path: nil, include_legends: false)
    @file_path = file_path
    @csv_path = csv_path || Rails.root.join('resources', 'models_seed.csv')
    @include_legends = include_legends
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
      next unless unit_name && !unit_name.strip.empty?

      next if unit_name.strip.downcase.include?('[legends]') && !include_legends
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

namespace :models do
  desc "Parse units from BattleScribe catalogue file and update CSV"
  task :parse_units_from_file => :environment do
    file_path = ENV['file_path']

    unless file_path
      puts "Error: file_path parameter is required"
      puts "Usage: rake battlescribe:parse_units_from_file file_path=\"./path/to/file.cat\""
      exit 1
    end

    parser = BattleScribeCatalogueParser.new(file_path:)
    parser.process
  end

  desc "Parse all BattleScribe catalogue files in ./resources/battlescribe"
  task :parse_units_from_dir => :environment do
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

      parser = BattleScribeCatalogueParser.new(file_path:)
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

  task :sync_models => :environment do
    models_csv_path = Rails.root.join('resources', 'models_seed.csv')
    game_system_name = ENV['game_system'] || 'Warhammer 40k'

    unless File.exist?(models_csv_path)
      puts "Error: Models CSV not found at #{models_csv_path}"
      exit 1
    end

    game_system = GameSystem.find_by(name: game_system_name)
    unless game_system
      puts "Error: GameSystem '#{game_system_name}' not found in database"
      exit 1
    end

    puts "Syncing factions and models from CSV: #{models_csv_path}"
    puts "=" * 80

    total_models = 0
    new_factions = 0
    new_models = 0
    CSV.foreach(models_csv_path, headers: true) do |row|
      faction_name = row['Faction Name']
      model_name = row['Model Name']
      next unless faction_name && model_name

      total_models += 1
      faction = Faction.find_or_create_by!(game_system:, name: faction_name.strip) do |new_faction|
        puts "New faction: #{new_faction.name}"
        new_factions += 1
      end
      Model.find_or_create_by!(faction:, name: model_name.strip) do |new_model|
        puts "[Faction: #{faction_name}] New model: #{new_model.name}"
        new_models += 1
      end
    end
    puts "=" * 80
    puts "Processed #{total_models} models"
    puts "New factions created: #{new_factions}"
    puts "New models created: #{new_models}"
    puts "Sync complete!"
  end
end
