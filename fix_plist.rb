require 'xcodeproj'
project_path = 'LosMusicians.xcodeproj'
project = Xcodeproj::Project.open(project_path)
main_group = project.main_group.children.find { |g| g.name == 'LosMusicians' || g.path == 'LosMusicians' }
preview_group = main_group.children.find { |g| g.name == 'Preview Content' || g.path == 'Preview Content' }

if preview_group
  plist_ref = preview_group.children.find { |f| f.path == 'GoogleService-Info.plist' }
  if plist_ref
    plist_ref.move(main_group)
    puts "Moved GoogleService-Info.plist out of Preview Content group."
  else
    puts "Could not find GoogleService-Info.plist in Preview Content."
  end
end
project.save
