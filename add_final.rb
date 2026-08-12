require 'xcodeproj'
project_path = 'LosMusicians.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

# Clean
['TunerView.swift', 'TunerService.swift', 'OfflineLibraryView.swift'].each do |file_name|
  target.source_build_phase.files.to_a.each do |build_file|
    if build_file.file_ref && build_file.file_ref.name == file_name || (build_file.file_ref && build_file.file_ref.path && build_file.file_ref.path.include?(file_name))
      build_file.remove_from_project
    end
  end
  
  project.main_group.recursive_children.each do |child|
    if child.is_a?(Xcodeproj::Project::Object::PBXFileReference) && (child.name == file_name || (child.path && child.path.include?(file_name)))
      child.remove_from_project
    end
  end
end

def add_file_correctly(project, target, full_path, group_path)
  group = project.main_group
  group_path.split('/').each do |component|
    group = group.groups.find { |g| g.display_name == component || g.name == component } || group.new_group(component)
  end
  
  # Create a file reference and explicitly set its source_tree to SOURCE_ROOT
  file_name = File.basename(full_path)
  file_ref = group.new_file(file_name)
  file_ref.source_tree = 'SOURCE_ROOT'
  file_ref.set_path(full_path)
  
  target.source_build_phase.add_file_reference(file_ref)
end

add_file_correctly(project, target, 'LosMusicians/Services/TunerService.swift', 'LosMusicians/Services')
add_file_correctly(project, target, 'LosMusicians/Views/Home/TunerView.swift', 'LosMusicians/Views/Home')
add_file_correctly(project, target, 'LosMusicians/Views/Library/OfflineLibraryView.swift', 'LosMusicians/Views/Library')

project.save
