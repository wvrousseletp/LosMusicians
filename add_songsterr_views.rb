require 'xcodeproj'

project_path = 'LosMusicians.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the target
target = project.targets.first

# Define the paths to the new files
files_to_add = [
  'LosMusicians/Views/Home/SongsterrWebView.swift',
  'LosMusicians/Views/Home/SongsterrPlayerView.swift'
]

# Find the group
group = project.main_group.find_subpath('LosMusicians/Views/Home', true)

files_to_add.each do |file_path|
  # Add file reference to the group
  # Using source_tree = 'SOURCE_ROOT' to avoid path duplication issues
  file_ref = group.new_file(file_path)
  file_ref.source_tree = 'SOURCE_ROOT'
  
  # Add the file to the target's build phases
  target.source_build_phase.add_file_reference(file_ref)
  puts "Added #{file_path} to project"
end

project.save
puts "Project saved successfully"
