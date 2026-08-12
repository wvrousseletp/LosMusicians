require 'xcodeproj'
project_path = 'LosMusicians.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

# Limpar novamente
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

def add_file_correctly(project, target, file_name, group_path)
  # O group path deve ser relativo ao SRCROOT (que é onde o .xcodeproj está)
  group = project.main_group
  group_path.split('/').each do |component|
    group = group.groups.find { |g| g.display_name == component || g.name == component } || group.new_group(component)
  end
  
  # new_file(path, source_tree = :group) -> se o path for o nome do arquivo, ele entende que está no diretório do group!
  # O diretório do group deve refletir a pasta real.
  file_ref = group.new_file(file_name)
  target.source_build_phase.add_file_reference(file_ref)
end

# Os arquivos estão em:
# LosMusicians/Services/TunerService.swift
# LosMusicians/Views/Home/TunerView.swift
# LosMusicians/Views/Library/OfflineLibraryView.swift

add_file_correctly(project, target, 'TunerService.swift', 'LosMusicians/Services')
add_file_correctly(project, target, 'TunerView.swift', 'LosMusicians/Views/Home')
add_file_correctly(project, target, 'OfflineLibraryView.swift', 'LosMusicians/Views/Library')

project.save
