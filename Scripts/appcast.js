const INFO = console.info.bind(console);
const DEBUG = () => {} // console.log.bind(console);

function main() {
    const args = getArugments();
    const info = getherInfo(args);
    const rss = generateXml(info);
    INFO("generated appcast\n", rss);
    const fs = require('fs');
    fs.writeFileSync(args.output, rss, "utf-8");
}
main();

/// steps
function getArugments() {
    if (process.argv.length <= 3) {
        console.error('usage: appcast app [description.md] output.xml');
        process.exit(-1);
    }
    let [node, js, app, description, output] = process.argv
    if (!output) {
        output = description;
        description = null;
    }
    return { app, description, output };
}

function getherInfo(args) {
    const project = getProp('CFBundleName');
    const fileSize = run(`stat -f%z ${project}.zip`);

    const tag = getProp('CFBundleShortVersionString');
    const feedUrl = getProp('SUFeedURL');
    const user = feedUrl.match(/https:\/\/(.*).github.io/)[1];
    const url = `https://github.com/${user}/${project}/releases/download/${tag}/${project}.zip`;

    const build = getProp('CFBundleVersion');
    const description = args.description ? run(`marked --gfm ${args.description}`) : "";
    const date = (new Date()).toUTCString();

    const signature = run(`cat signature | openssl enc -base64`);

    const result = {project, feedUrl, url, build, tag, fileSize, signature, date, description};
    DEBUG("generated info", result);
    return result;

    function getProp(key) {
        const PlistBuddy = '/usr/libexec/PlistBuddy';
        const plistFile = `${args.app}/Contents/Info.plist`;
        const result = run(`${PlistBuddy} -c "Print ${key}" ${plistFile}`);
        DEBUG("prop ${key} -> ${result}");
        return result;
    }
}

function generateXml(info) {
    const {project, feedUrl, url, build, tag, fileSize, signature, date, description} = info;
    const xml = `
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0"
    xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle"
    xmlns:dc="http://purl.org/dc/elements/1.1/">
<channel>
    <title>${project}</title>
    <link>${feedUrl}</link>
    <description>The stable channel of ${project}.</description>
    <language>en</language>
    <item>
        <title>${project} ${tag}</title>
        <pubDate>${date}</pubDate>
        <description>
            <![CDATA[
                ${description}
            ]]>
        </description>
        <enclosure
            url="${url}"
            sparkle:version="${build}"
            sparkle:shortVersionString="${tag}"
            sparkle:dsaSignature="${signature}"
            length="${fileSize}"
            type="application/octet-stream" />
    </item>
</channel>
</rss>
`;
    return xml.trim();
}

/// utils
function run(cmd) {
    DEBUG(`cmd: ${cmd}`);
    const cp = require('child_process');
    const output = cp.execSync(cmd);
    const result = output.toString('utf8');
    DEBUG(`result:\n${result}`);
    return result.trim();
}
