require 'xcodeproj'
project_path = 'LosMusicians.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

def add_file_to_group(project, target, file_path, group_path)
  group = project.main_group
  group_path.split('/').each do |component|
    group = group.groups.find { |g| g.display_name == component || g.name == component } || group.new_group(component)
  end
  file_ref = group.new_file(file_path)
  target.add_file_references([file_ref])
end

add_file_to_group(project, target, 'LosMusicians/Services/TunerService.swift', 'LosMusicians/Services')
add_file_to_group(project, target, 'LosMusicians/Views/Home/TunerView.swift', 'LosMusicians/Views/Home')
add_file_to_group(project, target, 'LosMusicians/Views/Library/OfflineLibraryView.swift', 'LosMusicians/Views/Library')

project.save
