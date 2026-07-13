# Image Preview Test

Use this file to verify Markdown image preview in Neovim.

Place the cursor on the image link below and press `<leader>mp`.

![Reader app icon](/home/tsien/code/reader/apps/web/public/android-chrome-512x512.png)

The same image through an HTML tag:

<img src="/home/tsien/code/reader/apps/web/public/android-chrome-512x512.png" alt="Reader app icon" />

Missing image path for failure-state testing:

![Missing image](./images/not-found.png)
