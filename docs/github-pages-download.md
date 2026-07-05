# GitHub Pages download pattern

Use this pattern in your separate GitHub Pages repository so the Download button fetches the latest release asset directly from GitHub Releases without redirecting users to GitHub.

```html
<a id="download-link" href="#">Download Everlastimer</a>
<script>
  async function getLatestRelease() {
    const response = await fetch('https://api.github.com/repos/OoADARSHoO/EVERLASTIMER/releases/latest');
    const data = await response.json();
    const asset = data.assets.find((item) => item.name.endsWith('.exe'));
    return asset ? asset.browser_download_url : null;
  }

  (async () => {
    const link = document.getElementById('download-link');
    const url = await getLatestRelease();
    if (url) {
      link.href = url;
      link.textContent = 'Download Everlastimer';
    } else {
      link.href = '#';
      link.textContent = 'Download unavailable';
    }
  })();
</script>
```

Replace the repository placeholder with your own GitHub owner and repo name.
