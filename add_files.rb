require 'xcodeproj'

project_path = 'LosMusicians.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'LosMusicians' }

files_to_add = [
  'LosMusicians/Services/TabSearchService.swift',
  'LosMusicians/Views/Home/SearchResultsView.swift',
  'LosMusicians/Views/Home/AILessonPlanView.swift'
]

files_to_add.each do |file_path|
  # Skip if already in project
  next if project.files.find { |f| f.path == file_path }
  
  # Get or create group
  group_path = File.dirname(file_path).sub('LosMusicians/', '')
  group = project.main_group.find_subpath(File.join('LosMusicians', group_path), true)
  
  group.set_source_tree('<group>')
  group.set_path(group_path)
  
  # Add file reference
  file_ref = group.new_reference(File.basename(file_path))
  
  # Add to build phase
  target.source_build_phase.add_file_reference(file_ref)
  puts "Added #{file_path}"
end

project.save
