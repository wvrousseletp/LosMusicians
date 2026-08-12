require 'xcodeproj'

project_path = 'LosMusicians.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the target
target = project.targets.first

# Find the file reference and remove it
group = project.main_group.find_subpath('LosMusicians/Views/Home', true)
file_ref = group.files.find { |f| f.path == 'SongsterrPlayerView.swift' || f.name == 'SongsterrPlayerView.swift' }

if file_ref
  # Remove from build phases
  target.source_build_phase.files.each do |build_file|
    if build_file.file_ref == file_ref
      build_file.remove_from_project
    end
  end
  # Remove from group
  file_ref.remove_from_project
  puts "Removed SongsterrPlayerView.swift from project"
else
  puts "File reference not found in project"
end

project.save
puts "Project saved successfully"
