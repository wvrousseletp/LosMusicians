require 'xcodeproj'
project_path = 'LosMusicians.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

# Remove bad references
target.source_build_phase.files.each do |build_file|
  if build_file.file_ref && build_file.file_ref.path && build_file.file_ref.path.start_with?('LosMusicians/')
    if build_file.file_ref.path.include?('TunerView.swift') || build_file.file_ref.path.include?('TunerService.swift') || build_file.file_ref.path.include?('OfflineLibraryView.swift')
      build_file.file_ref.remove_from_project
    end
  end
end

def add_file_correctly(project, target, real_path, group_path)
  group = project.main_group
  group_path.split('/').each do |component|
    group = group.groups.find { |g| g.display_name == component || g.name == component } || group.new_group(component)
  end
  # Real path should just be the relative path from the group, which is usually just the filename!
  file_name = File.basename(real_path)
  
  # Remove if it exists
  existing = group.files.find { |f| f.path == file_name }
  existing.remove_from_project if existing
  
  file_ref = group.new_file(file_name)
  target.add_file_references([file_ref])
end

add_file_correctly(project, target, 'LosMusicians/Services/TunerService.swift', 'LosMusicians/Services')
add_file_correctly(project, target, 'LosMusicians/Views/Home/TunerView.swift', 'LosMusicians/Views/Home')
add_file_correctly(project, target, 'LosMusicians/Views/Library/OfflineLibraryView.swift', 'LosMusicians/Views/Library')

project.save
