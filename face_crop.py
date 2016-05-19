#!/usr/local/bin/python3
import sys
import os
import math
import cv2
import numpy as np
from subprocess import call

# Get user supplied values
casc_dir = "/usr/local/opt/opencv3/share/OpenCV/haarcascades/"
casc_files = ["haarcascade_frontalface_default.xml", "haarcascade_frontalface_alt.xml",
              "haarcascade_frontalface_alt2.xml"]
rgb_profile = 'icm:/System/Library/ColorSync/Profiles/sRGB Profile.icc'
lab_profile = 'icm:/System/Library/ColorSync/Profiles/Generic Lab Profile.icc'
gray_profile = 'icm:/System/Library/ColorSync/Profiles/Generic Gray Profile.icc'

#targetFaceWidth = .55  # .49
targetFaceHeight = .55  # .49

targetSize = 400

outputDir = sys.argv[1]
#print("Output: " + outputDir)
image_paths = sys.argv[2:]

for image_path in image_paths:

    imagePathBase, ext = os.path.splitext(image_path)
    finalized = os.path.join(outputDir, imagePathBase + ".png")
    # if os.path.exists(finalized):
    #     continue
    
    outDir = os.path.dirname(finalized)
    try:
        os.makedirs(outDir)
    except OSError:
        if not os.path.isdir(outDir):
            raise

    preprocessed = os.path.join(outputDir, imagePathBase + ".tiff")
    preprocess = ['convert', image_path, '-depth', '16',
                  '-profile', rgb_profile,
                  '-strip', '-profile', rgb_profile,
                  '+compress', preprocessed]
    #print(preprocess)
    call(preprocess)

    # Read the image
    read_im = cv2.imread(preprocessed, cv2.IMREAD_ANYDEPTH | cv2.IMREAD_ANYCOLOR)
    os.remove(preprocessed)
    im = np.float32(read_im) / np.iinfo(read_im.dtype).max

    height, width = im.shape[:2]
    grayscale_image = len(im.shape) < 3 or im.shape[2] == 1
    square = min(width, height)

    im_u8 = np.uint8(np.rint(read_im / 256.))
    gray = cv2.cvtColor(im_u8, cv2.COLOR_BGR2GRAY) if not grayscale_image else im_u8
    #print(gray.dtype)
    minSize = (int(square / 4), int(square / 4))


    def process_face(image, face, cascade):
        x, y, w, h = face

        #tw = w / targetFaceWidth  # max(w/targetFaceWidth, min(square,targetSize))
        th = h / targetFaceHeight  # max(h/targetFaceHeight,min(square,targetSize))
        ts = min(th, square) #tw,

        fcx = x + w / 2.0
        fcy = y + h / 2.0

        fcx = int(round(fcx))
        fcy = int(round(fcy))
        # cv2.rectangle(image, (fcx-1, fcy-1), (fcx+1, fcy+1), (0, 255, 0), 2)

        tx = max((fcx - ts / 2.0), 0.0)
        ty = max((fcy - ts / 2.0), 0.0)
        tx -= max(tx + ts - width, 0.0)
        ty -= max(ty + ts - height, 0.0)

        tx = int(round(tx))
        ty = int(round(ty))
        ts = int(round(ts))

        # cv2.rectangle(image, (tx, ty), (tx+ts, ty+ts), (255, 0, 0), 2)

        print("{}\t{}\t{}\t{}\t{}\t{}".format(image_path,
                                              cascade, (x - (width - square) / 2.0) / square,
                                              (y - (height - square) / 2.0) / square,
                                              w / float(square),
                                              h / float(square)))

        #cv2.rectangle(image, (x, y), (x + w, y + h), (0, 255, 0), int(math.ceil(ts/400.)))
        image = image[ty:(ty + ts), tx:(tx + ts)]

        cropped_path = os.path.join(outputDir, imagePathBase + "_cropped.tiff")
        outImage = np.uint16(np.rint(image * np.iinfo(np.uint16).max))
        cv2.imwrite(cropped_path, outImage)

        resized_path = os.path.join(outputDir, imagePathBase + "_resized.tiff")
        img_size = "{0}x{0}!".format(2 * targetSize)
        resize = ['convert', cropped_path, '-depth', '16',
                  '-profile', rgb_profile, '-profile', lab_profile,
                  '-strip', '-profile', lab_profile,
                  '-filter', 'Mitchell', '-resize', img_size,
                  #'-filter', 'Spline', '-distort', 'resize', '800x800!',
                  # '-resize', '800x800!', #'-filter', 'Lanczos', '-distort',
                  '-profile', rgb_profile,
                  '+compress', resized_path]

        #print(resize)
        call(resize)
        os.remove(cropped_path)

        read_image = cv2.imread(resized_path, cv2.IMREAD_ANYDEPTH | cv2.IMREAD_ANYCOLOR)
        os.remove(resized_path)
        image = np.float32(read_image) / np.iinfo(read_image.dtype).max

        # image = cv2.resize(image, (512,512), interpolation=cv2.INTER_AREA)
        # cv2.imshow("", image)
        # cv2.waitKey(0)

        # thumbSize = 400 # min(400,ts)
        # thumb = cv2.resize(image, (thumbSize,thumbSize), interpolation=cv2.INTER_LANCZOS4)
        # cv2.imshow("", thumb)
        # cv2.waitKey(0)

        # if ts > 2*targetSize:
        #     image = cv2.resize(image, (2*targetSize,2*targetSize), interpolation=cv2.INTER_AREA)    
        # elif ts < targetSize:
        #     image = cv2.resize(image, (targetSize,targetSize), interpolation=cv2.INTER_CUBIC)

        image = cv2.cvtColor(image, cv2.COLOR_BGR2LAB)
        clahe = cv2.createCLAHE(clipLimit=0.5, tileGridSize=(16, 16))
        channels = cv2.split(image)

        # channels[0] = cv2.equalizeHist(channels[0])
        minl, maxl = np.percentile(channels[0], [0,100])
        #print(minl, p20l, midl, p80l, maxl)

        ufunc = np.vectorize(lambda x: min(max(0,np.uint8(np.rint((x - minl)/(maxl-minl) * np.iinfo(np.uint8).max))), np.iinfo(np.uint8).max))

        channel_u8 = np.uint8(np.rint(channels[0] * np.iinfo(np.uint8).max / 100.))
        #channel_u8 = ufunc(channels[0])
        #normalized_u8 = channel_u8
        normalized_u8 = clahe.apply(channel_u8)
        channels[0] = np.float32(normalized_u8) * 100. / np.iinfo(np.uint8).max

        image = cv2.merge(channels)
        image = cv2.cvtColor(image, cv2.COLOR_LAB2BGR)

        # thumb = cv2.resize(image, (thumbSize,thumbSize), interpolation=cv2.INTER_LANCZOS4)
        # cv2.imshow("", thumb)
        # cv2.waitKey(0)

        clahe_path = os.path.join(outputDir, imagePathBase + "_clahe.tiff")
        outImage = np.uint16(np.rint(image * np.iinfo(np.uint16).max))
        cv2.imwrite(clahe_path, outImage)

        final_img_size = "{0}x{0}!".format(targetSize)
        final_profile = rgb_profile if not grayscale_image else gray_profile
        finalize = ['convert', clahe_path, '-depth', '16',
                    '-profile', rgb_profile, '-profile', lab_profile,
                    '-filter', 'Mitchell', '-resize', final_img_size,
                    '-profile', final_profile, '-depth', '8', 
                    #'-quality', '90',
                    '-strip',
                    finalized]

        #print(finalize)
        call(finalize)
        os.remove(clahe_path)


    def try_cascades(image):
        cascade = 1
        for casc_file in casc_files:
            # Create the haar cascade
            face_cascade = cv2.CascadeClassifier(casc_dir + casc_file)

            # Detect faces in the image
            def face_detect(img):
                return face_cascade.detectMultiScale(
                    img,
                    scaleFactor=1.05,
                    minNeighbors=5,
                    minSize=minSize
                )

            faces = face_detect(gray)

            if len(faces) == 0:
                m = cv2.getRotationMatrix2D((height / 2, width / 2), -20, 1)
                rot_gray = cv2.warpAffine(gray, m, (height, width))
                rot_faces = face_detect(rot_gray)

                i_m = cv2.invertAffineTransform(m)

                def rotate_points(face):
                    x, y, w, h = face
                    point = (x + w / 2., y + h / 2.)
                    points = np.array([(point, point)], dtype=np.float32)
                    point = cv2.transform(points, i_m)[0][0]
                    return int(point[0] - w / 2.), int(point[1] - h / 2.), w, h

                faces = list(map(rotate_points, rot_faces))

            if len(faces) == 1:
                process_face(image, faces[0], cascade)
                return

            cascade += 1

        #hfw = width * targetFaceWidth
        hfw = hfh = height * targetFaceHeight
        cx, cy = width / 2., height / 2.
        fake_face = (int(round(cx - hfw / 2.)), int(round(cy - hfh / 2.)), int(round(hfw)), int(round(hfh)))
        # cv2.imshow("", image)
        # cv2.waitKey(0)
        process_face(image, fake_face, -1)


    try_cascades(im)
