# The site's mark: how its files are made

The company's mark is the METACOGNITIVE coin of the Tetrasemaphore. None of the files in `static/`
that show it is drawn by hand or resized from another picture: each is a render of the coin's layered
vector master at its own pixel size.

The master is `MASTER-medallion-METACOGNITIVE-notation-slot820.svg` (sha256 begins `cccfcff10dc74930`,
2,802,185 bytes), in the public repository `IT-Help-San-Diego/tetrasemaphore` at tag `v1.1.0`, folder
`artwork/master/states/proposals/notation/final-masters-2026-10-05/`, and in the deposit
https://doi.org/10.5281/zenodo.24267509 . It is not copied into this repository.

To remake every file, from the repository root:

    RESVG_JS=<folder of @resvg/resvg-js 2.6.2> python3 -I infra/brand-mark/assets.py <MASTER.svg> <a work folder>
    python3 -I infra/brand-mark/mail_logo.py <MASTER.svg> static/bimi-logo.svg
    RESVG_JS=<the same folder> python3 -I infra/brand-mark/pictures.py <MASTER.svg> <on-site.png> <remote.png> <a work folder>

| tool | writes |
|---|---|
| `render.js` | one SVG at one pixel width, with resvg-js 2.6.2, the renderer the published pictures of the coin were made with |
| `tab_icon.py` | the simpler drawing behind the 16 and 32 px frames of `favicon.ico`; its header says exactly what is the master's and what is added |
| `assets.py` | the hero (PNG and WebP), the four PNG icons, `favicon.ico`, the link-preview card |
| `mail_logo.py` | `static/bimi-logo.svg` in the SVG Tiny Portable/Secure profile; its header says what the profile forces out |
| `pictures.py` | the two "How we work" pictures of the home page (20 files), with the coin set over each of the eight owl medallions in the owner's two source pictures, which are not kept here; its header gives the method and the encoder settings |

Where the coin may sit is in `STYLE_GUIDE.md`, under "Brand Mark".
