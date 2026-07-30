const xcode = require('xcode');
const fs = require('fs');

const projectPath = 'LosMusicians.xcodeproj/project.pbxproj';
const myProj = xcode.project(projectPath);

myProj.parseSync();

const configurations = myProj.pbxXCBuildConfigurationSection();
for (const key in configurations) {
    if (configurations[key].buildSettings && configurations[key].buildSettings.PRODUCT_NAME === '"LosMusicians"') {
        configurations[key].buildSettings.INFOPLIST_KEY_CFBundleURLTypes = `(
            {
                CFBundleTypeRole = Editor;
                CFBundleURLSchemes = (
                    "com.googleusercontent.apps.973584151756-1dutt4u0djfff6mvsjsnsr0cprl6o9qk",
                );
            },
        )`;
    }
}

fs.writeFileSync(projectPath, myProj.writeSync());
console.log('URL Scheme added to project.pbxproj');
