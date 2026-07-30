require 'xcodeproj'
project_path = 'LosMusicians.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

# Helper to add a file to the project and target
def add_file(project, target, file_path, group_path)
  group = project.main_group
  group_path.split('/').each do |g|
    group = group.groups.find { |child| child.name == g || child.path == g } || group.new_group(g)
  end
  
  file_ref = group.new_reference(file_path)
  target.add_file_references([file_ref])
end

add_file(project, target, 'LosMusicians/Models/ExerciseModel.swift', 'LosMusicians/Models')
add_file(project, target, 'LosMusicians/Services/GeminiService.swift', 'LosMusicians/Services')
add_file(project, target, 'LosMusicians/Services/NotificationManager.swift', 'LosMusicians/Services')
add_file(project, target, 'LosMusicians/Views/Community/LeaderboardView.swift', 'LosMusicians/Views/Community')
add_file(project, target, 'LosMusicians/Views/SavedExercisesView.swift', 'LosMusicians/Views')

project.save
