# Showcase source

`render_showcase.py` builds the README header and the two short, silent GIFs
from the project's existing logo, Retail HUD screenshot and `forever-sim.png`.
It uses Pillow and DejaVu Sans from the local system; no hosted generation is
required. The GIFs animate stills and are not gameplay footage.

The Forever source image was rendered with wow-ui-sim v0.1.41's Forever build
from KwikTip Forever 0.1.0-alpha.7. `forever-state.lua` supplies a synthetic
Normal-mode Hall of Thanes and invokes the actual `/kwik boss 1` handler. The
simulator ran with networking disabled, the client's data mounted read-only,
and a scratch session without saved variables. The game UI art shown is from
the client. The simulator logged unrelated Blizzard SocialToast errors and
some missing texture resolutions; it reported no addon load failure or
fixture execution error. The render is an illustration, not live-client
verification.

To regenerate the composed assets on a system with Pillow and DejaVu Sans:

```sh
python3 media/src/render_showcase.py
```
