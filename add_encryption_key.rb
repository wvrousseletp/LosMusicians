require 'xcodeproj'
project_path = 'LosMusicians.xcodeproj'
project = Xcodeproj::Project.open(project_path)
project.targets.each do |target|
  if target.name == 'LosMusicians'
    target.build_configurations.each do |config|
      config.build_settings['INFOPLIST_KEY_ITSAppUsesNonExemptEncryption'] = 'NO'
    end
  end
end
project.save
puts "Added ITSAppUsesNonExemptEncryption = NO to build settings."
