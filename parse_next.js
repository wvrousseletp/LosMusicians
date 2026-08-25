const fs = require('fs');
const html = fs.readFileSync('songsterr.html', 'utf8');
const match = html.match(/<script id="__NEXT_DATA__" type="application\/json">(.*?)<\/script>/);
if (match) {
    const data = JSON.parse(match[1]);
    const song = data.props.pageProps.song;
    console.log("Found song data!");
    console.log(JSON.stringify(song.revisions[0], null, 2));
} else {
    console.log("No NEXT_DATA found");
}
