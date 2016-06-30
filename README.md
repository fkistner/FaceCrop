FaceCrop
========

Crop profile pictures consistently using face detection for use on an OrgChart
or similar.

### Usage

`FaceCrop inPath outPath [outFormat] [outSize] [outQuality]`

### Prerequisites

-   Xcode

-   opencv3  
    in `/usr/local/opt/opencv3`  
    `brew install homebrew/science/opencv3`

-   imagemagick with Little CMS 2 (and optionally HDRI) support  
    in `/usr/local/opt/imagemagick`  
    `brew reinstall imagemagick --with-hdri --with-little-cms2`
