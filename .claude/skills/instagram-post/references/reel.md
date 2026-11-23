# Reel

Reference implementation: `arts/src/posts/profissional_post_002.mjs`. Its header comment explains the
pipeline; the renderer is `openRenderer().video` in `arts/src/lib.mjs`.

## Specs

- 1080×1920 (9:16), 30 fps, 20 to 30 s, H.264 + silent AAC, plus a 1080×1920 `cover.png`.
- Safe zone: the Reels interface covers about the top 270px, the bottom 380px and the right edge of the
  lower half, so content stays inside y 280-1540 and x 72-960. The profile grid shows the centre 3:4 of
  the cover; the whole hook must sit inside it.
- The first frame carries the hook: Instagram autoplays from it, and the cover is the hook fully on screen
  (`COVER_TIME`).
- Silent on purpose. Every line is on screen; music is added in the Instagram app from its licensed library.

## Template

Copy the file to `arts/src/posts/<name>.mjs` and change the header, `dir()`, the scenes and the exported
videos array (`{ file, w, h, fps, duration, html, cover: { time, file } }`).

All motion is a CSS animation with an absolute delay on one shared clock: scene windows (`S`), the
helpers `a(name, delay, dur, ease)` and `scene(window, inner, { enter, exit })`, and the shared
keyframes. The renderer pauses every animation, seeks to each frame and screenshots it, so any timing
is reproducible. Scenes overlap by about 0.2s; each runs about 5s with one idea.

## Review

1. Stills first, in seconds, for the hook, a mid-animation moment and the end state of every scene:
   `VIDEO_PREVIEW=0,2.7,5,8 VIDEO_PREVIEW_DIR=<scratchpad>/stills node arts/src/build.mjs <name>`.
   Files are named `t002.7.png`. View each with Read.
2. Confirm `ffmpeg -version` works before the long render. When it fails, point `FFMPEG` at a static
   binary (`find ~/code -path '*ffmpeg-static/ffmpeg'`, needs libx264 and aac); ffprobe is not needed.
3. Full render, about three minutes, in the background: `node arts/src/build.mjs <name>`. A failed
   encode keeps the frames in the temp directory printed in the error, so only the encode is repeated.
4. Decode frames from the final MP4 (`ffmpeg -ss 10 -i reel.mp4 -frames:v 1 frame.png`) at each scene's
   end state and view them. `ffmpeg -i reel.mp4` shows size, fps and duration.

`post.md` for a Reel holds a storyboard table (time, scene, on-screen text, feature shown), the safe-zone
note, the audio note and a plain-text description of the video for accessibility, since Reels have no
alt-text field.
