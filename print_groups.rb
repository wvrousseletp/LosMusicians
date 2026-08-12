require 'xcodeproj'
project = Xcodeproj::Project.open('LosMusicians.xcodeproj')
main_group = project.main_group

def print_group(group, indent)
  path = group.path || "<no path>"
  puts "#{indent}#{group.name || group.display_name} (#{path})"
  group.groups.each { |g| print_group(g, indent + "  ") }
end

print_group(main_group.groups.find { |g| g.name == 'LosMusicians' || g.display_name == 'LosMusicians' }, "")
