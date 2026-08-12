require 'xcodeproj'
project = Xcodeproj::Project.open('LosMusicians.xcodeproj')
target = project.targets.find { |t| t.name == 'LosMusicians' }

services_group = project.main_group.find_subpath('LosMusicians/Services', true)
f1 = services_group.files.find { |f| f.path == 'TabSearchService.swift' }
if f1
  f1.set_path('LosMusicians/Services/TabSearchService.swift')
  f1.source_tree = 'SOURCE_ROOT'
end

home_group = project.main_group.find_subpath('LosMusicians/Views/Home', true)
f2 = home_group.files.find { |f| f.path == 'SearchResultsView.swift' }
if f2
  f2.set_path('LosMusicians/Views/Home/SearchResultsView.swift')
  f2.source_tree = 'SOURCE_ROOT'
end

f3 = home_group.files.find { |f| f.path == 'AILessonPlanView.swift' }
if f3
  f3.set_path('LosMusicians/Views/Home/AILessonPlanView.swift')
  f3.source_tree = 'SOURCE_ROOT'
end

project.save
