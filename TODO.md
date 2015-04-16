
Improvements:

- If a block device is mounted check its mountpoint for things like / and /home to protect users
- Check SHA hashes of images
- Add option to specify URL of image
- Have script get the image URLs from a web service that's always up to date
- When no file name is given in the headers of an image try and get it from the URL