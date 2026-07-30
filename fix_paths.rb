require 'xcodeproj'
project_path = 'LosMusicians.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Iterate over all file references and fix those starting with "LosMusicians/"
project.files.each do |file_ref|
  if file_ref.path && file_ref.path.start_with?('LosMusicians/')
    puts "Fixing path for: #{file_ref.path}"
    file_ref.set_path(file_ref.path.sub('LosMusicians/', ''))
  end
end

project.save
