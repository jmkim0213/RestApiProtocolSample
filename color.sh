grep -rl 'colorSpace="calibratedRGB"' DabangPro/Storyboard/* | xargs sed -i '' 's/colorSpace="calibratedRGB"/colorSpace="custom" customColorSpace="sRGB"/g'
grep -rl 'colorSpace="calibratedRGB"' DabangPro/UI/* | xargs sed -i '' 's/colorSpace="calibratedRGB"/colorSpace="custom" customColorSpace="sRGB"/g'
