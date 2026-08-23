const puppeteer = require('puppeteer');
(async () => {
  const browser = await puppeteer.launch();
  const page = await browser.newPage();
  page.on('response', response => {
    const url = response.url();
    if (url.includes('.gp') || url.includes('.gpx')) {
      console.log('FOUND TAB FILE:', url);
    }
  });
  await page.goto('https://www.songsterr.com/a/wsa/doors-riders-on-the-storm-solo-guitar-tab-s15');
  await new Promise(r => setTimeout(r, 5000));
  await browser.close();
})();
