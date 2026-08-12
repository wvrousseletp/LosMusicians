require 'xcodeproj'

project_path = 'LosMusicians.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the group and remove the double nesting by fixing its path
services_group = project.main_group.find_subpath('LosMusicians/Services', false)
if services_group
  services_group.set_path('Services')
end

home_group = project.main_group.find_subpath('LosMusicians/Views/Home', false)
if home_group
  home_group.set_path('Home')
end

project.save
