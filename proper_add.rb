require 'xcodeproj'
project = Xcodeproj::Project.open('LosMusicians.xcodeproj')
target = project.targets.find { |t| t.name == 'LosMusicians' }

services_group = project.main_group.find_subpath('LosMusicians/Services', true)
unless services_group.files.find { |f| f.path == 'TabSearchService.swift' }
  file_ref = services_group.new_file('TabSearchService.swift')
  target.source_build_phase.add_file_reference(file_ref)
end

home_group = project.main_group.find_subpath('LosMusicians/Views/Home', true)
unless home_group.files.find { |f| f.path == 'SearchResultsView.swift' }
  file_ref2 = home_group.new_file('SearchResultsView.swift')
  target.source_build_phase.add_file_reference(file_ref2)
end

unless home_group.files.find { |f| f.path == 'AILessonPlanView.swift' }
  file_ref3 = home_group.new_file('AILessonPlanView.swift')
  target.source_build_phase.add_file_reference(file_ref3)
end

project.save
